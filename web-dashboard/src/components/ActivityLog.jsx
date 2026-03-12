const TYPE_CONFIG = {
  upload:   { icon: "↑",  iconCls: "bg-gold-400/8 text-gold-400",     tagCls: "bg-gold-400/8 text-gold-400"     },
  chat:     { icon: "💬", iconCls: "bg-blue-400/7 text-blue-400",     tagCls: "bg-blue-400/7 text-blue-400"     },
  login:    { icon: "→",  iconCls: "bg-emerald-400/7 text-emerald-400", tagCls: "bg-emerald-400/7 text-emerald-400" },
  analysis: { icon: "⚡", iconCls: "bg-violet-400/7 text-violet-400", tagCls: "bg-violet-400/7 text-violet-400" },
  warning:  { icon: "!",  iconCls: "bg-amber-400/7 text-amber-400",   tagCls: "bg-amber-400/7 text-amber-400"   },
  error:    { icon: "✕",  iconCls: "bg-rose-400/7 text-rose-400",     tagCls: "bg-rose-400/7 text-rose-400"     },
  default:  { icon: "·",  iconCls: "bg-dark-600 text-ink-muted",      tagCls: "bg-dark-600 text-ink-muted"      },
};

function formatRelative(iso) {
  if (!iso) return "—";
  const d    = new Date(iso);
  if (isNaN(d)) return iso;
  const diff = Math.floor((Date.now() - d.getTime()) / 1000);
  if (diff < 60)    return "just now";
  if (diff < 3600)  return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  return d.toLocaleDateString("en", { day: "numeric", month: "short" });
}

export default function ActivityLog({ title = "Activity Log", subtitle, items = [] }) {
  return (
    <section className="card animate-fade-up">
      <div className="flex items-start justify-between gap-3 mb-5">
        <div>
          <h2 className="text-[15px] font-semibold text-ink-primary">{title}</h2>
          {subtitle && <p className="text-xs text-ink-secondary mt-0.5">{subtitle}</p>}
        </div>
        <span className="text-[11px] text-ink-muted uppercase tracking-[0.16em]">
          {items.length} events
        </span>
      </div>

      {items.length === 0 ? (
        <div className="py-8 text-center text-xs text-ink-muted">No activity recorded yet.</div>
      ) : (
        <div className="flex flex-col divide-y divide-white/[0.03]">
          {items.map((item, idx) => {
            const cfg = TYPE_CONFIG[item.type] || TYPE_CONFIG.default;
            return (
              <div key={idx} className="flex items-start gap-3.5 py-3">
                {/* Icon */}
                <div className={`w-7 h-7 rounded-lg ${cfg.iconCls} flex items-center justify-center text-[13px] font-bold shrink-0 mt-0.5`}>
                  {cfg.icon}
                </div>
                {/* Content */}
                <div className="flex-1 min-w-0">
                  <p className="text-[13px] text-ink-primary leading-snug truncate">
                    <span className="text-gold-400 font-medium">{item.user || "Unknown"}</span>
                    {" · "}
                    {item.resource || "—"}
                  </p>
                  <p className="text-[11px] text-ink-muted mt-0.5 flex items-center gap-1.5">
                    {item.type && (
                      <span className={`${cfg.tagCls} rounded px-1.5 py-px text-[10px] font-medium`}>
                        {item.type}
                      </span>
                    )}
                    {formatRelative(item.timestamp)}
                  </p>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </section>
  );
}