import { useNavigate, useLocation } from "react-router-dom";
import { clearAuth } from "../services/auth.js";

const ICONS = {
  "/company-dashboard": "🏢",
  "/dashboard":         "👤",
  "/admin-dashboard":   "⚙️",
};

export default function Sidebar({ title, subtitle, items = [], footerLabel }) {
  const navigate = useNavigate();
  const { pathname } = useLocation();

  return (
    <aside className="w-60 shrink-0 bg-dark-800 border-r border-dark-500 flex flex-col min-h-screen sticky top-0">
      {/* Logo */}
      <div className="px-5 pt-7 pb-6 border-b border-dark-500">
        <div className="flex items-center gap-2.5 mb-1.5">
          <div className="w-[34px] h-[34px] rounded-[9px] bg-gold-diagonal flex items-center justify-center text-base shrink-0">
            ⚖️
          </div>
          <span className="font-display text-xl font-semibold text-ink-primary">LexNova</span>
        </div>
        <p className="text-[11px] text-ink-muted pl-11 tracking-[0.04em]">
          {subtitle || "AI Legal Intelligence"}
        </p>
      </div>

      {/* Workspace label */}
      {title && (
        <p className="px-5 pt-3.5 pb-1.5 text-[10px] font-medium text-ink-muted uppercase tracking-[0.14em]">
          {title}
        </p>
      )}

      {/* Nav */}
      <nav className="flex-1 px-3 py-1.5 flex flex-col gap-0.5">
        {items.map((item) => {
          const active = pathname === item.path;
          return (
            <button
              key={item.path}
              onClick={() => navigate(item.path)}
              className={[
                "flex items-center gap-2.5 px-3 py-2.5 rounded-[10px] w-full text-left text-[13px] transition-all duration-150 border",
                active
                  ? "bg-gold-500/10 border-gold-500/18 text-gold-400 font-medium"
                  : "bg-transparent border-transparent text-ink-secondary hover:bg-dark-700 hover:text-ink-primary",
              ].join(" ")}
            >
              <span className="text-[15px]">{ICONS[item.path] || "●"}</span>
              {item.label}
            </button>
          );
        })}
      </nav>

      {/* Footer */}
      <div className="px-5 py-4 border-t border-dark-500 flex flex-col gap-2.5">
        {footerLabel && (
          <div className="flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 shadow-glow-emerald animate-pulse-dot inline-block" />
            <span className="text-[11px] text-ink-muted">{footerLabel}</span>
          </div>
        )}
        <button
          onClick={() => { clearAuth(); navigate("/admin-login"); }}
          className="flex items-center gap-2 px-3 py-2 rounded-[9px] bg-rose-500/6 border border-rose-500/18 text-rose-400 text-xs w-full cursor-pointer transition-colors hover:bg-rose-500/12"
        >
          <span>⎋</span> Sign out
        </button>
      </div>
    </aside>
  );
}