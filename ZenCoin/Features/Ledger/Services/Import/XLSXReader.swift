import Foundation
import Compression

/// 把 xlsx 字节流解析为 `[[String]]`，与 CSV parser 输出同形，
/// 之后由 WeChatPayParser 统一处理。
///
/// 设计：xlsx = zip + 一组 XML。我们只需要：
/// - `xl/sharedStrings.xml` — 字符串表（cells `t="s"` 时用）
/// - `xl/worksheets/sheet1.xml` — 第一张工作表
///
/// 不引外部依赖：用 Apple `Compression` 做 raw DEFLATE，`XMLParser` 走 SAX。
enum XLSXReader {

    static func readFirstSheet(_ data: Data) throws -> [[String]] {
        let zip = try MinimalZip(data: data)
        var sst: [String] = []
        if zip.entries["xl/sharedStrings.xml"] != nil {
            let sstData = try zip.extract("xl/sharedStrings.xml")
            sst = try parseSharedStrings(sstData)
        }
        let sheetData = try zip.extract("xl/worksheets/sheet1.xml")
        return try parseSheet(sheetData, sst: sst)
    }

    // MARK: - SST

    private static func parseSharedStrings(_ data: Data) throws -> [String] {
        let parser = XMLParser(data: data)
        let delegate = SSTDelegate()
        parser.delegate = delegate
        guard parser.parse() else { throw XLSXError.malformedXML }
        return delegate.strings
    }

    // MARK: - Sheet

    private static func parseSheet(_ data: Data, sst: [String]) throws -> [[String]] {
        let parser = XMLParser(data: data)
        let delegate = SheetDelegate(sst: sst)
        parser.delegate = delegate
        guard parser.parse() else { throw XLSXError.malformedXML }
        // 各行宽度补齐到最大列数（避免下游 row[index] 越界）
        let maxLen = delegate.rows.map { $0.count }.max() ?? 0
        return delegate.rows.map { row in
            row.count >= maxLen ? row : row + Array(repeating: "", count: maxLen - row.count)
        }
    }
}

// MARK: - Errors

enum XLSXError: Error, LocalizedError {
    case notZip
    case eocdNotFound
    case truncated
    case unsupportedMethod(UInt16)
    case decompressionFailed
    case missingFile(String)
    case malformedXML

    var errorDescription: String? {
        switch self {
        case .notZip:                  return "不是有效的 XLSX 文件"
        case .eocdNotFound:            return "XLSX 结构损坏（缺 EOCD）"
        case .truncated:               return "XLSX 文件被截断"
        case .unsupportedMethod(let m): return "暂不支持的压缩方式 \(m)"
        case .decompressionFailed:     return "XLSX 解压失败"
        case .missingFile(let n):      return "XLSX 缺少 \(n)"
        case .malformedXML:            return "XLSX 内部 XML 异常"
        }
    }
}

// MARK: - MinimalZip

private struct MinimalZip {
    private let bytes: [UInt8]
    let entries: [String: Entry]

    struct Entry {
        let method: UInt16
        let compressedSize: Int
        let uncompressedSize: Int
        let localOffset: Int
    }

    init(data: Data) throws {
        let bytes = Array(data)
        guard bytes.count >= 22 else { throw XLSXError.truncated }
        guard bytes[0] == 0x50, bytes[1] == 0x4B else { throw XLSXError.notZip }
        self.bytes = bytes

        // EOCD 反向扫描（PK\x05\x06）。注释区最多 65535 字节。
        let sig: [UInt8] = [0x50, 0x4B, 0x05, 0x06]
        var eocd = -1
        let lower = max(0, bytes.count - 65557)
        var i = bytes.count - 22
        while i >= lower {
            if bytes[i] == sig[0], bytes[i+1] == sig[1], bytes[i+2] == sig[2], bytes[i+3] == sig[3] {
                eocd = i; break
            }
            i -= 1
        }
        guard eocd >= 0 else { throw XLSXError.eocdNotFound }

        let totalEntries = Int(Self.u16(bytes, eocd + 10))
        let cdOffset = Int(Self.u32(bytes, eocd + 16))

        var entries: [String: Entry] = [:]
        var p = cdOffset
        for _ in 0..<totalEntries {
            guard p + 46 <= bytes.count else { throw XLSXError.truncated }
            // 中央目录条目签名：PK\x01\x02
            let method = Self.u16(bytes, p + 10)
            let compSize = Int(Self.u32(bytes, p + 20))
            let uncompSize = Int(Self.u32(bytes, p + 24))
            let nameLen = Int(Self.u16(bytes, p + 28))
            let extraLen = Int(Self.u16(bytes, p + 30))
            let commentLen = Int(Self.u16(bytes, p + 32))
            let localOffset = Int(Self.u32(bytes, p + 42))
            let nameStart = p + 46
            guard nameStart + nameLen <= bytes.count else { throw XLSXError.truncated }
            let name = String(bytes: bytes[nameStart..<(nameStart + nameLen)], encoding: .utf8) ?? ""
            entries[name] = Entry(
                method: method,
                compressedSize: compSize,
                uncompressedSize: uncompSize,
                localOffset: localOffset
            )
            p = nameStart + nameLen + extraLen + commentLen
        }
        self.entries = entries
    }

