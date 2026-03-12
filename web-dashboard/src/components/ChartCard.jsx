/* ── Pure-SVG Bar Chart ────────────────────────────────────────────────────── */
function BarChart({ data }) {
  if (!data || data.length === 0) {
    return (
      <div className="h-28 flex items-center justify-center">
        <p className="text-xs text-ink-muted">No data</p>
      </div>
    );
  }

  const max   = Math.max(...data.map((d) => d.value), 1);
  const BAR_H = 110;
  const GAP   = 6;
  const BAR_W = Math.max(18, Math.floor((280 - (data.length - 1) * GAP) / Math.max(data.length, 1)));
  const SVG_W = Math.max(data.length * BAR_W + (data.length - 1) * GAP, 280);

  return (
    <div className="overflow-x-auto">
      <svg width="100%" viewBox={`0 0 ${SVG_W} ${BAR_H + 28}`} className="block">
        {data.map((d, i) => {
          const barH  = Math.max(2, (d.value / max) * BAR_H);
          const x     = i * (BAR_W + GAP);
          const y     = BAR_H - barH;
          const alpha = (0.4 + 0.6 * (d.value / max)).toFixed(2);
          return (
            <g key={`${d.label}-${i}`}>
              <rect x={x} y={0}   width={BAR_W} height={BAR_H} rx={4} fill="rgba(255,255,255,0.02)" />
              <rect x={x} y={y}   width={BAR_W} height={barH}  rx={4} fill={`rgba(201,169,110,${alpha})`}>
                <title>{`${d.label}: ${d.value}`}</title>
              </rect>
              <text
                x={x + BAR_W / 2} y={BAR_H + 16}
                textAnchor="middle" fontSize={9}
                fill="#5a5040" fontFamily="DM Sans, sans-serif"
              >
                {String(d.label).length > 6 ? String(d.label).slice(0, 6) + "…" : d.label}
              </text>
            </g>
          );
        })}
      </svg>
    </div>
  );
}

/* ── Pure-SVG Donut Chart ──────────────────────────────────────────────────── */
const DONUT_COLORS = [
  "rgba(201,169,110,0.85)",
  "rgba(96,165,250,0.75)",
  "rgba(52,211,153,0.75)",
  "rgba(251,113,133,0.75)",
  "rgba(167,139,250,0.75)",
  "rgba(251,191,36,0.75)",
];

function DonutChart({ data }) {
  if (!data || data.length === 0) {
    return (
      <div className="h-36 flex items-center justify-center">
        <p className="text-xs text-ink-muted">No data</p>
      </div>
    );
  }

  const total = data.reduce((s, d) => s + d.value, 0) || 1;
  const R = 52; const CX = 70; const CY = 70; const SW = 14;

  let cumulative = 0;
  const arcs = data.map((d, i) => {
    const pct   = d.value / total;
    const start = cumulative;
    cumulative += pct;
    return { ...d, pct, start, color: DONUT_COLORS[i % DONUT_COLORS.length] };
  });

  function polarXY(cx, cy, r, pct) {
    const a = pct * 2 * Math.PI - Math.PI / 2;
    return [cx + r * Math.cos(a), cy + r * Math.sin(a)];
  }
  function arc(cx, cy, r, s, e) {
    if (e - s >= 1) e = s + 0.9999;
    const [sx, sy] = polarXY(cx, cy, r, s);
    const [ex, ey] = polarXY(cx, cy, r, e);
    const large = e - s > 0.5 ? 1 : 0;
    return `M ${sx} ${sy} A ${r} ${r} 0 ${large} 1 ${ex} ${ey}`;
  }

  return (
    <div className="flex items-center gap-4">
      <svg width={140} height={140} viewBox="0 0 140 140" className="shrink-0">
        <circle cx={CX} cy={CY} r={R} fill="none" stroke="rgba(255,255,255,0.04)" strokeWidth={SW} />
        {arcs.map((a, i) => (
          <path key={i} d={arc(CX, CY, R, a.start, a.start + a.pct)}
            fill="none" stroke={a.color} strokeWidth={SW} strokeLinecap="round">
            <title>{`${a.label}: ${a.value}`}</title>
          </path>
        ))}
        <text x={CX} y={CY - 5} textAnchor="middle" fontSize={18} fill="#f0ebe4"
          fontFamily="'Cormorant Garamond', serif" fontWeight={700}>
          {total > 999 ? `${(total / 1000).toFixed(1)}k` : total}
        </text>
        <text x={CX} y={CY + 12} textAnchor="middle" fontSize={9} fill="#5a5040"
          fontFamily="DM Sans, sans-serif">total</text>
      </svg>

      <div className="flex flex-col gap-1.5 flex-1">
        {arcs.map((a, i) => (
          <div key={i} className="flex items-center gap-2">
            <span className="inline-block w-2 h-2 rounded-[2px] shrink-0" style={{ background: a.color }} />
            <span className="text-[11px] text-ink-secondary flex-1 truncate">{a.label}</span>
            <span className="text-[11px] text-ink-primary font-medium">
              {a.pct > 0 ? `${(a.pct * 100).toFixed(0)}%` : "0%"}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

/* ── ChartCard wrapper ─────────────────────────────────────────────────────── */
export default function ChartCard({ title, subtitle, helper, type = "bar", data = [] }) {
  return (
    <div className="card animate-fade-up">
      <div className="flex items-start justify-between gap-3 mb-5">
        <div>
          <h3 className="text-sm font-semibold text-ink-primary leading-snug">{title}</h3>
          {subtitle && <p className="text-[11px] text-ink-secondary mt-0.5">{subtitle}</p>}
        </div>
        {helper && (
          <span className="text-[10px] text-ink-muted uppercase tracking-[0.16em] pt-0.5 shrink-0">
            {helper}
          </span>
        )}
      </div>
      {type === "donut" ? <DonutChart data={data} /> : <BarChart data={data} />}
    </div>
  );
}