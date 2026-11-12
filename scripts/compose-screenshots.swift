// App Store 用の完成画像を合成する。
// 使い方: swift scripts/compose-screenshots.swift <素材のルート> <出力のルート>
//
// 素材のルートには、端末ごとのディレクトリ（UI テストが撮ったアプリ画面）が並ぶ。
// 素材に、キャッチコピーと端末フレームを重ねる。
// 素材と同名の JSON（UI テストが記録した拡大範囲）があれば、その部分を拡大して端末の上に重ねる。
// 並び順とコピーは下の `phoneShots` と `tabletShots` で決める。

import AppKit
import CoreText
import ImageIO
import UniformTypeIdentifiers

struct Shot {
    enum Layout {
        /// コピーの下に端末全体を置く
        case device
        /// コピー、アプリアイコン、下から覗く端末
        case icon
        /// コピー、アプリアイコン、下から覗く iPad と iPhone（iPhone の素材がなければ iPad だけ）
        case iconWithPhone
    }

    let source: String
    let caption: [String]
    var layout: Layout = .device
}

/// iPhone と iPhone Duo（外側の画面）の並び
let phoneShots = [
    Shot(source: "subscriptions", caption: ["サブスクだけじゃない。", "クレカも銀行も、まとめて整理"]),
    Shot(source: "subscription-insights", caption: ["あなたの固定費の内訳は？", "カテゴリーごとに、ひと目で"]),
    Shot(source: "subscription-detail", caption: ["支払い方法と、ひもづく。", "クレカも口座振替も請求書も"]),
    Shot(source: "card-detail", caption: ["このクレカ、どこで使ってる？", "ひと目でわかる"]),
    Shot(source: "card-notifications", caption: ["クレカのうっかりを防ぐ。", "締め日・引き落とし日を通知"]),
    Shot(source: "subscriptions-inactive", caption: ["利用中、停止中、解約予定も。", "未来、過去、現在の記録を残せる"]),
    Shot(source: "bank-detail", caption: ["いざという時にも、困らない。", "大切な情報を、きちんと残す"]),
    Shot(source: "subscription-editor", caption: ["もちろんサブスク管理も充実。", "お好きな通貨と周期で"]),
    Shot(source: "onboarding", caption: ["iCloudに自動バックアップ。", "ログイン不要、データ収集なし"], layout: .icon),
]

/// iPad（横向き）の並び。一覧と詳細が 1 枚に収まるので、枚数が少ない
let tabletShots = [
    Shot(source: "subscriptions", caption: ["サブスクだけじゃない。", "クレカも銀行も、まとめて整理"]),
    Shot(source: "subscription-insights", caption: ["あなたの固定費の内訳は？", "カテゴリーごとに、ひと目で"]),
    Shot(source: "card-detail", caption: ["このクレカ、どこで使ってる？", "ひと目でわかる"]),
    Shot(source: "card-notifications", caption: ["クレカのうっかりを防ぐ。", "締め日・引き落とし日を通知"]),
    Shot(source: "bank-detail", caption: ["いざという時にも、困らない。", "大切な情報を、きちんと残す"]),
    Shot(source: "subscriptions", caption: ["iCloudに自動バックアップ。", "iPhoneでもiPadでも"], layout: .iconWithPhone),
]

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    fatalError("usage: compose-screenshots.swift <raw-root> <output-root>")
}
let rawRoot = URL(fileURLWithPath: arguments[1])
let outputRoot = URL(fileURLWithPath: arguments[2])
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

/// 画像を、記録された向きのとおりに読み込む（横向きで撮った iPad の素材は、縦向きの画像に向きの情報が付く）
func loadImage(_ url: URL) -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let width = properties[kCGImagePropertyPixelWidth] as? Int,
          let height = properties[kCGImagePropertyPixelHeight] as? Int,
          let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
              kCGImageSourceCreateThumbnailFromImageAlways: true,
              kCGImageSourceCreateThumbnailWithTransform: true,
              kCGImageSourceThumbnailMaxPixelSize: max(width, height),
          ] as CFDictionary) else {
        fatalError("画像を読み込めない: \(url.path)")
    }
    return image
}

/// 端末ごとの素材。端末の種類は、画面の形で見分ける。
struct Device {
    enum Kind {
        /// 縦長の iPhone
        case phone
        /// iPhone Duo の外側の画面
        case foldable
        /// 横向きの iPad
        case tablet
    }

    let name: String
    let directory: URL
    let kind: Kind

