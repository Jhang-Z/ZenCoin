---
name: Bill import/export + AI batch classify + insight bills sheet
description: 微信支付账单（xlsx/csv）一键导入、ZenCoin CSV 导出、AI 批量分类+备注清理、Insight 弹窗看当期账单、Ledger 日合计、设置页改回弹窗手势。本轮迭代的设计存档，方便回溯。
type: design
date: 2026-04-29
---

# 2026-04-29 · Import/Export + AI Batch + Insight Bills Sheet

迭代主题：把 ZenCoin 从「手动一笔笔录」扩展到「能吞下别家账单」，同时让 Insight 从只看图变成可以下钻看明细。AI 从单张截图识别延伸到批量分类 + 备注清理。

## 1. Background

之前 ZenCoin 只能手敲 / iOS 截图 → AI 单笔写入。新需求：
- 用户已有微信几个月的账单想一次性导入
- Insight 圆盘 + 热图只能看不能戳
- Ledger 列表上想一眼看到每天花了多少
- AI 该不该接管"语义分类"这种需要联想的任务

这一轮把这四件事一起处理掉。

## 2. What landed

### 2.1 Bill import — WeChat Pay (xlsx + csv)

**入口**：设置 → 数据 → 导入微信账单

**Pipeline**：
```
file picker → sniff PK\x03\x04 → xlsx 走 XLSXReader, 否则走 CSVUtilities
            → WeChatPayParser.parse(rows: [[String]]) 
            → ImportPreviewSheet（行可勾选 / 长按改类别）
            → ExpenseDataService.insertMany（externalId 查重幂等）
```

**关键决定**：
- **不引外部 zip / xlsx 依赖**。`XLSXReader.swift` 自包含 ~250 行：MinimalZip（搜 EOCD → 走中央目录 → Apple `Compression` 框架做 raw DEFLATE）+ XMLParser SAX 解 sharedStrings + sheet1。
- **Excel 序列日期处理**：xlsx 把 `2026-03-27 10:28:33` 存成 `46108.43649305555`。`parseDate` 加 fallback：字符串解析失败时若数值在 25000-100000 范围（覆盖 1968-2173），就当 days since 1899-12-30 处理。
- **格式 sniff**：前 4 字节 `PK\x03\x04` 即视为 zip 容器走 xlsx；否则当 csv 解码（UTF-8 BOM / GB18030 双解）。
- **微信特征校验**：前 20 行任一 cell 含「微信支付账单」才认。
- **过滤策略（用户拍板：策略 i）**：
  - **保留**：`已全额退款` / `已部分退款` 行（既保留原始支付，也保留对应退款行，反映真实流水）
  - **跳过**：`收/支 != "收入" && != "支出"`（中性交易：充值 / 提现 / 信用卡还款 / 零钱通存取）
  - **跳过**：`已撤销 / 失败 / 退款中`（真正没发生）
- **去重**：`Expense.externalId: String?` 字段（微信交易单号），导入前 `existingExternalIds()` 查重，重复 skip。Optional 字段 → SwiftData 自动 migration，旧库无感。

### 2.2 Note compose — 真实商家 + 订单号清洗

微信账单里「交易对方」并不可靠：可能是真实商户（"星巴克"），也可能是平台代收实体（"美团" / "美团平台商户"），后者真实商家在「商品」里。

**规则（按优先级）**：
1. `item` 末尾能剥出订单号 tail → 用剥后的 item（强信号）
2. `cp` 显式标注「平台商户」→ 用 cleaned item
3. `cp` 非空 → 用 cp
4. fallback → cleaned item

**订单号 tail regex**（保守剥，0 或 1 段）：
```
(?:-[^-]+)?-\d{10,}$
```
- 命中：`-美团外卖App-25082511...` / `-美团App-25082811...` / `-26032611...`
- 不命中：`12306消费` / `宁波地铁-二维码单程票` / `径河-汉口火车站`

故意收敛到 ≤1 段，避免 `门票-上海某园（团购店）-数字` 被切到只剩 `门票`。

### 2.3 AI batch classify + note polish

**何时调**：parser 落到 `.other / .otherIncome` 占位的行（关键词字典 miss）。命中字典的行不调 AI，零 token 浪费。

**Service 接口**：`ExpenseAIService.classifyImports([ClassifyItem]) -> [UUID: ClassifyResult]`
- `ClassifyItem(id, counterparty, item, isIncome)`
- `ClassifyResult(category, note?)`
- 用 `qwen-max-latest`（纯文本，比 vl-max 快/便宜 ~10×）
- 复用现有 `BailianKeyService`，不引新 key

**性能与稳定性**：
- 批量大小 30 / 批
- TaskGroup 并行（n 批同时发，受 URLSession 默认并发限制）
- 单批失败不阻断其他批；只有"全军覆没"才向上抛错
- `max_tokens: 4096`，`timeoutInterval: 90s`
- 渐进 onBatch 回调：每批返回立即应用到 drafts，header banner 实时刷 `N/M`

