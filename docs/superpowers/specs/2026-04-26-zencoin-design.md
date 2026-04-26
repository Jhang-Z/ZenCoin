---
name: ZenCoin design
description: Standalone iOS expense-tracking app distilled from FlashNotes' Expense feature, with a zen/minimal language and Claude / Cursor / Zapier theme presets sourced from awesome-design-md.
type: design
date: 2026-04-26
---

# ZenCoin — Design Spec

A focused, single-purpose 记账 (bookkeeping) app extracted from FlashNotes. Quiet. Slow. One thing at a time.

## 1. Position

- **Pulled from**: FlashNotes/Features/Expense (Swift / SwiftData / iOS 17+).
- **Cut from scope**: AI screenshot ingestion, Bailian/Volcano APIs, URL scheme/shortcut installer, screenshot attachments. ZenCoin is keystroke‑only: amount + category + optional note.
- **Kept**: Expense + Income, monthly fetch, simplified categories, theme system (rebuilt, not copied).
- **One sentence**: "Three taps to record, one glance to know — no charts, no streaks, no nags."

## 2. Subtraction (what we are *not* building)

The point of this app is what's missing. The following are deliberately omitted; do not add them later without re‑opening this spec:

- No AI / OCR / screenshot import.
- No login, no sync, no cloud — local SwiftData only.
- No goals, budgets, streaks, badges, notifications.
- No charts beyond a single horizontal category bar.
- No multi‑currency. One currency, configurable in Settings (default ¥).
- No tags. Categories only.

## 3. Information architecture

A bottom tab bar with **two** tabs only — `Ledger` and `Insight`. The "+" entry is a center‑floating action button overlaid on both tabs (Apple‑style transient sheet). Settings sit behind a top‑right glyph in Ledger.

```
┌─────────────────────────┐
│ Ledger      Insight     │   ← two‑tab bar
│   ●            ○        │
└─────────────────────────┘
        ╲_____●_____╱       ← floating "+" (presents EntrySheet)
```

Rationale: a third "Settings" tab dilutes the daily flow. Settings is touched once per month.

## 4. Screens

### 4.1 LedgerView (default)

- Top: month label (e.g. `April 2026`) tappable to switch month, plus a single‑line total in the brand accent color (e.g. `−¥1,284.50` for net spend that month). One number is the hero. No secondary stats.
- Body: entries grouped by day, newest first. Each row = `category icon · merchant/note · amount`. Income amounts use the accent color; expenses use the primary text color. No colored category pills, no row separators with weight — separators are theme `separator` token at 1px hairlines.
- Empty state: a single centered line, theme `textSecondary`. No illustration.
- Top‑right: gear glyph → SettingsView (push).

### 4.2 EntrySheet (presented from "+")

