import SwiftUI
import AlloForgeCore

/// Center panel: raw vendor table with error highlight + mapping editor.
struct VendorTableView: View {
    var file: VendorFile?

    var body: some View {
        if let file {
            ScrollView([.horizontal, .vertical]) {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                    GridRow {
                        Text("#").font(.caption).bold().frame(width: 36, alignment: .trailing)
                        ForEach(file.rawHeaders.indices, id: \.self) { col in
                            Text(file.rawHeaders[col]).font(.caption).bold()
                                .frame(minWidth: 90, alignment: .leading)
                        }
                    }
                    Divider()
                    ForEach(errorRows(file)) { row in
                        GridRow {
                            Text(row.rowLabel).font(.caption).monospaced()
                                .frame(width: 36, alignment: .trailing)
                                .foregroundStyle(.secondary)
                            ForEach(row.cells.indices, id: \.self) { col in
                                Text(col < row.cells.count ? row.cells[col] : "")
                                    .font(.caption).monospaced()
                                    .foregroundStyle(row.badCols.contains(col) ? .red : .primary)
                                    .fontWeight(row.badCols.contains(col) ? .bold : .regular)
                                    .frame(minWidth: 90, alignment: .leading)
                            }
                        }
                    }
                }
                .padding(8)
            }
        } else {
            ContentUnavailableView("No file selected", systemImage: "doc.text")
        }
    }

    private struct ErrorRow: Identifiable {
        var id: Int
        var rowLabel: String
        var cells: [String]
        var badCols: Set<Int>
    }

    private func errorRows(_ file: VendorFile) -> [ErrorRow] {
        let badByRow: [Int: Set<Int>] = file.issues.reduce(into: [:]) { acc, issue in
            guard let row = issue.row else { return }
            let col = file.rawHeaders.firstIndex(of: issue.field ?? "") ?? -1
            let idx = col >= 0 ? col : (file.normalizedHeaders.firstIndex(of: issue.field ?? "") ?? -1)
            if idx >= 0 { acc[row, default: []].insert(idx) }
        }
        return file.rows.enumerated().map { (i, cells) in
            ErrorRow(id: i, rowLabel: "\(i + 2)", cells: cells, badCols: badByRow[i + 2] ?? [])
        }
    }
}

/// Mapping editor: vendor header to ASM target with auto-suggest.
struct MappingEditorView: View {
    var file: VendorFile?
    @State private var rules: [MappingRule] = []
    private let mapper = MapperEngine()

    var body: some View {
        if let file {
            Table(rules) {
                TableColumn("Vendor Field", value: \.vendorField)
                TableColumn("ASM Path", value: \.asmPath)
                TableColumn("AFO Term", value: \.afoTerm)
                TableColumn("Key") { rule in
                    Text(rule.isMerckKeyField ? "★" : "")
                }
            }
            .onAppear { rules = mapper.autoMap(headers: file.rawHeaders) }
            .onChange(of: file.id) { _, _ in rules = mapper.autoMap(headers: file.rawHeaders) }
        } else {
            ContentUnavailableView("No mapping", systemImage: "arrow.left.arrow.right")
        }
    }
}
