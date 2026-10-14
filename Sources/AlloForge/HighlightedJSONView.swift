import AppKit
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

/// Scrollable JSON pane backed by a real NSScrollView.
///
/// A SwiftUI ScrollView nested in a List row does not receive mouse
/// scroll-wheel events. The outer List steals them. NSTextView in
/// NSScrollView joins AppKit scroll chaining, so the wheel scrolls the
/// JSON pane under the cursor and the inspector elsewhere.
struct ScrollableJSONView: NSViewRepresentable {
    var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.font = .monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 0

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        let font = NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        let full = NSMutableAttributedString()
        for token in JSONTokenizer().tokenize(text) {
            full.append(NSAttributedString(
                string: token.text,
                attributes: [.font: font, .foregroundColor: nsColor(for: token.kind)]
            ))
        }
        if textView.textStorage?.string != full.string {
            textView.textStorage?.setAttributedString(full)
        }
    }

    private func nsColor(for kind: JSONTokenizer.Kind) -> NSColor {
        switch kind {
        case .key: return .systemBlue
        case .string: return .systemGreen
        case .number: return .systemOrange
        case .literal: return .systemPurple
        case .punctuation: return .secondaryLabelColor
        case .whitespace: return .labelColor
        }
    }
}
