# ZenCoin · Design System

> 安静记账 · Quietly counting.
> 一份专为 ZenCoin 写的设计语言。所有改动都应能在这里找到依据。

---

## 1 · 哲学

| 原则 | 含义 |
| --- | --- |
| **克制优先** | 加东西之前先问「能不能不加」。不能回答就先不加。 |
| **一屏一主角** | 每一屏只有一个最该被看见的元素。其他全部退后。 |
| **功能让位于氛围** | 实现路径破坏「禅意」就重新设计，不要妥协。 |
| **中英共谋** | 结构标签用英文小写大写字母（IN / OUT / NOTE），内容与动作用中文。 |
| **声音很小** | 没有彩虹渐变、没有发光、没有抖动。变化用 0.22s easeInOut。 |

---

## 2 · 主题与色彩

三套主题预设，**结构相同**，仅替换 token 值。详见 [`ThemePresets.swift`](ZenCoin/Core/Theme/ThemePresets.swift)。

| Token | Claude（默认） | Cursor | Zapier |
| --- | --- | --- | --- |
| `bgPrimary` | `#F5F4ED` 羊皮纸 | `#F2F1ED` 暖奶油 | `#FFFEFB` 米白 |
| `bgSurface` | `#FAF9F5` | `#E6E5E0` | `#FFFDF9` |
| `accent` | `#C96442` 赤陶 | `#F54E00` 橙 | `#FF4F00` 烈橙 |
| `error` | `#B53333` | `#CF2D56` | `#CF2D56` |
| `fontDesign` | `.serif` | `.default` | `.default` |
| `tracking` | `0` | `-1.5` | `0` |
| `radiusLarge` | `24` | `999`（pill） | `20` |

**禁止**：自由选色、彩色背景渐变、阴影发光、玻璃磨砂（除非有强场景理由，但当前没有）。

---

## 3 · 字号

定义在 [`Typography.swift`](ZenCoin/Core/Theme/Typography.swift)，跟随主题的 `fontDesign`。

| Token | 用途 | 大小 / 字重 |
| --- | --- | --- |
| `display` | 月份净额 hero | 44 / medium |
| `title` | 月份标签 | 22 / medium |
| `heading` | 行标题、卡片标题、金额数字 | 17 / semibold |
| `body` | 正文、按钮 | 15 / regular |
| `caption` | 行副标题、说明文字 | 13 / regular |
| `micro` | 结构标签（IN / OUT / LEDGER） | 11 / medium，`tracking 0.6–1.2` |

**规则**：所有 ALL CAPS 英文标签必须使用 `micro` + tracking ≥ 0.6。汉字不加 letterspacing。

---

## 4 · 间距

| Token | 值 | 用途 |
| --- | --- | --- |
| 安全外边距 | `24pt` | 屏幕水平边距、section 内边距 |
| 行内邮票边距 | `16pt` | 卡片内边距 |
| 元素间距 | `12 / 14pt` | 行内元素间隔 |
| 段间距 | `24 / 32pt` | 不同 section 之间 |

底部 tab bar 之上的滚动内容应留出 `120-140pt` 的呼吸区，避免最后一行被浮动 + 按钮压住。

---

## 5 · 圆角

| Token | 用途 |
| --- | --- |
| `radiusSmall` | 输入框、按钮、行 chrome |
| `radiusMedium` | 卡片、模态、信息卡 |
| `radiusLarge` | hero card / 大型容器 |

不要混用主题外的圆角值。

---

## 6 · 组件

### 6.1 Row（账目行）
- 36pt 圆形图标 · 主标题 + 副标题（两行，主标题 lineLimit 1）· 右侧金额。
- 主标题 = 备注（fallback：分类名）。
- 副标题 = 分类名（fallback：时间）。
- 收入金额 `accent`，支出金额 `textPrimary`。
- 行的高度由内容决定，**不固定** —— 视觉重量由字号控制，不靠 padding 拉伸。

### 6.2 Card（信息卡）
- 单色 `bgSurface` 填充，`radiusMedium`，无边框无阴影。
- 多个内容用 1pt `separator` 横线分隔，**不**用空白分隔。

### 6.3 Bottom Bar
- 同时只能存在一种底部条：tabs 或 SelectionSummaryBar。切换用 0.22s easeInOut 淡入淡出。
- 浮动 `+`：56pt 圆，`accent` 填充，`-22` y-offset。**长按**触发 AI 识图。

### 6.4 Sheet
- `presentationBackground(theme.bgPrimary)`，不要使用系统默认浅灰。
- 头部对齐方式：左侧标签（micro caps），右侧关闭/完成按钮。