**Prompt 形态**：让 AI 同时返回 category + cleaned note。规则在 system prompt 里，识别真实商家、剥订单尾巴、平台代收时商品才是真实商家。

### 2.4 Insight — BillsSheet（日 / 月）

**交互**：
- 月模式下点日期格 → 弹 `BillsSheet(period: .day(date))`，显示当天明细
- 年模式下点月份格 → 弹 `BillsSheet(period: .month(year, month))`，显示当月明细，按日 group

**头部样式（DESIGN.md §6.4）**：
- 左 micro caps：`DAILY / 当日` 或 `MONTHLY / 当月`
- title 字号显示日期 / 月份
- 第三行：`n 笔 · ¥XXX` micro

**关闭逻辑**：去掉了"完成"按钮，仅靠系统 `presentationDragIndicator(.visible)` 那条小横线 grabber 和下拉手势关闭，与 app 其他 sheet 一致。

### 2.5 Ledger day total

每个日期分组 header 右侧拼一段：`4 月 28 日 · 星期二 · ¥47.60`。
- 沿用日期格式里已有的 `·` middle-dot 作为分隔符（不引入新视觉元素）
- micro 字号 + tracking 0.6 + textSecondary，monospacedDigit
- 当天没花费时该段不显示，保持克制

### 2.6 Settings 改用 sheet grabber

设置页原来 toolbar 上有个"完成"按钮 dismiss。改成：
- 删除 toolbar item
- 加 `presentationDragIndicator(.visible)`
- 仅靠下拉关闭

跟 BillsSheet / ImportPreviewSheet / BookSwitchSheet 等所有 sheet 行为一致。

## 3. Files

### 新增
- `ZenCoin/Features/Ledger/Services/Import/CSVUtilities.swift`
- `ZenCoin/Features/Ledger/Services/Import/XLSXReader.swift`
- `ZenCoin/Features/Ledger/Services/Import/WeChatPayParser.swift`
- `ZenCoin/Features/Ledger/Services/Import/CategoryGuesser.swift`
- `ZenCoin/Features/Ledger/Services/Import/ExpenseExporter.swift`
- `ZenCoin/Features/Settings/Views/ImportPreviewSheet.swift`
- `ZenCoin/Features/Insight/Views/BillsSheet.swift`

### 改动
- `ZenCoin/Features/Ledger/Models/Expense.swift` — `externalId: String?`
- `ZenCoin/Features/Ledger/Services/ExpenseDataService.swift` — `existingExternalIds() / insertMany / fetchAll`
- `ZenCoin/Features/AI/Services/ExpenseAIService.swift` — `classifyImports / classifyBatch / ClassifyItem / ClassifyResult` + `textModel = qwen-max-latest`
- `ZenCoin/Features/Insight/ViewModels/InsightViewModel.swift` — `entries(inMonth:)`
- `ZenCoin/Features/Insight/Views/InsightView.swift` — `pickedPeriod` 统一 dispatch 月/年
- `ZenCoin/Features/Insight/Views/CalendarHeatmapView.swift` — `onPickMonth: ((Int) -> Void)?`
- `ZenCoin/Features/Ledger/Views/LedgerView.swift` — day total in dayHeader
- `ZenCoin/Features/Ledger/ViewModels/LedgerViewModel.swift` — group items 透传给 dayHeader
- `ZenCoin/Features/Settings/Views/SettingsView.swift` — fileImporter / ShareLink / DATA section 加导入导出行；toolbar 删 "完成" + 加 dragIndicator

## 4. Decisions log

| 议题 | 选择 | 备选 / 为什么不选 |
| --- | --- | --- |
| xlsx 解析 | 自包含 MinimalZip + XMLParser | 引 ZIPFoundation：多一个 dep，不值 |
| AI 范围 | 仅未命中行（字典 miss） | 全量扔 AI：~22 batch × 12s，浪费 |
| AI 模型 | `qwen-max-latest`（纯文本） | `qwen-vl-max-latest`：贵 5-10×，无图无意义 |
| 已退款行 | 全部保留（策略 i） | 跳过：丢失"曾经付了又退"流水 |
| 订单号 regex 贪婪度 | 0 或 1 段 (`?`) | `*` 多段：会切掉合法的中间段如"团购店" |
| 日期落到行右 | 中点分隔 (`·`)，与日期内部分隔符复用 | 加竖线 / 加 OUT 标签：增加视觉元素 |
| 设置页关闭手势 | 系统 dragIndicator | toolbar "完成"：与其他 sheet 不一致 |

## 5. Open / next

- **AA 旅行账本（下一轮）**：单付款人 + 按笔指定参与人 + 平均分 + 极简结算视图。已与用户对齐方向。
- **支付宝 adapter**：schema 已知，照 WeChatPayParser 抄一份；放 v2。
- **重导入策略**：当前是"externalId 查重 + skip"，未来可能要"覆盖 / 合并"。
- **AI 进度细化**：当前 banner 只显示 `c/t`，没显示哪些行已落地；后续可考虑列表里行内 shimmer 标识刚被 AI 改过的行。