    init(directory: URL) {
        self.directory = directory
        name = directory.lastPathComponent
        let screen = loadImage(directory.appendingPathComponent("subscriptions.png"))
        if screen.width > screen.height {
            kind = .tablet
        } else if screen.height > screen.width * 2 {
            kind = .phone
        } else {
            kind = .foldable
        }
    }

    func screen(_ source: String) -> CGImage {
        loadImage(directory.appendingPathComponent("\(source).png"))
    }

    func highlight(_ source: String) -> CGRect? {
        loadHighlight(directory.appendingPathComponent("\(source).json"))
    }
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

    /// 中央揃えの 1 行を、行の中心が `centerY`（左上原点）に来るように描く。`centerX` を省くとキャンバスの中央に置く
    func text(_ string: String, font: CTFont, centerY: CGFloat, centerX: CGFloat? = nil) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: CGColor(gray: 0.07, alpha: 1),
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: string, attributes: attributes))
        let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
        context.textPosition = CGPoint(
            x: (centerX ?? width / 2) - bounds.width / 2 - bounds.minX,
            y: height - centerY - CTFontGetCapHeight(font) / 2
        )
        CTLineDraw(line, context)
    }

    /// 端末フレームの太さ（画面の幅に対する割合）。黒い縁と、その外側の細い枠
    static let bezelRatio: CGFloat = 0.028
    static let rimRatio: CGFloat = 0.008

    /// 端末フレームの下端が `bottom` に来るように描く。複数の端末を同じ面に置いたように並べるときに使う
    func device(_ screen: CGImage, bottom: CGFloat, screenWidth: CGFloat, centerX: CGFloat) {
        let screenHeight = screenWidth * CGFloat(screen.height) / CGFloat(screen.width)
        let frame = screenWidth * (Canvas.bezelRatio + Canvas.rimRatio)
        device(screen, top: bottom - frame - screenHeight, screenWidth: screenWidth, centerX: centerX)
    }

    /// 端末フレームに入れたアプリ画面を、画面上端が `top` に来るように描く。
    /// `highlight`（画面に対する割合）があれば、その部分を拡大して上に重ねる。
    /// `screenWidth` と `centerX` を省くと、キャンバス中央に幅の 72% で置く。
    func device(_ screen: CGImage, top: CGFloat, screenWidth: CGFloat? = nil, centerX: CGFloat? = nil, highlight: CGRect? = nil) {
        let aspect = CGFloat(screen.height) / CGFloat(screen.width)
        // 既定の幅は、端末の下端がキャンバスに収まる範囲で最大 72%（画面の短い iPhone Duo は小さくなる）
        let screenWidth = screenWidth ?? min(width * 0.72, (height - top - width * 0.06) / aspect)
        let centerX = centerX ?? width / 2
        let screenHeight = screenWidth * aspect
        let screenX = centerX - screenWidth / 2
        // 画面の角の丸み。縦横比が 4:3 に近い iPad は小さい
        let screenRadius = screenWidth * (aspect < 1.4 ? 0.04 : 0.14)
        let bezel = screenWidth * Canvas.bezelRatio
        let rim = screenWidth * Canvas.rimRatio

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
            x: screenRect.minX + highlight.midX * screenRect.width - zoomedWidth / 2,
            y: screenRect.maxY - highlight.midY * screenRect.height - zoomedHeight / 2,
            width: zoomedWidth,
            height: zoomedHeight
        )
        // 角の丸みは端末の大きさに合わせる。行の低い iPad では、丸くなりすぎないよう高さでも抑える
        let zoomedRadius = min(screenRect.width * 0.0625, zoomedHeight * 0.2)
        context.saveGState()
        context.setShadow(
            offset: CGSize(width: 0, height: -screenRect.width * 0.017),
            blur: screenRect.width * 0.07,
            color: CGColor(gray: 0, alpha: 0.3)
        )
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