    func extract(_ name: String) throws -> Data {
        guard let entry = entries[name] else { throw XLSXError.missingFile(name) }
        let lh = entry.localOffset
        guard lh + 30 <= bytes.count else { throw XLSXError.truncated }
        // 本地文件头：PK\x03\x04
        let nameLen = Int(Self.u16(bytes, lh + 26))
        let extraLen = Int(Self.u16(bytes, lh + 28))
        let dataStart = lh + 30 + nameLen + extraLen
        guard dataStart + entry.compressedSize <= bytes.count else { throw XLSXError.truncated }
        let compressed = Data(bytes[dataStart..<(dataStart + entry.compressedSize)])
        switch entry.method {
        case 0:
            return compressed
        case 8:
            return try inflate(compressed, expected: entry.uncompressedSize)
        default:
            throw XLSXError.unsupportedMethod(entry.method)
        }
    }

    private func inflate(_ src: Data, expected: Int) throws -> Data {
        var dst = Data(count: expected)
        let n = dst.withUnsafeMutableBytes { dstPtr -> Int in
            src.withUnsafeBytes { srcPtr -> Int in
                guard let dstBase = dstPtr.bindMemory(to: UInt8.self).baseAddress,
                      let srcBase = srcPtr.bindMemory(to: UInt8.self).baseAddress
                else { return 0 }
                // COMPRESSION_ZLIB 在 Apple Compression 中即 raw DEFLATE，与 zip 一致
                return compression_decode_buffer(
                    dstBase, expected,
                    srcBase, src.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        guard n == expected else { throw XLSXError.decompressionFailed }
        return dst
    }

    private static func u16(_ b: [UInt8], _ off: Int) -> UInt16 {
        UInt16(b[off]) | (UInt16(b[off+1]) << 8)
    }
    private static func u32(_ b: [UInt8], _ off: Int) -> UInt32 {
        UInt32(b[off]) | (UInt32(b[off+1]) << 8) | (UInt32(b[off+2]) << 16) | (UInt32(b[off+3]) << 24)
    }
}

// MARK: - XML delegates

private final class SSTDelegate: NSObject, XMLParserDelegate {
    var strings: [String] = []
    private var current = ""
    private var inT = false
    private var inSI = false

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes: [String : String]) {
        if elementName == "si" {
            current = ""
            inSI = true
        } else if elementName == "t" {
            inT = true
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inSI && inT { current += string }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "t" {
            inT = false
        } else if elementName == "si" {
            strings.append(current)
            inSI = false
        }
    }
}

private final class SheetDelegate: NSObject, XMLParserDelegate {
    let sst: [String]
    var rows: [[String]] = []
    private var currentRow: [String] = []
    private var currentCellType = ""
    private var currentValue = ""
    private var inV = false
    private var inT = false

    init(sst: [String]) { self.sst = sst; super.init() }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attrs: [String : String]) {
        switch elementName {
        case "row":
            currentRow = []
        case "c":
            // 用 r="A1" 计算列号，缺失列填空字符串
            let ref = attrs["r"] ?? ""
            let col = columnIndexFromRef(ref)
            while currentRow.count < col { currentRow.append("") }
            currentCellType = attrs["t"] ?? ""
            currentValue = ""
        case "v":
            inV = true
        case "t":
            inT = true
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inV || inT { currentValue += string }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "v":
            inV = false
        case "t":
            inT = false
        case "c":
            let text: String
            if currentCellType == "s" {
                if let idx = Int(currentValue), idx >= 0, idx < sst.count {
                    text = sst[idx]
                } else { text = "" }
            } else {
                text = currentValue
            }
            currentRow.append(text)
        case "row":
            rows.append(currentRow)
            currentRow = []
        default:
            break
        }
    }
}

private func columnIndexFromRef(_ ref: String) -> Int {
    var idx = 0
    let A = Character("A").asciiValue!
    for c in ref {
        guard let v = c.asciiValue else { break }
        if v >= A, v <= A + 25 {
            idx = idx * 26 + Int(v - A) + 1
        } else {
            break
        }
    }
    return max(0, idx - 1)
}
