import Foundation

/// Export VERA CSV (JIRA XRAY format) + traceability matrix.
public struct VeraExporter: Sendable {
    public init() {}

    /// Build VERA CSV text.
    public func veraCSV(cases: [VeraTestCase]) -> String {
        var lines = ["TestCaseID,FileName,Title,Status,Detail"]
        for c in cases {
            lines.append([
                csvCell(c.caseID), csvCell(c.fileName), csvCell(c.title),
                csvCell(c.status.rawValue.uppercased()), csvCell(c.detail)
            ].joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// Build traceability matrix CSV.
    public func traceabilityCSV(files: [VendorFile]) -> String {
        var lines = ["FileName,Requirement,TestCaseID,Status"]
        for file in files {
            for tc in VeraGenerator().generate(for: file) {
                lines.append([
                    csvCell(file.fileName), csvCell(tc.title),
                    csvCell(tc.caseID), csvCell(tc.status.rawValue.uppercased())
                ].joined(separator: ","))
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }

    private func csvCell(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}
