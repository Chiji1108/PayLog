// App Store 用の完成画像を合成する。
// 使い方: swift scripts/compose-screenshots.swift <素材ディレクトリ> <出力ディレクトリ>
//
// 素材（UI テストが撮ったアプリ画面）に、キャッチコピーと端末フレームを重ねる。
// 素材と同名の JSON（UI テストが記録した拡大範囲）があれば、その部分を拡大して端末の上に重ねる。
// 並び順とコピーは下の `shots` で決める。

import AppKit
import CoreText
import ImageIO
import UniformTypeIdentifiers

struct Shot {
    enum Layout {
        /// コピーの下に端末全体を置く
        case phone
        /// コピー、アプリアイコン、下から覗く端末
        case icon
    }

    let source: String
    let caption: [String]
    var layout: Layout = .phone
}

let shots = [
    Shot(source: "01-subscriptions", caption: ["サブスクだけじゃない。", "クレカも銀行も、まとめて整理"]),
    Shot(source: "02-subscription-detail", caption: ["支払い方法と、ひもづく。", "クレカも口座振替も請求書も"]),
    Shot(source: "06-card-detail", caption: ["このクレカ、どこで使ってる？", "ひと目でわかる"]),
    Shot(source: "05-subscriptions-inactive", caption: ["利用中、停止中、解約予定も。", "未来、過去、現在の記録を残せる"]),
    Shot(source: "08-bank-detail", caption: ["いざという時にも、困らない。", "大切な情報を、きちんと残す"]),
    Shot(source: "07-card-notifications", caption: ["クレカのうっかりを防ぐ。", "締め日・引き落とし日を通知"]),
    Shot(source: "03-subscription-editor", caption: ["もちろんサブスク管理も充実。", "お好きな通貨と周期で"]),
    Shot(source: "04-subscription-insights", caption: ["あなたの固定費の内訳は？", "サブスク集計もおまかせあれ"]),
    Shot(source: "09-onboarding", caption: ["iCloudに自動バックアップ。", "ログイン不要、データ収集なし"], layout: .icon),
]

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    fatalError("usage: compose-screenshots.swift <raw-dir> <output-dir>")
}
let rawDirectory = URL(fileURLWithPath: arguments[1])
let outputDirectory = URL(fileURLWithPath: arguments[2])
let iconURL = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("../PayLog/Assets.xcassets/AppIcon.appiconset/Icon.png")

/// UI テストが記録した拡大範囲。記録のない素材では nil
func loadHighlight(_ url: URL) -> CGRect? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    guard let highlight = try? JSONDecoder().decode(CGRect.self, from: data) else {
        fatalError("拡大範囲を読み込めない: \(url.path)")
    }
    return highlight
}

func loadImage(_ url: URL) -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fatalError("画像を読み込めない: \(url.path)")
    }
    return image
}

/// 左上原点の座標で描くためのキャンバス。出力は素材と同じピクセルサイズ・アルファなし。
struct Canvas {
    let context: CGContext
    let width: CGFloat
    let height: CGFloat

