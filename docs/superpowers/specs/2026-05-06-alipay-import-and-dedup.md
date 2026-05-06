---
name: Alipay import + AI screenshot dedup + heatmap currency
description: 支付宝账单 CSV 导入、AI 截图去重（图片哈希 + 内容）、热图金额补货币符号。本轮迭代的设计存档。
type: design
date: 2026-05-06
---

# 2026-05-06 · Alipay Import + AI Screenshot Dedup + Heatmap Currency

## 1. Background

上一轮（2026-04-29）已实现微信支付账单导入。本轮扩展两个方向：
1. 补全支付宝账单导入（路线图已标注 TODO）
2. 解决 AI 截图记账的重复记录问题（用户反馈：手抖重复截图会多记一笔）
3. 小修：Insight 热图格子内金额缺货币符号

## 2. What landed

### 2.1 支付宝账单导入 — AliPayParser

**入口**：设置 → 数据 → 导入支付宝账单

**文件结构**（官方 CSV 导出格式）：
```
前若干行 metadata（账户信息 / 起止时间 / 收支统计）
一行分隔线（含「支付宝（中国）网络技术有限公司」）
表头：交易时间,交易分类,交易对方,对方账号,商品说明,收/支,金额,收/付款方式,交易状态,交易订单号,商家订单号,备注
正文逐行
```

**Pipeline**：
```
file picker（单 .fileImporter）→ GB18030/UTF-8 解码
    → AliPayParser.parse(data)
    → ImportPreviewSheet（共用微信导入的预览 sheet）
    → ExpenseDataService.insertMany
```

**关键实现决定**：

**编码**：支付宝官方 CSV 导出为 GB18030。`CSVUtilities.decode()` 已支持 GB18030 fallback，无需额外处理。

**特征校验**：前 30 行任一 cell 含「支付宝」即认为是支付宝账单；否则抛 `.notAlipay`。

**表头定位**：遍历行，找同时含「交易时间」和「交易状态」的行作为 header，兜底处理文件头 metadata 行数不定的情况。

**列名精确匹配（iOS locale 关键 bug 修复）**：
- 问题：iOS 某些 locale 下 `"交易时间".contains("金额")` 返回 `true`，导致 `col.amount` 被定位到 0（时间列）而非 6（金额列），所有 `parseAmount("2026-02-28 19:04:22")` 返回 nil，所有行被标为 malformed skip。
- 诊断方法：在 `parse()` 末尾加 `throw NSError` 抛出 `DIAG cols[t=0 d=5 a=0 s=8]` 定位。
- 修复：`ColumnIndex.find()` 优先精确匹配（`==`），命中后直接返回，不走 `contains`：
  ```swift
  private static func find(_ header: [String], _ keyword: String) -> Int {
      if let i = header.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == keyword }) {
          return i
      }
      return header.firstIndex(where: { $0.contains(keyword) }) ?? -1
  }
  ```

**过滤策略**：
- 保留：`收/支 == "收入"` 或 `"支出"`
- 跳过（`.nonAccounting`）：余额宝收益、内部转账等 `收/支` 为 `"/"` 或其他非明确方向的行
- 跳过（`.refunded`）：`交易状态 == "交易关闭"` / 含「失败」/ `"等待买家付款"`

**note 组合策略**：支付宝「交易对方」字段比微信可靠（通常是真实商户名）。
- `counterparty` 非空且非「/」→ 直接用
- 否则 fallback 到「商品说明」

**共用类型**：`BillSkipped` 从 `WeChatPayParser` 的嵌套 `Skipped` 提取为顶层 struct，两个 parser 共用。`WeChatPayParser` 内保留 `typealias Skipped = BillSkipped` 向后兼容。

**单 fileImporter 路由**：原本准备加第二个 `.fileImporter`，但 SwiftUI 同一视图多个 `.fileImporter` modifier 会互相覆盖（只有最后一个响应）。解决方案：
```swift
private enum ImportSource { case wechat, alipay }
@State private var showingImporter = false
@State private var pendingImportSource: ImportSource = .wechat
// 按钮只改 pendingImportSource + showingImporter = true
// 单个 .fileImporter 根据 pendingImportSource switch 路由
```

