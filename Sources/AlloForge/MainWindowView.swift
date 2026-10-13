import SwiftUI
import AlloForgeCore
import UniformTypeIdentifiers

/// Main 3-panel window.
struct MainWindowView: View {
    @Bindable var state: AppState
    @State private var showDashboard = false
    @State private var showVera = false
    @State private var centerTab = 0
    @State private var dropTargeted = false
    private let exports = ExportService()

    var body: some View {
        NavigationSplitView {
            FileListView(state: state)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        } content: {
            VStack(spacing: 0) {
                Picker("", selection: $centerTab) {
                    Text("Vendor Table").tag(0)
                    Text("Mapping").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(8)
                if centerTab == 0 {
                    VendorTableView(file: state.selectedFile)
                } else {
                    MappingEditorView(file: state.selectedFile)
                }
            }
        } detail: {
            InspectorView(
                file: state.selectedFile,
                veraCases: state.veraCases.filter { $0.fileName == state.selectedFile?.fileName }
            )
        }
        .navigationTitle("AlloForge")
        .toolbar {
            ToolbarItemGroup {
                Button("Import", systemImage: "tray.and.arrow.down") { pickFiles() }
                Button("Dashboard", systemImage: "chart.bar") { showDashboard = true }
                    .keyboardShortcut("d", modifiers: .command)
                Button("VERA", systemImage: "checklist") { showVera = true }
            }
            ToolbarItemGroup {
                Menu("Export") {
                    Button("VERA CSV (JIRA XRAY)") { exports.saveVeraCSV(cases: state.veraCases) }
                    Button("Traceability Matrix") { exports.saveTraceability(files: state.files) }
                    Button("Validation PDF") { exports.saveValidationPDF(files: state.files, cases: state.veraCases) }
                    Button("All ASM JSONs (ZIP)") { exports.saveAsmZip(files: state.files) }
                }
            }
        }
        .overlay(alignment: .bottom) {
            HStack {
                if state.isBusy { ProgressView().controlSize(.small) }
                Text(state.statusMessage).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("\(state.files.count) files · \(state.veraCases.count) VERA").font(.caption).foregroundStyle(.secondary)
                Text("v\(AppVersion.current)").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(8)
            .background(.bar)
        }
        .sheet(isPresented: $showDashboard) {
            DashboardView(state: state)
                .frame(minWidth: 700, minHeight: 500)
        }
        .sheet(isPresented: $showVera) {
            VeraTableView(cases: state.veraCases)
                .frame(minWidth: 800, minHeight: 500)
        }
        .onDrop(of: [.fileURL], isTargeted: $dropTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
        .task {
            // Auto-load bundled sample data when present.
            if let zip = Bundle.main.url(forResource: "crazy_vendor_dataset", withExtension: "zip"),
               let data = try? Data(contentsOf: zip) {
                await state.importURLs([zip])
                _ = data
            }
        }
    }

    private func pickFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.allowedContentTypes = [.commaSeparatedText, .tabSeparatedText, .zip, .folder]
        if panel.runModal() == .OK {
            Task { await state.importURLs(panel.urls) }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        var urls: [URL] = []
        let group = DispatchGroup()
        for p in providers {
            group.enter()
            _ = p.loadObject(ofClass: URL.self) { url, _ in
                if let url { urls.append(url) }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            Task { await state.importURLs(urls) }
        }
    }
}
