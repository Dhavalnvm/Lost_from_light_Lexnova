import { useCallback, useEffect, useState } from "react";
import ActivityLog from "../components/ActivityLog.jsx";
import ChartCard   from "../components/ChartCard.jsx";
import Sidebar     from "../components/Sidebar.jsx";
import StatCard    from "../components/StatCard.jsx";
import TeamTable   from "../components/TeamTable.jsx";
import { getCompanyActivity, getCompanyDashboard, getCompanyTeam } from "../services/api.js";

const SIDEBAR_ITEMS = [
  { label: "Company Dashboard", path: "/company-dashboard" },
  { label: "User Dashboard",    path: "/dashboard"         },
  { label: "Admin Console",     path: "/admin-dashboard"   },
];

/* ── Normalisers ─────────────────────────────────────────────────────────────── */
const toNum = (v) => {
  if (typeof v === "number") return v;
  if (typeof v === "string") { const n = v.replace(/[^0-9.-]/g, ""); return n ? Number(n) : 0; }
  return 0;
};
const compact = (v) => new Intl.NumberFormat("en", { notation: "compact", maximumFractionDigits: 1 }).format(toNum(v));
const pct     = (v) => `${toNum(v).toFixed(1)}%`;
const currency= (v) => typeof v === "string" && v.trim() ? v : new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(toNum(v));
const ms      = (v) => `${Math.round(toNum(v))} ms`;
const first   = (src, keys, fb = 0) => { for (const k of keys) if (src?.[k] != null) return src[k]; return fb; };
const titleize= (v) => String(v ?? "").replace(/([a-z])([A-Z])/g,"$1 $2").replace(/_/g," ").replace(/\b\w/g,(c)=>c.toUpperCase());

function normSeries(input, label) {
  if (Array.isArray(input)) return input.map((d, i) => ({ label: d.label ?? d.name ?? d.date ?? `${label} ${i+1}`, value: toNum(d.value ?? d.count ?? d.total) }));
  if (input && typeof input === "object") {
    if (input.value != null || input.total != null || input.count != null) return [{ label, value: toNum(input.value ?? input.total ?? input.count) }];
    return Object.entries(input).map(([l, v]) => ({ label: titleize(l), value: toNum(v) }));
  }
  if (input != null) return [{ label, value: toNum(input) }];
  return [];
}
function normDocInsights(input) {
  if (Array.isArray(input)) return input.map((d) => ({ label: d.label ?? titleize(d.type ?? d.name), value: toNum(d.value ?? d.count ?? d.total) }));
  if (input && typeof input === "object") return ["contracts","ndas","policies","agreements"].filter((k) => input[k] != null).map((k) => ({ label: titleize(k), value: toNum(input[k]) }));
  return [];
}

