import UIKit
import Foundation

struct AIExpenseDraft: Identifiable {
    let id = UUID()
    let amount: Double
    let isIncome: Bool
    let category: ExpenseCategory
    let note: String
    let paymentTime: Date?
}

enum AIError: Error, LocalizedError {
    case noAPIKey
    case noImage
    case network(String)
    case parse(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "尚未设置 API Key（设置 → AI 记账）"
        case .noImage:  return "剪贴板里没有截图"
        case .network(let m): return "网络错误：\(m)"
        case .parse(let m): return "解析失败：\(m)"
        }
    }
}

private struct OpenAIResponse: Decodable {
    let choices: [Choice]
    struct Choice: Decodable { let message: Message }
    struct Message: Decodable { let content: String }
}

@MainActor
final class ExpenseAIService {
    static let shared = ExpenseAIService()
    private let keyService = BailianKeyService.shared

    private let endpoint = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    private let model = "qwen-vl-max-latest"
    /// 纯文本批量分类用：比 vl-max 快 5×、便宜 ~10×。
    private let textModel = "qwen-max-latest"

    private var systemPrompt: String {
        let now = Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm"
        fmt.locale = Locale(identifier: "zh_CN")
        let dateStr = fmt.string(from: now)
        let expenseRaws = ExpenseCategory.expenseCases.map { $0.rawValue }.joined(separator: ",")
        let incomeRaws = ExpenseCategory.incomeCases.map { $0.rawValue }.joined(separator: ",")
        return """
        你是支付截图 JSON 提取器。当前时间：\(dateStr)。规则：
        1. 只输出 JSON 数组，不要任何解释、前言、markdown
        2. 识别截图中所有支付记录，每笔一个对象
        3. 格式：[{"amount":数字,"isIncome":false,"category":"rawValue","note":"商户名或用途","paymentTime":"yyyy-MM-dd HH:mm"}]
        4. amount 必须是正数（去掉负号）
        5. paymentTime 必须包含完整年份；只有月日则按当前时间推断年份；"今天/昨天"转绝对日期
        6. category 取值——支出：\(expenseRaws)；收入：\(incomeRaws)
        7. 根据商户名或用途推断最合适的分类，无法判断填 other
        8. 字段缺失：字符串用 ""，数字用 0，布尔用 false，日期用 null
        9. 截图不是支付相关，返回 []
        """
    }

