import Foundation

/// 解析支付宝官方账单 CSV。
///
/// 文件结构：
/// 1. 前面若干行 metadata（账户信息、起止时间、收支统计等）
/// 2. 一行分隔线 `------------------------支付宝（中国）网络技术有限公司  电子客户账单------------------------`
/// 3. 表头：`交易时间,交易分类,交易对方,对方账号,商品说明,收/支,金额,收/付款方式,交易状态,交易订单号,商家订单号,备注`
/// 4. 正文逐行交易
struct AliPayParser {

    static func parse(_ data: Data) throws -> WeChatPayParser.Result {
        guard let text = CSVUtilities.decode(data) else {
            throw ImportError.invalidEncoding
        }
        let allRows = CSVUtilities.parseRows(text)

        // 校验是否为支付宝账单（前 30 行内任何 cell 含「支付宝」）
        let hasMarker = allRows.prefix(30).contains { row in
            row.contains { $0.contains("支付宝") }
        }
        guard hasMarker else { throw ImportError.notAlipay }

        guard let headerIdx = headerIndex(in: allRows) else {
            throw ImportError.headerNotFound
        }
        let header = allRows[headerIdx]
        let body = Array(allRows.dropFirst(headerIdx + 1))

        let col = ColumnIndex(header: header)
        guard col.isValid else { throw ImportError.headerNotFound }

        var drafts: [ImportDraft] = []
        var skipped: [BillSkipped] = []

        for row in body {
            guard row.count > col.minRequiredIndex,
                  !row[col.time].trimmingCharacters(in: .whitespaces).isEmpty else {
                continue
            }
            let direction = row[col.direction].trimmingCharacters(in: .whitespaces)
            // 仅保留明确的「收入」「支出」；余额宝收益等投资流水（"/"、空、或特殊值）视作中性跳过。
            guard direction == "收入" || direction == "支出" else {
                skipped.append(BillSkipped(reason: .nonAccounting, rawRow: row)); continue
            }
            let status = row[col.status].trimmingCharacters(in: .whitespaces)
            // 交易关闭 = 已撤销/超时，等待买家付款 = 未完成；失败同理。
            if status == "交易关闭" || status.contains("失败") || status == "等待买家付款" {
                skipped.append(BillSkipped(reason: .refunded, rawRow: row)); continue
            }
            guard let date = parseDate(row[col.time]) else {
                skipped.append(BillSkipped(reason: .malformed, rawRow: row)); continue
            }
            guard let amount = parseAmount(row[col.amount]) else {
                skipped.append(BillSkipped(reason: .malformed, rawRow: row)); continue
            }

            let isIncome = (direction == "收入")
            let counterparty = row[col.counterparty].trimmingCharacters(in: .whitespaces)
            let item = col.item >= 0 ? row[col.item].trimmingCharacters(in: .whitespaces) : ""
            let kind = col.kind >= 0 ? row[col.kind].trimmingCharacters(in: .whitespaces) : ""
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
                source: .alipay,
                pendingAI: guessed == nil,
                rawCounterparty: counterparty,
                rawItem: item
            ))
        }

        return WeChatPayParser.Result(drafts: drafts, skipped: skipped, source: .alipay)
    }

    // MARK: - Helpers

    private static func headerIndex(in rows: [[String]]) -> Int? {
        for (i, row) in rows.enumerated() {
            if row.contains(where: { $0.contains("交易时间") })
                && row.contains(where: { $0.contains("交易状态") }) {
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

    /// 支付宝的「交易对方」通常是真实商户名，比微信可靠。
    /// 若对方为「/」（理财/内部转账）则回退到商品说明。
    private static func composeNote(counterparty: String, item: String) -> String {
        let cp = counterparty.trimmingCharacters(in: .whitespaces)
        if !cp.isEmpty && cp != "/" { return cp }
        return item.trimmingCharacters(in: .whitespaces)
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

        /// 所有已定位列中最大的索引 + 1，用于 row.count 越界检查。
        var minRequiredIndex: Int {
            [time, direction, amount, status, txnId]
                .filter { $0 >= 0 }
                .max() ?? 0
        }

        var isValid: Bool {
            [time, direction, amount, status, txnId].allSatisfy { $0 >= 0 }
        }

        init(header: [String]) {
            self.time         = Self.find(header, "交易时间")
            self.kind         = Self.find(header, "交易分类")
            self.counterparty = Self.find(header, "交易对方")
            self.item         = Self.find(header, "商品说明")
            self.direction    = Self.find(header, "收/支")
            self.amount       = Self.find(header, "金额")
            self.status       = Self.find(header, "交易状态")
            self.txnId        = Self.find(header, "交易订单号")
        }

        private static func find(_ header: [String], _ keyword: String) -> Int {
            // 优先精确匹配，避免 iOS locale 下 contains 的误匹配（如"金额"误中"交易时间"）
            if let i = header.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == keyword }) {
                return i
            }
            return header.firstIndex(where: { $0.contains(keyword) }) ?? -1
        }
    }
}