let devices = try FileManager.default
    .contentsOfDirectory(at: rawRoot, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
    .filter(\.hasDirectoryPath)
    .sorted { $0.lastPathComponent < $1.lastPathComponent }
    .map(Device.init)
let phone = devices.first { $0.kind == .phone }
let foldable = devices.first { $0.kind == .foldable }
let tablet = devices.first { $0.kind == .tablet }

func captionFont(size: CGFloat) -> CTFont {
    CTFontCreateWithName("HiraginoSans-W7" as CFString, size, nil)
}

for device in devices {
    let outputDirectory = outputRoot.appendingPathComponent(device.name)
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

    let shots = device.kind == .tablet ? tabletShots : phoneShots
    for (index, shot) in shots.enumerated() {
        let screen = device.screen(shot.source)
        let canvas = Canvas(width: screen.width, height: screen.height)
        // レイアウトの基準長。横向きのキャンバスでは、高さに収まるよう小さくする
        let unit = min(canvas.width, canvas.height * 0.6) / 100
        let height = canvas.height

        for (lineIndex, line) in shot.caption.enumerated() {
            canvas.text(line, font: captionFont(size: unit * 5.4), centerY: unit * (18 + 10.4 * CGFloat(lineIndex)))
        }

        switch shot.layout {
        case .device:
            canvas.device(screen, top: unit * 47, highlight: device.highlight(shot.source))
        case .icon:
            // 画面の縦横比が違う端末でも収まるよう、キャンバスの高さに対する割合で置く
            canvas.appIcon(loadImage(iconURL), centerY: height * 0.396, size: height * 0.184)
            canvas.text("PayLog", font: CTFontCreateUIFontForLanguage(.emphasizedSystem, height * 0.023, nil)!, centerY: height * 0.525)
            canvas.device(screen, top: height * 0.7, screenWidth: canvas.width * 0.72)
        case .iconWithPhone:
            canvas.appIcon(loadImage(iconURL), centerY: height * 0.4, size: height * 0.2)
            canvas.text("PayLog", font: CTFontCreateUIFontForLanguage(.emphasizedSystem, height * 0.03, nil)!, centerY: height * 0.55)
            if let phone {
                canvas.device(screen, top: height * 0.66, screenWidth: canvas.width * 0.5, centerX: canvas.width * 0.42)
                canvas.device(phone.screen("subscriptions"), top: height * 0.7, screenWidth: canvas.width * 0.13, centerX: canvas.width * 0.8)
            } else {
                canvas.device(screen, top: height * 0.66, screenWidth: canvas.width * 0.5)
            }
        }

        canvas.write(to: outputDirectory.appendingPathComponent(String(format: "%02d.png", index + 1)))
    }
    print("完成画像: \(outputDirectory.path)")
}

// 商品ページのヘッダ用と検索結果用の横長画像（どちらも任意）。iPhone・iPhone Duo・iPad に対応していることを見せる。
// 端末によって左右が切り取られるので、大事なものは中央に寄せる。
if let phone, let foldable, let tablet {
    let caption = phoneShots[0].caption

    // 検索結果用（3:2）: 上にコピー、下に 3 台
    do {
        let canvas = Canvas(width: 3840, height: 2560)
        let unit: CGFloat = 20
        let center = canvas.width / 2
        for (lineIndex, line) in caption.enumerated() {
            canvas.text(line, font: captionFont(size: unit * 6.4), centerY: unit * (12 + 11 * CGFloat(lineIndex)))
        }
        canvas.device(phone.screen("card-detail"), bottom: unit * 112, screenWidth: unit * 30, centerX: center - unit * 72)
        canvas.device(foldable.screen("subscription-insights"), bottom: unit * 112, screenWidth: unit * 32, centerX: center + unit * 73)
        canvas.device(tablet.screen("subscriptions"), bottom: unit * 112, screenWidth: unit * 96, centerX: center)
        canvas.write(to: outputRoot.appendingPathComponent("search.png"))
    }

    // ヘッダ用（21:9）: 横長を活かして、左にコピー、右に 3 台。端末は切らずに全体を見せる
    do {
        let canvas = Canvas(width: 3840, height: 1646)
        let width = canvas.width
        let height = canvas.height
        for (lineIndex, line) in caption.enumerated() {
            canvas.text(
                line,
                font: captionFont(size: height * 0.06),
                centerY: height * (0.44 + 0.12 * CGFloat(lineIndex)),
                centerX: width * 0.22
            )
        }
        // 3 台を同じ面に置いたように、下端をそろえる
        let baseline = height * 0.79
        canvas.device(phone.screen("card-detail"), bottom: baseline, screenWidth: width * 0.078, centerX: width * 0.474)
        canvas.device(tablet.screen("subscriptions"), bottom: baseline, screenWidth: width * 0.302, centerX: width * 0.698)
        canvas.device(foldable.screen("subscription-insights"), bottom: baseline, screenWidth: width * 0.083, centerX: width * 0.927)
        canvas.write(to: outputRoot.appendingPathComponent("header.png"))
    }

    print("ヘッダ用と検索結果用の画像: \(outputRoot.path)")
} else {
    print("ヘッダ用と検索結果用の画像は作らない（iPhone・iPhone Duo・iPad の素材がそろっていない）")
}
