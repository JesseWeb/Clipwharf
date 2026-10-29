#!/usr/bin/env swift
//
// Draw the Clipwharf app icon (1024×1024 PNG) into Support/AppIcon.png.
//
// Usage: swift scripts/make-icon.swift
// scripts/make-app.sh turns the PNG into AppIcon.icns with sips + iconutil.
//
// Design: a deep indigo squircle, a soft top sheen, two fanned "history card"
// plates behind a white paperclip. Everything is drawn with AppKit so the icon
// can be regenerated at any resolution.

import AppKit

let size: CGFloat = 1024
let artworkInset: CGFloat = 100
let artwork = NSRect(x: artworkInset,
                     y: artworkInset,
                     width: size - artworkInset * 2,
                     height: size - artworkInset * 2)
let cornerRadius = artwork.width * 0.2237

guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                 pixelsWide: Int(size),
                                 pixelsHigh: Int(size),
                                 bitsPerSample: 8,
                                 samplesPerPixel: 4,
                                 hasAlpha: true,
                                 isPlanar: false,
                                 colorSpaceName: .deviceRGB,
                                 bytesPerRow: 0,
                                 bitsPerPixel: 0) else {
    fatalError("Could not allocate the icon bitmap")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let context = NSGraphicsContext.current!.cgContext

// MARK: - Background squircle

let body = NSBezierPath(roundedRect: artwork,
                        xRadius: cornerRadius,
                        yRadius: cornerRadius)
context.saveGState()
body.addClip()

let gradient = NSGradient(colors: [
    NSColor(srgbRed: 0.28, green: 0.44, blue: 0.98, alpha: 1),
    NSColor(srgbRed: 0.13, green: 0.16, blue: 0.52, alpha: 1)
])
gradient?.draw(in: body, angle: -78)

// Soft radial glow behind the paperclip, so the glyph does not sit on a flat field.
if let glow = NSGradient(colors: [
    NSColor(srgbRed: 0.62, green: 0.78, blue: 1.0, alpha: 0.55),
    NSColor(srgbRed: 0.62, green: 0.78, blue: 1.0, alpha: 0.28),
    NSColor(srgbRed: 0.62, green: 0.78, blue: 1.0, alpha: 0.0)
]) {
    let center = NSPoint(x: artwork.midX, y: artwork.midY + 40)
    glow.draw(fromCenter: center, radius: 0,
              toCenter: center, radius: artwork.width * 0.52,
              options: [.drawsAfterEndingLocation])
}

// Top sheen: a soft vertical wash that fades out well before the edges.
if let sheen = NSGradient(colors: [
    NSColor.white.withAlphaComponent(0.16),
    NSColor.white.withAlphaComponent(0.0)
]) {
    sheen.draw(in: artwork, angle: -90)
}
context.restoreGState()

// MARK: - Depth wash

// A gentle vignette keeps the lower half grounded.
if let vignette = NSGradient(colors: [
    NSColor.black.withAlphaComponent(0.0),
    NSColor.black.withAlphaComponent(0.20)
]) {
    vignette.draw(in: artwork, angle: -90)
}

// MARK: - Paperclip glyph

let symbolSize = artwork.width * 0.50
let config = NSImage.SymbolConfiguration(pointSize: symbolSize, weight: .regular)
guard let raw = NSImage(systemSymbolName: "paperclip", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) else {
    fatalError("paperclip symbol unavailable")
}

// Tint the template glyph white.
let glyph = NSImage(size: raw.size)
glyph.lockFocus()
raw.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1)
NSColor.white.setFill()
NSRect(origin: .zero, size: raw.size).fill(using: .sourceAtop)
glyph.unlockFocus()

let target = NSRect(x: artwork.midX - raw.size.width / 2,
                    y: artwork.midY - raw.size.height / 2 - 6,
                    width: raw.size.width,
                    height: raw.size.height)

context.saveGState()
let glyphShadow = NSShadow()
glyphShadow.shadowColor = NSColor.black.withAlphaComponent(0.30)
glyphShadow.shadowBlurRadius = 30
glyphShadow.shadowOffset = NSSize(width: 0, height: -12)
glyphShadow.set()
glyph.draw(in: target)
context.restoreGState()

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode the icon PNG")
}
let output = URL(fileURLWithPath: "Support/AppIcon.png")
try png.write(to: output)
print("Wrote \(output.path)")
