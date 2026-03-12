import { useNavigate } from "react-router-dom";
import { isLoggedIn } from "../services/auth.js";

const FEATURES = [
  { icon: "📄", title: "Document Analysis",   desc: "Upload PDF or DOCX contracts. Get plain-language summaries, risk flags, and safety scores instantly." },
  { icon: "⚡", title: "Risk Detection",      desc: "Every clause scored by severity — high, medium, low — so you know exactly where to focus." },
  { icon: "⚖️", title: "Fairness Assessment", desc: "Compare clauses against industry benchmarks to spot one-sided terms before you sign." },
  { icon: "💬", title: "AI Legal Chat",       desc: "Ask questions about documents or get general legal guidance from Lex, your AI counsel." },
  { icon: "🔄", title: "Version Comparison",  desc: "Diff two versions of a contract side-by-side to track what changed between drafts." },
  { icon: "🌐", title: "Multi-language",      desc: "Translate legal documents into your preferred language without losing precision." },
];

const STATS = [
  { value: "50+",  label: "Document types"  },
  { value: "0.3s", label: "Avg parse time"  },
  { value: "100",  label: "Safety score max" },
  { value: "8",    label: "Categories"       },
];

export default function Home() {
  const navigate = useNavigate();
  const loggedIn = isLoggedIn();

  return (
    <div className="min-h-screen bg-dark-900 relative overflow-x-hidden">
      {/* Background glow */}
      <div aria-hidden className="fixed inset-0 pointer-events-none z-0 bg-hero-glow" />

      {/* ── Navbar ──────────────────────────────────────────────────────────── */}
      <nav className="sticky top-0 z-50 h-16 bg-dark-900/85 backdrop-blur-md border-b border-white/5 flex items-center justify-between px-6 md:px-16">
        <div className="flex items-center gap-2.5">
          <div className="w-[34px] h-[34px] rounded-[9px] bg-gold-diagonal flex items-center justify-center text-base">⚖️</div>
          <span className="font-display text-[22px] font-semibold text-ink-primary">LexNova</span>
        </div>
        <div className="flex items-center gap-2.5">
          {loggedIn ? (
            <>
              <button className="btn-ghost !py-2 !text-[13px]" onClick={() => navigate("/dashboard")}>Dashboard</button>
              <button className="btn-gold !py-2 !px-5 !text-[13px]" onClick={() => navigate("/company-dashboard")}>Enterprise</button>
            </>
          ) : (
            <>
              <button className="btn-ghost !py-2 !text-[13px]" onClick={() => navigate("/admin-login")}>Sign in</button>
              <button className="btn-gold !py-2 !px-5 !text-[13px]" onClick={() => navigate("/admin-login")}>Get started</button>
            </>
          )}
        </div>
      </nav>

      {/* ── Hero ────────────────────────────────────────────────────────────── */}
      <section className="relative z-10 max-w-4xl mx-auto px-6 pt-24 pb-20 text-center">
        <div className="badge badge-gold mb-7 mx-auto">AI-Powered Legal Intelligence</div>

        <h1 className="font-display text-5xl md:text-7xl font-bold leading-[1.06] tracking-tight text-ink-primary mb-7">
          Understand every{" "}
          <em className="not-italic" style={{ background: "linear-gradient(135deg,#dfc07e,#b5935a)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent", backgroundClip: "text" }}>
            clause
          </em>
          <br />before you sign.
        </h1>

        <p className="text-base md:text-lg text-ink-secondary leading-[1.7] max-w-[600px] mx-auto mb-11">
          LexNova transforms dense legal documents into clear, actionable intelligence.
          Risk analysis, fairness scoring, and AI guidance — all in seconds.
        </p>

        <div className="flex items-center justify-center gap-3 flex-wrap">
          <button className="btn-gold !py-3.5 !px-9 !text-[15px]" onClick={() => navigate(loggedIn ? "/dashboard" : "/admin-login")}>
            {loggedIn ? "Open dashboard" : "Start for free"}
          </button>
          <button className="btn-ghost !py-3 !px-7" onClick={() => navigate("/admin-dashboard")}>
            Admin console →
          </button>
        </div>
      </section>

      {/* ── Stats bar ───────────────────────────────────────────────────────── */}
      <section className="relative z-10 border-y border-dark-500 bg-dark-800/60 py-7 px-6">
        <div className="max-w-3xl mx-auto grid grid-cols-4 gap-2">
          {STATS.map((s) => (
            <div key={s.label} className="text-center">
              <p className="font-display text-[36px] font-bold text-gold-400 leading-none mb-1.5">{s.value}</p>
              <p className="text-[11px] text-ink-muted tracking-[0.06em]">{s.label}</p>
            </div>
          ))}
        </div>
      </section>

      {/* ── Features ────────────────────────────────────────────────────────── */}
      <section className="relative z-10 max-w-6xl mx-auto px-6 py-20">
        <div className="text-center mb-14">
          <p className="text-[11px] text-ink-muted uppercase tracking-[0.2em] mb-3.5">Platform capabilities</p>
          <h2 className="font-display text-4xl md:text-5xl font-bold text-ink-primary tracking-tight">
            Everything you need to navigate legal risk
          </h2>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 stagger">
          {FEATURES.map((f) => (
            <div key={f.title} className="card card-hover animate-fade-up">
              <div className="w-11 h-11 rounded-xl bg-gold-400/8 border border-gold-400/12 flex items-center justify-center text-xl mb-4">{f.icon}</div>
              <h3 className="font-display text-[16px] font-semibold text-ink-primary mb-2">{f.title}</h3>
              <p className="text-[13px] text-ink-secondary leading-[1.65]">{f.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* ── CTA banner ──────────────────────────────────────────────────────── */}
      <section className="relative z-10 px-6 pb-20">
        <div className="max-w-2xl mx-auto bg-card-gold border border-gold-400/18 rounded-4xl px-10 py-16 text-center shadow-gold-lg">
          <h2 className="font-display text-3xl md:text-4xl font-bold text-ink-primary mb-4 tracking-tight">
            Start understanding your contracts today.
          </h2>
          <p className="text-sm text-ink-secondary mb-9 leading-[1.7]">
            No legal background required. LexNova makes complex contracts readable for everyone.
          </p>
          <button
            className="btn-gold !py-3.5 !px-10 !text-[15px]"
            onClick={() => navigate(loggedIn ? "/dashboard" : "/admin-login")}
          >
            {loggedIn ? "Go to your dashboard →" : "Create free account →"}
          </button>
        </div>
      </section>

      {/* ── Footer ──────────────────────────────────────────────────────────── */}
      <footer className="relative z-10 border-t border-dark-500 px-6 md:px-16 py-7 flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-2">
          <span className="text-base">⚖️</span>
          <span className="font-display text-base text-ink-secondary">LexNova</span>
        </div>
        <p className="text-xs text-ink-muted">AI-powered legal intelligence. Not a substitute for professional legal advice.</p>
      </footer>
    </div>
  );
}