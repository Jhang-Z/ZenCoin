---
name: Per-expense participants via 8-color slots
description: 在每笔 expense 上挂"参与人色位"属性，用 8 色固定调色板的 idx 集合表达"哪几个人一起出现"，无 Person 注册表、无 trip book、无身份概念。行末渲染 dot strip；tap strip 自动归桶进选择模式 + bar 同时显示总额与"我的份额"。
type: design
date: 2026-04-30
---

# 2026-04-30 · Per-expense Participants via Color Slots

迭代主题：把"AA 共担/分摊"的能力嵌进现有账本，**不引入任何身份模型**。设计反复收敛了 4 次：先做了 trip book → 觉得臃肿砍掉 → 提议全局 Person + 管理页 → 用户嫌重 → 最终落到「8 色固定调色板，色 idx 即匿名身份」。

## 1. Problem

> 一段时期我和 B 有 3 笔共同账单、和 C 有 2 笔、和 B+C 有 4 笔。
> 1) 在 row 上一眼分得出某笔属于哪个组合。
> 2) 能分别统计三个组合的均分摊销。

约束：
- 不要 person 管理页（用户原话："不需要臃肿的设计"）
- 不要给"人"起名字（"我不具体到对应的人"）
- 但要能"区分不同人"（同色跨账单 = 同一个人，靠用户大脑映射）

## 2. Decision

### 模型

`Expense.participantColors: [Int]`（升序、含 idx 0=自己），其它一切不变：
- 不再有 `Person` / `Member` @Model
- 不再有 `Book.kind` / `BookKind`
- `Expense.paidByMemberId` 移除
- `Expense.participantIds` 移除（被 `participantColors` 替换）

### 调色板（固定 8 色，跨主题不变）

```swift
enum ParticipantPalette {
    static let hexes = [
        "#C96442",  // 0 self  · terracotta
        "#5A8DAA",  // 1       · slate blue
        "#E8B14F",  // 2       · mustard
        "#79A06E",  // 3       · sage
        "#B86F94",  // 4       · mauve
        "#6F7BA8",  // 5       · indigo
        "#C58D5A",  // 6       · camel
        "#8C7B68",  // 7       · taupe
    ]
}
```

哲学：**位置即身份**。idx 0 永远是「你自己」；idx 1-7 是匿名"另外的人"，跨账单同色 = 同一个人，靠用户心智映射（"slate blue ≡ B、mustard ≡ C"）。

低饱和度 + 固定色，避开任何主题 accent 冲突，符合 DESIGN.md「声音很小」。

### UI

**录入页 / 详情页**：8 个圆形 chip，已选实心 / 未选 18% alpha。idx 0 chip 中央嵌一个白色小点提示「这是我」，且不可取消。

**Ledger row**（仅当 `participantColors.count >= 2` 时渲染）：
```
[餐饮] 胖哥俩肉蟹煲                    -¥160.00
       餐饮 · 19:25 · ●●●          ← 6pt 圆点 strip
```
- 1 人（仅自己）→ 不渲染，行外观完全不变
- ≥ 2 人 → 圆点按 idx 升序排，6pt diameter，3pt gap

**dot strip 是独立 hit area**：
- tap row body → 进详情（不变）
- long-press row body → 进选择模式 + 仅勾这 1 笔（不变）
- **tap row 末尾 dot strip → 进选择模式 + 自动勾选所有 `participantColors` 完全相同的笔**

技术上 strip 在 row 内部，但因为是独立的 contentShape + onTapGesture 子区域，与外层手势不冲突。DESIGN.md §9 的"row 上手势 ≤ 2 层"在这里做了一个小破例（strip 子区域算第三个 tap surface），换来零新 view 的归桶能力。

### Selection bar 增强

`SelectionSummaryBar` 已选笔的"总额"下方多一行 `我的份额 ¥XXX`，仅当 `myShare ≠ totalExpense` 时显示（避免冗余）。份额计算：
```
myShare = Σ (e.amount / max(1, e.participantColors.count))
                       for e in selected where !e.isIncome
```
关键点：**每笔单独除自己的人数再求和**，不是 `total / N`。这避免了变参与人数的均分陷阱。

## 3. Files

### 新增
- `ZenCoin/Features/Ledger/Models/ParticipantPalette.swift` — 8 色 + Color hex helper

