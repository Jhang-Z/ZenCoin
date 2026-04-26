# ZenCoin · Design System

> **安静记账 · Quietly counting.**
> A zen-minimal iOS bookkeeping app — three taps to record, one glance to know.

This design system distills ZenCoin's in-house design language ([`DESIGN.md`](https://github.com/Jhang-Z/ZenCoin/blob/main/DESIGN.md)) into reusable tokens, components, and reference UI. It is theme-aware: four presets (Claude / Cursor / Zapier / ElevenLabs) share an identical structure and only swap token values.

---

## Sources

This system was built from:

- **Codebase:** [`Jhang-Z/ZenCoin`](https://github.com/Jhang-Z/ZenCoin) (Swift / SwiftUI / SwiftData, iOS 17+)
- **In-house spec:** [`DESIGN.md`](https://github.com/Jhang-Z/ZenCoin/blob/main/DESIGN.md) — the philosophy + anti-patterns doc
- **Theme presets:** `ZenCoin/Core/Theme/ThemePresets.swift`
- **Type ramp:** `ZenCoin/Core/Theme/Typography.swift`
- **Categories + iconography:** `ZenCoin/Features/Ledger/Models/ExpenseCategory.swift`
- **Reference screens:** `RootView`, `LedgerView`, `EntrySheet`, `InsightView`

This skill ships the brand assets, design tokens, and reference UI for any future
ZenCoin work — production code review, mocks, slides, marketing pages.

---

## What is ZenCoin?

A SwiftUI iOS bookkeeping app that prizes **quiet attention** over information density. Three opinionated mechanics define it:

1. **Three-tap entry** — floating `+` → category → save. A custom amount keypad supports `+ − × ÷` expressions with live evaluation.
2. **AI screenshot bookkeeping** — a Shortcuts + Back-Tap path: see a payment screenshot → double-tap the back of the phone → AppIntent runs in the background, calls Aliyun Bailian `qwen-vl-max-latest`, writes the entry silently. The app never comes to the foreground.
3. **Donut + heatmap insight** — hand-drawn ring chart with side-stacked labels and L-leader lines, paired with a month/year heatmap calendar.

Plus: multi-book support (default + scenario books like 旅行 / 装修), four themes, and zero notifications.

---

## Content fundamentals

ZenCoin's voice is **bilingual by rule, not by accident**. There's a clear pattern:

| Where | Language | Example |
|---|---|---|
| Brand name | English | `ZenCoin` |
| Structural caps labels | English (uppercase, tracking ≥ 0.6) | `IN` / `OUT` / `BAL` / `LEDGER` / `INSIGHT` / `EXPENSE` / `NOTE` / `CATEGORY` / `TIME` / `SELECTED` |
| Section headers | Bilingual pair | `APPEARANCE / 外观` · `EXPENSE / 支出` |
| Screen titles | Chinese | 设置 · 主题 · 账目详情 |
| Buttons / actions | Chinese | 保存 · 删除 · 取消 · 完成 |
| Categories, notes, dialogs | Chinese | 餐饮 · 交通 · 工资 |

**Tone:**
- Quiet, declarative, never enthusiastic. No exclamation points.
- Confirmations are short factual statements: `本月还没有记录` · `记账成功 · 餐饮 -¥38`.
- Destructive copy is plain: `删除` (not `永久删除` or `确定要删除？`).
- Errors are inline banners, never modal toasts. Tone: `识别失败，请手动输入`.
- No emoji. No nagging notifications. No marketing copy in the app.
- "拼音 / 翻译腔" (pinyin or translationese) is explicitly forbidden — Chinese must read natural and conversational.

**Vibe one-liners** the brand uses for itself:
- 安静记账 / Quietly counting.
- 三下记账，一眼了然.
- Made with quiet attention.

---

## Visual foundations

### Philosophy in five lines (from `DESIGN.md`)

1. **克制优先** — before adding anything, ask if it can be left out.
2. **一屏一主角** — one element per screen earns the spotlight; everything else recedes.
3. **功能让位于氛围** — if the implementation breaks the zen, redesign it.
4. **中英共谋** — English caps for structure, Chinese for content/actions.
5. **声音很小** — no rainbow gradients, no glow, no shake. Transitions are 0.22s easeInOut.

### Color

Four theme presets with **identical token structure** (see `colors_and_type.css`). Each carries:
- `bgPrimary` / `bgSurface` / `bgInput` (three surface tones — never invent more)
- `textPrimary` / `textSecondary`
- `accent` / `accentMuted` (15% / 12% / 10% / 18% per theme)
- `separator` / `error`

**Defaults — Claude theme:**
- Parchment background `#F5F4ED`, surface `#FAF9F5`
- Terracotta accent `#C96442` (15% muted)
- Text `#141413` / `#5E5D59`
- Hairline separator `#F0EEE6` (1px, never thicker)

**Forbidden:** free color picking, color gradients on backgrounds, shadows / glow, frosted glass.

### Type

System fonts only — `New York` (serif design) for the Claude theme; `SF Pro` (default design) elsewhere. The brand fonts (Anthropic Serif, CursorGothic, Degular Display) are not redistributable, so the spec calls for *system designs + tracking* as an approximation.

| Token | Size · Weight | Use |
|---|---|---|
| `display` | 44 / 500 | Month net hero, big numbers |
| `title` | 22 / 500 | Section / month label |
| `heading` | 17 / 500 | Row / card titles — **CJK-text-heavy** content |
| `headingNumeric` | 17 / 500 | Amount numerals, IN/OUT/BAL — **Latin-numeric** content |
| `body` | 15 / 400 | Body, button labels |
| `caption` | 13 / 400 | Row subtitle, helper text |
| `micro` | 11 / 500 · tracking ≥ 0.06em | `IN / OUT / LEDGER` etc. |

**Rule:** All-caps English labels must use `micro` + tracking ≥ 0.6. Chinese characters never get letter-spacing.

#### iOS-specific gotcha — Claude theme + 汉字

iOS `Font.system(design: .serif)` 在汉字上会**回退到 PingFang SC**（无衬线），不是 New York 衬线。这等于在 Claude 主题下，CJK 文字默认根本拿不到衬线感。

约定：
- **CJK 文本主导**（行标题 / 弹窗标题 / 描述等）→ 用 `heading` token，
  iOS 端实现为 `Font.custom("STSongti-SC-Regular", size: 17)`。Songti SC 是 iOS 自带宋体，
  跟 New York 是中英衬线对。
- **数字 / 金额主导**（IN/OUT/BAL 数字、行金额、详情金额等）→ 用 `headingNumeric` token，
  iOS 端实现为 `Font.system(.serif)`。Latin 数字字形拿到的是 New York，跟 `display`
  hero 同字风。
- **千万别让金额走 `heading`**：Songti 的 Latin 字形偏中式衬线，跟 New York Medium 放一起会
  视觉上像两个字体。这是踩过的坑，code review 时盯紧。
- 其他三个主题（Cursor / Zapier / ElevenLabs）的 fontDesign 都是 `.default`，`heading` 与
  `headingNumeric` 等价 — 这套区分只对 Claude (serif) 主题生效。

> **Font substitution flagged:** ZenCoin uses iOS system `New York` (serif) and `SF Pro`. We render with the same system stack; if you build outside Apple platforms, web fallbacks `Iowan Old Style` / `Charter` / `Inter` are used. **Ask the user for licensed brand fonts if the design system needs to render off-iOS.**

### Spacing

A strict 24 / 16 / 12-14 / 8 grid — full table in `colors_and_type.css`.

- `24pt` — screen horizontal margin, section inner padding
- `16pt` — card inner padding
- `12 / 14pt` — element gaps
- `24 / 32pt` — between sections
- Floating tab bar reserves `120-140pt` of bottom breathing room above scroll content.

### Shape

Three corner radii per theme, no others permitted:

| Theme | small | medium | large |
|---|---|---|---|
| Claude | 8 | 12 | 24 |
| Cursor | 8 | 8 | 999 (pill) |
| Zapier | 4 | 8 | 20 |
| ElevenLabs | 8 | 12 | 20 |

### Surfaces, depth, motion

- **No shadows. No glow. No frosted glass.** Cards are flat surface fills; structure comes from `separator` hairlines (1px).
- **Borders:** rare. Only the destructive button uses a `separator` border (no fill). Book chip uses a 1px capsule stroke.
- **Animation:** `0.22s easeInOut` for everything. Bottom-bar swap is fade. Sheets default. No bounces, no springs longer than the system default.
- **Hover/press (iOS):** `UISelectionFeedbackGenerator` for taps; `UIImpactFeedbackGenerator(.medium/.heavy)` for long-press / commits. Visual press = nothing extra; the haptic carries the weight.
- **Transparency / blur:** none. (`accentMuted` uses alpha but is the only place colors stack.)
- **Imagery:** no photography in product. No illustration. The brand is text + icon + paper.
- **Layout fixed elements:** bottom tab bar (or `SelectionSummaryBar`, never both). Floating `+` button (56pt circle, `accent` fill, `-22pt` y-offset). Long-press the `+` triggers AI capture.

### Components in one breath

- **Row** — 36pt circular monochrome icon · two-line title/subtitle · right-aligned amount. Income amount uses `accent`; expense uses `textPrimary`.
- **Card** — `bgSurface` fill, `radiusMedium`, no border, no shadow. Internal stacks separated by 1pt `separator`, never whitespace.
- **Sheet** — `presentationBackground(theme.bgPrimary)`. Header is left caps-label + right close button.
- **Buttons** — Primary (`accent` fill, `bgPrimary` text) · Secondary (`bgSurface` fill, `textPrimary`) · Tertiary/Cancel (`bgInput` fill, `textSecondary`) · Destructive (no fill, `error` text + `separator` stroke).
- **Bottom bar** — two label tabs (`LEDGER` / `INSIGHT` micro-caps) flanking the floating `+`. Selected tab gets `accent` 16×1pt underline rule.

---

## Iconography

**Sole icon system: SF Symbols.** Monochrome by design, no color variants, no filled/outlined mixing within one cluster.

Real symbols used in the codebase (extracted from `ExpenseCategory.swift` + view files):

| Domain | Symbols |
|---|---|
| Categories — expense | `fork.knife` · `tram.fill` · `bag` · `cart` · `music.note` · `house` · `cross.case` · `tshirt` · `antenna.radiowaves.left.and.right` · `airplane` · `book` · `circle.grid.2x2` |
| Categories — income | `banknote` · `gift` · `chart.line.uptrend.xyaxis` · `arrow.down.circle` |
| Chrome | `plus` · `xmark` · `chevron.down` · `gearshape` · `pencil` · `list.bullet` · `chart.bar` · `checkmark.circle.fill` · `circle` · `sparkles` · `trash` |

**Rules:**
- Always `theme.accent` (when on a row icon) or `theme.textPrimary/Secondary` (when chrome). Never multi-color.
- No emoji anywhere in the product. Emoji are not part of the brand.
- No Unicode symbols as icons. (The keypad uses `÷ × − +` typographically — those are *operators*, not icons.)
- No custom SVG iconography. If SF Symbols doesn't have it, redesign the feature so it does.

**Web substitution.** Outside Apple platforms, SF Symbols can't ship. We use **[Lucide](https://lucide.dev/)** as the closest match (same stroke weight, same monochrome rule). Mappings live in `assets/sf-to-lucide-map.md`. **Flagged substitution — when shipping native iOS, always switch back to the real `Image(systemName:)` calls.**

---

## Index — what's in this folder

| Path | What |
|---|---|
| `README.md` | This file |
| `SKILL.md` | Cross-compatible Agent Skills frontmatter for use in Claude Code |
| `colors_and_type.css` | Single source of truth — all theme tokens + type ramp + base components |
| `assets/` | Logos, app icon options, lucide CDN map |
| `preview/` | Design-System-tab cards (type, color, spacing, components, brand) |
| `ui_kits/app/` | iOS UI kit — JSX components + interactive index demo |
| `ui_kits/app/README.md` | Kit-specific notes |

### Caveats

- **No font files** — ZenCoin uses iOS system fonts (`New York`, `SF Pro`) which are not redistributable. Web previews use the same names with `Iowan Old Style` / `Inter` fallbacks. Ask the user to provide licensed alternates if rendering on non-Apple platforms.
- **Icons are Lucide-substituted on web.** SF Symbols aren't shippable; mappings are 1:1 by meaning + stroke style.
- The `docs/superpowers/specs/2026-04-26-zencoin-design.md` file in the repo was not pulled — the codebase + DESIGN.md were sufficient.
