import { useCallback, useEffect, useState } from "react";
import ActivityLog from "../components/ActivityLog.jsx";
import ChartCard   from "../components/ChartCard.jsx";
import Sidebar     from "../components/Sidebar.jsx";
import StatCard    from "../components/StatCard.jsx";
import { getUserDashboard } from "../services/api.js";

const SIDEBAR_ITEMS = [
  { label: "User Dashboard",    path: "/dashboard"         },
  { label: "Company Dashboard", path: "/company-dashboard" },
  { label: "Admin Console",     path: "/admin-dashboard"   },
];

function fmt(iso) {
  if (!iso) return "—";
  const d = new Date(iso);
  return isNaN(d) ? iso : d.toLocaleDateString("en", { day: "numeric", month: "short", year: "numeric" });
}

function SafetyBadge({ score }) {
  const s = score ?? 0;
  const cls = s >= 75 ? "badge-success" : s >= 45 ? "badge-warning" : "badge-danger";
  const lbl = s >= 75 ? "Safe"          : s >= 45 ? "Moderate"       : "Risky";
  return <span className={`badge ${cls}`}>{s} · {lbl}</span>;
}

function RiskPanel({ risk, loading }) {
  const total = (risk.high || 0) + (risk.medium || 0) + (risk.low || 0) || 1;
  const bands = [
    { label: "High",   count: risk.high   || 0, bar: "bg-rose-400",    txt: "text-rose-400"    },
    { label: "Medium", count: risk.medium || 0, bar: "bg-amber-400",   txt: "text-amber-400"   },
    { label: "Low",    count: risk.low    || 0, bar: "bg-emerald-400", txt: "text-emerald-400" },
  ];

  return (
    <section className="card animate-fade-up">
      <div className="flex items-start justify-between mb-5">
        <div>
          <h2 className="text-[15px] font-semibold text-ink-primary">Risk Summary</h2>
          <p className="text-xs text-ink-secondary mt-0.5">Clause severity across all documents</p>
        </div>
        <span className="text-[10px] text-ink-muted uppercase tracking-[0.16em]">Flags</span>
      </div>

      {loading ? (
        <div className="flex flex-col gap-3">
          {[...Array(3)].map((_, i) => <div key={i} className="skeleton h-14 rounded-xl" />)}
        </div>
      ) : (
        <div className="flex flex-col gap-2.5">
          {bands.map(({ label, count, bar, txt }) => {
            const pct = Math.round((count / total) * 100);
            return (
              <div key={label} className="bg-dark-900/60 border border-dark-500 rounded-xl p-3.5">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-xs text-ink-secondary">{label} risk</span>
                  <span className={`font-display text-lg font-bold ${txt}`}>{count}</span>
                </div>
                <div className="h-[3px] rounded-sm bg-dark-600">
                  <div className={`h-full rounded-sm ${bar} transition-all duration-500`} style={{ width: `${pct}%` }} />
                </div>
              </div>
            );
          })}
        </div>
      )}
    </section>
  );
}

function RecentDocs({ docs, loading }) {
  if (loading) {
    return (
      <section className="card animate-fade-up !p-0 overflow-hidden">
        <div className="px-6 py-5 border-b border-dark-500">
          <div className="skeleton h-[18px] w-40 rounded-md" />
        </div>
        {[...Array(4)].map((_, i) => (
          <div key={i} className="px-6 py-4 border-b border-white/[0.025]">
            <div className="skeleton h-3.5 w-[60%] rounded mb-1.5" />
            <div className="skeleton h-2.5 w-[35%] rounded" />
          </div>
        ))}
      </section>
    );
  }

  return (
    <section className="card animate-fade-up !p-0 overflow-hidden">
      <div className="px-6 pt-5 pb-4 border-b border-dark-500 flex items-center justify-between">
        <div>
          <h2 className="text-[15px] font-semibold text-ink-primary">Recent Documents</h2>
          <p className="text-xs text-ink-secondary mt-0.5">Your last {docs.length} analysed files</p>
        </div>
        <span className="badge badge-gold">{docs.length} files</span>
      </div>

      {docs.length === 0 ? (
        <div className="px-6 py-8 text-center text-xs text-ink-muted">No documents analysed yet. Upload one to get started.</div>
      ) : (
        <>
          <div className="grid grid-cols-[1fr_auto_auto] gap-4 px-6 py-2.5 border-b border-white/[0.03]">
            {["Filename", "Type", "Safety"].map((h) => (
              <span key={h} className="text-[10px] font-medium text-ink-muted uppercase tracking-[0.12em]">{h}</span>
            ))}
          </div>
          {docs.map((doc, idx) => (
            <div key={doc.document_id || idx}
              className="grid grid-cols-[1fr_auto_auto] gap-4 px-6 py-3.5 items-center border-b border-white/[0.025] last:border-0 hover:bg-white/[0.015] transition-colors">
              <div>
                <p className="text-[13px] text-ink-primary font-medium truncate">{doc.filename || "Untitled"}</p>
                <p className="text-[11px] text-ink-muted mt-0.5">{fmt(doc.uploaded_at)}</p>
              </div>
              <span className="text-xs text-ink-secondary">{doc.doc_type || "—"}</span>
              <SafetyBadge score={doc.safety_score} />
            </div>
          ))}
        </>
      )}
    </section>
  );
}

