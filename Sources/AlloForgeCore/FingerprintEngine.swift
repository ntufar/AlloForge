import Foundation

/// Build fingerprint for one file: headers, instrument, issues, coverage.
public struct FingerprintEngine: Sendable {
    private let parser = CSVParserService()
    private let synonyms = SynonymDictionary()
    private let dates = DateParserService()
    private let values = ValueNormalization()

    public init() {}

    /// Fingerprint one file from bytes.
    public func fingerprint(fileName: String, data: Data) -> VendorFile {
        let (parsed, encoding) = parser.parse(data: data)
        return fingerprint(fileName: fileName, parsed: parsed, encoding: encoding)
    }

    func fingerprint(fileName: String, parsed: CSVParserService.ParsedCSV, encoding: String) -> VendorFile {
        let normalized = parsed.headers.map { synonyms.canonicalField(for: $0) ?? $0 }
        let instrument = detectInstrument(fileName: fileName)
        var issues: [FileIssue] = []

        if parsed.hadBOM {
            issues.append(FileIssue(
                code: .bomEncoding, severity: .info,
                message: "File has UTF-8 BOM. Parser stripped it."
            ))
        }

        // Delimiter check: rows wider or narrower than header.
        let width = parsed.headers.count
        for (index, row) in parsed.rows.enumerated() {
            if row.count != width {
                issues.append(FileIssue(
                    code: .delimiterInconsistent, severity: .warning,
                    row: index + 2,
                    message: "Row \(index + 2) has \(row.count) fields, header has \(width)."
                ))
            }
        }

        // Column index by canonical name.
        var colIndex: [String: Int] = [:]
        for (i, name) in normalized.enumerated() {
            if colIndex[name] == nil { colIndex[name] = i }
        }

        // Key field coverage.
        let keyFields = SynonymDictionary.merckKeyFields
        let present = keyFields.filter { colIndex[$0] != nil }.count
        let coverage = keyFields.isEmpty ? 0 : Double(present) / Double(keyFields.count)
        for key in keyFields where colIndex[key] == nil {
            issues.append(FileIssue(
                code: .missingKeyField, severity: .error, field: key,
                message: "Key field \(key) is missing."
            ))
        }

        // Per-row checks.
        var seenIDs = Set<String>()
        var duplicateIDs = Set<String>()
        for (index, row) in parsed.rows.enumerated() {
            let rowNum = index + 2 // 1-based + header
            func cell(_ canonical: String) -> String? {
                guard let i = colIndex[canonical], i < row.count else { return nil }
                return row[i]
            }

            // Sample_ID: empty + duplicate.
            if let rawID = cell("Sample_ID") {
                let id = values.trim(rawID)
                if id.isEmpty || id.uppercased() == "N/A" {
                    issues.append(FileIssue(
                        code: .emptyValue, severity: .warning, row: rowNum,
                        field: "Sample_ID", value: rawID,
                        message: "Row \(rowNum): Sample_ID is empty."
                    ))
                } else if id != "SMP-001" {
                    if seenIDs.contains(id) { duplicateIDs.insert(id) }
                    seenIDs.insert(id)
                }
            }

            // pH: comma decimal note, parse, range.
            if let rawPH = cell("pH") {
                let t = values.trim(rawPH)
                if t.contains(",") {
                    issues.append(FileIssue(
                        code: .commaDecimal, severity: .info, row: rowNum,
                        field: "pH", value: rawPH,
                        message: "Row \(rowNum): comma decimal converted to dot."
                    ))
                }
                if t.isEmpty || t.uppercased() == "N/A" {
                    issues.append(FileIssue(
                        code: .emptyValue, severity: .warning, row: rowNum,
                        field: "pH", value: rawPH,
                        message: "Row \(rowNum): pH is empty."
                    ))
                } else if let v = values.parseFloat(rawPH) {
                    if values.isPHOutOfRange(v) {
                        issues.append(FileIssue(
                            code: .outOfRange, severity: .error, row: rowNum,
                            field: "pH", value: t,
                            message: "Row \(rowNum): pH \(t) is outside 0-14."
                        ))
                    }
                } else {
                    issues.append(FileIssue(
                        code: .outOfRange, severity: .warning, row: rowNum,
                        field: "pH", value: t,
                        message: "Row \(rowNum): pH value '\(t)' is not numeric."
                    ))
                }
            }

            // Date: bad date.
            if let rawDate = cell("Date") {
                let t = values.trim(rawDate)
                if !t.isEmpty, t.uppercased() != "N/A", dates.parse(t) == nil {
                    issues.append(FileIssue(
                        code: .badDate, severity: .warning, row: rowNum,
                        field: "Date", value: t,
                        message: "Row \(rowNum): date '\(t)' does not match known formats."
                    ))
                } else if t.isEmpty || t.uppercased() == "N/A" {
                    issues.append(FileIssue(
                        code: .emptyValue, severity: .warning, row: rowNum,
                        field: "Date", value: rawDate,
                        message: "Row \(rowNum): date is empty."
                    ))
                }
            }
        }

        for dup in duplicateIDs {
            issues.append(FileIssue(
                code: .duplicateID, severity: .error, field: "Sample_ID", value: dup,
                message: "Sample_ID \(dup) appears more than once."
            ))
        }

        let status: FileStatus = issues.contains(where: { $0.severity == .error })
            ? .fail : (issues.isEmpty ? .pass : .warning)

        return VendorFile(
            fileName: fileName,
            delimiter: String(parsed.delimiter) == "\t" ? "\\t" : String(parsed.delimiter),
            encoding: encoding,
            rawHeaders: parsed.headers,
            normalizedHeaders: normalized,
            detectedInstrument: instrument,
            merckKeyFieldCoverage: coverage,
            issues: issues,
            status: status,
            rowCount: parsed.rows.count,
            rows: parsed.rows
        )
    }

    /// Parse many files in parallel with TaskGroup.
    public func fingerprintMany(_ inputs: [(fileName: String, data: Data)]) async -> [VendorFile] {
        await withTaskGroup(of: VendorFile.self) { group in
            for input in inputs {
                group.addTask { self.fingerprint(fileName: input.fileName, data: input.data) }
            }
            var results: [VendorFile] = []
            results.reserveCapacity(inputs.count)
            for await file in group { results.append(file) }
            return results.sorted { $0.fileName < $1.fileName }
        }
    }

    /// Parse all CSVs inside a ZIP archive (in-memory).
    public func fingerprintZip(_ data: Data) async throws -> [VendorFile] {
        let entries = try ZipReader.entries(from: data)
        let inputs = entries.map { (fileName: $0.name, data: $0.data) }
        return await fingerprintMany(inputs)
    }

    private func detectInstrument(fileName: String) -> InstrumentType {
        let upper = fileName.uppercased()
        if upper.contains("METTLER") { return .mettler }
        if upper.contains("AGILENT") { return .agilent }
        if upper.contains("THERMO") { return .thermo }
        if upper.contains("BIOTEK") { return .biotek }
        if upper.contains("SARTORIUS") { return .sartorius }
        return .unknown
    }
}