### 2.2 AI 截图去重 — 双层防护

**背景**：用户反馈重复截图会多记。

**方案选择过程**：
- 内容去重（同金额 + 同备注 + 5 分钟窗口）→ 误杀：同店同金额短时间内买两次会被跳过
- 最终：图片哈希（第一道）+ 支付时间内容去重（第二道），两层组合

**第一道：图片哈希**（`isDuplicateScreenshot`）
- 对 `screenshot.data` 做 SHA-256（`CryptoKit`），与 `UserDefaults` 存的上次哈希 + 时间戳比较
- 10 分钟内相同 → 直接返回「已跳过：与上次截图相同」，**不调 AI**（节省 token）
- 覆盖场景：同一张截图被快捷指令触发两次

**第二道：内容去重**（`isDuplicateExpense`）
- 调完 AI 后、插入前逐笔检查
- 条件：同账本 + 同金额 + `paymentTime` 落在同一分钟（精确到分钟匹配）
- 依据：AI 从收据截图识别的 `paymentTime` 精确到分钟；同一张收据不管截几次，识别出的时间永远相同；而真正买了两次，收据时间不同
- 覆盖场景：付款页 + 成功页两张不同截图识别出同一笔

**误杀分析**：
- 同店同金额买两次 → 两张不同截图，第一道哈希不同；两笔 `paymentTime` 不同（收据时间不同），第二道不触发 ✅
- 同一张截图触发两次 → 第一道哈希命中，直接拦截 ✅

**去重后提示语**：
```
全部重复 → "已跳过：账单已记录过"
部分重复 → "记账成功 · 餐饮 -¥38（跳过重复 1 笔）"
全部正常 → "记账成功 · 餐饮 -¥38"
```

### 2.3 热图金额补货币符号

`CalendarHeatmapView.shortAmount()` 补 `CurrencyFormatter.symbol.rawValue` 前缀，与 Ledger / Insight 其他数字显示保持一致。

## 3. Files

### 新增
- `ZenCoin/Features/Ledger/Services/Import/AliPayParser.swift`

### 改动
- `ZenCoin/Features/AI/Intent/AddExpenseFromScreenshot.swift` — `import CryptoKit`；`isDuplicateScreenshot` + `isDuplicateExpense` 双重去重
- `ZenCoin/Features/Ledger/Services/Import/WeChatPayParser.swift` — `BillSkipped` 提取为顶层；`Result` 加 `source: ImportDraft.Source`；`ImportError` 加 `.notAlipay`
- `ZenCoin/Features/Settings/Views/ImportPreviewSheet.swift` — header title 按 `source` 区分「支付宝账单 / 微信支付账单」
- `ZenCoin/Features/Settings/Views/SettingsView.swift` — 单 `fileImporter` + `ImportSource` enum 路由；`handleAlipayImporterResult`；移除 CURRENCY section
- `ZenCoin/Features/Insight/Views/CalendarHeatmapView.swift` — `shortAmount` 加货币符号

## 4. Decisions log

| 议题 | 选择 | 备选 / 为什么不选 |
| --- | --- | --- |
| 列名匹配策略 | 精确 `==` 优先，`contains` fallback | 纯 `contains`：iOS locale bug 导致误匹配 |
| 多 fileImporter | 单实例 + enum 路由 | 两个 modifier：SwiftUI bug，后者覆盖前者 |
| 去重策略 | 图片哈希 + 支付时间内容去重 | 纯内容去重（金额+备注+5分钟）：误杀同店短时两次购买 |
| 内容去重时间粒度 | 分钟（paymentTime 精确到分） | 秒：AI 返回格式本身只精确到分，没意义 |
| 支付宝 note 策略 | counterparty 优先（比微信可靠） | item 优先：支付宝 counterparty 通常直接是商户名 |

## 5. Open / next

- **重导入策略**：当前 externalId 查重仅 skip，未来可能要「覆盖 / 合并」选项
- **Apple Pay Wallet Transaction 自动记账**（iOS 17+）
- **iCloud 同步 CloudKit sync**
