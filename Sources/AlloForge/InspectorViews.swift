import SwiftUI
import Charts
import AlloForgeCore

/// Right inspector: fingerprint, ASM JSON, quality, VERA.
struct InspectorView: View {
    var file: VendorFile?
    var veraCases: [VeraTestCase]

    var body: some View {
        if let file {
            List {
                Section("Fingerprint") {
                    LabeledContent("Delimiter", value: file.delimiter == "\\t" ? "TAB" : file.delimiter)
                    LabeledContent("Encoding", value: file.encoding)
                    LabeledContent("Instrument", value: file.detectedInstrument.rawValue)
                    LabeledContent("Coverage", value: "\(Int(file.merckKeyFieldCoverage * 100))%")
                    LabeledContent("Rows", value: "\(file.rowCount)")
                }
                Section("ASM JSON") {
                    ScrollableJSONView(text: file.asmJSON ?? "{}")
                        .frame(minHeight: 160, maxHeight: 320)
                }
                Section("Data Quality (\(file.issues.count))") {
                    ForEach(file.issues) { issue in
                        HStack {
                            Circle()
                                .fill(issue.severity == .error ? Color.red : (issue.severity == .warning ? Color.yellow : Color.blue))
                                .frame(width: 8, height: 8)
                            VStack(alignment: .leading) {
                                Text(issue.message).font(.caption)
                                if let field = issue.field {
                                    Text(field).font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                Section("VERA (\(veraCases.count))") {
                    ForEach(veraCases) { tc in
                        HStack {
                            Image(systemName: tc.status == .pass ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(tc.status == .pass ? .green : .red)
                            VStack(alignment: .leading) {
                                Text("\(tc.caseID) \(tc.title)").font(.caption).bold()
                                Text(tc.detail).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        } else {
            ContentUnavailableView("No selection", systemImage: "sidebar.right")
        }
    }
}

/// Dashboard window content: native cards + tables.
struct DashboardView: View {
    @Bindable var state: AppState

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                dashboardCard("Total Files", "\(state.files.count)", .blue)
                dashboardCard("Passed", "\(state.passedCount)", .green)
                dashboardCard("Failed", "\(state.failedCount)", .red)
                dashboardCard("Warnings", "\(state.warningCount)", .yellow)
                dashboardCard("Avg Coverage", "\(Int(state.avgCoverage * 100))%", .purple)
            }
            .padding()
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("Issues by Code").font(.headline)
                    Chart(issueCounts, id: \.code) { item in
                        BarMark(x: .value("Count", item.count), y: .value("Code", item.code))
                    }
                    .frame(minHeight: 180)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading) {
                    Text("Files by Instrument").font(.headline)
                    Chart(instrumentCounts, id: \.name) { item in
                        BarMark(x: .value("Count", item.count), y: .value("Instrument", item.name))
                    }
                    .frame(minHeight: 180)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            Table(state.files) {
                TableColumn("File", value: \.fileName)
                TableColumn("Instrument", value: \.detectedInstrument.rawValue)
                TableColumn("Status", value: \.status.rawValue)
                TableColumn("Coverage") { Text("\(Int($0.merckKeyFieldCoverage * 100))%") }
                TableColumn("Issues") { Text("\($0.issues.count)") }
            }
            .frame(minHeight: 300)
            .padding()
        }
    }

    private struct CountItem {
        var code: String
        var name: String
        var count: Int
    }

    private var issueCounts: [CountItem] {
        let groups = Dictionary(grouping: state.files.flatMap { $0.issues }, by: { $0.code.rawValue })
        return groups.map { CountItem(code: $0.key, name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    private var instrumentCounts: [CountItem] {
        let groups = Dictionary(grouping: state.files, by: { $0.detectedInstrument.rawValue })
        return groups.map { CountItem(code: $0.key, name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    private func dashboardCard(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack {
            Text(value).font(.largeTitle).bold().foregroundStyle(color)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// VERA table for export review.
struct VeraTableView: View {
    var cases: [VeraTestCase]

    var body: some View {
        Table(cases) {
            TableColumn("Case", value: \.caseID)
            TableColumn("File", value: \.fileName)
            TableColumn("Title", value: \.title)
            TableColumn("Status", value: \.status.rawValue)
            TableColumn("Detail", value: \.detail)
        }
    }
}
