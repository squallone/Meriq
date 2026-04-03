import AppKit
import Foundation

enum IconGenerationError: Error {
    case missingContext
    case couldNotCreatePNG
}

let outputDirectory: URL = {
    if let customPath = CommandLine.arguments.dropFirst().first {
        return URL(fileURLWithPath: customPath, isDirectory: true)
    }

    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent("Sources/Meriq/Resources/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
}()

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let iconFiles: [(String, CGFloat)] = [
    ("appicon_16.png", 16),
    ("appicon_32.png", 32),
    ("appicon_64.png", 64),
    ("appicon_128.png", 128),
    ("appicon_256.png", 256),
    ("appicon_512.png", 512),
    ("appicon_1024.png", 1024)
]

for (filename, size) in iconFiles {
    let destination = outputDirectory.appendingPathComponent(filename)
    try renderIcon(side: size, to: destination)
}

func renderIcon(side: CGFloat, to url: URL) throws {
    let image = NSImage(size: NSSize(width: side, height: side))

    image.lockFocus()
    guard let context = NSGraphicsContext.current?.cgContext else {
        throw IconGenerationError.missingContext
    }

    let canvas = CGRect(x: 0, y: 0, width: side, height: side)
    context.clear(canvas)
    context.interpolationQuality = .high
    context.setAllowsAntialiasing(true)

    let cardInset = side * 0.055
    let cardRect = canvas.insetBy(dx: cardInset, dy: cardInset)
    let cardRadius = side * 0.23

    let shadow = NSShadow()
    shadow.shadowColor = NSColor(calibratedRed: 0.06, green: 0.14, blue: 0.17, alpha: 0.22)
    shadow.shadowBlurRadius = side * 0.07
    shadow.shadowOffset = NSSize(width: 0, height: -side * 0.02)
    shadow.set()

    let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: cardRadius, yRadius: cardRadius)
    cardPath.addClip()

    NSGradient(
        colors: [
            NSColor(calibratedRed: 0.10, green: 0.55, blue: 0.60, alpha: 1.0),
            NSColor(calibratedRed: 0.10, green: 0.28, blue: 0.36, alpha: 1.0)
        ]
    )?.draw(in: cardRect, angle: -70)

    NSColor(calibratedRed: 0.98, green: 0.72, blue: 0.42, alpha: 0.38).setFill()
    NSBezierPath(ovalIn: CGRect(x: cardRect.minX - side * 0.02, y: cardRect.maxY - side * 0.44, width: side * 0.52, height: side * 0.52)).fill()

    NSColor(calibratedRed: 0.71, green: 0.93, blue: 0.88, alpha: 0.18).setFill()
    NSBezierPath(ovalIn: CGRect(x: cardRect.maxX - side * 0.34, y: cardRect.minY + side * 0.06, width: side * 0.34, height: side * 0.34)).fill()

    let sheetRect = CGRect(
        x: side * 0.18,
        y: side * 0.18,
        width: side * 0.64,
        height: side * 0.64
    )
    let sheetRadius = side * 0.11

    let innerShadow = NSShadow()
    innerShadow.shadowColor = NSColor(calibratedWhite: 1.0, alpha: 0.2)
    innerShadow.shadowBlurRadius = side * 0.02
    innerShadow.shadowOffset = NSSize(width: 0, height: side * 0.008)
    innerShadow.set()

    let sheetPath = NSBezierPath(roundedRect: sheetRect, xRadius: sheetRadius, yRadius: sheetRadius)
    NSGradient(
        colors: [
            NSColor(calibratedRed: 1.0, green: 0.98, blue: 0.94, alpha: 1.0),
            NSColor(calibratedRed: 0.95, green: 0.92, blue: 0.86, alpha: 1.0)
        ]
    )?.draw(in: sheetPath, angle: 90)

    NSColor(calibratedRed: 0.27, green: 0.35, blue: 0.37, alpha: 0.10).setStroke()
    sheetPath.lineWidth = max(side * 0.008, 1)
    sheetPath.stroke()

    let clipRect = CGRect(
        x: sheetRect.midX - side * 0.10,
        y: sheetRect.maxY - side * 0.04,
        width: side * 0.20,
        height: side * 0.10
    )
    let clipPath = NSBezierPath(roundedRect: clipRect, xRadius: side * 0.04, yRadius: side * 0.04)
    NSColor(calibratedRed: 0.13, green: 0.21, blue: 0.25, alpha: 0.95).setFill()
    clipPath.fill()

    let nodeLine = NSBezierPath()
    nodeLine.lineWidth = max(side * 0.045, 2)
    nodeLine.lineCapStyle = .round
    nodeLine.lineJoinStyle = .round

    let leftNodeCenter = CGPoint(x: sheetRect.minX + side * 0.19, y: sheetRect.midY + side * 0.02)
    let topRightNodeCenter = CGPoint(x: sheetRect.maxX - side * 0.18, y: sheetRect.maxY - side * 0.18)
    let bottomRightNodeCenter = CGPoint(x: sheetRect.maxX - side * 0.18, y: sheetRect.minY + side * 0.19)

    nodeLine.move(to: CGPoint(x: leftNodeCenter.x + side * 0.10, y: leftNodeCenter.y + side * 0.035))
    nodeLine.line(to: CGPoint(x: topRightNodeCenter.x - side * 0.08, y: topRightNodeCenter.y))
    nodeLine.move(to: CGPoint(x: leftNodeCenter.x + side * 0.10, y: leftNodeCenter.y - side * 0.035))
    nodeLine.line(to: CGPoint(x: bottomRightNodeCenter.x - side * 0.09, y: bottomRightNodeCenter.y))
    NSColor(calibratedRed: 0.18, green: 0.30, blue: 0.33, alpha: 0.82).setStroke()
    nodeLine.stroke()

    let leftNodeRect = CGRect(
        x: leftNodeCenter.x - side * 0.12,
        y: leftNodeCenter.y - side * 0.07,
        width: side * 0.24,
        height: side * 0.14
    )
    let leftNodePath = NSBezierPath(roundedRect: leftNodeRect, xRadius: side * 0.05, yRadius: side * 0.05)
    NSColor(calibratedRed: 0.98, green: 0.70, blue: 0.41, alpha: 1.0).setFill()
    leftNodePath.fill()

    let diamondSize = side * 0.19
    let diamondPath = NSBezierPath()
    diamondPath.move(to: CGPoint(x: topRightNodeCenter.x, y: topRightNodeCenter.y + diamondSize * 0.5))
    diamondPath.line(to: CGPoint(x: topRightNodeCenter.x + diamondSize * 0.5, y: topRightNodeCenter.y))
    diamondPath.line(to: CGPoint(x: topRightNodeCenter.x, y: topRightNodeCenter.y - diamondSize * 0.5))
    diamondPath.line(to: CGPoint(x: topRightNodeCenter.x - diamondSize * 0.5, y: topRightNodeCenter.y))
    diamondPath.close()
    NSColor(calibratedRed: 0.55, green: 0.86, blue: 0.77, alpha: 1.0).setFill()
    diamondPath.fill()

    let bottomNodeRect = CGRect(
        x: bottomRightNodeCenter.x - side * 0.13,
        y: bottomRightNodeCenter.y - side * 0.07,
        width: side * 0.26,
        height: side * 0.14
    )
    let bottomNodePath = NSBezierPath(roundedRect: bottomNodeRect, xRadius: side * 0.05, yRadius: side * 0.05)
    NSColor(calibratedRed: 0.93, green: 0.46, blue: 0.41, alpha: 1.0).setFill()
    bottomNodePath.fill()

    image.unlockFocus()

    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        throw IconGenerationError.couldNotCreatePNG
    }

    try pngData.write(to: url)
}
