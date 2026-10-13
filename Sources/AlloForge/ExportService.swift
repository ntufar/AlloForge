import Foundation
import AlloForgeCore
import PDFKit
import AppKit

/// Export VERA CSV, traceability matrix, PDF report, ASM ZIP. Offline.
struct ExportService {
    private let exporter = VeraExporter()

    func saveVeraCSV(cases: [VeraTestCase]) {
        write(text: exporter.veraCSV(cases: cases), fileName: "vera_report.csv")
    }

    func saveTraceability(files: [VendorFile]) {
        write(text: exporter.traceabilityCSV(files: files), fileName: "traceability_matrix.csv")
    }

    func saveValidationPDF(files: [VendorFile], cases: [VeraTestCase]) {
        let pass = cases.filter { $0.status == .pass }.count
        let body = """
        AlloForge Validation Report
        Generated: \(ISO8601DateFormatter().string(from: Date()))
        Files: \(files.count)
        VERA cases: \(cases.count), passed: \(pass), failed: \(cases.count - pass)

        """ + files.prefix(100).map { f in
            "\(f.fileName) [\(f.status.rawValue)] coverage \(Int(f.merckKeyFieldCoverage * 100))% issues \(f.issues.count)"
        }.joined(separator: "\n")
        guard let page = PDFPage(image: renderImage(text: body)) else { return }
        let doc = PDFDocument()
        doc.insert(page, at: 0)
        writePDF(doc, fileName: "validation_report.pdf")
    }

    func saveAsmZip(files: [VendorFile]) {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("alloforge_asm_\(Int(Date().timeIntervalSince1970))")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for file in files {
            let out = dir.appendingPathComponent(file.fileName + ".asm.json")
            try? (file.asmJSON ?? "{}").write(to: out, atomically: true, encoding: .utf8)
        }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "asm_bundle.zip"
        panel.allowedContentTypes = [.zip]
        if panel.runModal() == .OK, let dest = panel.url {
            try? FileManager.default.removeItem(at: dest)
            zipFolder(dir, to: dest)
        }
    }

    // MARK: - Helpers

    private func write(text: String, fileName: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = fileName
        if panel.runModal() == .OK, let dest = panel.url {
            try? text.write(to: dest, atomically: true, encoding: .utf8)
        }
    }

    private func writePDF(_ doc: PDFDocument, fileName: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = fileName
        if panel.runModal() == .OK, let dest = panel.url {
            doc.write(to: dest)
        }
    }

    private func renderImage(text: String) -> NSImage {
        let attr = NSAttributedString(string: text, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        ])
        let size = attr.boundingRect(
            with: NSSize(width: 550, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin]).size
        let height = max(size.height + 40, 700)
        let image = NSImage(size: NSSize(width: 600, height: height))
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: 600, height: height).fill()
        attr.draw(at: NSPoint(x: 24, y: max(0, height - size.height - 24)))
        image.unlockFocus()
        return image
    }

    private func zipFolder(_ folder: URL, to dest: URL) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        task.arguments = ["-jr", dest.path, folder.path]
        try? task.run()
        task.waitUntilExit()
    }
}
