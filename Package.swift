// swift-tools-version: 5.9
//
// Clipwharf — a tiny, local-only clipboard history for macOS.
// GNU AGPL-3.0. Commercial licences: see COMMERCIAL.md.
//
// The executable target imports AppKit/SwiftUI, so it is only declared on
// macOS. Omitting it elsewhere lets the AppKit-free core tests run on Linux.

import PackageDescription

var products: [Product] = []
var targets: [Target] = [
    .target(
        name: "ClipwharfCore",
        path: "Sources/ClipwharfCore"
    ),
    .testTarget(
        name: "ClipwharfCoreTests",
        dependencies: ["ClipwharfCore"],
        path: "Tests/ClipwharfCoreTests"
    )
]

#if os(macOS)
products.append(.executable(name: "Clipwharf", targets: ["Clipwharf"]))
targets.append(
    .executableTarget(
        name: "Clipwharf",
        dependencies: ["ClipwharfCore"],
        path: "Sources/Clipwharf",
        linkerSettings: [
            .linkedFramework("AppKit"),
            .linkedFramework("SwiftUI"),
            .linkedFramework("Carbon"),
            .linkedFramework("ApplicationServices"),
            .linkedFramework("CoreGraphics"),
            .linkedFramework("ServiceManagement"),
            .linkedFramework("QuickLookThumbnailing")
        ]
    )
)
#endif

let package = Package(
    name: "Clipwharf",
    platforms: [
        .macOS(.v13)
    ],
    products: products,
    targets: targets
)