    init(width: Int, height: Int) {
        context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )!
        self.width = CGFloat(width)
        self.height = CGFloat(height)
        // 背景
        fill(
            CGRect(x: 0, y: 0, width: width, height: height),
            color: CGColor(red: 0.945, green: 0.949, blue: 0.965, alpha: 1)
        )
    }

    /// 左上原点の矩形を CoreGraphics の左下原点に変換する
    func rect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGRect {
        CGRect(x: x, y: self.height - y - height, width: width, height: height)
    }

    func fill(_ rect: CGRect, radius: CGFloat = 0, color: CGColor) {
        context.setFillColor(color)
        context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
        context.fillPath()
    }

    func draw(_ image: CGImage, in rect: CGRect, radius: CGFloat) {
        context.saveGState()
        context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
        context.clip()
        context.interpolationQuality = .high
        context.draw(image, in: rect)
        context.restoreGState()
    }

    /// 中央揃えの 1 行を、行の中心が `centerY`（左上原点）に来るように描く
    func text(_ string: String, font: CTFont, centerY: CGFloat) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: CGColor(gray: 0.07, alpha: 1),
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: string, attributes: attributes))
        let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
        context.textPosition = CGPoint(
            x: (width - bounds.width) / 2 - bounds.minX,
            y: height - centerY - CTFontGetCapHeight(font) / 2
        )
        CTLineDraw(line, context)
    }

    /// 端末フレームに入れたアプリ画面を、画面上端が `top` に来るように描く。
    /// `highlight`（画面に対する割合）があれば、その部分を拡大して上に重ねる。
    /// `screenWidth` と `centerX` を省くと、キャンバス中央に幅の 72% で置く。
    func phone(_ screen: CGImage, top: CGFloat, screenWidth: CGFloat? = nil, centerX: CGFloat? = nil, highlight: CGRect? = nil) {
        let aspect = CGFloat(screen.height) / CGFloat(screen.width)
        // 既定の幅は、端末の下端がキャンバスに収まる範囲で最大 72%（画面の短い iPhone Duo は小さくなる）
        let screenWidth = screenWidth ?? min(width * 0.72, (height - top - width * 0.06) / aspect)
        let centerX = centerX ?? width / 2
        let screenHeight = screenWidth * aspect
        let screenX = centerX - screenWidth / 2
        let screenRadius = screenWidth * 0.14
        let bezel = screenWidth * 0.028
        let rim = screenWidth * 0.008

        let screenRect = rect(x: screenX, y: top, width: screenWidth, height: screenHeight)
        fill(
            screenRect.insetBy(dx: -(bezel + rim), dy: -(bezel + rim)),
            radius: screenRadius + bezel + rim,
            color: CGColor(red: 0.33, green: 0.36, blue: 0.43, alpha: 1)
        )
        fill(
            screenRect.insetBy(dx: -bezel, dy: -bezel),
            radius: screenRadius + bezel,
            color: CGColor(gray: 0.04, alpha: 1)
        )
        draw(screen, in: screenRect, radius: screenRadius)

        // Dynamic Island（縦長の iPhone だけ。iPhone Duo の外側の画面にはない）
        if aspect > 2 {
            let islandWidth = screenWidth * 0.29
            let islandHeight = screenWidth * 0.085
            fill(
                rect(x: centerX - islandWidth / 2, y: top + screenWidth * 0.032, width: islandWidth, height: islandHeight),
                radius: islandHeight / 2,
                color: CGColor(gray: 0, alpha: 1)
            )
        }

        zoom(screen, highlight, screenRect: screenRect)
    }

    /// 画面の `highlight`（画面に対する割合）の部分を拡大して、端末の上に重ねる
    private func zoom(_ screen: CGImage, _ highlight: CGRect?, screenRect: CGRect) {
        guard let highlight else { return }
        let crop = CGRect(
            x: highlight.minX * CGFloat(screen.width),
            y: highlight.minY * CGFloat(screen.height),
            width: highlight.width * CGFloat(screen.width),
            height: highlight.height * CGFloat(screen.height)
        )
        guard let zoomed = screen.cropping(to: crop) else {
            fatalError("拡大範囲が画面の外にある: \(highlight)")
        }
        // 端末の画面より左右に少しはみ出す大きさ
        let zoomedWidth = screenRect.width * highlight.width * 1.4
        let zoomedHeight = zoomedWidth * crop.height / crop.width
        let zoomedRect = CGRect(
            x: screenRect.midX - zoomedWidth / 2,
            y: screenRect.maxY - highlight.midY * screenRect.height - zoomedHeight / 2,
            width: zoomedWidth,
            height: zoomedHeight
        )
        let zoomedRadius = width * 0.045
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -width * 0.012), blur: width * 0.05, color: CGColor(gray: 0, alpha: 0.3))
        fill(zoomedRect, radius: zoomedRadius, color: CGColor(gray: 1, alpha: 1))
        context.restoreGState()
        draw(zoomed, in: zoomedRect, radius: zoomedRadius)
    }

    func appIcon(_ icon: CGImage, centerY: CGFloat, size: CGFloat) {
        let iconRect = rect(x: (width - size) / 2, y: centerY - size / 2, width: size, height: size)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -size * 0.02), blur: size * 0.08, color: CGColor(gray: 0, alpha: 0.15))
        fill(iconRect, radius: size * 0.2237, color: CGColor(gray: 1, alpha: 1))
        context.restoreGState()
        draw(icon, in: iconRect, radius: size * 0.2237)
    }

    func write(to url: URL) {
        guard let image = context.makeImage(),
              let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            fatalError("画像を書き出せない: \(url.path)")
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            fatalError("画像を書き出せない: \(url.path)")
        }
    }
}

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for (index, shot) in shots.enumerated() {
    let screen = loadImage(rawDirectory.appendingPathComponent("\(shot.source).png"))
    let highlight = loadHighlight(rawDirectory.appendingPathComponent("\(shot.source).json"))
    let canvas = Canvas(width: screen.width, height: screen.height)
    let unit = canvas.width / 100

    let captionFont = CTFontCreateWithName("HiraginoSans-W7" as CFString, unit * 5.4, nil)
    for (lineIndex, line) in shot.caption.enumerated() {
        canvas.text(line, font: captionFont, centerY: unit * (18 + 10.4 * CGFloat(lineIndex)))
    }

    switch shot.layout {
    case .phone:
        canvas.phone(screen, top: unit * 47, highlight: highlight)
    case .icon:
        // 画面の縦横比が違う端末でも収まるよう、キャンバスの高さに対する割合で置く
        let height = canvas.height
        canvas.appIcon(loadImage(iconURL), centerY: height * 0.396, size: height * 0.184)
        canvas.text("PayLog", font: CTFontCreateUIFontForLanguage(.emphasizedSystem, height * 0.023, nil)!, centerY: height * 0.525)
        canvas.phone(screen, top: height * 0.7, screenWidth: canvas.width * 0.72)
    }

    canvas.write(to: outputDirectory.appendingPathComponent(String(format: "%02d.png", index + 1)))
}

