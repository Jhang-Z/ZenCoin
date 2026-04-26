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
}
