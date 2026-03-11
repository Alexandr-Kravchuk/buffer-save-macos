import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    fatalError("Expected output path")
}

let outputURL = URL(fileURLWithPath: arguments[1])
let imageSize = NSSize(width: 1024, height: 1024)
let canvas = NSImage(size: imageSize)
canvas.lockFocus()

let rect = NSRect(origin: .zero, size: imageSize)
NSColor.clear.setFill()
rect.fill()

let shadow = NSShadow()
shadow.shadowColor = NSColor(calibratedWhite: 0.15, alpha: 0.18)
shadow.shadowBlurRadius = 40
shadow.shadowOffset = NSSize(width: 0, height: -16)
shadow.set()

let backgroundRect = rect.insetBy(dx: 76, dy: 76)
let backgroundPath = NSBezierPath(roundedRect: backgroundRect, xRadius: 220, yRadius: 220)
let backgroundGradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.97, green: 0.98, blue: 0.99, alpha: 1),
    NSColor(calibratedRed: 0.85, green: 0.89, blue: 0.94, alpha: 1),
])!
backgroundGradient.draw(in: backgroundPath, angle: -90)

NSGraphicsContext.current?.saveGraphicsState()
let innerShadow = NSShadow()
innerShadow.shadowColor = NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 0.55)
innerShadow.shadowBlurRadius = 18
innerShadow.shadowOffset = NSSize(width: 0, height: 8)
innerShadow.set()
NSColor(calibratedWhite: 1, alpha: 0.4).setStroke()
backgroundPath.lineWidth = 4
backgroundPath.stroke()
NSGraphicsContext.current?.restoreGraphicsState()

let documentRect = NSRect(x: 298, y: 226, width: 428, height: 536)
let documentPath = NSBezierPath(roundedRect: documentRect, xRadius: 82, yRadius: 82)
let documentGradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.99, green: 0.995, blue: 1, alpha: 1),
    NSColor(calibratedRed: 0.95, green: 0.97, blue: 0.99, alpha: 1),
])!
documentGradient.draw(in: documentPath, angle: -90)
NSColor(calibratedRed: 0.71, green: 0.78, blue: 0.87, alpha: 1).setStroke()
documentPath.lineWidth = 6
documentPath.stroke()

let clipRect = NSRect(x: 414, y: 718, width: 196, height: 72)
let clipPath = NSBezierPath(roundedRect: clipRect, xRadius: 36, yRadius: 36)
NSColor(calibratedRed: 0.33, green: 0.45, blue: 0.57, alpha: 1).setFill()
clipPath.fill()

let lineColor = NSColor(calibratedRed: 0.72, green: 0.79, blue: 0.87, alpha: 1)
for offset in stride(from: 0, through: 3, by: 1) {
    let y = 628 - CGFloat(offset) * 70
    let lineRect = NSRect(x: 374, y: y, width: 276, height: 14)
    let linePath = NSBezierPath(roundedRect: lineRect, xRadius: 7, yRadius: 7)
    lineColor.setFill()
    linePath.fill()
}

let trayPath = NSBezierPath()
trayPath.lineWidth = 36
trayPath.lineCapStyle = .round
trayPath.move(to: NSPoint(x: 392, y: 338))
trayPath.line(to: NSPoint(x: 632, y: 338))
trayPath.move(to: NSPoint(x: 432, y: 338))
trayPath.line(to: NSPoint(x: 432, y: 292))
trayPath.move(to: NSPoint(x: 592, y: 338))
trayPath.line(to: NSPoint(x: 592, y: 292))
NSColor(calibratedRed: 0.19, green: 0.34, blue: 0.52, alpha: 1).setStroke()
trayPath.stroke()

let arrowPath = NSBezierPath()
arrowPath.lineWidth = 36
arrowPath.lineCapStyle = .round
arrowPath.lineJoinStyle = .round
arrowPath.move(to: NSPoint(x: 512, y: 560))
arrowPath.line(to: NSPoint(x: 512, y: 372))
arrowPath.line(to: NSPoint(x: 454, y: 430))
arrowPath.move(to: NSPoint(x: 512, y: 372))
arrowPath.line(to: NSPoint(x: 570, y: 430))
NSColor(calibratedRed: 0.16, green: 0.48, blue: 0.78, alpha: 1).setStroke()
arrowPath.stroke()

canvas.unlockFocus()

guard let tiffData = canvas.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Failed to generate icon")
}

try pngData.write(to: outputURL, options: .atomic)
