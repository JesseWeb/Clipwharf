import Foundation
import ServiceManagement

/// "Launch at Login" support.
///
/// Prefers `SMAppService`, the modern login-item API. Ad-hoc signed builds can
/// be rejected by it, so the fallback writes a per-user LaunchAgent instead.
/// Either way the item shows up under System Settings → General → Login Items.
enum LaunchAtLogin {
    private static let agentLabel = "dev.clipwharf.Clipwharf.login"

    private static var agentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
            .appendingPathComponent("\(agentLabel).plist")
    }

    private static var serviceStatus: SMAppService.Status {
        SMAppService.mainApp.status
    }

    static var isEnabled: Bool {
        switch serviceStatus {
        case .enabled, .requiresApproval:
            return true
        default:
            return FileManager.default.fileExists(atPath: agentURL.path)
        }
    }

    /// True when the system still wants the user to approve the item.
    static var needsApproval: Bool {
        serviceStatus == .requiresApproval
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            if serviceStatus == .enabled || serviceStatus == .requiresApproval {
                return
            }
            do {
                try SMAppService.mainApp.register()
                removeAgentFile()
            } catch {
                try installAgent()
            }
        } else {
            if serviceStatus == .enabled || serviceStatus == .requiresApproval {
                try? SMAppService.mainApp.unregister()
            }
            unloadAgent()
            removeAgentFile()
        }
    }

    /// Opens System Settings → General → Login Items.
    static func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    // MARK: - LaunchAgent fallback

    private static func installAgent() throws {
        let executable = Bundle.main.executablePath
            ?? Bundle.main.bundlePath + "/Contents/MacOS/Clipwharf"

        let plist: [String: Any] = [
            "Label": agentLabel,
            "ProgramArguments": [executable],
            "RunAtLoad": true,
            "ProcessType": "Interactive",
            "LimitLoadToSessionType": "Aqua"
        ]

        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        try FileManager.default.createDirectory(
            at: agentURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: agentURL, options: .atomic)
    }

    private static func removeAgentFile() {
        try? FileManager.default.removeItem(at: agentURL)
    }

    /// Unloads the agent if this login session already bootstrapped it.
    private static func unloadAgent() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["bootout", "gui/\(getuid())/\(agentLabel)"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
    }
}
