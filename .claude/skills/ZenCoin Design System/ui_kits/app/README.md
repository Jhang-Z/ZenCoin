# ZenCoin · iOS UI Kit

A pixel-faithful HTML/JSX recreation of the SwiftUI app's three core surfaces. Use these as building blocks for mockups, marketing shots, or icon comps.

## Components

| File | What |
|---|---|
| `LedgerHeader.jsx` | Book chip + month label + display net + IN/OUT/BAL summary strip |
| `EntryRow.jsx` | A ledger row — 36pt monochrome icon, two-line title/subtitle, right-aligned amount |
| `BottomBar.jsx` | Two tabs flanking the floating `+`. Long-press `+` → AI capture. |
| `EntrySheet.jsx` | The full manual-entry surface: mode toggle, 56px expression display, category grid, note, custom amount keypad |
| `InsightView.jsx` | Hand-drawn donut + breakdown list. Slice opacity ramps `[1.0, 0.85, 0.7, 0.55, 0.4, 0.28]` matching `InsightView.swift` |
| `index.html` | Interactive demo — toggle Ledger / Insight, tap `+` to open the entry sheet |
| `ios-frame.jsx` | iPhone device-bezel starter (unused in index, kept for reuse) |

## Conventions

- Theme tokens come from `../../colors_and_type.css`. Switch with `data-theme="claude|cursor|zapier|elevenlabs"` on `<body>`.
- Icons are inline SVG sized to match SF Symbols visually (15/17/18/22 px). See `../../assets/sf-to-lucide-map.md` for the substitution table.
- All transitions use `0.22s ease-in-out`. No shadows on UI surfaces. No multi-color icons.
- Categories follow `ExpenseCategory.swift` exactly — 12 expense + 4 income.

## Caveats

- This is a UI kit, not real bookkeeping. The amount keypad does eval expressions; everything else is presentational.
- Long-press → AI capture isn't wired (the iOS path goes through Shortcuts + AppIntent, which has no web equivalent).
- Donut is simplified — it skips the side-stacked label algorithm with L-leader lines from `DonutChartView.swift`. Add that back if you need a hi-fi marketing shot.
