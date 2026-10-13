import SwiftUI
import AlloForgeCore

/// Sidebar file list with search + status filter.
struct FileListView: View {
    @Bindable var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Status", selection: $state.statusFilter) {
                    Text("All").tag(nil as FileStatus?)
                    Text("Pass").tag(FileStatus.pass as FileStatus?)
                    Text("Warn").tag(FileStatus.warning as FileStatus?)
                    Text("Fail").tag(FileStatus.fail as FileStatus?)
                }
                .pickerStyle(.segmented)
            }
            .padding(8)
            List(state.filteredFiles, selection: $state.selection) { file in
                HStack(spacing: 8) {
                    StatusBadge(status: file.status)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.fileName)
                            .font(.callout)
                            .lineLimit(1)
                        Text("\(file.delimiter == "\\t" ? "TAB" : file.delimiter) · \(file.detectedInstrument.rawValue) · \(Int(file.merckKeyFieldCoverage * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if file.issues.contains(where: { $0.severity == .error }) {
                        Text("\(file.issues.filter { $0.severity == .error }.count)")
                            .font(.caption2)
                            .padding(4)
                            .background(Color.red.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .tag(file.id)
            }
            .searchable(text: $state.searchText, prompt: "Filter by name or issue")
        }
    }
}
