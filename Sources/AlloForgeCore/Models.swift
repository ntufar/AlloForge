import Foundation

// MARK: - Instrument

public enum InstrumentType: String, Codable, Sendable, CaseIterable {
    case mettler, agilent, thermo, biotek, sartorius, unknown
}

// MARK: - Issues

public enum Severity: String, Codable, Sendable {
    case error, warning, info
}

public enum IssueCode: String, Codable, Sendable, CaseIterable {
    case missingKeyField
    case outOfRange
    case badDate
    case commaDecimal
    case delimiterInconsistent
    case emptyValue
    case duplicateID
    case bomEncoding
}

public struct FileIssue: Codable, Sendable, Identifiable {
    public var id: UUID
    public var code: IssueCode
    public var severity: Severity
    public var row: Int?
    public var field: String?
    public var value: String?
    public var message: String

    public init(
        code: IssueCode, severity: Severity, row: Int? = nil,
        field: String? = nil, value: String? = nil, message: String
    ) {
        self.id = UUID()
        self.code = code
        self.severity = severity
        self.row = row
        self.field = field
        self.value = value
        self.message = message
    }
}

// MARK: - File status

public enum FileStatus: String, Codable, Sendable {
    case pass, warning, fail
}

// MARK: - Vendor file

public struct VendorFile: Codable, Sendable, Identifiable {
    public var id: UUID
    public var fileName: String
    public var delimiter: String
    public var encoding: String
    public var rawHeaders: [String]
    public var normalizedHeaders: [String]
    public var detectedInstrument: InstrumentType
    public var merckKeyFieldCoverage: Double
    public var issues: [FileIssue]
    public var status: FileStatus
    public var rowCount: Int
    /// Raw rows, one array per data row. Values stay raw for display.
    public var rows: [[String]]
    public var asmJSON: String?

    public init(
        id: UUID = UUID(), fileName: String, delimiter: String, encoding: String,
        rawHeaders: [String], normalizedHeaders: [String],
        detectedInstrument: InstrumentType, merckKeyFieldCoverage: Double,
        issues: [FileIssue], status: FileStatus, rowCount: Int,
        rows: [[String]] = [], asmJSON: String? = nil
    ) {
        self.id = id
        self.fileName = fileName
        self.delimiter = delimiter
        self.encoding = encoding
        self.rawHeaders = rawHeaders
        self.normalizedHeaders = normalizedHeaders
        self.detectedInstrument = detectedInstrument
        self.merckKeyFieldCoverage = merckKeyFieldCoverage
        self.issues = issues
        self.status = status
        self.rowCount = rowCount
        self.rows = rows
        self.asmJSON = asmJSON
    }
}

// MARK: - Mapping

public enum TransformationType: String, Codable, Sendable {
    case direct, round2, isoDate, float, trim, commaToDot
}

public struct MappingRule: Codable, Sendable, Identifiable {
    public var id: UUID
    public var vendorField: String
    public var asmPath: String
    public var afoTerm: String
    public var isMerckKeyField: Bool
    public var transformation: TransformationType

    public init(
        vendorField: String, asmPath: String, afoTerm: String,
        isMerckKeyField: Bool, transformation: TransformationType
    ) {
        self.id = UUID()
        self.vendorField = vendorField
        self.asmPath = asmPath
        self.afoTerm = afoTerm
        self.isMerckKeyField = isMerckKeyField
        self.transformation = transformation
    }
}

// MARK: - VERA

public enum VeraStatus: String, Codable, Sendable {
    case pass, fail
}

public struct VeraTestCase: Codable, Sendable, Identifiable {
    public var id: UUID
    public var caseID: String
    public var fileName: String
    public var title: String
    public var status: VeraStatus
    public var detail: String

    public init(caseID: String, fileName: String, title: String, status: VeraStatus, detail: String) {
        self.id = UUID()
        self.caseID = caseID
        self.fileName = fileName
        self.title = title
        self.status = status
        self.detail = detail
    }
}
