import AppKit

let output = CommandLine.arguments.dropFirst().first ?? "Leash.png"
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()
let background = NSBezierPath(roundedRect: NSRect(x: 32, y: 32, width: 960, height: 960), xRadius: 220, yRadius: 220)
NSColor(calibratedRed: 0.95, green: 0.94, blue: 0.90, alpha: 1).setFill()
background.fill()

let ring = NSBezierPath(ovalIn: NSRect(x: 212, y: 212, width: 600, height: 600))
ring.lineWidth = 54
NSColor(calibratedRed: 0.12, green: 0.13, blue: 0.11, alpha: 1).setStroke()
ring.stroke()

let leash = NSBezierPath(roundedRect: NSRect(x: 382, y: 472, width: 260, height: 78), xRadius: 39, yRadius: 39)
var transform = AffineTransform.identity
transform.translate(x: 512, y: 512)
transform.rotate(byDegrees: -35)
transform.translate(x: -512, y: -512)
leash.transform(using: transform)
NSColor(calibratedRed: 0.90, green: 0.33, blue: 0.21, alpha: 1).setFill()
leash.fill()
image.unlockFocus()

guard let data = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: data),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not render icon")
}
try png.write(to: URL(fileURLWithPath: output))
