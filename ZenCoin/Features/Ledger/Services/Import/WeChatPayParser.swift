import Foundation

/// 解析微信支付官方账单 CSV。
///
/// 文件结构：
/// 1. 前面若干行 metadata（"微信支付账单明细"、起止时间等）
/// 2. 一行分隔线 `----------------------微信支付账单明细列表----------------------`
/// 3. 表头：`交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注`
/// 4. 正文逐行交易
struct WeChatPayParser {

    /// 解析结果（含被跳过的行 + 原因，给预览页透明展示）。
    struct Result: Identifiable {
        let id = UUID()
        var drafts: [ImportDraft]
        var skipped: [Skipped]
    }

    struct Skipped {
        enum Reason: String {
            case nonAccounting    // 不计收支
            case refunded          // 已退款 / 已撤销
            case malformed         // 字段缺失 / 解析失败
        }
        let reason: Reason
        let rawRow: [String]
    }

    static func parse(_ data: Data) throws -> Result {
        let allRows: [[String]]
        if isZipFormat(data) {
            // xlsx：zip 容器 → 走 XLSXReader
            allRows = try XLSXReader.readFirstSheet(data)
        } else {
            guard let text = CSVUtilities.decode(data) else {
                throw ImportError.invalidEncoding
            }
            allRows = CSVUtilities.parseRows(text)
        }

        // 校验是否为微信账单（前 20 行内任何 cell 含「微信支付账单」）
        let hasMarker = allRows.prefix(20).contains { row in
            row.contains { $0.contains("微信支付账单") }
        }
        guard hasMarker else { throw ImportError.notWeChatPay }

        guard let headerIdx = headerIndex(in: allRows) else {
            throw ImportError.headerNotFound
        }
        let header = allRows[headerIdx]
        let body = Array(allRows.dropFirst(headerIdx + 1))

        // 列定位（容忍列顺序变化）
        let col = ColumnIndex(header: header)
        guard col.isValid else { throw ImportError.headerNotFound }

        var drafts: [ImportDraft] = []
        var skipped: [Skipped] = []

        for row in body {
            // 至少要有交易时间
            guard row.count >= header.count, !row[col.time].trimmingCharacters(in: .whitespaces).isEmpty else {
                continue
            }
            let direction = row[col.direction].trimmingCharacters(in: .whitespaces)
            // 中性交易（充值 / 提现 / 信用卡还款 / 零钱通存取 / 理财通购买等）— 收/支 列为 "/"。
            // 策略：仅保留明确的「收入」「支出」，其他一律视作中性跳过。
            guard direction == "收入" || direction == "支出" else {
                skipped.append(Skipped(reason: .nonAccounting, rawRow: row)); continue
            }
            let status = row[col.status]
            // 注：「已全额退款」「已部分退款」按用户策略保留（既保留原始支付，也保留对应退款行，反映真实流水）。
            // 这里只过滤真正没发生的交易。
            if status.contains("已撤销") || status.contains("失败") || status == "退款中" {
                skipped.append(Skipped(reason: .refunded, rawRow: row)); continue
            }
            guard let date = parseDate(row[col.time]) else {
                skipped.append(Skipped(reason: .malformed, rawRow: row)); continue
            }
            guard let amount = parseAmount(row[col.amount]) else {
                skipped.append(Skipped(reason: .malformed, rawRow: row)); continue
            }

            let isIncome = (direction == "收入")
            let counterparty = row[col.counterparty].trimmingCharacters(in: .whitespaces)
            let item = row[col.item].trimmingCharacters(in: .whitespaces)
            let kind = row[col.kind]
            let note = composeNote(counterparty: counterparty, item: item)
            let guessed = CategoryGuesser.guess([kind, item, counterparty], isIncome: isIncome)
            let category = guessed ?? (isIncome ? .otherIncome : .other)
            let externalId = row[col.txnId].trimmingCharacters(in: .whitespaces)

            drafts.append(ImportDraft(
                paymentTime: date,
                amount: amount,
                isIncome: isIncome,
                category: category,
                note: note,
                externalId: externalId.isEmpty ? nil : externalId,
                source: .wechat,
                pendingAI: guessed == nil,
                rawCounterparty: counterparty,
                rawItem: item
            ))
        }

        return Result(drafts: drafts, skipped: skipped)
    }

    // MARK: - Helpers

    /// zip 容器特征字节：`PK\x03\x04`（local file header）/ `PK\x05\x06`（empty）/ `PK\x07\x08`（spanned）。
    private static func isZipFormat(_ data: Data) -> Bool {
        guard data.count >= 4 else { return false }
        let b0 = data[data.startIndex]
        let b1 = data[data.index(data.startIndex, offsetBy: 1)]
        let b2 = data[data.index(data.startIndex, offsetBy: 2)]
        let b3 = data[data.index(data.startIndex, offsetBy: 3)]
        return b0 == 0x50 && b1 == 0x4B && (b2 == 0x03 || b2 == 0x05 || b2 == 0x07) && (b3 == 0x04 || b3 == 0x06 || b3 == 0x08)
    }

    private static func headerIndex(in rows: [[String]]) -> Int? {
        for (i, row) in rows.enumerated() {
            // 允许首列出现在任意位置（兼容前后空白行）
            if row.contains(where: { $0.contains("交易时间") })
                && row.contains(where: { $0.contains("收/支") }) {
                return i
            }
        }
        return nil
    }

