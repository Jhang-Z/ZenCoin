// EntrySheet.jsx — manual entry: mode toggle + amount display + category grid + note + amount keypad
function EntrySheet({ onDismiss, onSave }) {
  const [isIncome, setIsIncome] = React.useState(false);
  const [expr, setExpr] = React.useState("");
  const [category, setCategory] = React.useState("dining");
  const [note, setNote] = React.useState("");
  const amount = evalExpr(expr);
  const hasOp = /[+\-×÷]/.test(expr.slice(1));

  const append = (t) => setExpr((e) => e + (t === "−" ? "-" : t));
  const back = () => setExpr((e) => e.slice(0, -1));

  return (
    <div style={{ background: "var(--bg-primary)", height: "100%", display: "flex", flexDirection: "column" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 8, padding: "18px 24px 0" }}>
        <ModeBtn active={!isIncome} onClick={() => setIsIncome(false)}>支出</ModeBtn>
        <ModeBtn active={isIncome} onClick={() => setIsIncome(true)}>收入</ModeBtn>
        <div style={{ flex: 1 }} />
        <button onClick={onDismiss} style={{ width: 32, height: 32, borderRadius: 999, background: "var(--bg-surface)", border: 0, color: "var(--text-secondary)", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" }}>
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round"><path d="M18 6L6 18M6 6l12 12"/></svg>
        </button>
      </div>
      <div style={{ padding: "24px 24px 0", textAlign: "right" }}>
        <div style={{ fontSize: 56, fontWeight: 500, fontFamily: "var(--font-design)", letterSpacing: "var(--display-tracking)", color: amount > 0 ? "var(--accent)" : "var(--text-secondary)", lineHeight: 1.05 }}>
          {expr || "0"}
        </div>
        {hasOp && <div className="zc-caption" style={{ marginTop: 4 }}>= ¥{amount.toFixed(2)}</div>}
      </div>
      <div style={{ marginTop: 20 }}>
        <CategoryGrid isIncome={isIncome} selected={category} onSelect={setCategory} />
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 8, margin: "12px 24px 0", padding: "10px 14px", borderRadius: "var(--radius-small)", background: "var(--bg-surface)" }}>
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="var(--text-secondary)" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4z"/></svg>
        <input value={note} onChange={(e) => setNote(e.target.value)} placeholder="描述（可选）" className="zc-body" style={{ flex: 1, background: "none", border: 0, outline: "none", color: "var(--text-primary)" }}/>
      </div>
      <div style={{ flex: 1 }} />
      <Keypad canSave={amount > 0} onToken={append} onBack={back} onSave={() => onSave && onSave({ isIncome, amount, category, note })} />
    </div>
  );
}
function evalExpr(s) {
  if (!s) return 0;
  try { const v = Function("return (" + s.replace(/×/g, "*").replace(/÷/g, "/") + ")")(); return Number.isFinite(v) ? v : 0; } catch { return 0; }
}
function ModeBtn({ active, onClick, children }) {
  return <button onClick={onClick} className="zc-body"
    style={{ padding: "8px 16px", borderRadius: "var(--radius-small)", border: 0, cursor: "pointer",
      background: active ? "var(--text-primary)" : "var(--bg-surface)",
      color: active ? "var(--bg-primary)" : "var(--text-secondary)" }}>{children}</button>;
}
function CategoryGrid({ isIncome, selected, onSelect }) {
  const expense = ["dining","transport","shopping","daily","fun","housing","medical","clothing","telecom","travel","education","other"];
  const income  = ["salary","bonus","invest","otherIncome"];
  const labels = { dining:"餐饮", transport:"交通", shopping:"购物", daily:"日用", fun:"娱乐", housing:"住房", medical:"医疗", clothing:"服饰", telecom:"通讯", travel:"旅行", education:"教育", other:"其他", salary:"工资", bonus:"奖金", invest:"理财", otherIncome:"其他收入" };
  const cats = isIncome ? income : expense;
  return (
    <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "14px 12px", padding: "0 24px" }}>
      {cats.map((c) => {
        const sel = c === selected;
        return (
          <button key={c} onClick={() => onSelect(c)} style={{ background: "none", border: 0, cursor: "pointer", display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
            <div style={{ width: 44, height: 44, borderRadius: 999, background: sel ? "var(--accent)" : "var(--bg-surface)", color: sel ? "var(--bg-primary)" : "var(--text-primary)", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <CategoryIcon name={c} />
            </div>
            <div className="zc-micro" style={{ color: sel ? "var(--text-primary)" : "var(--text-secondary)", textTransform: "none", letterSpacing: 0 }}>{labels[c]}</div>
          </button>
        );
      })}
    </div>
  );
}
function CategoryIcon({ name }) {
  const I = { dining: <><path d="M3 2v7a2 2 0 0 0 4 0V2"/><path d="M5 2v20"/><path d="M21 12a4 4 0 0 0-4-4V2"/><path d="M17 22V12"/></>,
    transport: <><rect x="4" y="3" width="16" height="16" rx="2"/><path d="M4 11h16M9 19l-2 3M15 19l2 3"/></>,
    shopping: <><path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"/><line x1="3" y1="6" x2="21" y2="6"/><path d="M16 10a4 4 0 0 1-8 0"/></>,
    daily: <><circle cx="9" cy="21" r="1"/><circle cx="20" cy="21" r="1"/><path d="M1 1h4l2.7 13.4a2 2 0 0 0 2 1.6h9.7a2 2 0 0 0 2-1.6L23 6H6"/></>,
    fun: <><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></>,
    housing: <><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></>,
    medical: <><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16M12 11v4M10 13h4"/></>,
    clothing: <><path d="M20.4 14.5 16 10 4 20l11-11 5.4 4.5z"/><path d="M14 5 6 13l-3-3 8-8z"/></>,
    telecom: <><path d="M4.9 19.1C1 15.2 1 8.8 4.9 4.9M7.8 16.2c-2.3-2.3-2.3-6.1 0-8.5"/><circle cx="12" cy="12" r="2"/><path d="M16.2 7.8c2.3 2.3 2.3 6.1 0 8.5M19.1 4.9C23 8.8 23 15.2 19.1 19.1"/></>,
    travel: <><path d="M17.8 19.2 16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 1.5L13 8 4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 1.3L9 12l-2 3H4l-1 1 3 2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 1.3.3l.5-.2c.4-.3.6-.7.5-1.2z"/></>,
    education: <><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2zM22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/></>,
    other: <><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/></>,
    salary: <><rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="2"/></>,
    bonus: <><rect x="3" y="8" width="18" height="4"/><path d="M12 8v13M19 12v9H5v-9M7.5 8a2.5 2.5 0 0 1 0-5C11 3 12 8 12 8M16.5 8a2.5 2.5 0 0 0 0-5C13 3 12 8 12 8"/></>,
    invest: <><polyline points="3 17 9 11 13 15 21 7"/><polyline points="14 7 21 7 21 14"/></>,
    otherIncome: <><circle cx="12" cy="12" r="10"/><polyline points="8 12 12 16 16 12"/><line x1="12" y1="8" x2="12" y2="16"/></>
  };
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">{I[name] || I.other}</svg>;
}
function Keypad({ canSave, onToken, onBack, onSave }) {
  const rows = [["1","2","3","÷"],["4","5","6","×"],["7","8","9","−"],[".","0","⌫","+"]];
  return (
    <div style={{ display: "flex", gap: 1, background: "var(--separator)" }}>
      <div style={{ flex: 1, display: "grid", gridTemplateRows: "repeat(4, 56px)", gap: 1 }}>
        {rows.map((r, ri) => (
          <div key={ri} style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 1 }}>
            {r.map((k) => {
              const isOp = ["÷","×","−","+"].includes(k);
              const isCtrl = k === "⌫";
              return (
                <button key={k}
                  onClick={() => k === "⌫" ? onBack() : onToken(k)}
                  style={{ height: 56, border: 0, cursor: "pointer",
                    background: isOp ? "var(--bg-surface)" : "var(--bg-primary)",
                    color: isOp ? "var(--accent)" : isCtrl ? "var(--text-secondary)" : "var(--text-primary)",
                    fontFamily: "var(--font-design)",
                    fontSize: isCtrl ? 18 : 22, fontWeight: isOp ? 500 : 400 }}>
                  {k}
                </button>
              );
            })}
          </div>
        ))}
      </div>
      <button onClick={canSave ? onSave : undefined} disabled={!canSave}
        style={{ width: 84, border: 0, cursor: canSave ? "pointer" : "default",
          background: canSave ? "var(--accent)" : "var(--bg-input)",
          color: canSave ? "var(--bg-primary)" : "var(--text-secondary)",
          fontFamily: "var(--font-design)", fontSize: 17, fontWeight: 600 }}>
        保存
      </button>
    </div>
  );
}
window.EntrySheet = EntrySheet;
