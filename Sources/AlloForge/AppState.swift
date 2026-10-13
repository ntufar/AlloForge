import Foundation
import Observation
import SwiftUI
import UniformTypeIdentifiers
import AlloForgeCore

/// Shared app state. Runs parse work off the main thread.
@Observable
@MainActor
final class AppState {
    var files: [VendorFile] = []
    var veraCases: [VeraTestCase] = []
    var selection: VendorFile.ID?
    var isBusy = false
    var statusMessage = "Drop CSVs or a ZIP onto the window."
    var searchText = ""
    var statusFilter: FileStatus? = nil
    var watchFolderURL: URL?

    private let engine = FingerprintEngine()
    private let asm = AsmBuilder()
    private let vera = VeraGenerator()
    private var watcher: FileWatcherService?

    var selectedFile: VendorFile? {
        files.first { $0.id == selection }
    }

    var filteredFiles: [VendorFile] {
        files.filter { file in
            if let f = statusFilter, file.status != f { return false }
            if searchText.isEmpty { return true }
            return file.fileName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var passedCount: Int { files.filter { $0.status == .pass }.count }
    var failedCount: Int { files.filter { $0.status == .fail }.count }
    var warningCount: Int { files.filter { $0.status == .warning }.count }
    var avgCoverage: Double {
        guard !files.isEmpty else { return 0 }
        return files.map { $0.merckKeyFieldCoverage }.reduce(0, +) / Double(files.count)
    }

    func importURLs(_ urls: [URL]) async {
        isBusy = true
        defer { isBusy = false }
        var inputs: [(fileName: String, data: Data)] = []
        for url in urls {
            let resolved = url.resolvingSymlinksInPath()
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: resolved.path, isDirectory: &isDir) else { continue }
            if isDir.boolValue {
                let found = (try? FileManager.default.contentsOfDirectory(
                    at: resolved, includingPropertiesForKeys: nil)) ?? []
                for f in found where f.pathExtension.lowercased() == "csv" {
                    if let data = try? Data(contentsOf: f) {
                        inputs.append((fileName: f.lastPathComponent, data: data))
                    }
                }
            } else if resolved.pathExtension.lowercased() == "zip" {
                if let data = try? Data(contentsOf: resolved),
                   let parsed = try? await engine.fingerprintZip(data) {
                    addFingerprinted(parsed)
                }
            } else {
                if let data = try? Data(contentsOf: resolved) {
                    inputs.append((fileName: resolved.lastPathComponent, data: data))
                }
            }
        }
        if !inputs.isEmpty {
            let parsed = await engine.fingerprintMany(inputs)
            addFingerprinted(parsed)
        }
    }

    private func addFingerprinted(_ parsed: [VendorFile]) {
        var enriched = parsed
        for i in enriched.indices {
            enriched[i].asmJSON = asm.buildJSON(for: enriched[i])
        }
        let names = Set(files.map { $0.fileName })
        let fresh = enriched.filter { !names.contains($0.fileName) }
        files.append(contentsOf: fresh)
        files.sort { $0.fileName < $1.fileName }
        veraCases = vera.generateAll(for: files)
        if selection == nil { selection = files.first?.id }
        statusMessage = "\(files.count) files. \(failedCount) fail, \(warningCount) warn, \(passedCount) pass."
    }

    func startWatching(_ url: URL) {
        watchFolderURL = url
        watcher?.stop()
        watcher = FileWatcherService(url: url) { [weak self] newCSVs in
            Task { await self?.importURLs(newCSVs) }
        }
        watcher?.start()
        statusMessage = "Watching \(url.path). New CSVs convert on arrival."
    }

    func stopWatching() {
        watcher?.stop()
        watcher = nil
        watchFolderURL = nil
    }
}
