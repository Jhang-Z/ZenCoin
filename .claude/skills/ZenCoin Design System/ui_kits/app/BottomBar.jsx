// BottomBar.jsx — two tabs flanking the floating + (long-press for AI capture)
function BottomBar({ active = "ledger", onTab, onAdd, onLongAdd }) {
  const pressTimer = React.useRef(null);
  return (
    <div style={{ position: "relative", height: 84, background: "var(--bg-surface)", borderTop: "1px solid var(--separator)", display: "flex", justifyContent: "space-around", alignItems: "flex-start", padding: "10px 24px 0" }}>
      <Tab id="ledger" label="LEDGER" active={active === "ledger"} onClick={() => onTab && onTab("ledger")}>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round"><line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/></svg>
      </Tab>
      <button
        onMouseDown={() => { pressTimer.current = setTimeout(() => onLongAdd && onLongAdd(), 500); }}
        onMouseUp={() => { clearTimeout(pressTimer.current); onAdd && onAdd(); }}
        onMouseLeave={() => clearTimeout(pressTimer.current)}
        aria-label="新增记账"
        style={{ position: "absolute", left: "50%", top: -22, transform: "translateX(-50%)", width: 56, height: 56, borderRadius: 999, background: "var(--accent)", color: "var(--bg-primary)", border: 0, display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer" }}>
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round"><path d="M12 5v14M5 12h14"/></svg>
      </button>
      <Tab id="insight" label="INSIGHT" active={active === "insight"} onClick={() => onTab && onTab("insight")}>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="20" x2="12" y2="10"/><line x1="18" y1="20" x2="18" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>
      </Tab>
    </div>
  );
}
function Tab({ label, active, onClick, children }) {
  return (
    <button onClick={onClick} style={{ background: "none", border: 0, color: active ? "var(--text-primary)" : "var(--text-secondary)", display: "flex", flexDirection: "column", alignItems: "center", gap: 5, cursor: "pointer", flex: 1 }}>
      {children}
      <div className="zc-micro">{label}</div>
      <div style={{ width: 16, height: 1, background: active ? "var(--accent)" : "transparent" }}></div>
    </button>
  );
}
window.BottomBar = BottomBar;