/* ── SecurityPanel ───────────────────────────────────────────────────────────── */
function SecurityPanel({ security }) {
  return (
    <section className="card animate-fade-up">
      <div className="flex items-start justify-between gap-3 mb-5">
        <div>
          <h2 className="text-[15px] font-semibold text-ink-primary">Security Monitoring</h2>
          <p className="text-xs text-ink-secondary mt-0.5">Failed logins, suspicious access, and login locations.</p>
        </div>
        <span className="text-[10px] text-ink-muted uppercase tracking-[0.2em]">Ops</span>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
        {[
          ["Failed logins",     security.failedLoginAttempts ?? 0, "text-rose-400"   ],
          ["Suspicious access", security.suspiciousAccess    ?? 0, "text-amber-400"  ],
        ].map(([label, value, cls]) => (
          <div key={label} className="bg-dark-900/72 border border-dark-500 rounded-2xl p-4">
            <p className="text-[10px] uppercase tracking-[0.16em] text-ink-muted">{label}</p>
            <p className={`font-display text-3xl font-bold mt-2.5 ${cls}`}>{value}</p>
          </div>
        ))}
        <div className="bg-dark-900/72 border border-dark-500 rounded-2xl p-4">
          <p className="text-[10px] uppercase tracking-[0.16em] text-ink-muted mb-2.5">Login locations</p>
          {(security.loginLocations ?? []).map((loc) => (
            <p key={loc} className="text-sm text-ink-secondary">{loc}</p>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ── BillingPanel ────────────────────────────────────────────────────────────── */
function BillingPanel({ billing }) {
  const plan = billing.plan ?? billing.currentPlan ?? "Unknown";
  return (
    <section className="card animate-fade-up">
      <div className="flex items-start justify-between gap-3 mb-5">
        <div>
          <h2 className="text-[15px] font-semibold text-ink-primary">Billing & Subscription</h2>
          <p className="text-xs text-ink-secondary mt-0.5">Plan, monthly AI consumption, and estimated costs.</p>
        </div>
        <span className="badge badge-gold">{plan}</span>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
        {[
          ["Current plan",      plan],
          ["Monthly usage",     billing.monthlyUsage ?? billing.monthlyAiUsage ?? "Unavailable"],
          ["Estimated cost",    billing.estimatedCost ? currency(billing.estimatedCost) : "Unavailable"],
          ["Next billing date", billing.nextBillingDate ?? "Unavailable"],
        ].map(([label, value]) => (
          <div key={label} className="bg-dark-900/72 border border-dark-500 rounded-2xl p-4">
            <p className="text-[10px] uppercase tracking-[0.16em] text-ink-muted">{label}</p>
            <p className="font-display text-xl font-semibold text-ink-primary mt-2.5">{value}</p>
          </div>
        ))}
      </div>
    </section>
  );
}

/* ── Main page ───────────────────────────────────────────────────────────────── */
export default function CompanyDashboard() {
  const [dashboard, setDashboard] = useState(null);
  const [team,      setTeam]      = useState([]);
  const [activity,  setActivity]  = useState([]);
  const [loading,   setLoading]   = useState(true);
  const [error,     setError]     = useState("");

  const load = useCallback(async () => {
    setError(""); setLoading(true);
    try {
      const [d, t, a] = await Promise.all([getCompanyDashboard(), getCompanyTeam(), getCompanyActivity()]);
      setDashboard(d);
      setTeam(t.team ?? []);
      setActivity((a.activity ?? []).map((item) => ({
        ...item,
        user: item.user ?? item.actor ?? "Unknown",
        resource: item.resource ?? item.detail ?? "Not specified",
        type: String(item.type ?? "default").toLowerCase(),
      })));
    } catch (err) { setError(err.message || "Unable to load company dashboard."); }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const overview   = dashboard?.overview            ?? {};
  const company    = dashboard?.company             ?? {};
  const modelUsage = dashboard?.modelUsageAnalytics ?? {};
  const docInsights= normDocInsights(dashboard?.documentInsights);
  const riskAna    = dashboard?.riskAnalytics       ?? {};
  const apiUsage   = dashboard?.apiUsage            ?? {};
  const security   = dashboard?.securityMonitoring  ?? {};
  const billing    = dashboard?.billing             ?? {};

  const stats = [
    { label: "Total Users",        value: compact(first(overview,["totalUsers","totalEmployees"])), icon:"U",  tone:"gold",    helper:"Users across the workspace"        },
    { label: "Documents Analyzed", value: compact(first(overview,["documentsAnalyzed","totalDocumentsAnalyzed"])), icon:"D", tone:"blue", helper:"Reviewed by the platform" },
    { label: "AI Requests",        value: compact(first(overview,["aiRequests"])),                  icon:"AI", tone:"emerald", helper:"Requests to model layer"           },
    { label: "Risky Clauses",      value: compact(first(overview,["riskyClauses","riskClausesDetected"])), icon:"!", tone:"rose", helper:"Issues flagged for review"     },
  ];

  const modelCards = [
    { title:"AI Requests",    subtitle:"Request volume from the analytics API.",    helper:"Usage",   type:"bar",   data:normSeries(modelUsage.aiRequests ?? modelUsage.aiRequestsPerDay,"AI Requests") },
    { title:"Token Usage",    subtitle:"Input and output tokens consumed.",          helper:"Tokens",  type:"donut", data:normSeries(modelUsage.tokenUsage,"Token Usage") },
    { title:"Estimated Cost", subtitle:"Current spend across model usage.",         helper:"Cost",    type:"bar",   data:normSeries(modelUsage.estimatedCost,"Estimated Cost") },
    { title:"Response Time",  subtitle:"Average latency for model-backed operations.", helper:"Latency", type:"bar", data:normSeries(modelUsage.responseTime,"Response Time") },
  ];

  const riskData = [
    { label:"High",   value:toNum(first(riskAna,["high","highRiskClauses"]))   },
    { label:"Medium", value:toNum(first(riskAna,["medium","mediumRiskClauses"])) },
    { label:"Low",    value:toNum(first(riskAna,["low","lowRiskClauses"]))    },
  ];

  const apiMetrics = [
    ["Requests today",    compact(first(apiUsage,["requestsToday","totalRequests"]))],
    ["Success rate",      apiUsage.successRate != null ? pct(apiUsage.successRate) : pct(100 - toNum(apiUsage.errorRate ?? 0))],
    ["Avg response time", ms(first(apiUsage,["averageResponseTime","responseTimeMs","responseTime"]))],
  ];

  return (
    <div className="min-h-screen flex bg-dark-900">
      <Sidebar title="Enterprise Workspace" subtitle="B2B Dashboard" items={SIDEBAR_ITEMS} footerLabel="Enterprise telemetry live" />

      <main className="flex-1 p-5 md:p-8 lg:p-10 overflow-y-auto">
        <div className="max-w-7xl mx-auto flex flex-col gap-6">

          {/* Header */}
          <section className="card animate-fade-up bg-card-blue overflow-hidden">
            <p className="text-[10px] uppercase tracking-[0.22em] text-ink-muted mb-1.5">Company Dashboard</p>
            <h1 className="font-display text-3xl md:text-4xl font-bold text-ink-primary tracking-tight">
              {loading ? "Loading company analytics…" : (company.name ?? "Company overview")}
            </h1>
            <div className="flex gap-4 flex-wrap mt-3">
              {company.industry && <span className="badge badge-info">{company.industry}</span>}
              {(company.plan ?? company.currentPlan) && <span className="badge badge-gold">{company.plan ?? company.currentPlan}</span>}
            </div>
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

          {/* Model usage */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            {(loading ? Array(4).fill(null) : modelCards).map((c, i) =>
              c ? <ChartCard key={c.title} {...c} /> : <div key={i} className="card skeleton h-56" />
            )}
          </div>

          {/* Doc insights + risk */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
            {loading ? (
              <><div className="card skeleton h-56" /><div className="card skeleton h-56" /></>
            ) : (
              <>
                <ChartCard title="Document Insights" subtitle="Processed documents by category." helper="Volume" type="bar" data={docInsights} />
                <ChartCard title="Risk Analytics" subtitle="Clause severity distribution across analysed content." helper="Severity" type="donut" data={riskData} />
              </>
            )}
          </div>

          {/* Team + API usage */}
          <div className="grid grid-cols-1 lg:grid-cols-[1.5fr_1fr] gap-5">
            {loading ? <div className="card skeleton h-72" /> : <TeamTable members={team} />}
            <section className="card animate-fade-up">
              <div className="flex items-start justify-between mb-5">
                <div>
                  <h2 className="text-[15px] font-semibold text-ink-primary">API Usage</h2>
                  <p className="text-xs text-ink-secondary mt-0.5">Operational metrics for enterprise API consumption.</p>
                </div>
                <span className="text-[10px] text-ink-muted uppercase tracking-[0.2em]">Live</span>
              </div>
              <div className="flex flex-col gap-3">
                {loading
                  ? [...Array(3)].map((_, i) => <div key={i} className="skeleton h-16 rounded-xl" />)
                  : apiMetrics.map(([label, value]) => (
                    <div key={label} className="bg-dark-900/72 border border-dark-500 rounded-xl px-4 py-3.5">
                      <p className="text-[10px] uppercase tracking-[0.16em] text-ink-muted">{label}</p>
                      <p className="font-display text-2xl font-bold text-ink-primary mt-1.5">{value}</p>
                    </div>
                  ))
                }
              </div>
            </section>
          </div>

          {/* Activity */}
          {loading ? <div className="card skeleton h-60" /> : <ActivityLog title="Activity Logs" subtitle="Audit trail of admin and analyst actions." items={activity} />}
          {loading ? <div className="card skeleton h-44" /> : <SecurityPanel security={security} />}
          {loading ? <div className="card skeleton h-44" /> : <BillingPanel billing={billing} />}
        </div>
      </main>
    </div>
  );
}