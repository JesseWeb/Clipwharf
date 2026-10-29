import Foundation

public enum AppPaths {
    public static let appName = "Clipwharf"

    /// `~/Library/Application Support/Clipwharf` on macOS.
    public static func defaultDirectory(fileManager: FileManager = .default) -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
                .appendingPathComponent("Library/Application Support", isDirectory: true)
        return base.appendingPathComponent(appName, isDirectory: true)
    }
}

public enum ClipwharfBuildInfo {
    public static let version = "1.0.0"
    public static let license = "AGPL-3.0"
    public static let tagline = "A tiny, local clipboard history for macOS."
    public static let sourceURL = "https://github.com/JesseWeb/Clipwharf"
}
