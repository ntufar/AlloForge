import Foundation

/// Merck key fields and vendor synonyms.
public struct SynonymDictionary: Sendable {
    public init() {}

    /// Canonical field to known vendor spellings.
    public static let synonyms: [String: [String]] = [
        "Sample_ID": ["Sample_ID", "sample id", "ID", "id"],
        "pH": ["pH", "pH_Reading", "pH Reading", "Acid.", "acid", "pH Value"],
        "Temperature": ["Temp_C", "Temp", "temperature (C)", "Temperature", "Temp (C)"],
        "Date": ["Date", "measurement date", "Date/Time", "date/time"],
        "Operator": ["Operator", "analyst", "Op", "op"]
    ]

    /// Merck key fields for coverage score.
    public static let merckKeyFields = ["Sample_ID", "pH", "Temperature", "Date", "Operator"]

    /// Map raw header to canonical field. Uses exact match, then Levenshtein.
    public func canonicalField(for header: String) -> String? {
        let trimmed = header.trimmingCharacters(in: .whitespaces)
        for (canonical, variants) in Self.synonyms {
            if variants.contains(where: { $0.lowercased() == trimmed.lowercased() }) {
                return canonical
            }
        }
        return suggest(header: trimmed)
    }

    /// Suggest closest canonical field by edit distance.
    public func suggest(header: String) -> String? {
        let target = header.lowercased().trimmingCharacters(in: .whitespaces)
        guard !target.isEmpty else { return nil }
        var best: (field: String, distance: Int)?
        for (canonical, variants) in Self.synonyms {
            for variant in variants {
                let d = Self.levenshtein(target, variant.lowercased())
                // Accept when distance is small relative to length.
                let limit = max(2, variant.count / 3)
                if d <= limit, best == nil || d < best!.distance {
                    best = (canonical, d)
                }
            }
        }
        return best?.field
    }

    /// Classic edit distance.
    public static func levenshtein(_ a: String, _ b: String) -> Int {
        let x = Array(a), y = Array(b)
        var prev = Array(0...y.count)
        for i in 1...x.count {
            var cur = [i] + Array(repeating: 0, count: y.count)
            for j in 1...y.count {
                cur[j] = x[i - 1] == y[j - 1]
                    ? prev[j - 1]
                    : min(prev[j - 1], prev[j], cur[j - 1]) + 1
            }
            prev = cur
        }
        return prev[y.count]
    }
}