    private static func parseDate(_ s: String) -> Date? {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        for fmt in ["yyyy-MM-dd HH:mm:ss", "yyyy/MM/dd HH:mm:ss", "yyyy-MM-dd HH:mm"] {
            f.dateFormat = fmt
            if let d = f.date(from: trimmed) { return d }
        }
        // xlsx 把日期存成 Excel 序列数（fractional days since 1899-12-30）。
        // 我们没解 styles.xml，靠数值范围兜底（25000-100000 ≈ 1968-2173）。
        if let v = Double(trimmed), v > 25000, v < 100000 {
            var comps = DateComponents()
            comps.year = 1899; comps.month = 12; comps.day = 30
            if let epoch = Calendar(identifier: .gregorian).date(from: comps) {
                return epoch.addingTimeInterval(v * 86400)
            }
        }
        return nil
    }

    private static func parseAmount(_ s: String) -> Double? {
        let cleaned = s
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: "￥", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }

    /// 根据交易对方 + 商品组合一个易读的备注。
    ///
    /// 微信账单的「交易对方」并不可靠——既可能是真实商户（"星巴克"），也可能只是
    /// 平台代收实体（"美团"/"美团平台商户"/"拼多多"），后者真实商家其实在「商品」里。
    /// 用 item 末尾「订单号 tail」作为最强信号识别后者。
    ///
    /// 规则（按顺序）：
    /// 1. item 末尾能剥出订单号 tail → 用剥后的 item（说明这是被平台中转的单子，
    ///    item 前半段才是真商家名）
    /// 2. cp 显式标注「平台商户」→ 用 cleaned item 兜底
    /// 3. cp 非空 → 用 cp
    /// 4. 啥都没 → 用 cleaned item
    private static func composeNote(counterparty: String, item: String) -> String {
        let cp = counterparty.trimmingCharacters(in: .whitespaces)
        let raw = item.trimmingCharacters(in: .whitespaces)
        let cleaned = stripTrailingOrderId(raw)
        let itemHadOrderId = (cleaned != raw)

        if itemHadOrderId, !cleaned.isEmpty { return cleaned }
        if isPlatformCounterparty(cp), !cleaned.isEmpty { return cleaned }
        if !cp.isEmpty { return cp }
        return cleaned
    }

    /// cp 显式带「平台商户」字样的兜底信号（不是主要判据）。
    private static func isPlatformCounterparty(_ s: String) -> Bool {
        s.contains("平台商户")
    }

    /// 剥掉商品名末尾的订单 ID tail。匹配模式：
    /// - 0 或 1 段 `-name` + 末尾 `-数字串`（≥10 位）
    /// 覆盖：
    /// - `-美团外卖App-25082511...`         （-平台名-订单号）
    /// - `-美团App-25082811...`             （-平台名-订单号）
    /// - `-26032611100300001307447...`      （直接订单号，无前缀段）
    /// 收着剥（≤1 段）：避免 `门票-上海某园（团购店）-数字` 被切到只剩 `门票`。
    private static let trailingOrderIdRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "(?:-[^-]+)?-\\d{10,}$")
    }()

    private static func stripTrailingOrderId(_ s: String) -> String {
        let range = NSRange(s.startIndex..<s.endIndex, in: s)
        let cleaned = trailingOrderIdRegex.stringByReplacingMatches(in: s, range: range, withTemplate: "")
        return cleaned.trimmingCharacters(in: .whitespaces)
    }

    private struct ColumnIndex {
        let time: Int
        let kind: Int
        let counterparty: Int
        let item: Int
        let direction: Int
        let amount: Int
        let status: Int
        let txnId: Int
        var isValid: Bool {
            [time, kind, counterparty, item, direction, amount, status, txnId].allSatisfy { $0 >= 0 }
        }

        init(header: [String]) {
            self.time = Self.find(header, "交易时间")
            self.kind = Self.find(header, "交易类型")
            self.counterparty = Self.find(header, "交易对方")
            self.item = Self.find(header, "商品")
            self.direction = Self.find(header, "收/支")
            self.amount = Self.find(header, "金额")
            self.status = Self.find(header, "当前状态")
            self.txnId = Self.find(header, "交易单号")
        }

        private static func find(_ header: [String], _ keyword: String) -> Int {
            header.firstIndex(where: { $0.contains(keyword) }) ?? -1
        }
    }
}

// MARK: - Shared types

struct ImportDraft: Identifiable {
    let id = UUID()
    var paymentTime: Date
    var amount: Double
    var isIncome: Bool
    var category: ExpenseCategory
    var note: String
    var externalId: String?
    var source: Source
    /// 用户在预览页可能取消勾选某些行。
    var enabled: Bool = true
    /// 关键词字典没命中、等待 AI 推断的占位行。AI 完成后置 false。
    var pendingAI: Bool = false
    /// 当前 category / note 是否由 AI 推断（用于在预览页打个轻量标签）。
    var aiSuggested: Bool = false
    /// 原始「交易对方」「商品」字段，仅用于 AI 调用时给模型更多上下文，不入库。
    var rawCounterparty: String = ""
    var rawItem: String = ""

    enum Source: String { case wechat, alipay, generic }
}

enum ImportError: LocalizedError {
    case invalidEncoding
    case notWeChatPay
    case headerNotFound
    case empty

    var errorDescription: String? {
        switch self {
        case .invalidEncoding: return "无法识别文件编码"
        case .notWeChatPay:    return "不是微信支付账单"
        case .headerNotFound:  return "找不到表头"
        case .empty:           return "文件没有可导入的记录"
        }
    }
}