### 改动
- `ZenCoin/Features/Ledger/Models/Expense.swift` — 加 `participantColors: [Int] = [0]`；删 `participantIds`、`paidByMemberId`
- `ZenCoin/Features/Ledger/ViewModels/EntryViewModel.swift` — `participantColors: Set<Int>` + `toggleParticipantColor(_:)`，self 不可移
- `ZenCoin/Features/Ledger/ViewModels/LedgerViewModel.swift` — `selectionTotals` 返回 `(expense, income, myShare)`
- `ZenCoin/Features/Ledger/Views/EntrySheet.swift` — chip 行
- `ZenCoin/Features/Ledger/Views/ExpenseDetailView.swift` — chip card
- `ZenCoin/Features/Ledger/Views/EntryRowView.swift` — dot strip + `onParticipantStripTap` 回调
- `ZenCoin/Features/Ledger/Views/LedgerView.swift` — `handleParticipantStripTap` 自动归桶
- `ZenCoin/Features/Ledger/Views/LedgerSelectionStore.swift` — `enter(withGroup:)`
- `ZenCoin/Features/Ledger/Views/SelectionSummaryBar.swift` — 「我的份额」行
- `ZenCoin/Features/Ledger/Views/RootView.swift` — 把 myShare 透传

### 删除（一并回滚 trip book 一整套）
- `ZenCoin/Features/Books/Models/Member.swift`
- `ZenCoin/Features/Books/Services/MemberDataService.swift`（连带 Services 目录）
- `ZenCoin/Features/Books/Views/BookCreationSheet.swift`
- `ZenCoin/Features/Books/Views/MemberManagementView.swift`
- `ZenCoin/Features/Books/Views/TripBookDetailView.swift`
- `ZenCoin/Features/Books/Views/SettlementView.swift`
- `Book.kindRaw` / `BookKind` enum
- `BookStore.create` 的 trip 参数 / `BookStore.delete` 的 member cleanup
- `ZenCoinApp.makeContainer` 里的 `Member.self`
- `BookSwitchSheet.onCreate` 旧 signature
- `BookManagementView` 的 trip-book 行 / `TripBookDetailView` NavigationLink
- `LedgerView` onCreate 调用
- `EntryViewModel` members / participantIds / isTripBook 分支
- `ExpenseDetailView` trip context 加载
- pbxproj 里 6 个 trip-book 文件 entry + Books/Services group

## 4. Decisions log

| 议题 | 选择 | 备选 / 为什么不选 |
| --- | --- | --- |
| 身份模型 | 无 ——「色位即身份」 | 全局 Person 注册表：用户嫌臃肿；trip book + Member：边界太刚性 |
| 调色板 | 8 色固定 hex，跨主题不变 | 跟主题走：person "色"在不同主题下不一致，破坏视觉记忆 |
| 自己的色位 | 永远 idx 0 = terracotta | 让用户选：每个用户 self 色不一致，不便记忆 |
| 行上视觉 | 6pt 圆点 strip | SF Symbol `person.fill`：形状重复增加视觉重量；avatar stack：尺寸过大 |
| 1 人时显示 | 不渲染 | 渲染 1 个圆点：增加视觉噪声，违"克制" |
| 归桶入口 | tap row 末尾 dot strip → 进 selection + 自动勾全组 | 新 PersonScopeSheet：1 个新 view；filter chip header：增加 row |
| 归桶范围 | "完全相同的 color set" 才归同组 | "包含某色"的 super-set：与"我和 B 单独"vs"我和 B+C"语义混淆 |
| 多份额数学 | 每笔除以自己的人数再求和 | 总额/N：变参与人数下完全错 |
| 选择 bar 份额行 | 仅当 ≠ 总支出时显示 | 总是显示：单人笔时跟总额重复，冗余 |

## 5. Open / next

- **支付宝账单导入**（仍未做）。
- **dot strip 跨账本聚合**：用户暂时不要 PersonScopeSheet，但之后真正想看"slate blue 全年累计"时可作为追加。
- **重导入策略**：当前是"externalId 查重 + skip"。
- **tap strip 与 row tap 冲突的真机验证**：dot strip 是独立 hit area，理论上不冲突，但小尺寸点击区域要在真机测一下命中率。
- **SwiftData 字段删除**：移除 `participantIds` / `paidByMemberId` 是 destructive schema 变更。开发期 `wipeStore()` 兜底；正式发布前需要明确 migration 策略，或这些字段从未在生产数据里存在过（迭代期间还没合 main，应该没有真实用户数据）。
