// LedgerHeader.jsx — month label + display net + IN/OUT/BAL strip + book chip
function LedgerHeader({ bookName = "主账本", monthLabel = "2026 年 4 月", netSigned = "+¥1,284", incomeTotal = "¥12,800", expenseTotal = "¥11,516", balSigned = "+¥1,284", isPositive = true, onSettings, onPickMonth, onPickBook }) {
  return (
    <div style={{ padding: "16px 24px 12px" }}>
      <button onClick={onPickBook}
        style={{ display: "inline-flex", alignItems: "center", gap: 6, padding: "5px 10px", borderRadius: 999, background: "transparent", border: "1px solid var(--separator)", cursor: "pointer", marginBottom: 14 }}>
        <span style={{ width: 6, height: 6, borderRadius: 999, background: "var(--text-secondary)" }}></span>
        <span className="zc-micro" style={{ color: "var(--text-primary)", textTransform: "none", letterSpacing: "0.06em" }}>{bookName}</span>
        <Chevron />
      </button>
      <div style={{ display: "flex", alignItems: "center" }}>
        <button onClick={onPickMonth}
          style={{ display: "inline-flex", alignItems: "center", gap: 6, background: "none", border: 0, padding: 0, cursor: "pointer" }}>
          <span className="zc-title" style={{ color: "var(--text-primary)" }}>{monthLabel}</span>
          <Chevron small />
        </button>
        <div style={{ flex: 1 }} />
        <button onClick={onSettings} aria-label="设置"
          style={{ width: 32, height: 32, background: "none", border: 0, color: "var(--text-secondary)", cursor: "pointer" }}>
          <Gear />
        </button>
      </div>
      <div className="zc-display" style={{ marginTop: 8, color: isPositive ? "var(--accent)" : "var(--text-primary)" }}>
        {netSigned}
      </div>
      <div style={{ display: "flex", alignItems: "stretch", marginTop: 14 }}>
        <SummaryItem label="IN"  amount={incomeTotal}  color="var(--accent)" />
        <Vrule />
        <SummaryItem label="OUT" amount={expenseTotal} color="var(--text-primary)" />
        <Vrule />
        <SummaryItem label="BAL" amount={balSigned}    color="var(--text-primary)" />
      </div>
      <hr className="zc-separator" style={{ marginTop: 16 }} />
    </div>
  );
}
function SummaryItem({ label, amount, color }) {
  return (
    <div style={{ flex: 1, textAlign: "center" }}>
      <div className="zc-micro">{label}</div>
      <div className="zc-heading" style={{ color, marginTop: 4, fontVariantNumeric: "tabular-nums" }}>{amount}</div>
    </div>
  );
}
function Vrule() { return <div style={{ width: 1, background: "var(--separator)" }} />; }
function Chevron({ small }) {
  return <svg width={small ? 11 : 9} height={small ? 11 : 9} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><polyline points="6 9 12 15 18 9"/></svg>;
}
function Gear() {
  return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1A1.7 1.7 0 0 0 4.6 9 1.7 1.7 0 0 0 4.3 7.2l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></svg>;
}
window.LedgerHeader = LedgerHeader;
