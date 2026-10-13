import Foundation

/// Generate 5 VERA cases per file. 300 files give 1500 rows.
public struct VeraGenerator: Sendable {
    public init() {}

    public func generate(for file: VendorFile) -> [VeraTestCase] {
        let byCode = Dictionary(grouping: file.issues, by: { $0.code })
        func has(_ code: IssueCode) -> Bool { byCode[code]?.isEmpty == false }

        let keyMissing = byCode[.missingKeyField]?.compactMap { $0.field } ?? []
        let cases: [VeraTestCase] = [
            VeraTestCase(
                caseID: "TC-AUTO-001", fileName: file.fileName,
                title: "Key Fields Present",
                status: keyMissing.isEmpty ? .pass : .fail,
                detail: keyMissing.isEmpty
                    ? "All 5 Merck key fields map."
                    : "Missing: \(keyMissing.joined(separator: ", "))."
            ),
            VeraTestCase(
                caseID: "TC-AUTO-002", fileName: file.fileName,
                title: "pH Range 0-14",
                status: has(.outOfRange) ? .fail : .pass,
                detail: has(.outOfRange)
                    ? "\(byCode[.outOfRange]?.count ?? 0) pH value(s) out of range."
                    : "All pH values in range."
            ),
            VeraTestCase(
                caseID: "TC-AUTO-003", fileName: file.fileName,
                title: "Date Valid",
                status: has(.badDate) ? .fail : .pass,
                detail: has(.badDate)
                    ? "\(byCode[.badDate]?.count ?? 0) bad date(s)."
                    : "All dates parse to ISO8601."
            ),
            VeraTestCase(
                caseID: "TC-AUTO-004", fileName: file.fileName,
                title: "Sample_ID Unique",
                status: has(.duplicateID) ? .fail : .pass,
                detail: has(.duplicateID)
                    ? "Duplicate Sample_ID found."
                    : "Sample_ID values are unique."
            ),
            VeraTestCase(
                caseID: "TC-AUTO-005", fileName: file.fileName,
                title: "Delimiter Consistent",
                status: has(.delimiterInconsistent) ? .fail : .pass,
                detail: has(.delimiterInconsistent)
                    ? "Row widths differ from header."
                    : "Delimiter '\(file.delimiter)' consistent."
            )
        ]
        return cases
    }

    public func generateAll(for files: [VendorFile]) -> [VeraTestCase] {
        files.flatMap { generate(for: $0) }
    }
}
