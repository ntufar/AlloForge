import SwiftUI
import AlloForgeCore

/// Status color dot.
struct StatusBadge: View {
    var status: FileStatus

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
    }

    private var color: Color {
        switch status {
        case .pass: return .green
        case .warning: return .yellow
        case .fail: return .red
        }
    }
}

/// Drop target overlay for CSV / ZIP / folder.
struct DropZoneView: View {
    var onDrop: ([URL]) -> Void
    @State private var hovering = false

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(hovering ? Color.accentColor : Color.secondary, style: StrokeStyle(lineWidth: 2, dash: [8]))
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.largeTitle)
                    Text("Drop CSVs, ZIP, or folder here")
                        .font(.headline)
                }
                .foregroundStyle(.secondary)
                .padding(40)
            }
            .background(hovering ? Color.accentColor.opacity(0.08) : Color.clear)
            .onHover { hovering = $0 }
            .onDrop(of: [.fileURL], isTargeted: $hovering) { providers in
                var urls: [URL] = []
                let group = DispatchGroup()
                for p in providers {
                    group.enter()
                    _ = p.loadObject(ofClass: URL.self) { url, _ in
                        if let url { urls.append(url) }
                        group.leave()
                    }
                }
                group.notify(queue: .main) { onDrop(urls) }
                return true
            }
    }
}
