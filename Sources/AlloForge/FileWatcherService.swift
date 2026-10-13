import Foundation

/// Watch a folder for new CSV files. Uses polling timer, Apple frameworks only.
final class FileWatcherService {
    private let url: URL
    private let onNewFiles: ([URL]) -> Void
    private var timer: Timer?
    private var seen: Set<String> = []

    init(url: URL, onNewFiles: @escaping ([URL]) -> Void) {
        self.url = url
        self.onNewFiles = onNewFiles
    }

    func start() {
        seen = currentCSVs().reduce(into: Set<String>()) { $0.insert($1.path) }
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        let current = currentCSVs()
        let fresh = current.filter { !seen.contains($0.path) }
        for f in fresh { seen.insert(f.path) }
        if !fresh.isEmpty { onNewFiles(fresh) }
    }

    private func currentCSVs() -> [URL] {
        (try? FileManager.default.contentsOfDirectory(
            at: url, includingPropertiesForKeys: nil)) ?? []
    }
}
