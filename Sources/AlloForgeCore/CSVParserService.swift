import Foundation

/// Parse CSV text with `,` `;` or tab delimiter.
/// Handles BOM, `#` comment lines, quoted fields, CRLF.
public struct CSVParserService: Sendable {
    public init() {}

    public struct ParsedCSV: Sendable {
        public var headers: [String]
        public var rows: [[String]]
        public var delimiter: Character
        public var hadBOM: Bool
    }

    /// Detect delimiter from header line.
    public func detectDelimiter(headerLine: String) -> Character {
        let counts: [(Character, Int)] = [
            ("\t", headerLine.filter { $0 == "\t" }.count),
            (";", headerLine.filter { $0 == ";" }.count),
            (",", headerLine.filter { $0 == "," }.count)
        ]
        // Prefer tab, then semicolon, then comma on ties.
        return counts.max(by: { $0.1 < $1.1 })?.0 ?? ","
    }

    /// Split one line on delimiter. Honors double quotes.
    public func splitLine(_ line: String, delimiter: Character) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var iterator = line.makeIterator()
        while let ch = iterator.next() {
            if ch == "\"" {
                inQuotes.toggle()
                continue
            }
            if ch == delimiter, !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(ch)
            }
        }
        fields.append(current)
        return fields
    }

    /// Parse full file text.
    public func parse(text: String) -> ParsedCSV {
        var source = text
        var hadBOM = false
        if source.hasPrefix("\u{FEFF}") {
            hadBOM = true
            source.removeFirst()
        }
        let rawLines = source.components(separatedBy: .newlines)
        // Drop `#` comments and blank lines.
        let dataLines = rawLines.filter { line in
            let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
            return !t.isEmpty && !t.hasPrefix("#")
        }
        guard let headerLine = dataLines.first else {
            return ParsedCSV(headers: [], rows: [], delimiter: ",", hadBOM: hadBOM)
        }
        let delimiter = detectDelimiter(headerLine: headerLine)
        let headers = splitLine(headerLine, delimiter: delimiter)
        let rows = dataLines.dropFirst().map { splitLine($0, delimiter: delimiter) }
        return ParsedCSV(headers: headers, rows: Array(rows), delimiter: delimiter, hadBOM: hadBOM)
    }

    /// Parse raw bytes. Detects UTF-8/16 encoding.
    public func parse(data: Data) -> (parsed: ParsedCSV, encoding: String) {
        if let text = String(data: data, encoding: .utf8) {
            let enc = hasBOM(data) ? "UTF-8-BOM" : "UTF-8"
            return (parse(text: text), enc)
        }
        if let text = String(data: data, encoding: .utf16) {
            return (parse(text: text), "UTF-16")
        }
        let text = String(decoding: data, as: UTF8.self)
        return (parse(text: text), "UTF-8-lossy")
    }

    private func hasBOM(_ data: Data) -> Bool {
        data.starts(with: [0xEF, 0xBB, 0xBF])
    }
}
