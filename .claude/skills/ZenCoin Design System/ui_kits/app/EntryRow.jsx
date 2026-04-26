// EntryRow.jsx — a ledger row: 36pt monochrome icon · two-line · right amount
const CATEGORY_ICONS = {
  dining:    { path: <><path d="M3 2v7a2 2 0 0 0 4 0V2"/><path d="M5 2v20"/><path d="M21 12a4 4 0 0 0-4-4V2"/><path d="M17 22V12"/></> },
  transport: { path: <><rect x="4" y="3" width="16" height="16" rx="2"/><path d="M4 11h16"/><path d="M9 19l-2 3"/><path d="M15 19l2 3"/></> },
  shopping:  { path: <><path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"/><line x1="3" y1="6" x2="21" y2="6"/><path d="M16 10a4 4 0 0 1-8 0"/></> },
  daily:     { path: <><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.7 13.4a2 2 0 0 0 2 1.6h9.7a2 2 0 0 0 2-1.6L23 6H6"/></> },
  fun:       { path: <><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></> },
  housing:   { path: <><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></> },
  travel:    { path: <><path d="M17.8 19.2 16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 1.5L13 8 4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 1.3L9 12l-2 3H4l-1 1 3 2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 1.3.3l.5-.2c.4-.3.6-.7.5-1.2z"/></> },
  salary:    { path: <><rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="2"/><path d="M6 12h.01M18 12h.01"/></> },
  other:     { path: <><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/></> },
};
function EntryRow({ category = "dining", title = "公司食堂", subtitle = "餐饮 · 12:14", amount = "−¥28.00", isIncome = false, isSelectionMode = false, isSelected = false, onTap, onLongPress }) {
  const ic = CATEGORY_ICONS[category] || CATEGORY_ICONS.other;
  const pressTimer = React.useRef(null);
  return (
    <div
      onMouseDown={() => { pressTimer.current = setTimeout(() => onLongPress && onLongPress(), 350); }}
      onMouseUp={() => { clearTimeout(pressTimer.current); onTap && onTap(); }}
      onMouseLeave={() => clearTimeout(pressTimer.current)}
      style={{ display: "flex", alignItems: "center", gap: 14, padding: "14px 24px", cursor: "pointer", userSelect: "none" }}>
      {isSelectionMode && (
        <div style={{ width: 24, color: isSelected ? "var(--accent)" : "var(--separator)" }}>
          {isSelected
            ? <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><circle cx="12" cy="12" r="10"/><polyline points="9 12 11 14 15 10" stroke="var(--bg-primary)" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
            : <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6"><circle cx="12" cy="12" r="10"/></svg>}
        </div>
      )}
      <div style={{ width: 36, height: 36, borderRadius: 999, background: "var(--accent-muted)", color: "var(--accent)", display: "flex", alignItems: "center", justifyContent: "center", flex: "none" }}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">{ic.path}</svg>
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="zc-heading" style={{ color: "var(--text-primary)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{title}</div>
        <div className="zc-caption">{subtitle}</div>
      </div>
      <div className="zc-heading" style={{ color: isIncome ? "var(--accent)" : "var(--text-primary)", fontVariantNumeric: "tabular-nums" }}>{amount}</div>
    </div>
  );
}
window.EntryRow = EntryRow;
