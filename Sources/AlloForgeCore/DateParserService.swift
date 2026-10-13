import Foundation

/// Parse 5 vendor date formats. Output ISO8601.
public struct DateParserService: Sendable {
    public init() {}

    private static let formats = [
        "yyyy-MM-dd HH:mm:ss",
        "MM/dd/yyyy hh:mm a",
        "dd.MM.yyyy HH:mm",
        "yyyy-MM-dd",
        "MM/dd/yyyy"
    ]

    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// Parse date string. Returns nil for blank or `N/A`.
    public func parse(_ raw: String) -> Date? {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, t.uppercased() != "N/A" else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in Self.formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: t) { return date }
        }
        return nil
    }

    /// Parse date string. Output ISO8601 string or nil.
    public func isoString(_ raw: String) -> String? {
        guard let date = parse(raw) else { return nil }
        return Self.iso.string(from: date)
    }
}
