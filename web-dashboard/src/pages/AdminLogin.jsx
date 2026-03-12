import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { adminLogin, registerUser } from "../services/api.js";
import { saveAuth, isLoggedIn } from "../services/auth.js";

export default function AdminLogin() {
  const navigate = useNavigate();
  const [mode,     setMode]     = useState("login");
  const [name,     setName]     = useState("");
  const [email,    setEmail]    = useState("");
  const [password, setPassword] = useState("");
  const [loading,  setLoading]  = useState(false);
  const [error,    setError]    = useState("");

  useEffect(() => {
    if (isLoggedIn()) navigate("/dashboard", { replace: true });
  }, [navigate]);

  const handleSubmit = async () => {
    setError("");
    if (!email.trim() || !password.trim()) { setError("Email and password are required."); return; }
    if (mode === "register" && !name.trim()) { setError("Name is required."); return; }
    setLoading(true);
    try {
      const data = mode === "login"
        ? await adminLogin(email.trim(), password)
        : await registerUser(name.trim(), email.trim(), password);
      saveAuth(data);
      navigate("/dashboard");
    } catch (err) {
      setError(err.message || "Authentication failed. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-dark-900 flex items-center justify-center p-5 relative overflow-hidden">
      {/* Glow */}
      <div aria-hidden className="fixed top-[-20%] left-1/2 -translate-x-1/2 w-[70vw] h-[70vw] max-w-[700px] max-h-[700px] rounded-full pointer-events-none"
        style={{ background: "radial-gradient(circle, rgba(201,169,110,0.06) 0%, transparent 70%)" }} />

      <div className="w-full max-w-[420px] animate-scale-in">
        <div className="bg-dark-800 border border-dark-500 rounded-4xl px-9 py-10 shadow-card-lg">
          {/* Logo */}
          <div className="text-center mb-9">
            <div className="w-[52px] h-[52px] rounded-[14px] bg-gold-diagonal flex items-center justify-center text-2xl mx-auto mb-5 shadow-glow-gold">
              ⚖️
            </div>
            <h1 className="font-display text-[30px] font-bold text-ink-primary mb-1.5 tracking-tight">LexNova</h1>
            <p className="text-[13px] text-ink-secondary">
              {mode === "login" ? "Sign in to your account" : "Create your account"}
            </p>
          </div>

          {/* Mode toggle */}
          <div className="flex bg-dark-700 border border-dark-500 rounded-[10px] p-1 mb-7">
            {["login", "register"].map((m) => (
              <button
                key={m}
                onClick={() => { setMode(m); setError(""); }}
                className={[
                  "flex-1 py-2 rounded-[7px] text-[13px] border-none cursor-pointer transition-all duration-200",
                  mode === m
                    ? "bg-dark-500 text-ink-primary font-medium"
                    : "bg-transparent text-ink-muted hover:text-ink-secondary",
                ].join(" ")}
              >
                {m === "login" ? "Sign in" : "Register"}
              </button>
            ))}
          </div>

          {/* Fields */}
          <div className="flex flex-col gap-3.5">
            {mode === "register" && (
              <div>
                <label className="block text-[11px] font-medium text-ink-secondary uppercase tracking-[0.1em] mb-1.5">Full name</label>
                <input className="lex-input" type="text" placeholder="Jane Smith" value={name}
                  onChange={(e) => setName(e.target.value)} onKeyDown={(e) => e.key === "Enter" && handleSubmit()} autoComplete="name" />
              </div>
            )}
            <div>
              <label className="block text-[11px] font-medium text-ink-secondary uppercase tracking-[0.1em] mb-1.5">Email address</label>
              <input className="lex-input" type="email" placeholder="you@example.com" value={email}
                onChange={(e) => setEmail(e.target.value)} onKeyDown={(e) => e.key === "Enter" && handleSubmit()} autoComplete="email" />
            </div>
            <div>
              <label className="block text-[11px] font-medium text-ink-secondary uppercase tracking-[0.1em] mb-1.5">Password</label>
              <input className="lex-input" type="password"
                placeholder={mode === "register" ? "Minimum 6 characters" : "••••••••"}
                value={password} onChange={(e) => setPassword(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleSubmit()}
                autoComplete={mode === "login" ? "current-password" : "new-password"} />
            </div>
          </div>

          {/* Error */}
          {error && (
            <div className="mt-4 px-3.5 py-2.5 rounded-[9px] bg-rose-500/8 border border-rose-500/20 text-[13px] text-rose-400 flex items-center gap-2">
              <span>⚠</span> {error}
            </div>
          )}

          {/* Submit */}
          <button className="btn-gold w-full mt-6 !py-3.5 !text-sm" onClick={handleSubmit} disabled={loading}>
            {loading ? (
              <span className="flex items-center justify-center gap-2">
                <span className="spinner w-4 h-4" />
                {mode === "login" ? "Signing in…" : "Creating account…"}
              </span>
            ) : (
              mode === "login" ? "Sign in →" : "Create account →"
            )}
          </button>

          {/* Links */}
          <div className="mt-5 pt-5 border-t border-dark-500 flex justify-center gap-4">
            {[
              { label: "← Back to home",  onClick: () => navigate("/")               },
              { label: "Admin console →", onClick: () => navigate("/admin-dashboard") },
            ].map(({ label, onClick }) => (
              <button key={label} onClick={onClick}
                className="text-xs text-ink-muted bg-transparent border-0 cursor-pointer hover:text-gold-400 transition-colors">
                {label}
              </button>
            ))}
          </div>
        </div>

        <p className="text-center text-[11px] text-ink-muted mt-5 leading-relaxed px-4">
          By signing in you agree that LexNova provides AI assistance only and is not a substitute for professional legal advice.
        </p>
      </div>
    </div>
  );
}