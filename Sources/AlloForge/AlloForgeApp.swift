import SwiftUI
import AlloForgeCore

@main
struct AlloForgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var state = AppState()

    var body: some Scene {
        WindowGroup {
            MainWindowView(state: state)
                .frame(minWidth: 1100, minHeight: 650)
        }
        .commands {
            CommandGroup(after: .importExport) {
                Button("Watch Folder…") { pickWatchFolder() }
                Button("Stop Watching") { state.stopWatching() }
                    .disabled(state.watchFolderURL == nil)
            }
        }
    }

    private func pickWatchFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() == .OK, let url = panel.url {
            state.startWatching(url)
        }
    }
}
