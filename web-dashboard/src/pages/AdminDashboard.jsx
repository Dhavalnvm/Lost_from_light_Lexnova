import { useCallback, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { API_BASE_URL } from "../services/api.js";
import { clearAuth, isLoggedIn } from "../services/auth.js";

const BASE = API_BASE_URL;
const NH   = { "ngrok-skip-browser-warning": "true" };

const fetchHealth   = async () => { const r = await fetch(`${BASE}/health`, { headers: NH }); if (!r.ok) throw new Error(`Health failed (${r.status})`); return r.json(); };
const fetchDocTypes = async () => { const r = await fetch(`${BASE}/api/v1/document-types`, { headers: NH }); if (!r.ok) throw new Error(`Doc types failed (${r.status})`); return r.json(); };
const fetchRoot     = async () => { const r = await fetch(`${BASE}/`, { headers: NH }); if (!r.ok) throw new Error(`Root failed (${r.status})`); return r.json(); };

function StatusDot({ ok }) {
  return (
    <span className={[
      "inline-block w-2 h-2 rounded-full shrink-0",
      ok ? "bg-emerald-400 shadow-glow-emerald animate-pulse-dot" : "bg-rose-400 shadow-glow-rose",
    ].join(" ")} />
  );
}

function InfoRow({ label, children }) {
  return (
    <div className="flex items-center justify-between py-3 border-b border-dark-600 last:border-0 text-[13px] gap-3">
      <span className="text-ink-secondary">{label}</span>
      <span className="text-ink-primary font-medium flex items-center gap-2">{children}</span>
    </div>
  );
}

const ENDPOINTS = [
  { method:"GET",  path:"/",                                      desc:"App info & version"                   },
  { method:"GET",  path:"/health",                                desc:"Ollama + server health"               },
  { method:"GET",  path:"/api/v1/document-types",                 desc:"List all document categories"        },
  { method:"POST", path:"/api/v1/upload-document",                desc:"Upload & process PDF/DOCX"           },
  { method:"GET",  path:"/api/v1/analyze-stream/{document_id}",   desc:"SSE — summary, risk, fairness, safety"},
  { method:"GET",  path:"/api/v1/document-summary/{document_id}", desc:"Plain-language summary"             },
  { method:"GET",  path:"/api/v1/risk-analysis/{document_id}",    desc:"Red flags & risk score"              },
  { method:"GET",  path:"/api/v1/clause-fairness/{document_id}",  desc:"Clause fairness rating"              },
  { method:"GET",  path:"/api/v1/safety-score/{document_id}",     desc:"Overall safety score (0–100)"       },
  { method:"POST", path:"/api/v1/chat-with-document",             desc:"RAG Q&A on a document"               },
  { method:"POST", path:"/api/v1/legal-chat",                     desc:"General legal chatbot"               },
  { method:"POST", path:"/api/v1/translate",                      desc:"Multi-language translation"         },
];

const NAV_GROUPS = [
  { section:"Overview",  items:[{icon:"📊",label:"Dashboard",active:true},{icon:"🩺",label:"System Health"}] },
  { section:"Platform",  items:[{icon:"📄",label:"Document Types"},{icon:"🤖",label:"AI Endpoints"},{icon:"⚖️",label:"Legal Chatbot"},{icon:"🌐",label:"Translation"}] },
  { section:"System",    items:[{icon:"📋",label:"API Docs"},{icon:"📁",label:"Logs"}] },
];

export default function AdminDashboard() {
  const navigate = useNavigate();
  useEffect(() => { if (!isLoggedIn()) navigate("/admin-login"); }, [navigate]);

  const [health,       setHealth]       = useState(null);
  const [docTypes,     setDocTypes]     = useState(null);
  const [appInfo,      setAppInfo]      = useState(null);
  const [docTypesErr,  setDocTypesErr]  = useState("");
  const [loading,      setLoading]      = useState(true);
  const [error,        setError]        = useState("");
  const [lastRefresh,  setLastRefresh]  = useState(null);

  const load = useCallback(async () => {
    setLoading(true); setError(""); setDocTypesErr("");
    try {
      const [hRes, dRes, aRes] = await Promise.allSettled([fetchHealth(), fetchDocTypes(), fetchRoot()]);
      if (hRes.status !== "fulfilled") throw hRes.reason;
      if (aRes.status !== "fulfilled") throw aRes.reason;
      setHealth(hRes.value); setAppInfo(aRes.value);
      if (dRes.status === "fulfilled") { setDocTypes(dRes.value); }
      else { setDocTypes(null); setDocTypesErr(dRes.reason?.message || "Document types unavailable."); }
      setLastRefresh(new Date());
    } catch (err) { setError(err.message); }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const totalCats  = docTypes ? Object.keys(docTypes).length : 0;
  const totalTypes = docTypes ? Object.values(docTypes).flat().length : 0;

  const localStats = [
    { label:"Backend Status", value: loading ? "—" : (health?.status === "healthy" ? "Healthy" : "Degraded"), icon:"🩺", colorBg: health?.status==="healthy" ? "bg-emerald-400/10" : "bg-rose-400/10" },
    { label:"Ollama LLM",     value: loading ? "—" : (health?.ollama === "connected" ? "Connected" : "Offline"), icon:"🤖", colorBg:"bg-blue-400/10", sub: health?.model_smart ?? health?.model ?? "" },
    { label:"Doc Categories", value: loading ? "—" : String(totalCats),  icon:"📂", colorBg:"bg-gold-400/10", sub:"Supported types" },
    { label:"Templates",      value: loading ? "—" : String(totalTypes), icon:"📄", colorBg:"bg-violet-400/10", sub:"Across all categories" },
  ];

  return (
    <div className="min-h-screen flex flex-col bg-dark-900">
      {/* Navbar */}
      <nav className="h-[60px] bg-dark-800 border-b border-dark-500 flex items-center justify-between px-6 shrink-0 sticky top-0 z-40">
        <div className="flex items-center gap-2.5">
          <div className="w-[34px] h-[34px] rounded-[9px] bg-gold-diagonal flex items-center justify-center text-base">⚖️</div>
          <span className="font-display text-xl font-semibold text-ink-primary">Lex</span>
          <span className="badge badge-gold text-[10px] tracking-[0.1em]">Admin</span>
        </div>
        <div className="flex items-center gap-3">
          {lastRefresh && <span className="text-[11px] text-ink-muted">Updated {lastRefresh.toLocaleTimeString()}</span>}
          <button className="btn-ghost !py-1.5 !px-3.5 !text-xs" onClick={load} disabled={loading}>
            {loading ? <span className="spinner w-3 h-3" /> : "↻"} Refresh
          </button>
          <button
            onClick={() => { clearAuth(); navigate("/admin-login"); }}
            className="flex items-center gap-1.5 bg-red-500/8 border border-red-500/20 rounded-lg px-3.5 py-1.5 text-[12px] text-rose-400 cursor-pointer hover:bg-red-500/14 transition-colors"
          >
            ⎋ Logout
          </button>
        </div>
      </nav>

      <div className="flex flex-1 overflow-hidden">
        {/* Sidebar */}
        <aside className="w-[220px] shrink-0 bg-dark-800 border-r border-dark-500 flex flex-col overflow-y-auto">
          <div className="p-3 flex flex-col gap-1 flex-1">
            {NAV_GROUPS.map(({ section, items }) => (
              <div key={section}>
                <p className="text-[10px] font-medium text-ink-muted uppercase tracking-[0.14em] px-2.5 pt-3 pb-1.5">{section}</p>
                {items.map(({ icon, label, active }) => (
                  <div key={label}
                    className={[
                      "flex items-center gap-2.5 px-3 py-2.5 rounded-[9px] mb-0.5 text-[13px] cursor-pointer transition-all duration-150 border",
                      active ? "bg-gold-500/10 border-gold-500/15 text-gold-400" : "bg-transparent border-transparent text-ink-secondary hover:bg-dark-700 hover:text-ink-primary",
                    ].join(" ")}
                  >
                    <span className="text-[15px]">{icon}</span> {label}
                  </div>
                ))}
              </div>
            ))}
          </div>
          <div className="p-4 border-t border-dark-500 text-center">
            <p className="text-[11px] text-ink-muted leading-relaxed">
              Legal AI Backend<br />
              <span className="text-gold-400">{appInfo?.version ?? "—"}</span>
            </p>
          </div>
        </aside>

        {/* Main */}
        <main className="flex-1 overflow-y-auto p-7 flex flex-col gap-6">
          {/* Header */}
          <div className="animate-fade-up">
            <h1 className="font-display text-3xl font-bold text-gold-gradient tracking-tight">Dashboard</h1>
            <p className="text-[13px] text-ink-secondary mt-1">Read-only overview of the LexNova Legal AI platform</p>
          </div>

          {/* Error */}
          {error && (
            <div className="flex items-center gap-3 bg-red-500/7 border border-red-500/20 rounded-xl p-4 text-[13px] text-rose-400 animate-fade-up">
              <span className="text-lg">⚠️</span>
              <div className="flex-1">
                <p className="font-medium">Could not reach backend</p>
                <p className="text-xs opacity-75 mt-0.5">{error} — check server on {BASE}</p>
              </div>
              <button onClick={load} className="bg-red-500/15 border border-red-500/25 text-rose-400 rounded-lg px-3 py-1.5 text-xs cursor-pointer">Retry</button>
            </div>
          )}

          {/* Stat cards */}
          <div className="grid grid-cols-4 gap-4 stagger">
            {localStats.map((s, i) => (
              <div key={i} className="card card-hover animate-fade-up flex flex-col gap-3">
                <div className="flex items-center justify-between">
                  <span className="text-[10px] text-ink-secondary uppercase tracking-[0.12em] font-medium">{s.label}</span>
                  <div className={`w-8 h-8 rounded-[9px] ${s.colorBg} flex items-center justify-center text-base`}>{s.icon}</div>
                </div>
                {loading ? <div className="skeleton h-7 w-[55%] rounded" /> : (
                  <p className="font-display text-[26px] font-bold text-ink-primary tracking-tight">{s.value}</p>
                )}
                {s.sub && <p className="text-[11px] text-ink-muted">{s.sub}</p>}
              </div>
            ))}
          </div>

          {/* 2-col: health + app info */}
          <div className="grid grid-cols-2 gap-4">
            <div className="card animate-fade-up">
              <div className="flex items-center justify-between pb-4 border-b border-dark-500 mb-0.5">
                <div>
                  <h2 className="text-sm font-semibold text-ink-primary">System Health</h2>
                  <p className="text-xs text-ink-secondary mt-0.5">Live from /health endpoint</p>
                </div>
              </div>
              {loading ? (
                <div className="flex flex-col gap-3.5 pt-3">
                  {[...Array(4)].map((_, i) => <div key={i} className="skeleton h-4 rounded" style={{ width: `${70+i*5}%` }} />)}
                </div>
              ) : health ? (
                <>
                  <InfoRow label="Status"><StatusDot ok={health.status==="healthy"} />{health.status}</InfoRow>
                  <InfoRow label="Ollama"><StatusDot ok={health.ollama==="connected"} />{health.ollama}</InfoRow>
                  {health.ollama_url && <InfoRow label="Ollama URL"><span className="font-mono text-xs">{health.ollama_url}</span></InfoRow>}
                  <InfoRow label="Model (smart)"><span className="font-mono text-xs">{health.model_smart ?? health.model ?? "—"}</span></InfoRow>
                  {health.model_fast && <InfoRow label="Model (fast)"><span className="font-mono text-xs">{health.model_fast}</span></InfoRow>}
                </>
              ) : <p className="text-xs text-ink-muted pt-3">No data available</p>}
            </div>

            <div className="card animate-fade-up">
              <div className="flex items-center justify-between pb-4 border-b border-dark-500 mb-0.5">
                <div>
                  <h2 className="text-sm font-semibold text-ink-primary">Application Info</h2>
                  <p className="text-xs text-ink-secondary mt-0.5">From / root endpoint</p>
                </div>
              </div>
              {loading ? (
                <div className="flex flex-col gap-3.5 pt-3">
                  {[...Array(4)].map((_, i) => <div key={i} className="skeleton h-4 rounded" style={{ width: `${65+i*7}%` }} />)}
                </div>
              ) : appInfo ? (
                <>
                  <InfoRow label="Name">{appInfo.name}</InfoRow>
                  <InfoRow label="Version"><span className="badge badge-gold">v{appInfo.version}</span></InfoRow>
                  <InfoRow label="Status"><StatusDot ok={appInfo.status==="running"} />{appInfo.status}</InfoRow>
                  <InfoRow label="API Docs">
                    <a href={`${BASE}/docs`} target="_blank" rel="noreferrer" className="text-gold-400 text-xs hover:underline">
                      {BASE}/docs ↗
                    </a>
                  </InfoRow>
                </>
              ) : <p className="text-xs text-ink-muted pt-3">No data available</p>}
            </div>
          </div>

          {/* API Endpoints */}
          <div className="card animate-fade-up !p-0 overflow-hidden">
            <div className="flex items-center justify-between px-5 py-4 border-b border-dark-500">
              <div>
                <h2 className="text-sm font-semibold text-ink-primary">API Endpoints</h2>
                <p className="text-xs text-ink-secondary mt-0.5">All available routes — read-only view</p>
              </div>
              <span className="badge badge-gold">{ENDPOINTS.length} routes</span>
            </div>
            {ENDPOINTS.map((ep, i) => (
              <div key={i}
                className="flex items-center gap-3 px-5 py-2.5 border-b border-dark-600 last:border-0 text-xs hover:bg-white/[0.015] transition-colors">
                <span className={[
                  "text-[10px] font-bold px-1.5 py-0.5 rounded tracking-[0.06em] shrink-0 border",
                  ep.method === "GET"
                    ? "bg-emerald-400/12 text-emerald-400 border-emerald-400/20"
                    : "bg-blue-400/12 text-blue-400 border-blue-400/20",
                ].join(" ")}>
                  {ep.method}
                </span>
                <span className="text-ink-primary font-mono flex-1">{ep.path}</span>
                <span className="text-ink-muted text-right">{ep.desc}</span>
              </div>
            ))}
          </div>

          {/* Document categories */}
          <div className="card animate-fade-up !p-0 overflow-hidden">
            <div className="flex items-center justify-between px-5 py-4 border-b border-dark-500">
              <div>
                <h2 className="text-sm font-semibold text-ink-primary">Supported Document Categories</h2>
                <p className="text-xs text-ink-secondary mt-0.5">From /api/v1/document-types</p>
              </div>
              <span className="badge badge-gold">
                {loading ? "…" : `${totalCats} categories · ${totalTypes} types`}
              </span>
            </div>
            {loading ? (
              <div className="grid grid-cols-[repeat(auto-fill,minmax(180px,1fr))] gap-3 p-5">
                {[...Array(6)].map((_, i) => <div key={i} className="skeleton h-32 rounded-xl" />)}
              </div>
            ) : docTypes && totalCats > 0 ? (
              <div className="grid grid-cols-[repeat(auto-fill,minmax(180px,1fr))] gap-3 p-5">
                {Object.entries(docTypes).map(([cat, types]) => (
                  <div key={cat} className="bg-dark-700 border border-dark-600 rounded-xl p-4 card-hover cursor-default">
                    <p className="text-[13px] font-medium text-ink-primary mb-1.5 capitalize">
                      {cat.replace(/_/g, " ")}
                    </p>
                    <span className="badge badge-gold mb-2.5">{types.length} types</span>
                    <div className="flex flex-wrap gap-1 mt-2">
                      {types.map((t) => (
                        <span key={t} className="text-[10px] text-ink-muted bg-dark-600 rounded px-1.5 py-0.5 leading-relaxed">
                          {t}
                        </span>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="px-6 py-6 text-xs text-ink-muted">{docTypesErr || "No categories loaded"}</p>
            )}
          </div>
        </main>
      </div>
    </div>
  );
}