// 商品ページのヘッダ用と検索結果用の横長画像（どちらも任意）。
// 端末によって左右が切り取られるので、コピーと中央の端末を真ん中に寄せ、左右の端末は切れてもよい飾りにする。
struct Banner {
    let name: String
    let width: Int
    let height: Int
    /// レイアウトの基準長（ピクセル）
    let unit: CGFloat
}

let banners = [
    Banner(name: "header", width: 3840, height: 1646, unit: 16.5),
    Banner(name: "search", width: 3840, height: 2560, unit: 20),
]

for banner in banners {
    let canvas = Canvas(width: banner.width, height: banner.height)
    let unit = banner.unit
    let screen = { (name: String) in loadImage(rawDirectory.appendingPathComponent("\(name).png")) }

    let captionFont = CTFontCreateWithName("HiraginoSans-W7" as CFString, unit * 6.4, nil)
    for (lineIndex, line) in shots[0].caption.enumerated() {
        canvas.text(line, font: captionFont, centerY: unit * (12 + 11 * CGFloat(lineIndex)))
    }

    canvas.phone(screen("06-card-detail"), top: unit * 46, screenWidth: unit * 44, centerX: canvas.width / 2 - unit * 62)
    canvas.phone(screen("08-bank-detail"), top: unit * 46, screenWidth: unit * 44, centerX: canvas.width / 2 + unit * 62)
    canvas.phone(screen("01-subscriptions"), top: unit * 36, screenWidth: unit * 52)

    canvas.write(to: outputDirectory.appendingPathComponent("\(banner.name).png"))
}

print("完成画像: \(outputDirectory.path)")
