// App Store 用の完成画像を合成する。
// 使い方: swift scripts/compose-screenshots.swift <素材ディレクトリ> <出力ディレクトリ>
//
// 素材（UI テストが撮ったアプリ画面）に、キャッチコピーと端末フレームを重ねる。
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

    /// 端末フレームに入れたアプリ画面を、画面上端が `top` に来るように描く
    func phone(_ screen: CGImage, top: CGFloat) {
        let screenWidth = width * 0.72
        let screenHeight = screenWidth * CGFloat(screen.height) / CGFloat(screen.width)
        let screenX = (width - screenWidth) / 2
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

        // Dynamic Island
        let islandWidth = screenWidth * 0.29
        let islandHeight = screenWidth * 0.085
        fill(
            rect(x: (width - islandWidth) / 2, y: top + screenWidth * 0.032, width: islandWidth, height: islandHeight),
            radius: islandHeight / 2,
            color: CGColor(gray: 0, alpha: 1)
        )
    }

    func appIcon(_ icon: CGImage, centerY: CGFloat) {
        let size = width * 0.4
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
    let canvas = Canvas(width: screen.width, height: screen.height)
    let unit = canvas.width / 100

    canvas.fill(
        CGRect(x: 0, y: 0, width: canvas.width, height: canvas.height),
        color: CGColor(red: 0.945, green: 0.949, blue: 0.965, alpha: 1)
    )

    let captionFont = CTFontCreateWithName("HiraginoSans-W7" as CFString, unit * 5.4, nil)
    for (lineIndex, line) in shot.caption.enumerated() {
        canvas.text(line, font: captionFont, centerY: unit * (18 + 10.4 * CGFloat(lineIndex)))
    }

    switch shot.layout {
    case .phone:
        canvas.phone(screen, top: unit * 47)
    case .icon:
        canvas.appIcon(loadImage(iconURL), centerY: unit * 86)
        canvas.text("PayLog", font: CTFontCreateUIFontForLanguage(.emphasizedSystem, unit * 5, nil)!, centerY: unit * 114)
        canvas.phone(screen, top: unit * 152)
    }

    canvas.write(to: outputDirectory.appendingPathComponent(String(format: "%02d.png", index + 1)))
}

print("完成画像: \(outputDirectory.path)")
