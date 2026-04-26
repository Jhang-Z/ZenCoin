# SF Symbol → Lucide mapping

ZenCoin uses SF Symbols natively. On the web (where SF Symbols can't ship), substitute Lucide icons (same monochrome / stroked aesthetic). Load via CDN:

```html
<script src="https://unpkg.com/lucide@latest/dist/umd/lucide.min.js"></script>
```

| SF Symbol | Lucide | Used for |
|---|---|---|
| `fork.knife` | `utensils` | 餐饮 (dining) |
| `tram.fill` | `train-front` | 交通 (transport) |
| `bag` | `shopping-bag` | 购物 (shopping) |
| `cart` | `shopping-cart` | 日用 (daily) |
| `music.note` | `music` | 娱乐 (fun) |
| `house` | `house` | 住房 (housing) |
| `cross.case` | `briefcase-medical` | 医疗 (medical) |
| `tshirt` | `shirt` | 服饰 (clothing) |
| `antenna.radiowaves.left.and.right` | `radio` | 通讯 (telecom) |
| `airplane` | `plane` | 旅行 (travel) |
| `book` | `book-open` | 教育 (education) |
| `circle.grid.2x2` | `grid-2x2` | 其他 (other) |
| `banknote` | `banknote` | 工资 (salary) |
| `gift` | `gift` | 奖金 (bonus) |
| `chart.line.uptrend.xyaxis` | `trending-up` | 理财 (invest) |
| `arrow.down.circle` | `arrow-down-circle` | 其他收入 (other income) |
| `plus` | `plus` | floating add |
| `xmark` | `x` | sheet close |
| `chevron.down` | `chevron-down` | header chip |
| `gearshape` | `settings` | settings |
| `pencil` | `pencil` | note field |
| `list.bullet` | `list` | LEDGER tab |
| `chart.bar` | `bar-chart-3` | INSIGHT tab |
| `checkmark.circle.fill` | `check-circle-2` | selection on |
| `circle` | `circle` | selection off |
| `sparkles` | `sparkles` | AI capture |
| `trash` | `trash-2` | destructive |

**Rules:**
- Stroke width: `1.5` (Lucide default). Don't change.
- Color: `theme.accent` for category icons in rows; `theme.textPrimary` / `Secondary` for chrome.
- Size: 15px for row icons, 17px for category-picker, 18px for tab/chrome, 22px for the floating +.
- Never colorize. Never use Lucide's `*-fill` or filled SF variants except `tram.fill` (a SF naming quirk — the substitute is just `train-front`).