- A modal sheet, ~70% height, no nav bar.
- Layout, top to bottom:
  1. Segmented control: `Expense | Income` (`支出 | 收入`).
  2. Amount display — large display font, right‑aligned, theme accent color when typed.
  3. Category grid — 4×N icons, monochrome at rest, accent‑filled when selected. No multi‑color category palette (a deliberate departure from FlashNotes' Morandi colors — it fragments the screen).
  4. Single‑line note field (optional).
  5. Date row — defaults to *now*, tappable to change.
  6. A custom numeric keypad pinned to the bottom (digits + `.` + `⌫` + `Save`). The system keyboard is never shown for amount entry.
- Save closes the sheet, light haptic, returns to LedgerView with the new row visible.

### 4.3 InsightView

- One screen, scrolls only if necessary. No tab bars within the tab.
- Top: month picker + the same hero number as Ledger.
- Middle: a single horizontal stacked bar — width = month spend, segments = top categories. Below the bar, a list of `icon · category name · amount · % of month`, ranked. Max 8 categories shown; rest collapsed into "Other".
- That is the entire Insight screen. No pie, no line chart, no comparisons.

### 4.4 SettingsView

- Sections: `Appearance`, `Currency`, `Data`, `About`.
- `Appearance` → `Theme` row → ThemePickerView (Claude / Cursor / Zapier swatches, single accent dot, font name shown).
- `Currency` → segmented `¥ / $ / €` (UserDefaults).
- `Data` → `Erase all entries` (destructive, with confirmation dialog).
- `About` → version + a single quiet line of credit.

## 5. Visual language

Following the awesome‑design‑md system for each brand. The shared zen rules:

- **One accent per theme.** No secondary colors except semantic error.
- **No decorative gradients, no glow shadows, no glassmorphism.** Borders or hairlines only — Cursor/Zapier are border‑forward, Claude uses ring shadows.
- **No category color palette.** Icons are monochrome (`textPrimary` at rest, `accent` when selected). The Morandi palette from FlashNotes is removed because it fights the brand accent.
- **Typography**: SwiftUI cannot ship the brand fonts (Anthropic Serif, CursorGothic, Degular Display) without licensing. We approximate per theme using system font designs:
  - Claude → `.serif` design (system "New York"), weight 500‑equivalent (`.medium`), tight line height.
  - Cursor → `.default` design with custom tracking (negative for display sizes).
  - Zapier → `.default` design, `.medium`/`.semibold`, compressed line spacing on display sizes.
- **Hero per screen**: Ledger = today's total, Insight = month total, Entry = the amount being typed. Everything else is restrained.

### 5.1 Theme tokens

Each theme provides:

```swift
struct ThemeTokens {
    let bgPrimary, bgSurface, bgInput, textPrimary, textSecondary,
        accent, accentMuted, separator, error: Color
    let radiusSmall, radiusMedium, radiusLarge: CGFloat
    let fontDesign: Font.Design   // .serif | .default | .rounded
    let displayTracking: CGFloat  // negative for Cursor, ~0 for others
    let isDark: Bool
}
```

### 5.2 Preset values

Pulled directly from the awesome‑design‑md templates.

**Claude (default, light, parchment)** — atmosphere: warm parchment, terracotta accent, serif headlines, ring shadows.

| Token | Value |
|------|-------|
| bgPrimary | `#f5f4ed` (Parchment) |
| bgSurface | `#faf9f5` (Ivory) |
| bgInput | `#e8e6dc` (Warm Sand) |
| textPrimary | `#141413` (Near Black) |
| textSecondary | `#5e5d59` (Olive Gray) |
| accent | `#c96442` (Terracotta) |
| accentMuted | `#c96442` @ 0.15 |
| separator | `#f0eee6` (Border Cream) |
| error | `#b53333` |
| radius | 8 / 12 / 24 |
| fontDesign | `.serif` |
| displayTracking | 0 |

**Cursor (light, warm cream, gothic)** — atmosphere: warm off‑white, near‑black, compressed display.

| Token | Value |
|------|-------|
| bgPrimary | `#f2f1ed` (Cream) |
| bgSurface | `#e6e5e0` (Surface 400) |
| bgInput | `#ebeae5` (Surface 300) |
| textPrimary | `#26251e` (Cursor Dark) |
| textSecondary | `rgba(38,37,30,0.55)` |
| accent | `#f54e00` (Cursor Orange) |
| accentMuted | `#f54e00` @ 0.12 |
| separator | `rgba(38,37,30,0.10)` |
| error | `#cf2d56` |
| radius | 8 / 8 / 999 (pill) |
| fontDesign | `.default` |
| displayTracking | -1.5 (negative) |

**Zapier (light, cream, friendly)** — atmosphere: cream, vivid orange, border‑forward.

| Token | Value |
|------|-------|
| bgPrimary | `#fffefb` (Cream White) |
| bgSurface | `#fffdf9` (Off‑White) |
| bgInput | `#eceae3` (Light Sand) |
| textPrimary | `#201515` (Zapier Black) |
| textSecondary | `#36342e` (Dark Charcoal) |
| accent | `#ff4f00` (Zapier Orange) |
| accentMuted | `#ff4f00` @ 0.10 |
| separator | `#c5c0b1` (Sand) |
| error | `#cf2d56` |
| radius | 4 / 8 / 20 |
| fontDesign | `.default` |
| displayTracking | 0 |

All three are light themes by design — the zen aesthetic is rooted in warm light surfaces; we do not ship dark variants in v1.

## 6. Architecture

```
ZenCoin/
  ZenCoinApp.swift               // @main, SwiftData container, theme env
  Core/
    Theme/
      ThemeID.swift              // enum: claude | cursor | zapier
      ThemeTokens.swift          // struct
      ThemePresets.swift         // static let claude/cursor/zapier
      ThemeManager.swift         // @Observable, persists to UserDefaults
      Typography.swift           // theme-aware font helpers
      Color+Hex.swift
    Currency/
      CurrencyFormatter.swift    // ¥ / $ / € via UserDefaults
  Features/
    Ledger/
      Models/
        Expense.swift            // @Model
        ExpenseCategory.swift    // simplified enum (12 expense + 4 income)
      Services/
        ExpenseDataService.swift // CRUD + fetchMonth
      ViewModels/
        LedgerViewModel.swift
        EntryViewModel.swift
      Views/
        LedgerView.swift
        EntryRowView.swift
        EntrySheet.swift
        AmountKeypadView.swift
        CategoryPickerView.swift
    Insight/
      Views/
        InsightView.swift
        CategoryBarView.swift
    Settings/
      Views/
        SettingsView.swift
        ThemePickerView.swift
  Resources/
    Info.plist
project.yml                       // xcodegen
```

### 6.1 Data model

`Expense` (SwiftData `@Model`):
- `id: UUID`
- `amount: Double` (always positive; sign comes from `isIncome`)
- `isIncome: Bool`
- `categoryRaw: String`
- `note: String` (default "")
- `paymentTime: Date`
- `createdAt: Date`

Categories are reduced from FlashNotes' 22 entries to the ones a personal user actually picks:

- Expense: dining, transport, shopping, daily, fun, housing, medical, other.
- Income: salary, bonus, invest, otherIncome.

This keeps the EntrySheet category grid to a single screen (`4×3`) with no scroll.

## 7. Build / verify

- xcodegen via `project.yml`, iOS 17 deployment, Swift 5.9.
- `xcodebuild -scheme ZenCoin -destination 'generic/platform=iOS Simulator' build` must succeed before reporting done.
- No tests in v1 — this is a UI‑first redesign, not a logic change. Add tests when behavior outgrows the simple `ExpenseDataService` CRUD.

## 8. Out‑of‑scope follow‑ups (parking lot)

- Dark variants of each theme.
- Custom font licensing for Anthropic Serif / CursorGothic / Degular Display.
- iCloud sync.
- Weekly/yearly Insight ranges.
- Recurring entries.
