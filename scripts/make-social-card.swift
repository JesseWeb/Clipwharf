#!/usr/bin/env swift
//
// Draw the 1280×640 social preview card into docs/social-preview.png.
//
// Usage: swift scripts/make-social-card.swift
// Upload the result in the repository settings (Settings → Social preview),
// which has no API. GitHub shows it when the repository is linked on social
// sites and in chat apps.

import AppKit

let size = NSSize(width: 1280, height: 640)

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size.width),
    pixelsHigh: Int(size.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("Could not allocate the social card bitmap")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let bounds = NSRect(origin: .zero, size: size)

// Background: deep navy with a soft blue glow in the lower right.
NSGradient(colors: [
    NSColor(srgbRed: 0.043, green: 0.063, blue: 0.110, alpha: 1),
    NSColor(srgbRed: 0.078, green: 0.110, blue: 0.210, alpha: 1)
])?.draw(in: bounds, angle: -70)

if let glow = NSGradient(colors: [
    NSColor(srgbRed: 0.26, green: 0.45, blue: 0.98, alpha: 0.55),
    NSColor(srgbRed: 0.26, green: 0.45, blue: 0.98, alpha: 0.0)
]) {
    let center = NSPoint(x: 1080, y: 120)
    glow.draw(fromCenter: center, radius: 0,
              toCenter: center, radius: 520,
              options: [.drawsAfterEndingLocation])
}

// App icon.
let iconPath = "Support/AppIcon.png"
if let icon = NSImage(contentsOfFile: iconPath) {
    icon.draw(in: NSRect(x: 96, y: 220, width: 200, height: 200))
}

// Wordmark.
let title = "Clipwharf" as NSString
title.draw(
    in: NSRect(x: 344, y: 322, width: 860, height: 110),
    withAttributes: [
        .font: NSFont.systemFont(ofSize: 86, weight: .semibold),
        .foregroundColor: NSColor.white
    ]
)

let tagline = "Local-only clipboard history for macOS" as NSString
tagline.draw(
    in: NSRect(x: 348, y: 268, width: 820, height: 44),
    withAttributes: [
        .font: NSFont.systemFont(ofSize: 30, weight: .regular),
        .foregroundColor: NSColor(srgbRed: 0.72, green: 0.78, blue: 0.90, alpha: 1)
    ]
)

let details = "⌘⇧V  ·  text, links, colors, images, files  ·  pinboards  ·  no cloud" as NSString
details.draw(
    in: NSRect(x: 348, y: 210, width: 880, height: 34),
    withAttributes: [
        .font: NSFont.systemFont(ofSize: 21, weight: .medium),
        .foregroundColor: NSColor(srgbRed: 0.47, green: 0.55, blue: 0.72, alpha: 1)
    ]
)

let repo = "github.com/JesseWeb/Clipwharf" as NSString
repo.draw(
    in: NSRect(x: 348, y: 150, width: 600, height: 30),
    withAttributes: [
        .font: NSFont.monospacedSystemFont(ofSize: 19, weight: .regular),
        .foregroundColor: NSColor(srgbRed: 0.55, green: 0.64, blue: 0.82, alpha: 1)
    ]
)

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode the social card")
}
let output = URL(fileURLWithPath: "docs/social-preview.png")
try png.write(to: output)
print("Wrote \(output.path)")
