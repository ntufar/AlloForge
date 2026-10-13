import AppKit

/// Brings the window forward on launch.
/// Needed when the app runs as a bare binary with no app bundle.
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        // Order the first window front in case it opens behind Xcode.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
