const TONES = {
  gold:    { iconBg: "bg-gold-400/10",    iconText: "text-gold-400",    bar: "from-gold-400/50",    glow: "shadow-glow-gold"    },
  blue:    { iconBg: "bg-blue-400/10",    iconText: "text-blue-400",    bar: "from-blue-400/50",    glow: ""                    },
  emerald: { iconBg: "bg-emerald-400/10", iconText: "text-emerald-400", bar: "from-emerald-400/50", glow: "shadow-glow-emerald" },
  rose:    { iconBg: "bg-rose-400/10",    iconText: "text-rose-400",    bar: "from-rose-400/50",    glow: "shadow-glow-rose"    },
  amber:   { iconBg: "bg-amber-400/10",   iconText: "text-amber-400",   bar: "from-amber-400/50",   glow: ""                    },
  default: { iconBg: "bg-gold-400/8",     iconText: "text-gold-400",    bar: "from-gold-400/40",    glow: ""                    },
};

export default function StatCard({ label, value, icon, helper, tone = "default", loading = false }) {
  const t = TONES[tone] || TONES.default;

  return (
    <div className="card card-hover animate-fade-up flex flex-col gap-3.5">
      <div className="flex items-start justify-between">
        <p className="text-[11px] font-medium text-ink-secondary uppercase tracking-[0.14em] leading-snug">
          {label}
        </p>
        <div className={`w-9 h-9 rounded-[10px] ${t.iconBg} flex items-center justify-center text-[15px] font-mono font-semibold ${t.iconText} shrink-0`}>
          {icon}
        </div>
      </div>

      {loading ? (
        <div className="skeleton h-9 w-[55%] rounded-md" />
      ) : (
        <p className="font-display text-[34px] font-bold text-ink-primary tracking-tight leading-none">
          {value}
        </p>
      )}

      {helper && (
        <p className="text-[11px] text-ink-muted -mt-1">{helper}</p>
      )}

      {/* Accent bar */}
      <div className={`h-0.5 rounded-sm bg-gradient-to-r ${t.bar} to-transparent mt-0.5`} />
    </div>
  );
}