export default function UserDashboard() {
  const [data,    setData]    = useState(null);
  const [loading, setLoading] = useState(true);
  const [error,   setError]   = useState("");

  const load = useCallback(async () => {
    setLoading(true); setError("");
    try { setData(await getUserDashboard()); }
    catch (err) { setError(err.message || "Unable to load dashboard."); }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const user      = data?.user            ?? {};
  const overview  = data?.overview        ?? {};
  const risk      = data?.riskSummary     ?? {};
  const trend     = data?.uploadTrend     ?? [];
  const typeBreak = data?.docTypeBreakdown ?? [];
  const recentDocs = data?.recentDocuments ?? [];
  const activity  = (data?.recentActivity ?? []).map((item) => ({
    ...item,
    user:     item.user     ?? "Unknown",
    resource: item.resource ?? "Not specified",
    type:     String(item.type ?? "default").toLowerCase(),
  }));

  const stats = [
    { label: "Total Documents", value: String(overview.totalDocuments   ?? 0), icon: "D",  tone: "gold",    helper: "Files uploaded and analysed"       },
    { label: "This Month",      value: String(overview.recentDocuments  ?? 0), icon: "↑",  tone: "blue",    helper: "Documents in the last 30 days"     },
    { label: "Avg Safety",      value: overview.avgSafetyScore != null ? String(overview.avgSafetyScore) : "—", icon: "✓", tone: "emerald", helper: "Across all your documents" },
    { label: "Risky Clauses",   value: String(overview.riskyClauses     ?? 0), icon: "!",  tone: "rose",    helper: "High + medium severity flags"      },
  ];

  return (
    <div className="min-h-screen flex bg-dark-900">
      <Sidebar title="My Workspace" subtitle="User Dashboard" items={SIDEBAR_ITEMS} footerLabel="Analytics live" />

      <main className="flex-1 p-5 md:p-8 lg:p-10 overflow-y-auto">
        <div className="max-w-6xl mx-auto flex flex-col gap-6">

          {/* Header */}
          <section className="card animate-fade-up bg-card-gold overflow-hidden">
            <p className="text-[10px] uppercase tracking-[0.22em] text-ink-muted mb-1.5">Personal Dashboard</p>
            <h1 className="font-display text-3xl md:text-4xl font-bold text-ink-primary tracking-tight">
              {loading ? "Loading…" : `Welcome back, ${user.name || "Counsellor"}.`}
            </h1>
            <p className="text-[13px] text-ink-secondary mt-2">
              {user.email && `${user.email} · `}
              {user.member_since && `Member since ${fmt(user.member_since)}`}
            </p>
          </section>

          {/* Error */}
          {error && (
            <section className="card border-rose-500/30 bg-rose-500/5">
              <div className="flex items-center justify-between gap-3">
                <div>
                  <h2 className="text-sm font-semibold text-rose-400">Dashboard unavailable</h2>
                  <p className="text-[13px] text-rose-400/75 mt-1">{error}</p>
                </div>
                <button className="btn-ghost !border-rose-500/30 !text-rose-400 shrink-0" onClick={load}>Retry</button>
              </div>
            </section>
          )}

          {/* Stats */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 stagger">
            {(loading ? Array(4).fill(null) : stats).map((s, i) =>
              s ? <StatCard key={s.label} {...s} /> : <div key={i} className="card skeleton h-36" />
            )}
          </div>

          {/* Charts */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
            {loading ? (
              <><div className="card skeleton h-56" /><div className="card skeleton h-56" /></>
            ) : (
              <>
                <ChartCard title="Upload Trend" subtitle="Documents uploaded in the last 7 days" helper="Volume" type="bar" data={trend} />
                <ChartCard title="Document Types" subtitle="Breakdown by category" helper="Mix" type="donut" data={typeBreak} />
              </>
            )}
          </div>

          {/* Risk + recent docs */}
          <div className="grid grid-cols-1 lg:grid-cols-[1fr_1.8fr] gap-5">
            <RiskPanel risk={risk} loading={loading} />
            <RecentDocs docs={recentDocs} loading={loading} />
          </div>

          {/* Activity */}
          {loading
            ? <div className="card skeleton h-52" />
            : <ActivityLog title="Recent Activity" subtitle="Your latest interactions with the platform" items={activity} />
          }
        </div>
      </main>
    </div>
  );
}