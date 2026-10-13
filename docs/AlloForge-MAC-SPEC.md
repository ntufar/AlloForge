# AlloForge for Mac - Native ASM Auto-Validator & VERA Forge

> Tagline: The native Mac app that forges 1000 crazy lab CSVs into validated Allotrope ASM + VERA reports — offline, fast, no browser.

**Project Name:** AlloForge Mac
**Bundle ID:** com.ntufar.alloforge
**Platform:** macOS 14+ (Sonoma), Apple Silicon + Intel, SwiftUI

---

## 1. Why Mac Swift is Better for This Problem

- **File System:** Drag 1000 files / 1GB HPLC files from Finder, watch folders — browser can't
- **Performance:** Parse 300 CSVs in parallel using Swift Concurrency, not JS worker limit
- **Offline Labs:** Many Merck labs have no internet, Mac app works offline
- **Native UX:** Menu bar icon, Quick Look for ASM JSON, Share sheet to export VERA PDF
- **Pro Feel:** For your portfolio, a native Mac app stands out vs another Next.js dashboard

---

## 2. Tech Stack (for Muse Code Agent - Swift)

**Language:** Swift 5.9, SwiftUI, SwiftData

**Core Frameworks:**
- SwiftUI + AppKit interop for drag-drop
- SwiftData for local persistence (3000 files metadata)
- TabularData framework (Apple's native CSV parsing, handles , ; \t)
- UniformTypeIdentifiers for custom .asm.json type
- Charts framework (Apple native) for dashboard
- CreateML (optional) for auto-mapping suggestions using ML

**Architecture: MVVM + Clean**
- Model: FileFingerprint, MappingRule, AsmDocument, VeraTestCase (SwiftData @Model)
- ViewModel: FingerprintEngine, MapperEngine, VeraGenerator (Observable)
- View: 3-panel layout like Mac Finder + Xcode

**Dependencies (SPM only, no CocoaPods):**
- No external deps for MVP — use Apple frameworks only
- Optional: SwiftCSV for fallback parsing, ZIPFoundation for zip handling

**Build:**
- Xcode 15+, Swift Package Manager
- Target: macOS 14.0
- Distribution: Direct DMG + TestFlight + Mac App Store later
- Notarization: Apple Developer ID

---

## 3. Data Models (SwiftData)

```swift
@Model
class VendorFile {
  var id: UUID
  var fileName: String
  var fileURL: URL
  var fileSize: Int
  var delimiter: String // "," ";" "\t"
  var encoding: String
  var rawHeaders: [String]
  var normalizedHeaders: [String]
  var detectedInstrument: InstrumentType
  var merckKeyFieldCoverage: Double
  var issues: [FileIssue]
  var status: FileStatus
  var asmJSON: String? // generated
}

enum InstrumentType: String, Codable {
  case mettler, agilent, thermo, biotek, sartorius, unknown
}

@Model
class FileIssue {
  var code: IssueCode
  var severity: Severity
  var row: Int?
  var field: String?
  var value: String?
  var message: String
}

enum IssueCode: String, Codable {
  case missingKeyField, outOfRange, badDate, commaDecimal, delimiterInconsistent, emptyValue, duplicateID, bomEncoding
}

@Model
class MappingRule {
  var vendorField: String
  var asmPath: String
  var afoTerm: String
  var isMerckKeyField: Bool
  var transformation: TransformationType
}

enum TransformationType: String, Codable {
  case direct, round2, isoDate, float, trim, commaToDot
}
```

---

## 4. Features - MVP Mac App

### 4.1 Main Window - 3-Panel (like Xcode)
- **Sidebar (25%):** File list with icons, status colors (green pass, red fail, yellow warning), search + filter by IssueCode
- **Center (40%):** Vendor table (SwiftUI Table with sortable columns), shows raw CSV, highlights errors inline (red cell for pH 15.5)
- **Right (35%):** Inspector: 
  - Top: Fingerprint details (delimiter, encoding, headers)
  - Middle: ASM JSON viewer with syntax highlighting (using CodeEditor)
  - Bottom: Data Quality + VERA table

### 4.2 Drag & Drop + Watch Folder
- Accept: Drop CSVs, multiple files, ZIP, folder from Finder onto Dock icon or window
- Menu: File -> Watch Folder -> Select /LabData/Incoming, auto-converts new files (uses FileSystemEvents)
- Menu bar extra: AlloForge icon shows pending files count

### 4.3 Fingerprint Dashboard (Native Charts)
Window: Dashboard (cmd+D)
- Cards: Total Files, Passed, Failed, Avg Coverage
- Pie Chart: Issue distribution (Swift Charts)
- Bar: Instrument distribution
- Table: All files, exportable

### 4.4 Mapping Editor (Inspector)
- Synonym Dictionary (hardcoded):
```
pH: ["pH", "pH_Reading", "Acid.", "pH Value"]
Sample_ID: ["Sample_ID", "sample id", "ID"]
```
- Drag vendor header to ASM target
- Auto-suggest using Levenshtein (implement in Swift)
- Merck Key Field toggle (star)

### 4.5 ASM Conversion Engine (Swift)
- Parser: TabularData or custom that handles , ; \t
- Logic:
  - Trim spaces: "  7.02  " -> 7.02
  - Comma decimal: "7,02" -> 7.02
  - Round: 7.123456 -> 7.12
  - Date: try 5 formats -> ISO8601
  - Validate: pH 0-14, flag OUT_OF_RANGE
- Output: Real ASM JSON structure

### 4.6 VERA Forge
For each file, auto-gen 5 test cases (Swift structs):
1. TC-AUTO-001: Key Fields Present
2. TC-AUTO-002: pH Range
3. TC-AUTO-003: Date Valid
4. TC-AUTO-004: Sample_ID Unique
5. TC-AUTO-005: Delimiter Consistent

Table view + Export:
- Export VERA CSV (for JIRA XRAY)
- Export Traceability Matrix (CSV)
- Export Validation PDF (using PDFKit, native Mac)
- Export All ASM JSONs as ZIP

### 4.7 Quick Look + Share
- Select ASM JSON file in Finder, press Space -> Quick Look preview shows pretty lab report, not raw JSON (implement QLThumbnail extension)
- Share sheet: AirDrop VERA report to colleague

---

## 5. Folder Structure (for Muse Code Agent)

```
/AlloForge
  AlloForge.xcodeproj
  AlloForge/
    AlloForgeApp.swift
    Models/
      VendorFile.swift
      FileIssue.swift
      MappingRule.swift
      AsmDocument.swift
      VeraTestCase.swift
    ViewModels/
      FingerprintEngine.swift
      MapperEngine.swift
      VeraGenerator.swift
      DashboardViewModel.swift
    Views/
      MainWindowView.swift (3-panel)
      Sidebar/
        FileListView.swift
        FileRowView.swift
      Center/
        VendorTableView.swift
        MappingEditorView.swift
      Inspector/
        FingerprintInspector.swift
        AsmJsonViewer.swift
        QualityPanel.swift
        VeraTableView.swift
      Dashboard/
        FingerprintDashboardView.swift
      Components/
        DropZoneView.swift
        StatusBadge.swift
    Services/
      CSVParserService.swift (handles , ; \t, encoding)
      SynonymDictionary.swift
      DateParserService.swift (5 formats)
      FileWatcherService.swift
    Resources/
      Examples/ (6 CSVs + 300 zip)
  AlloForgeTests/
    FingerprintEngineTests.swift
    MapperTests.swift
```

---

## 6. Acceptance Criteria

1. Drag crazy_vendor_dataset.zip (300 files) onto app, parses all in <5s using Swift Concurrency
2. Sidebar shows delimiter correctly per file
3. Mapping Editor auto-maps "Acid." -> pH
4. File with pH 15.5 shows red cell + OUT_OF_RANGE in Quality panel
5. VERA table has 1500 rows for 300 files
6. Export VERA CSV opens correctly in Excel/Numbers and is importable to JIRA XRAY
7. App works offline, no network calls
8. Watch Folder: drop new CSV into ~/LabData, app auto-converts and shows notification
9. Quick Look: Space on .asm.json shows formatted report

---

## 7. Roadmap

**MVP (Week 1):** File list + Parser + Fingerprint + ASM preview + VERA export
**V2:** Watch Folder + Menu bar extra + Quick Look + PDFKit report + Charts dashboard + ML-based mapping suggestions
**V3:** Real Allotrope schema validation (embed Python allotrope lib via PythonKit), HPLC chromatogram viewer (10k points chart)

---

## 8. Instructions for Muse Code Agent (Mac)

You are building AlloForge Mac - native macOS SwiftUI app.

Steps:
1. Create new macOS SwiftUI project, min macOS 14.0, bundle com.ntufar.alloforge
2. Implement Models first (SwiftData)
3. Implement Services: CSVParserService must handle , ; \t delimiters, encoding detection, trim, comma decimal
4. Implement ViewModels: FingerprintEngine with parallel parsing using TaskGroup
5. Build Views in order: MainWindowView (NavigationSplitView 3-column) -> FileListView -> VendorTableView -> AsmJsonViewer -> VeraTableView -> Dashboard
6. Use sample data from crazy_vendor_dataset.zip for dev
7. No external SPM deps for MVP, use Apple frameworks only
8. Test: drag 300 files, check performance

Start coding now.

---

End of Mac Spec
