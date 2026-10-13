import Foundation
import Compression

/// Minimal ZIP reader for stored + deflated entries. Apple frameworks only.
public struct ZipReader: Sendable {
    public struct Entry: Sendable {
        public var name: String
        public var data: Data
    }

    public init() {}

    public static func entries(from data: Data) throws -> [Entry] {
        // Find End of Central Directory.
        guard let eocdOffset = findEOCD(in: data) else {
            throw ZipError.notAZip
        }
        let cdCount = Int(readU16(data, at: eocdOffset + 10))
        var cdOffset = Int(readU32(data, at: eocdOffset + 16))
        var results: [Entry] = []
        for _ in 0..<cdCount {
            guard readU32(data, at: cdOffset) == 0x0201_4B50 else { break }
            let method = readU16(data, at: cdOffset + 10)
            let compSize = Int(readU32(data, at: cdOffset + 20))
            let uncompSize = Int(readU32(data, at: cdOffset + 24))
            let nameLen = Int(readU16(data, at: cdOffset + 28))
            let extraLen = Int(readU16(data, at: cdOffset + 30))
            let commentLen = Int(readU16(data, at: cdOffset + 32))
            let localOffset = Int(readU32(data, at: cdOffset + 42))
            let nameData = data.subdata(in: cdOffset + 46 ..< cdOffset + 46 + nameLen)
            let name = String(data: nameData, encoding: .utf8) ?? ""
            cdOffset += 46 + nameLen + extraLen + commentLen

            if name.hasSuffix("/") { continue } // directory
            guard readU32(data, at: localOffset) == 0x0403_4B50 else { continue }
            let localNameLen = Int(readU16(data, at: localOffset + 26))
            let localExtraLen = Int(readU16(data, at: localOffset + 28))
            let payloadStart = localOffset + 30 + localNameLen + localExtraLen
            let payload = data.subdata(in: payloadStart ..< payloadStart + compSize)

            let raw: Data
            switch method {
            case 0:
                raw = payload
            case 8:
                raw = try inflate(raw: payload, uncompressedSize: uncompSize)
            default:
                continue // skip unsupported method
            }
            results.append(Entry(name: name, data: raw))
        }
        return results
    }

    // MARK: - Inflate (raw deflate)

    private static func inflate(raw: Data, uncompressedSize: Int) throws -> Data {
        if raw.isEmpty { return Data() }
        let capacity = max(uncompressedSize, 1)
        var output = Data(count: capacity)
        let decoded: Int = output.withUnsafeMutableBytes { dst in
            raw.withUnsafeBytes { src in
                guard let dstBase = dst.baseAddress, let srcBase = src.baseAddress else { return 0 }
                return compression_decode_buffer(
                    dstBase.assumingMemoryBound(to: UInt8.self), capacity,
                    srcBase.assumingMemoryBound(to: UInt8.self), raw.count,
                    nil, COMPRESSION_ZLIB)
            }
        }
        guard decoded > 0 else { throw ZipError.corrupt }
        output.count = decoded
        return output
    }

    // MARK: - Helpers

    private static func findEOCD(in data: Data) -> Int? {
        guard data.count >= 22 else { return nil }
        var i = data.count - 22
        while true {
            if readU32(data, at: i) == 0x0605_4B50 { return i }
            if i == 0 { return nil }
            i -= 1
            if data.count - i > 22 + 65536 { return nil }
        }
    }

    private static func readU16(_ data: Data, at offset: Int) -> UInt16 {
        guard offset + 2 <= data.count else { return 0 }
        return data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: UInt16.self).littleEndian }
    }

    private static func readU32(_ data: Data, at offset: Int) -> UInt32 {
        guard offset + 4 <= data.count else { return 0 }
        return data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self).littleEndian }
    }

    public enum ZipError: Error {
        case notAZip, corrupt
    }
}
