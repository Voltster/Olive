import Cocoa

// Create a high-res 1024x1024 macOS Squircle App Icon for Olive
let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

guard let context = NSGraphicsContext.current?.cgContext else {
    exit(1)
}

// 1. Draw macOS App Icon Squircle Base (Dark Obsidian)
let squircleRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let squirclePath = CGPath(roundedRect: squircleRect, cornerWidth: 185, cornerHeight: 185, transform: nil)

context.saveGState()
context.addPath(squirclePath)
context.clip()

// Background Gradient (Deep Space Forest)
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bgColors = [
    CGColor(red: 0.08, green: 0.12, blue: 0.09, alpha: 1.0),
    CGColor(red: 0.04, green: 0.06, blue: 0.05, alpha: 1.0)
] as CFArray

if let gradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0]) {
    context.drawLinearGradient(gradient, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
}

// 2. Glowing Inner Border
context.setStrokeColor(CGColor(red: 0.52, green: 0.80, blue: 0.09, alpha: 0.35))
context.setLineWidth(14)
context.addPath(squirclePath)
context.strokePath()

// 3. Central Olive Fruit Motif
let center = CGPoint(x: 512, y: 470)

// Olive Body (Oval Shape)
context.saveGState()
context.translateBy(x: center.x, y: center.y)
context.rotate(by: -0.26) // slight 15 degree tilt

let oliveRect = CGRect(x: -160, y: -220, width: 320, height: 440)
let olivePath = CGPath(ellipseIn: oliveRect, transform: nil)

let oliveColors = [
    CGColor(red: 0.65, green: 0.88, blue: 0.18, alpha: 1.0), // Lime Glow
    CGColor(red: 0.40, green: 0.65, blue: 0.08, alpha: 1.0), // Deep Olive
    CGColor(red: 0.22, green: 0.40, blue: 0.05, alpha: 1.0)  // Shadow Olive
] as CFArray

if let oliveGrad = CGGradient(colorsSpace: colorSpace, colors: oliveColors, locations: [0.0, 0.6, 1.0]) {
    context.addPath(olivePath)
    context.clip()
    context.drawLinearGradient(oliveGrad, start: CGPoint(x: -80, y: 160), end: CGPoint(x: 80, y: -160), options: [])
}

// Gloss Highlight
context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.22))
let glossRect = CGRect(x: -110, y: 60, width: 90, height: 160)
context.fillEllipse(in: glossRect)

context.restoreGState()

// Leaf on Stem
context.saveGState()
context.translateBy(x: center.x + 30, y: center.y + 210)
context.rotate(by: 0.45)

let leafPath = CGMutablePath()
leafPath.move(to: CGPoint(x: 0, y: 0))
leafPath.addQuadCurve(to: CGPoint(x: 180, y: 70), control: CGPoint(x: 80, y: 90))
leafPath.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: 90, y: -20))

let leafColors = [
    CGColor(red: 0.45, green: 0.78, blue: 0.15, alpha: 1.0),
    CGColor(red: 0.25, green: 0.50, blue: 0.08, alpha: 1.0)
] as CFArray

if let leafGrad = CGGradient(colorsSpace: colorSpace, colors: leafColors, locations: [0.0, 1.0]) {
    context.addPath(leafPath)
    context.clip()
    context.drawLinearGradient(leafGrad, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 180, y: 70), options: [])
}

context.restoreGState()
context.restoreGState()

image.unlockFocus()

// Save PNG
if let tiffData = image.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiffData),
   let pngData = rep.representation(using: .png, properties: [:]) {
    let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
    try? pngData.write(to: URL(fileURLWithPath: outputPath))
    print("Generated app icon at \(outputPath)")
}
