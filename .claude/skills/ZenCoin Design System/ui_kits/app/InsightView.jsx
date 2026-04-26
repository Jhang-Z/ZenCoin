// InsightView.jsx — donut chart + breakdown list (simplified)
function InsightView({ slices = SAMPLE_SLICES, total = 4216, count = 47 }) {
  return (
    <div style={{ padding: "16px 0 140px" }}>
      <div style={{ padding: "0 24px", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <button style={{ display: "inline-flex", alignItems: "center", gap: 6, background: "none", border: 0, padding: 0, cursor: "pointer" }}>
          <span className="zc-title" style={{ color: "var(--text-primary)" }}>2026 年 4 月</span>
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="var(--text-secondary)" strokeWidth="3" strokeLinecap="round"><polyline points="6 9 12 15 18 9"/></svg>
        </button>
        <Segmented />
      </div>
      <div className="zc-micro" style={{ padding: "16px 24px 0" }}>EXPENSE / 支出</div>
      <Donut slices={slices} total={total} count={count} />
      <div style={{ padding: "28px 0 0" }}>
        {slices.map((s, i) => (
          <React.Fragment key={s.label}>
            <div style={{ display: "flex", alignItems: "center", gap: 14, padding: "14px 24px" }}>
              <div style={{ width: 12, height: 12, borderRadius: 2, background: `rgba(201,100,66,${OPACITY[Math.min(i, 5)]})` }}></div>
              <div className="zc-body" style={{ color: "var(--text-primary)" }}>{s.label}</div>
              <div style={{ flex: 1 }} />
              <div className="zc-caption" style={{ width: 40, textAlign: "right" }}>{Math.round(s.share * 100)}%</div>
              <div className="zc-body" style={{ minWidth: 80, textAlign: "right", color: "var(--text-primary)", fontVariantNumeric: "tabular-nums" }}>¥{s.amount.toFixed(2)}</div>
            </div>
            {i < slices.length - 1 && <hr className="zc-separator" style={{ margin: "0 24px" }}/>}
          </React.Fragment>
        ))}
      </div>
    </div>
  );
}
const OPACITY = [1.0, 0.85, 0.7, 0.55, 0.4, 0.28];
const SAMPLE_SLICES = [
  { label: "餐饮", amount: 1284.5, share: 0.305 },
  { label: "购物", amount: 880,    share: 0.209 },
  { label: "交通", amount: 540,    share: 0.128 },
  { label: "住房", amount: 480,    share: 0.114 },
  { label: "娱乐", amount: 320,    share: 0.076 },
  { label: "其他", amount: 711.5,  share: 0.169 },
];
function Segmented() {
  const [v, set] = React.useState("month");
  return (
    <div style={{ display: "inline-flex", padding: 2, borderRadius: "var(--radius-small)", background: "var(--bg-surface)" }}>
      {[["month","MONTH"],["year","YEAR"]].map(([id, label]) => (
        <button key={id} onClick={() => set(id)} className="zc-micro"
          style={{ padding: "7px 12px", border: 0, cursor: "pointer", borderRadius: "var(--radius-small)",
            background: v === id ? "var(--text-primary)" : "transparent",
            color: v === id ? "var(--bg-primary)" : "var(--text-secondary)" }}>
          {label}
        </button>
      ))}
    </div>
  );
}
function Donut({ slices, total, count }) {
  const R = 88, INNER = 64, CX = 150, CY = 150;
  let acc = 0;
  return (
    <div style={{ position: "relative", height: 300, padding: "16px 24px 0" }}>
      <svg width="100%" height="100%" viewBox="0 0 300 300" style={{ display: "block" }}>
        {slices.map((s, i) => {
          const start = acc, end = acc + s.share; acc = end;
          const a0 = start * 2 * Math.PI - Math.PI / 2;
          const a1 = end   * 2 * Math.PI - Math.PI / 2;
          const x0 = CX + R * Math.cos(a0), y0 = CY + R * Math.sin(a0);
          const x1 = CX + R * Math.cos(a1), y1 = CY + R * Math.sin(a1);
          const xi0 = CX + INNER * Math.cos(a0), yi0 = CY + INNER * Math.sin(a0);
          const xi1 = CX + INNER * Math.cos(a1), yi1 = CY + INNER * Math.sin(a1);
          const large = end - start > 0.5 ? 1 : 0;
          const d = `M ${x0} ${y0} A ${R} ${R} 0 ${large} 1 ${x1} ${y1} L ${xi1} ${yi1} A ${INNER} ${INNER} 0 ${large} 0 ${xi0} ${yi0} Z`;
          return <path key={i} d={d} fill={`rgba(201,100,66,${OPACITY[Math.min(i, 5)]})`} />;
        })}
        <text x={CX} y={CY - 2} textAnchor="middle" fontFamily="var(--font-design)" fontSize="22" fontWeight="500" fill="var(--text-primary)">¥{total.toFixed(0)}</text>
        <text x={CX} y={CY + 18} textAnchor="middle" fontFamily="-apple-system, system-ui" fontSize="12" fill="var(--text-secondary)">{count} 笔</text>
      </svg>
    </div>
  );
}
window.InsightView = InsightView;
