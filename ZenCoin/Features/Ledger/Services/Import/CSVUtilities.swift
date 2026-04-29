import Foundation

/// 极简 CSV 解析 / 序列化。
///
/// 仅支持 RFC 4180 的常见子集：
/// - 字段用 `,` 分隔；
/// - 字段含逗号 / 引号 / 换行时用双引号包裹，内部双引号转义为 `""`。
/// 微信、支付宝等的导出都遵守这套；够用。
enum CSVUtilities {

    // MARK: - Decoding

    /// 把原始文件 bytes 解成字符串。
    /// 优先 UTF-8（可带 BOM）；失败回退到 GB18030（覆盖 GBK，老支付宝账单常见）。
    static func decode(_ data: Data) -> String? {
        var bytes = data
        // 去掉 UTF-8 BOM（EF BB BF）
        if bytes.starts(with: [0xEF, 0xBB, 0xBF]) {
            bytes = bytes.dropFirst(3)
        }
        if let s = String(data: bytes, encoding: .utf8) { return s }
        let gb18030 = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
        if let s = String(data: data, encoding: String.Encoding(rawValue: gb18030)) {
            return s
        }
        return nil
    }

    // MARK: - Row parsing

    /// 把整段 CSV 文本切成行（保留每行内字段的字符串数组）。
    /// 处理引号内的换行。
    static func parseRows(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var field = ""
        var row: [String] = []
        var inQuotes = false
        var i = text.startIndex

        while i < text.endIndex {
            let c = text[i]
            if inQuotes {
                if c == "\"" {
                    let next = text.index(after: i)
                    if next < text.endIndex, text[next] == "\"" {
                        field.append("\"")
                        i = text.index(after: next)
                        continue
                    }
                    inQuotes = false
                    i = text.index(after: i)
                    continue
                }
                field.append(c)
                i = text.index(after: i)
                continue
            }
            switch c {
            case "\"":
                inQuotes = true
            case ",":
                row.append(field)
                field = ""
            case "\r":
                // 吃掉 \r\n 中的 \r
                break
            case "\n":
                row.append(field)
                rows.append(row)
                field = ""
                row = []
            default:
                field.append(c)
            }
            i = text.index(after: i)
        }
        // 收尾
        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }
        return rows
    }

    // MARK: - Encoding

    /// 把字段数组拼成 CSV 一行（含必要的引号转义），不带换行。
    static func formatRow(_ fields: [String]) -> String {
        fields.map { escape($0) }.joined(separator: ",")
    }

    /// 把整张表序列化为 UTF-8 BOM 的 CSV 文本（Excel 中文友好）。
    static func encode(rows: [[String]]) -> Data {
        var s = "\u{FEFF}"
        s += rows.map { formatRow($0) }.joined(separator: "\r\n")
        s += "\r\n"
        return Data(s.utf8)
    }

    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            let esc = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(esc)\""
        }
        return field
    }
}
