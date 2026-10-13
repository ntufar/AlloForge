import Foundation

/// Auto-map vendor headers to ASM paths.
public struct MapperEngine: Sendable {
    private let synonyms = SynonymDictionary()

    public init() {}

    /// ASM target path per canonical field.
    public static let asmPaths = [
        "Sample_ID": "asm.sample.id",
        "pH": "asm.measurement.pH",
        "Temperature": "asm.measurement.temperature",
        "Date": "asm.measurement.datetime",
        "Operator": "asm.metadata.operator"
    ]

    /// AFO term per canonical field.
    public static let afoTerms = [
        "Sample_ID": "AFO:0000001",
        "pH": "AFO:0000002",
        "Temperature": "AFO:0000003",
        "Date": "AFO:0000004",
        "Operator": "AFO:0000005"
    ]

    public static let transformations: [String: TransformationType] = [
        "Sample_ID": .trim,
        "pH": .round2,
        "Temperature": .float,
        "Date": .isoDate,
        "Operator": .trim
    ]

    /// Build rules for raw headers.
    public func autoMap(headers: [String]) -> [MappingRule] {
        headers.compactMap { header in
            guard let canonical = synonyms.canonicalField(for: header) else { return nil }
            return MappingRule(
                vendorField: header,
                asmPath: Self.asmPaths[canonical] ?? "asm.custom.\(canonical)",
                afoTerm: Self.afoTerms[canonical] ?? "AFO:0000000",
                isMerckKeyField: SynonymDictionary.merckKeyFields.contains(canonical),
                transformation: Self.transformations[canonical] ?? .direct
            )
        }
    }
}
