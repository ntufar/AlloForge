import Foundation

/// Normalize raw cell values: trim, comma decimal, float, round, date.
public struct ValueNormalization: Sendable {
    public init() {}

    /// Trim spaces.
    public func trim(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Convert comma decimal `"7,02"` to `"7.02"`.
    public func commaToDot(_ raw: String) -> String {
        let t = trim(raw)
        // Only convert when it looks like a decimal number.
        let pattern = #"^-?\d+,\d+$"#
        if t.range(of: pattern, options: .regularExpression) != nil {
            return t.replacingOccurrences(of: ",", with: ".")
        }
        return t
    }

    /// Parse float after trim + comma fix. Nil for blank, N/A, OVER.
    public func parseFloat(_ raw: String) -> Double? {
        let t = commaToDot(raw)
        guard !t.isEmpty else { return nil }
        let upper = t.uppercased()
        if upper == "N/A" || upper == "OVER" || upper == "NAN" { return nil }
        return Double(t)
    }

    /// Round to 2 decimals.
    public func round2(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    /// Check pH range 0-14.
    public func isPHOutOfRange(_ value: Double) -> Bool {
        value < 0 || value > 14
    }
}