    func recognize(image: UIImage) async throws -> [AIExpenseDraft] {
        guard let apiKey = keyService.apiKey() else { throw AIError.noAPIKey }
        guard let jpegData = image.jpegData(compressionQuality: 0.6) else {
            throw AIError.parse("图片编码失败")
        }
        let base64 = jpegData.base64EncodedString()

        let messages: [[String: Any]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": [
                ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64)"]],
                ["type": "text", "text": "提取所有支付记录。"]
            ]]
        ]

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 2048,
            "messages": messages
        ]

        var request = URLRequest(url: URL(string: endpoint)!, timeoutInterval: 90)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIError.network(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw AIError.network("HTTP \(http.statusCode) — \(msg.prefix(200))")
        }

        guard let decoded = try? JSONDecoder().decode(OpenAIResponse.self, from: data),
              let text = decoded.choices.first?.message.content else {
            throw AIError.parse("API 响应异常")
        }

        return parseDrafts(text)
    }

    private func parseDrafts(_ text: String) -> [AIExpenseDraft] {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```") {
            if let nl = cleaned.firstIndex(of: "\n") {
                cleaned = String(cleaned[cleaned.index(after: nl)...])
            }
            if cleaned.hasSuffix("```") { cleaned = String(cleaned.dropLast(3)) }
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let start = cleaned.firstIndex(of: "["),
              let end = cleaned.lastIndex(of: "]") else { return [] }
        let jsonStr = String(cleaned[start...end])
        guard let jsonData = jsonStr.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            return []
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")

        let fallback = DateFormatter()
        fallback.dateFormat = "MM-dd HH:mm"
        fallback.locale = Locale(identifier: "zh_CN")
        let currentYear = Calendar.current.component(.year, from: Date())

        return array.compactMap { json in
            var amount = (json["amount"] as? Double) ?? (json["amount"] as? Int).map(Double.init) ?? 0
            if amount < 0 { amount = abs(amount) }
            guard amount > 0 else { return nil }

            let isIncome = json["isIncome"] as? Bool ?? false
            let categoryRaw = json["category"] as? String ?? "other"
            var category = ExpenseCategory(rawValue: categoryRaw) ?? .other
            if isIncome && !category.isIncome { category = .otherIncome }
            if !isIncome && category.isIncome { category = .other }

            let note = (json["note"] as? String) ?? (json["merchant"] as? String) ?? ""

            var paymentTime: Date?
            if let s = json["paymentTime"] as? String, !s.isEmpty {
                paymentTime = formatter.date(from: s)
                if paymentTime == nil, let partial = fallback.date(from: s) {
                    var comps = Calendar.current.dateComponents([.month, .day, .hour, .minute], from: partial)
                    comps.year = currentYear
                    paymentTime = Calendar.current.date(from: comps)
                }
            }

            return AIExpenseDraft(
                amount: amount,
                isIncome: isIncome,
                category: category,
                note: note,
                paymentTime: paymentTime
            )
        }
    }

    // MARK: - Import-time batch classification

    /// 把一批 import 草稿（关键词字典没命中的那些）批量发给纯文本模型分类。
    ///
    /// 拆成 ≤30 条的小批量，TaskGroup 并行，避免一次性发几百条触发：
    /// (1) 输出 token 超过 max_tokens 被截断；(2) 60s 请求超时。
    ///
    /// `onBatch` 在每个 batch 拿到结果时同步回调（MainActor 上调用），
    /// 用来给 UI 实时刷"AI 推断中 N/M"。
    ///
    /// 错误策略：单 batch 失败不阻断其他 batch；只有"全部失败"才向上抛错。
    func classifyImports(
        _ items: [ClassifyItem],
        onBatch: (([UUID: ClassifyResult]) -> Void)? = nil
    ) async throws -> [UUID: ClassifyResult] {
        guard let apiKey = keyService.apiKey() else { throw AIError.noAPIKey }
        guard !items.isEmpty else { return [:] }

        let batchSize = 30
        let batches: [[ClassifyItem]] = stride(from: 0, to: items.count, by: batchSize).map {
            Array(items[$0..<min($0 + batchSize, items.count)])
        }

        var combined: [UUID: ClassifyResult] = [:]
        var anySuccess = false
        var lastError: Error?

        await withTaskGroup(of: Result<[UUID: ClassifyResult], Error>.self) { group in
            for batch in batches {
                group.addTask {
                    do {
                        return .success(try await self.classifyBatch(batch, apiKey: apiKey))
                    } catch {
                        return .failure(error)
                    }
                }
            }
            for await result in group {
                switch result {
                case .success(let dict):
                    anySuccess = true
                    combined.merge(dict) { _, new in new }
                    onBatch?(dict)
                case .failure(let err):
                    lastError = err
                }
            }
        }

        if !anySuccess, let err = lastError { throw err }
        return combined
    }

    /// 单批分类（发一次 HTTP）。
    private func classifyBatch(_ items: [ClassifyItem], apiKey: String) async throws -> [UUID: ClassifyResult] {
        let expenseRaws = ExpenseCategory.expenseCases.map { $0.rawValue }.joined(separator: ",")
        let incomeRaws = ExpenseCategory.incomeCases.map { $0.rawValue }.joined(separator: ",")
        let system = """
        你是账单分类 + 备注清理器。给每条交易输出 category 和清理后的 note。
        输入字段：id / counterparty(交易对方) / item(商品) / isIncome。

        【输出】只输出 JSON 数组，不要解释 / markdown / 前言：
        [{"id":"<原 id>","category":"<rawValue>","note":"<清理后备注，≤20 字>"}]

        【category 规则】
        - 支出类目：\(expenseRaws)
        - 收入类目：\(incomeRaws)
        - isIncome 与 category 维度需匹配；判断不出时：支出 → other，收入 → otherIncome

        【note 规则】优先级从高到低：
        1. 如果 item 里能识别真实商家名（典型平台模式："胖哥俩肉蟹煲-美团App-2508..."），用商家名（去掉所有 -XXXApp-数字串 / -订单号 / 数字尾巴等订单 ID）
        2. 如果 counterparty 是平台代收（"美团" / "美团平台商户" / "拼多多" / "京东" / "支付宝" 等），真实商家在 item 里
        3. 如果 counterparty 是真实商户名 / 人名，用 counterparty
        4. counterparty 无意义（如"扫二维码付款"），用 item 清理后内容
        5. 都没有有意义信息时返回空字符串 ""
        """

        let payload: [[String: Any]] = items.map { item in
            [
                "id": item.id.uuidString,
                "counterparty": item.counterparty,
                "item": item.item,
                "isIncome": item.isIncome
            ]
        }
        let userText = "请分类并清理：" + (String(data: try JSONSerialization.data(withJSONObject: payload), encoding: .utf8) ?? "[]")

        let body: [String: Any] = [
            "model": textModel,
            "max_tokens": 4096,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": userText]
            ]
        ]

        var request = URLRequest(url: URL(string: endpoint)!, timeoutInterval: 90)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIError.network(error.localizedDescription)
        }
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw AIError.network("HTTP \(http.statusCode) — \(msg.prefix(200))")
        }
        guard let decoded = try? JSONDecoder().decode(OpenAIResponse.self, from: data),
              let text = decoded.choices.first?.message.content else {
            throw AIError.parse("API 响应异常")
        }

        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```") {
            if let nl = cleaned.firstIndex(of: "\n") {
                cleaned = String(cleaned[cleaned.index(after: nl)...])
            }
            if cleaned.hasSuffix("```") { cleaned = String(cleaned.dropLast(3)) }
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let s = cleaned.firstIndex(of: "["),
              let e = cleaned.lastIndex(of: "]"),
              let json = String(cleaned[s...e]).data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: json) as? [[String: Any]] else {
            throw AIError.parse("AI 返回不是合法 JSON")
        }

        var out: [UUID: ClassifyResult] = [:]
        let inputIsIncome = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0.isIncome) })
        for entry in arr {
            guard let idStr = entry["id"] as? String, let id = UUID(uuidString: idStr) else { continue }
            let raw = entry["category"] as? String ?? ""
            guard var cat = ExpenseCategory(rawValue: raw) else { continue }
            let income = inputIsIncome[id] ?? false
            if income && !cat.isIncome { cat = .otherIncome }
            if !income && cat.isIncome { cat = .other }
            let note = (entry["note"] as? String)?.trimmingCharacters(in: .whitespaces)
            out[id] = ClassifyResult(category: cat, note: note?.isEmpty == false ? note : nil)
        }
        return out
    }

    struct ClassifyItem {
        let id: UUID
        let counterparty: String
        let item: String
        let isIncome: Bool
    }

    struct ClassifyResult {
        let category: ExpenseCategory
        /// AI 给出的清理后备注；nil 表示 AI 没建议（保留原 note）。
        let note: String?
    }
}
