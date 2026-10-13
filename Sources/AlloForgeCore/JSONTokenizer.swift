import Foundation

/// Tokenize JSON text for syntax highlight. No external deps.
public struct JSONTokenizer: Sendable {
    public enum Kind: Sendable {
        case key, string, number, literal, punctuation, whitespace
    }

    public struct Token: Sendable {
        public var kind: Kind
        public var text: String
    }

    public init() {}

    public func tokenize(_ input: String) -> [Token] {
        var tokens: [Token] = []
        let chars = Array(input)
        var i = 0
        while i < chars.count {
            let ch = chars[i]
            if ch.isWhitespace {
                var j = i
                while j < chars.count, chars[j].isWhitespace { j += 1 }
                tokens.append(Token(kind: .whitespace, text: String(chars[i..<j])))
                i = j
            } else if ch == "\"" {
                var j = i + 1
                while j < chars.count {
                    if chars[j] == "\\" { j += 2; continue }
                    if chars[j] == "\"" { j += 1; break }
                    j += 1
                }
                let text = String(chars[i..<min(j, chars.count)])
                // A string is a key when `:` follows it.
                var k = j
                while k < chars.count, chars[k].isWhitespace { k += 1 }
                let kind: Kind = (k < chars.count && chars[k] == ":") ? .key : .string
                tokens.append(Token(kind: kind, text: text))
                i = j
            } else if ch == "-" || ch.isNumber {
                var j = i
                while j < chars.count, chars[j].isNumber || "-+.eE".contains(chars[j]) { j += 1 }
                tokens.append(Token(kind: .number, text: String(chars[i..<j])))
                i = j
            } else if ch.isLetter {
                var j = i
                while j < chars.count, chars[j].isLetter { j += 1 }
                tokens.append(Token(kind: .literal, text: String(chars[i..<j])))
                i = j
            } else {
                tokens.append(Token(kind: .punctuation, text: String(ch)))
                i += 1
            }
        }
        return tokens
    }
}
