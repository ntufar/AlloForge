import SwiftUI
import AlloForgeCore

/// JSON text with syntax highlight. Keys blue, strings green,
/// numbers orange, literals purple.
struct HighlightedJSONView: View {
    var text: String
    private let tokenizer = JSONTokenizer()

    var body: some View {
        let runs = tokenizer.tokenize(text)
        runs.reduce(Text("")) { acc, token in
            acc + Text(token.text).foregroundStyle(color(for: token.kind))
        }
        .font(.system(.caption, design: .monospaced))
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func color(for kind: JSONTokenizer.Kind) -> Color {
        switch kind {
        case .key: return .blue
        case .string: return .green
        case .number: return .orange
        case .literal: return .purple
        case .punctuation: return .secondary
        case .whitespace: return .primary
        }
    }
}
