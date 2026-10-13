import XCTest
@testable import AlloForgeCore

final class JSONTokenizerTests: XCTestCase {
    let tokenizer = JSONTokenizer()

    func testRoundTrip() {
        let json = "{\n  \"sampleID\": \"SMP-1\",\n  \"pH\": 7.02,\n  \"ok\": true,\n  \"x\": null\n}"
        let tokens = tokenizer.tokenize(json)
        XCTAssertEqual(tokens.map { $0.text }.joined(), json)
    }

    func testKinds() {
        let tokens = tokenizer.tokenize("{\"sampleID\": \"SMP-1\", \"pH\": 7.02, \"ok\": true}")
        let kinds = tokens.filter { $0.kind != .whitespace && $0.kind != .punctuation }
        XCTAssertEqual(kinds.map { $0.kind }, [.key, .string, .key, .number, .key, .literal])
    }

    func testEscapedQuotes() {
        let tokens = tokenizer.tokenize("{\"a\": \"x\\\"y\"}")
        let strings = tokens.filter { $0.kind == .string }
        XCTAssertEqual(strings.count, 1)
        XCTAssertEqual(strings.first?.text, "\"x\\\"y\"")
    }
}
