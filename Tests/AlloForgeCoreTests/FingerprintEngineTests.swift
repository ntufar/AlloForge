import XCTest
@testable import AlloForgeCore

final class FingerprintEngineTests: XCTestCase {
    let engine = FingerprintEngine()

    func testDelimiterDetection() {
        let parser = CSVParserService()
        XCTAssertEqual(parser.detectDelimiter(headerLine: "a,b,c"), ",")
        XCTAssertEqual(parser.detectDelimiter(headerLine: "a;b;c"), ";")
        XCTAssertEqual(parser.detectDelimiter(headerLine: "a\tb\tc"), "\t")
    }

    func testAcidMapsToPH() {
        let synonyms = SynonymDictionary()
        XCTAssertEqual(synonyms.canonicalField(for: "Acid."), "pH")
    }

    func testPHOutOfRangeFlagged() {
        let csv = "ID,Acid.,Temp,Date/Time,Op\nSMP-4431,15.5,20.8,N/A,\n"
        let file = engine.fingerprint(
            fileName: "vendor_0006_AGILENT.csv", data: Data(csv.utf8))
        XCTAssertTrue(file.issues.contains { $0.code == .outOfRange && $0.field == "pH" })
    }

    func testCommaDecimalHandled() {
        let v = ValueNormalization()
        XCTAssertEqual(v.commaToDot("\"7,02\"".replacingOccurrences(of: "\"", with: "")), "7.02")
        XCTAssertEqual(v.parseFloat("7,02"), 7.02)
        XCTAssertEqual(v.round2(7.123456), 7.12)
    }

    func testDateFormats() {
        let d = DateParserService()
        XCTAssertNotNil(d.parse("2026-10-13 14:53:50"))
        XCTAssertNotNil(d.parse("10/13/2026 02:53 PM"))
        XCTAssertNotNil(d.parse("13.10.2026 14:53"))
        XCTAssertNil(d.parse("N/A"))
        XCTAssertNotNil(d.isoString("2026-10-13 14:53:50"))
    }

    func testVeraFiveCasesPerFile() {
        let csv = "Sample_ID,pH,Temp_C,Date,Operator\nSMP-1,7.0,21.0,2026-10-13 14:53:50,A\n"
        let file = engine.fingerprint(fileName: "t.csv", data: Data(csv.utf8))
        let cases = VeraGenerator().generate(for: file)
        XCTAssertEqual(cases.count, 5)
        XCTAssertEqual(cases.map { $0.caseID },
                       ["TC-AUTO-001", "TC-AUTO-002", "TC-AUTO-003", "TC-AUTO-004", "TC-AUTO-005"])
    }

    func testDatasetAcceptance() async throws {
        let zipURL = URL(fileURLWithPath: "data/crazy_vendor_dataset.zip")
        guard FileManager.default.fileExists(atPath: zipURL.path) else {
            throw XCTSkip("Dataset zip not found")
        }
        let zipData = try Data(contentsOf: zipURL)
        let entries = try ZipReader.entries(from: zipData).sorted { $0.name < $1.name }
        XCTAssertEqual(entries.count, 300)
        let files = await engine.fingerprintMany(
            entries.map { (fileName: $0.name, data: $0.data) })
        // Delimiter matches raw header counts per file.
        for (entry, file) in zip(entries, files) {
            let text = String(data: entry.data, encoding: .utf8)
                ?? String(decoding: entry.data, as: UTF8.self)
            let header = text.components(separatedBy: .newlines).first {
                let t = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                return !t.isEmpty && !t.hasPrefix("#")
            } ?? ""
            let expected: String
            if header.filter({ $0 == "\t" }).count > 0 { expected = "\\t" }
            else if header.filter({ $0 == ";" }).count > header.filter({ $0 == "," }).count { expected = ";" }
            else { expected = "," }
            XCTAssertEqual(file.delimiter, expected, "Delimiter for \(file.fileName)")
        }
        // At least one pH OUT_OF_RANGE across dataset.
        XCTAssertTrue(files.flatMap { $0.issues }.contains { $0.code == .outOfRange })
        // Mapping: every file maps at least Sample_ID + pH.
        let mapper = MapperEngine()
        for file in files {
            let rules = mapper.autoMap(headers: file.rawHeaders)
            XCTAssertTrue(rules.contains { $0.asmPath == "asm.sample.id" }, "\(file.fileName) maps Sample_ID")
            XCTAssertTrue(rules.contains { $0.asmPath == "asm.measurement.pH" }, "\(file.fileName) maps pH")
        }
        // VERA CSV has header + 1500 rows and valid quoting.
        let vera = VeraGenerator().generateAll(for: files)
        let csv = VeraExporter().veraCSV(cases: vera)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        XCTAssertEqual(lines.count, 1501)
        XCTAssertEqual(lines.first, "TestCaseID,FileName,Title,Status,Detail")
        // ASM JSON parses.
        let asm = AsmBuilder().buildJSON(for: files[0])
        XCTAssertNotNil(try? JSONSerialization.jsonObject(with: Data(asm.utf8)))
    }

    func testVersionMatchesFile() throws {
        let url = URL(fileURLWithPath: "VERSION")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("VERSION file not found")
        }
        let pinned = try String(contentsOf: url, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(AppVersion.current, pinned, "Bump AppVersion.current with VERSION file")
    }

    func testDatasetPerformance() async throws {
        let zipURL = URL(fileURLWithPath: "data/crazy_vendor_dataset.zip")
        guard FileManager.default.fileExists(atPath: zipURL.path) else {
            throw XCTSkip("Dataset zip not found at \(zipURL.path)")
        }
        let zipData = try Data(contentsOf: zipURL)
        let start = Date()
        let files = try await engine.fingerprintZip(zipData)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertEqual(files.count, 300)
        XCTAssertLessThan(elapsed, 5.0, "Parsed 300 files in \(elapsed)s, must be <5s")
        // 5 VERA rows per file = 1500 rows.
        let vera = VeraGenerator().generateAll(for: files)
        XCTAssertEqual(vera.count, 1500)
    }
}