### 6.5 按钮

| 类型 | 样式 |
| --- | --- |
| Primary | `bgPrimary` 文字 on `accent` 背景，`radiusSmall` |
| Secondary | `textPrimary` 文字 on `bgSurface` 背景 |
| Tertiary / Cancel | `textSecondary` 文字 on `bgInput` 背景 |
| Destructive | `error` 文字 + `separator` 描边（无填充） |
| Icon-only Destructive | `error` 着色的 SF Symbol，仅出现在详情页 toolbar |

---

## 7 · 交互语言

### 7.1 删除（Destructive）

**原则**：删除是一个有意识的动作，必须可达且必须可撤销，但**不能干扰浏览**。

| 场景 | 操作 |
| --- | --- |
| 单条删除 | 进入详情页 → toolbar 右上角 trash 图标 → confirmationDialog |
| 批量删除 | 列表长按进入圈选 → 底部 SummaryBar → "删除" |
| 全部清空 | 设置 → 数据 → 清空所有记录 |

**禁止**：
- 列表行上**不要**出现常驻 trash 图标（破坏一行一主角原则）。
- 不使用 `swipeActions`（在 `LazyVStack/ScrollView` 里不可用，且非视觉化）。
- confirmationDialog 一律使用 `.destructive` role + 中文动作词（"删除" / "清空"）。

### 7.2 月份切换

| 操作 | 触发 |
| --- | --- |
| 跳到任意月份 | 点击月份标签 → MonthPickerSheet（年份步进 + 4×3 月份格） |
| 上 / 下个月 | header 区域**水平滑动**（≥ 60pt） |

**禁止**：左右箭头按钮（已弃用 — 浪费横向空间，且和滑动冗余）。

### 7.3 多选

- 长按任意行进入圈选模式，长按手感用 `UIImpactFeedbackGenerator(.medium)`。
- 进入圈选时：tab bar 让位 → SelectionSummaryBar 升起。
- 单击 = toggle，最后一项被取消时自动退出圈选。

### 7.4 AI 识图

三个对等触发口：
1. 录入页 header 的 `sparkles AI` pill。
2. 浮动 `+` **长按**（0.5s）。
3. URL Scheme `zencoin://ai-expense`（给系统轻点背面快捷指令用）。

成功 → 把识别结果直接套到当前录入草稿；失败 → header 下方红色细 banner，可手动关闭。

### 7.5 反馈

- 选择类操作 `UISelectionFeedbackGenerator()`。
- 进入圈选 / 长按 `+` `UIImpactFeedbackGenerator(.medium)` 或 `.heavy`。
- 不要使用通知音、不要全屏 toast。

---

## 8 · 中英混排规则

| 出现位置 | 语言 |
| --- | --- |
| 屏幕标题 | 中文（设置 / 主题 / 账目详情） |
| 结构标签（micro caps） | 英文（IN / OUT / BAL / LEDGER / INSIGHT / EXPENSE / NOTE / CATEGORY / TIME / SELECTED） |
| Section 标题 | 双语 `APPEARANCE / 外观` |
| 按钮文字 | 中文（保存 / 删除 / 取消 / 完成） |
| 分类、备注、对话框文字 | 中文 |
| 品牌名 | 英文（ZenCoin） |

英文标签一律 `tracking ≥ 0.6`，避免与中文混排时显得局促。

---

## 9 · 反模式（红线）

| 反模式 | 为什么 |
| --- | --- |
| 列表行 trash 图标 | 破坏 zen，每行平均视觉重量被破坏 |
| 上下箭头切月份 | 与点击 + 滑动重复，浪费 header 宽度 |
| `.swipeActions` | 在 ScrollView/LazyVStack 内静默失效 |
| 彩色按钮 | 多颜色 = 多焦点，违反一屏一主角 |
| 阴影/glow | "AI 感"，且与扁平 token 冲突 |
| 加载占位 spinner 全屏 | 用 inline progress 或 banner |
| 多语言提示文案使用拼音 / 翻译腔 | 中文要自然口语 |
| 在 row 上做超过两层嵌套手势 | 长按 + tap 是上限 |

---

## 10 · 参考

- VoltAgent — *awesome-design-md*：本文档结构上的参考。
- Anthropic Claude marketing：parchment + serif + 赤陶 accent。
- Cursor.com：warm cream + compressed sans + 烈橙。
- Zapier.com：cream + border-forward sections。

---

## 修订

| 日期 | 内容 |
| --- | --- |
| 2026-04-26 | 初版。删除收编为「详情页 icon + 圈选 batch」；移除月份左右箭头；AI 三触发口落定。 |
