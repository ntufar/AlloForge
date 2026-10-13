import Foundation

/// Build Allotrope ASM JSON for one fingerprinted file.
public struct AsmBuilder: Sendable {
    private let dates = DateParserService()
    private let values = ValueNormalization()

    public init() {}

    /// Build ASM JSON string for file.
    public func buildJSON(for file: VendorFile) -> String {
        var colIndex: [String: Int] = [:]
        for (i, name) in file.normalizedHeaders.enumerated() {
            if colIndex[name] == nil { colIndex[name] = i }
        }
        func cell(_ row: [String], _ canonical: String) -> String {
            guard let i = colIndex[canonical], i < row.count else { return "" }
            return row[i]
        }

        var measurements: [[String: Any]] = []
        for row in file.rows {
            let rawID = values.trim(cell(row, "Sample_ID"))
            let rawPH = cell(row, "pH")
            let rawTemp = cell(row, "Temperature")
            let rawDate = cell(row, "Date")
            let rawOp = values.trim(cell(row, "Operator"))
            var m: [String: Any] = [:]
            m["sampleID"] = rawID
            if let v = values.parseFloat(rawPH) {
                m["pH"] = values.round2(v)
            }
            if let v = values.parseFloat(rawTemp) {
                m["temperatureC"] = values.round2(v)
            }
            if let iso = dates.isoString(rawDate) {
                m["datetime"] = iso
            }
            m["operator"] = rawOp
            measurements.append(m)
        }

        let doc: [String: Any] = [
            "$schema": "https://allotrope.org/asm/1.0",
            "sourceFile": file.fileName,
            "instrument": file.detectedInstrument.rawValue,
            "keyFieldCoverage": file.merckKeyFieldCoverage,
            "measurementCount": measurements.count,
            "measurements": measurements
        ]
        guard let data = try? JSONSerialization.data(
            withJSONObject: doc, options: [.prettyPrinted, .sortedKeys]),
            let json = String(data: data, encoding: .utf8)
        else { return "{}" }
        return json
    }
}
