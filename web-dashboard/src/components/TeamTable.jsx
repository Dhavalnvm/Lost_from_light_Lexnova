const ROLE = {
  owner:   "badge-gold",
  admin:   "bg-violet-400/10 text-violet-400 border border-violet-400/20",
  analyst: "badge-info",
  viewer:  "bg-dark-600 text-ink-secondary border border-dark-500",
};

function initials(name = "") {
  return name.split(" ").slice(0, 2).map((w) => w[0]?.toUpperCase() ?? "").join("");
}

export default function TeamTable({ members = [] }) {
  return (
    <section className="card animate-fade-up !p-0 overflow-hidden">
      {/* Header */}
      <div className="px-6 pt-5 pb-4 border-b border-dark-500 flex items-center justify-between">
        <div>
          <h2 className="text-[15px] font-semibold text-ink-primary">Team Members</h2>
          <p className="text-xs text-ink-secondary mt-0.5">Active workspace users</p>
        </div>
        <span className="badge badge-gold">{members.length} {members.length === 1 ? "member" : "members"}</span>
      </div>

      {members.length === 0 ? (
        <div className="px-6 py-8 text-center text-xs text-ink-muted">No team members found.</div>
      ) : (
        <>
          {/* Column headers */}
          <div className="grid grid-cols-[1fr_1fr_auto_auto] gap-3 px-6 py-2.5 border-b border-white/[0.03]">
            {["Member", "Email", "Role", "Docs"].map((h) => (
              <span key={h} className="text-[10px] font-medium text-ink-muted uppercase tracking-[0.12em]">{h}</span>
            ))}
          </div>

          {/* Rows */}
          {members.map((m, idx) => (
            <div
              key={m.user_id || idx}
              className="grid grid-cols-[1fr_1fr_auto_auto] gap-3 px-6 py-3.5 items-center border-b border-white/[0.025] last:border-0 hover:bg-white/[0.015] transition-colors"
            >
              {/* Avatar + name */}
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-[9px] bg-gradient-to-br from-dark-600 to-dark-500 border border-dark-400 flex items-center justify-center text-[11px] font-semibold text-gold-400 shrink-0">
                  {initials(m.name)}
                </div>
                <span className="text-[13px] text-ink-primary font-medium truncate">{m.name || "—"}</span>
              </div>

              <span className="text-xs text-ink-secondary truncate">{m.email || "—"}</span>

              <span className={`badge ${ROLE[m.role?.toLowerCase()] ?? ROLE.viewer} text-[10px] capitalize`}>
                {m.role || "member"}
              </span>

              <span className="text-[13px] text-ink-primary font-medium text-right font-mono">
                {m.documents ?? 0}
              </span>
            </div>
          ))}
        </>
      )}
    </section>
  );
}