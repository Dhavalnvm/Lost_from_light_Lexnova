import { useState, useEffect, useRef } from "react";

const features = [
  {
    icon: "⚖️",
    color: "#e8ddd0",
    accent: "#b5935a",
    title: "Ask Lex Anything",
    desc: "General legal guidance, instantly. Not a lawyer — but fluent in law. Get clear answers to complex legal questions.",
  },
  {
    icon: "📄",
    color: "#dce8e0",
    accent: "#4a8c6a",
    title: "Document Analyzer",
    desc: "Upload any contract, lease, or agreement. Lex reads the fine print so you don't have to — flagging risks in seconds.",
  },
  {
    icon: "🏠",
    color: "#dde4f0",
    accent: "#4a6aac",
    title: "Housing & Property",
    desc: "Rent, buy, lease with confidence. Understand your rights before signing anything.",
  },
  {
    icon: "💼",
    color: "#f0e8dd",
    accent: "#b56a2a",
    title: "Employment Law",
    desc: "Jobs, NDAs, contracts. Know exactly what you're agreeing to before it's too late.",
  },
  {
    icon: "🏦",
    color: "#e0edd8",
    accent: "#5a8a3a",
    title: "Loans & Finance",
    desc: "Home, personal, car loans. Decode complex financial agreements with plain-language explanations.",
  },
  {
    icon: "🛡️",
    color: "#ede8d8",
    accent: "#a08040",
    title: "Insurance Guidance",
    desc: "Health, life, property. Understand your coverage — and what's buried in the exclusions.",
  },
];

const faqs = [
  {
    q: "Is Lex a real lawyer?",
    a: "No — Lex is an AI legal assistant. It provides general legal information and guidance, but does not constitute legal advice. For complex matters, always consult a qualified attorney.",
  },
  {
    q: "What documents can I analyze?",
    a: "Lex can analyze rental agreements, employment contracts, NDAs, loan documents, insurance policies, partnership agreements, and most standard legal documents.",
  },
  {
    q: "Is my data private?",
    a: "Your documents and conversations are encrypted and never shared with third parties. We take privacy seriously — your legal matters stay yours.",
  },
  {
    q: "Which languages does Lex support?",
    a: "Lex currently supports English, Hindi, and several regional Indian languages, with more being added regularly.",
  },
];

const categories = [
  { label: "Housing & Property", icon: "🏠", sub: "Rent, buy, lease" },
  { label: "Loans & Finance", icon: "🏦", sub: "Home, personal, car" },
  { label: "Employment", icon: "💼", sub: "Jobs, NDAs, contracts" },
  { label: "Business", icon: "📊", sub: "GST, partnerships" },
  { label: "Education", icon: "🎓", sub: "Admissions, scholarships" },
  { label: "Insurance", icon: "🛡️", sub: "Health, life, property" },
];

function AnimatedNumber({ target, suffix = "" }) {
  const [val, setVal] = useState(0);
  const ref = useRef(null);
  useEffect(() => {
    const obs = new IntersectionObserver(([e]) => {
      if (e.isIntersecting) {
        let start = 0;
        const step = target / 60;
        const t = setInterval(() => {
          start += step;
          if (start >= target) { setVal(target); clearInterval(t); }
          else setVal(Math.floor(start));
        }, 16);
      }
    }, { threshold: 0.5 });
    if (ref.current) obs.observe(ref.current);
    return () => obs.disconnect();
  }, [target]);
  return <span ref={ref}>{val.toLocaleString()}{suffix}</span>;
}

export default function LexLanding() {
  const [openFaq, setOpenFaq] = useState(null);
  const [question, setQuestion] = useState("");
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40);
    window.addEventListener("scroll", onScroll);
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <div style={{
      fontFamily: "'Cormorant Garamond', 'Georgia', serif",
      background: "#f5f0ea",
      color: "#1a1612",
      minHeight: "100vh",
      overflowX: "hidden",
    }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,500&family=DM+Sans:wght@300;400;500&display=swap');
        * { box-sizing: border-box; margin: 0; padding: 0; }
        ::selection { background: #c9a96e40; }
        html { scroll-behavior: smooth; }

        @keyframes fadeUp {
          from { opacity: 0; transform: translateY(32px); }
          to { opacity: 1; transform: translateY(0); }
        }
        @keyframes fadeIn {
          from { opacity: 0; } to { opacity: 1; }
        }
        @keyframes float {
          0%, 100% { transform: translateY(0px); }
          50% { transform: translateY(-10px); }
        }
        @keyframes shimmer {
          0% { background-position: -200% center; }
          100% { background-position: 200% center; }
        }
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.4; }
        }

        .fade-up { animation: fadeUp 0.8s ease forwards; }
        .fade-up-d1 { animation: fadeUp 0.8s 0.15s ease both; }
        .fade-up-d2 { animation: fadeUp 0.8s 0.3s ease both; }
        .fade-up-d3 { animation: fadeUp 0.8s 0.45s ease both; }
        .fade-up-d4 { animation: fadeUp 0.8s 0.6s ease both; }

        .feature-card {
          background: white;
          border-radius: 20px;
          padding: 32px 28px;
          transition: transform 0.3s ease, box-shadow 0.3s ease;
          cursor: default;
          border: 1px solid #ece5db;
        }
        .feature-card:hover {
          transform: translateY(-6px);
          box-shadow: 0 20px 60px #b5935a18;
        }

        .category-chip {
          background: white;
          border-radius: 16px;
          padding: 20px 18px;
          display: flex;
          align-items: center;
          gap: 14px;
          border: 1px solid #ece5db;
          transition: all 0.25s ease;
          cursor: pointer;
        }
        .category-chip:hover {
          background: #fffaf5;
          border-color: #c9a96e;
          transform: translateX(4px);
        }

        .cta-btn {
          background: #b5935a;
          color: white;
          border: none;
          border-radius: 50px;
          padding: 16px 40px;
          font-family: 'DM Sans', sans-serif;
          font-size: 15px;
          font-weight: 500;
          cursor: pointer;
          transition: all 0.25s ease;
          letter-spacing: 0.03em;
        }
        .cta-btn:hover {
          background: #9a7a48;
          transform: translateY(-2px);
          box-shadow: 0 12px 30px #b5935a35;
        }

        .outline-btn {
          background: transparent;
          color: #b5935a;
          border: 1.5px solid #b5935a;
          border-radius: 50px;
          padding: 15px 38px;
          font-family: 'DM Sans', sans-serif;
          font-size: 15px;
          font-weight: 500;
          cursor: pointer;
          transition: all 0.25s ease;
          letter-spacing: 0.03em;
        }
        .outline-btn:hover {
          background: #b5935a10;
          transform: translateY(-2px);
        }

        .nav-link {
          font-family: 'DM Sans', sans-serif;
          font-size: 14px;
          color: #5a4a38;
          text-decoration: none;
          transition: color 0.2s;
          letter-spacing: 0.02em;
        }
        .nav-link:hover { color: #b5935a; }

        .faq-item {
          border-bottom: 1px solid #ece5db;
          padding: 24px 0;
          cursor: pointer;
        }
        .faq-item:last-child { border-bottom: none; }

        .phone-mockup {
          animation: float 4s ease-in-out infinite;
        }

        .stat-number {
          font-size: clamp(40px, 6vw, 72px);
          font-weight: 700;
          color: #b5935a;
          line-height: 1;
          letter-spacing: -0.02em;
        }

        .section-label {
          font-family: 'DM Sans', sans-serif;
          font-size: 11px;
          letter-spacing: 0.18em;
          text-transform: uppercase;
          color: #b5935a;
          font-weight: 500;
        }

        .gradient-text {
          background: linear-gradient(135deg, #b5935a 0%, #d4a96a 50%, #9a7040 100%);
          background-size: 200% auto;
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
          background-clip: text;
          animation: shimmer 4s linear infinite;
        }

        .tag-pill {
          display: inline-flex;
          align-items: center;
          gap: 6px;
          background: #b5935a15;
          border: 1px solid #b5935a30;
          border-radius: 100px;
          padding: 6px 14px;
          font-family: 'DM Sans', sans-serif;
          font-size: 12px;
          color: #8a6a3a;
          font-weight: 500;
        }

        .dot-live {
          width: 7px; height: 7px;
          background: #5cb85c;
          border-radius: 50%;
          animation: pulse 2s ease infinite;
          display: inline-block;
        }

        input:focus { outline: none; }
        textarea:focus { outline: none; }
      `}</style>

      {/* NAV */}
      <nav style={{
        position: "fixed", top: 0, left: 0, right: 0, zIndex: 100,
        padding: "0 40px",
        height: 68,
        display: "flex", alignItems: "center", justifyContent: "space-between",
        background: scrolled ? "rgba(245,240,234,0.92)" : "transparent",
        backdropFilter: scrolled ? "blur(12px)" : "none",
        borderBottom: scrolled ? "1px solid #ece5db" : "none",
        transition: "all 0.3s ease",
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{
            width: 36, height: 36, background: "#b5935a",
            borderRadius: 10, display: "flex", alignItems: "center", justifyContent: "center",
            fontSize: 18,
          }}>⚖️</div>
          <span style={{ fontSize: 22, fontWeight: 600, letterSpacing: "-0.01em" }}>Lex</span>
        </div>
        <div style={{ display: "flex", gap: 36, alignItems: "center" }}>
          {["Features", "How It Works", "Pricing", "FAQ"].map(l => (
            <a key={l} href={`#${l.toLowerCase().replace(/ /g, "-")}`} className="nav-link">{l}</a>
          ))}
        </div>
        <div style={{ display: "flex", gap: 12 }}>
          <button className="outline-btn" style={{ padding: "10px 24px", fontSize: 13 }}>Log in</button>
          <button className="cta-btn" style={{ padding: "10px 24px", fontSize: 13 }}>Download App</button>
        </div>
      </nav>

      {/* HERO */}
      <section style={{
        minHeight: "100vh",
        display: "flex", alignItems: "center",
        padding: "100px 80px 60px",
        maxWidth: 1200, margin: "0 auto",
        gap: 80,
        position: "relative",
      }}>
        {/* BG decoration */}
        <div style={{
          position: "absolute", top: 120, right: -60,
          width: 500, height: 500,
          background: "radial-gradient(circle, #b5935a12 0%, transparent 70%)",
          borderRadius: "50%", pointerEvents: "none",
        }} />
        <div style={{
          position: "absolute", bottom: 60, left: -80,
          width: 350, height: 350,
          background: "radial-gradient(circle, #c9a96e0e 0%, transparent 70%)",
          borderRadius: "50%", pointerEvents: "none",
        }} />

        {/* Left text */}
        <div style={{ flex: 1, maxWidth: 560 }}>
          <div className="fade-up" style={{ marginBottom: 24 }}>
            <span className="tag-pill"><span className="dot-live" />AI-Powered · Free to Try</span>
          </div>

          <h1 className="fade-up-d1" style={{
            fontSize: "clamp(48px, 6vw, 82px)",
            fontWeight: 700,
            lineHeight: 1.08,
            letterSpacing: "-0.02em",
            marginBottom: 24,
          }}>
            Legal clarity,<br />
            <span className="gradient-text">without the fees.</span>
          </h1>

          <p className="fade-up-d2" style={{
            fontFamily: "'DM Sans', sans-serif",
            fontSize: 17,
            color: "#6a5a48",
            lineHeight: 1.7,
            marginBottom: 36,
            fontWeight: 300,
            maxWidth: 440,
          }}>
            Meet Lex — your AI legal assistant. Ask anything about contracts, housing, employment, or business law. Not a lawyer, but fluent in law.
          </p>

          <div className="fade-up-d3" style={{ display: "flex", gap: 14, marginBottom: 56, flexWrap: "wrap" }}>
            <button className="cta-btn">Get Started Free</button>
            <button className="outline-btn">Watch Demo</button>
          </div>

          <div className="fade-up-d4" style={{
            display: "flex", gap: 48,
            borderTop: "1px solid #ece5db",
            paddingTop: 36,
          }}>
            {[["50K+", "Documents Analyzed"], ["4.9★", "App Rating"], ["6", "Legal Categories"]].map(([n, l]) => (
              <div key={l}>
                <div style={{ fontSize: 28, fontWeight: 700, color: "#b5935a", letterSpacing: "-0.02em" }}>{n}</div>
                <div style={{ fontFamily: "'DM Sans', sans-serif", fontSize: 12, color: "#9a8a78", marginTop: 2 }}>{l}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Phone mockup */}
        <div style={{ flex: "0 0 auto", display: "flex", gap: 20, alignItems: "center" }}>
          {/* Phone 1 */}
          <div className="phone-mockup" style={{
            width: 220, background: "#f5f0ea",
            borderRadius: 36,
            border: "2px solid #ece5db",
            boxShadow: "0 40px 80px #1a161225, 0 0 0 1px #b5935a10",
            overflow: "hidden",
            transform: "rotate(-4deg) translateY(20px)",
          }}>
            <div style={{ background: "#1a1612", height: 32, display: "flex", alignItems: "center", justifyContent: "center" }}>
              <div style={{ width: 60, height: 8, background: "#333", borderRadius: 4 }} />
            </div>
            <div style={{ padding: "20px 16px", background: "#f5f0ea", minHeight: 420 }}>
              <div style={{ fontSize: 18, fontWeight: 700, marginBottom: 4 }}>Document Guide</div>
              <div style={{ fontFamily: "DM Sans", fontSize: 11, color: "#9a8a78", marginBottom: 16 }}>What do you need today?</div>
              {[
                { icon: "🏠", bg: "#dde4f0", label: "Housing & Property", sub: "Rent, buy, lease..." },
                { icon: "🏦", bg: "#dce8e0", label: "Loans & Finance", sub: "Home, personal..." },
                { icon: "💼", bg: "#f0e8dd", label: "Employment", sub: "Jobs, NDAs..." },
                { icon: "📊", bg: "#f0ddf0", label: "Business", sub: "GST, partnerships..." },
              ].map(c => (
                <div key={c.label} style={{
                  background: "white", borderRadius: 12, padding: "12px 10px",
                  marginBottom: 8, display: "flex", gap: 10, alignItems: "center",
                  border: "1px solid #ece5db",
                }}>
                  <div style={{
                    width: 32, height: 32, background: c.bg,
                    borderRadius: 8, display: "flex", alignItems: "center", justifyContent: "center",
                    fontSize: 14,
                  }}>{c.icon}</div>
                  <div>
                    <div style={{ fontFamily: "DM Sans", fontSize: 11, fontWeight: 600 }}>{c.label}</div>
                    <div style={{ fontFamily: "DM Sans", fontSize: 10, color: "#9a8a78" }}>{c.sub}</div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Phone 2 */}
          <div className="phone-mockup" style={{
            width: 230, background: "#f5f0ea",
            borderRadius: 36,
            border: "2px solid #ece5db",
            boxShadow: "0 40px 80px #1a161235, 0 0 0 1px #b5935a18",
            overflow: "hidden",
            animationDelay: "1s",
          }}>
            <div style={{ background: "#1a1612", height: 32, display: "flex", alignItems: "center", justifyContent: "center" }}>
              <div style={{ width: 60, height: 8, background: "#333", borderRadius: 4 }} />
            </div>
            <div style={{ padding: "20px 16px", background: "#f5f0ea", minHeight: 440 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 20 }}>
                <div style={{
                  width: 32, height: 32, background: "#e8ddd0",
                  borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 14,
                }}>⚖️</div>
                <div>
                  <div style={{ fontWeight: 700, fontSize: 14 }}>Lex</div>
                  <div style={{ display: "flex", alignItems: "center", gap: 4, fontFamily: "DM Sans", fontSize: 10, color: "#5cb85c" }}>
                    <span className="dot-live" style={{ width: 5, height: 5 }} />AI Legal Assistant
                  </div>
                </div>
              </div>
              <div style={{ textAlign: "center", marginBottom: 20 }}>
                <div style={{
                  width: 52, height: 52, background: "#e8ddd0",
                  borderRadius: "50%", display: "flex", alignItems: "center",
                  justifyContent: "center", fontSize: 22, margin: "0 auto 12px",
                }}>⚖️</div>
                <div style={{ fontSize: 18, fontWeight: 700, lineHeight: 1.2, marginBottom: 6 }}>Ask Lex Anything</div>
                <div style={{ fontFamily: "DM Sans", fontSize: 11, color: "#9a8a78", lineHeight: 1.5 }}>
                  General legal guidance,<br />instantly. Not a lawyer —<br />but fluent in law.
                </div>
              </div>
              <div style={{ fontFamily: "DM Sans", fontSize: 9, color: "#b5935a", letterSpacing: "0.12em", marginBottom: 10 }}>SUGGESTED QUESTIONS</div>
              {[
                { icon: "💼", cat: "EMPLOYMENT", q: "What is a non-compete clause?" },
                { icon: "🏠", cat: "REAL ESTATE", q: "What should I check before signing?" },
              ].map(s => (
                <div key={s.q} style={{
                  background: "white", borderRadius: 10, padding: "10px 10px",
                  marginBottom: 8, display: "flex", gap: 8, alignItems: "center",
                  border: "1px solid #ece5db",
                }}>
                  <div style={{
                    width: 28, height: 28, background: "#e8ddd0",
                    borderRadius: 7, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 12,
                  }}>{s.icon}</div>
                  <div>
                    <div style={{ fontFamily: "DM Sans", fontSize: 9, color: "#b5935a", letterSpacing: "0.08em" }}>{s.cat}</div>
                    <div style={{ fontFamily: "DM Sans", fontSize: 11 }}>{s.q}</div>
                  </div>
                </div>
              ))}
              <div style={{
                background: "white", borderRadius: 10, padding: "10px 12px",
                border: "1px solid #ece5db", marginTop: 10,
                display: "flex", alignItems: "center", justifyContent: "space-between",
              }}>
                <span style={{ fontFamily: "DM Sans", fontSize: 11, color: "#b0a090" }}>Ask a legal question...</span>
                <div style={{
                  width: 26, height: 26, background: "#b5935a",
                  borderRadius: 8, display: "flex", alignItems: "center", justifyContent: "center",
                  color: "white", fontSize: 12,
                }}>▶</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* TRUSTED BY */}
      <div style={{
        borderTop: "1px solid #ece5db", borderBottom: "1px solid #ece5db",
        background: "white", padding: "28px 80px",
        display: "flex", alignItems: "center", justifyContent: "center", gap: 60,
        flexWrap: "wrap",
      }}>
        <span style={{ fontFamily: "DM Sans", fontSize: 12, color: "#b0a090", letterSpacing: "0.12em", textTransform: "uppercase" }}>
          Trusted by users across
        </span>
        {["Delhi NCR", "Mumbai", "Bangalore", "Chennai", "Hyderabad", "Pune"].map(c => (
          <span key={c} style={{ fontFamily: "DM Sans", fontSize: 14, color: "#5a4a38", fontWeight: 500 }}>{c}</span>
        ))}
      </div>

      {/* FEATURES */}
      <section id="features" style={{ padding: "100px 80px", maxWidth: 1200, margin: "0 auto" }}>
        <div style={{ textAlign: "center", marginBottom: 64 }}>
          <p className="section-label" style={{ marginBottom: 16 }}>What Lex Can Do</p>
          <h2 style={{ fontSize: "clamp(36px, 5vw, 56px)", fontWeight: 700, letterSpacing: "-0.02em", lineHeight: 1.1 }}>
            Your complete legal<br />
            <em style={{ fontStyle: "italic", fontWeight: 400 }}>companion</em>
          </h2>
        </div>
        <div style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(320px, 1fr))",
          gap: 24,
        }}>
          {features.map((f, i) => (
            <div key={f.title} className="feature-card" style={{ animationDelay: `${i * 0.08}s` }}>
              <div style={{
                width: 52, height: 52, background: f.color,
                borderRadius: 14, display: "flex", alignItems: "center",
                justifyContent: "center", fontSize: 24, marginBottom: 20,
              }}>{f.icon}</div>
              <h3 style={{ fontSize: 20, fontWeight: 600, marginBottom: 10, letterSpacing: "-0.01em" }}>{f.title}</h3>
              <p style={{ fontFamily: "DM Sans", fontSize: 14, color: "#7a6a58", lineHeight: 1.7, fontWeight: 300 }}>{f.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* HOW IT WORKS */}
      <section id="how-it-works" style={{
        background: "#1a1612", color: "#f5f0ea",
        padding: "100px 80px",
      }}>
        <div style={{ maxWidth: 1200, margin: "0 auto" }}>
          <div style={{ textAlign: "center", marginBottom: 72 }}>
            <p style={{ ...{}, fontFamily: "DM Sans", fontSize: 11, letterSpacing: "0.18em", textTransform: "uppercase", color: "#c9a96e", marginBottom: 16 }}>Simple & Fast</p>
            <h2 style={{ fontSize: "clamp(36px, 5vw, 56px)", fontWeight: 700, letterSpacing: "-0.02em", lineHeight: 1.1 }}>
              Legal clarity in<br />
              <em style={{ color: "#c9a96e", fontWeight: 400 }}>3 easy steps</em>
            </h2>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 48 }}>
            {[
              { n: "01", title: "Ask or Upload", desc: "Type your legal question or upload a document — lease, contract, NDA, or any agreement." },
              { n: "02", title: "Lex Analyzes", desc: "Lex reads through the legal language, identifies key clauses, risks, and obligations instantly." },
              { n: "03", title: "Get Clear Answers", desc: "Receive plain-language explanations, summaries, and guidance you can actually act on." },
            ].map((s, i) => (
              <div key={s.n}>
                <div style={{
                  fontSize: 72, fontWeight: 700, color: "#c9a96e18",
                  letterSpacing: "-0.04em", lineHeight: 1, marginBottom: 8,
                }}>{s.n}</div>
                <h3 style={{ fontSize: 24, fontWeight: 600, marginBottom: 14, letterSpacing: "-0.01em" }}>{s.title}</h3>
                <p style={{ fontFamily: "DM Sans", fontSize: 14, color: "#9a8a78", lineHeight: 1.75, fontWeight: 300 }}>{s.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* DOCUMENT CATEGORIES */}
      <section style={{ padding: "100px 80px", maxWidth: 1200, margin: "0 auto" }}>
        <div style={{ display: "flex", gap: 80, alignItems: "center", flexWrap: "wrap" }}>
          <div style={{ flex: "0 0 400px" }}>
            <p className="section-label" style={{ marginBottom: 16 }}>Document Guide</p>
            <h2 style={{ fontSize: "clamp(32px, 4vw, 48px)", fontWeight: 700, letterSpacing: "-0.02em", lineHeight: 1.15, marginBottom: 20 }}>
              Every legal category,<br />covered.
            </h2>
            <p style={{ fontFamily: "DM Sans", fontSize: 15, color: "#6a5a48", lineHeight: 1.7, marginBottom: 36, fontWeight: 300 }}>
              From housing agreements to business contracts, Lex provides guidance across 6 major legal categories — with more coming.
            </p>
            <button className="cta-btn">Browse All Documents</button>
          </div>
          <div style={{ flex: 1, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
            {categories.map(c => (
              <div key={c.label} className="category-chip">
                <div style={{
                  width: 40, height: 40, background: "#e8ddd0",
                  borderRadius: 10, display: "flex", alignItems: "center",
                  justifyContent: "center", fontSize: 18, flexShrink: 0,
                }}>{c.icon}</div>
                <div>
                  <div style={{ fontWeight: 600, fontSize: 15, marginBottom: 2 }}>{c.label}</div>
                  <div style={{ fontFamily: "DM Sans", fontSize: 12, color: "#9a8a78" }}>{c.sub}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* STATS */}
      <section style={{
        background: "white",
        borderTop: "1px solid #ece5db", borderBottom: "1px solid #ece5db",
        padding: "72px 80px",
      }}>
        <div style={{ maxWidth: 1200, margin: "0 auto", display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 40 }}>
          {[
            { n: 50000, s: "+", l: "Documents Analyzed" },
            { n: 200, s: "+", l: "Legal Templates" },
            { n: 6, s: "", l: "Practice Areas" },
            { n: 98, s: "%", l: "User Satisfaction" },
          ].map(stat => (
            <div key={stat.l} style={{ textAlign: "center" }}>
              <div className="stat-number">
                <AnimatedNumber target={stat.n} suffix={stat.s} />
              </div>
              <div style={{ fontFamily: "DM Sans", fontSize: 13, color: "#9a8a78", marginTop: 8, letterSpacing: "0.02em" }}>{stat.l}</div>
            </div>
          ))}
        </div>
      </section>

      {/* ASK LEX CTA */}
      <section style={{ padding: "100px 80px", maxWidth: 800, margin: "0 auto", textAlign: "center" }}>
        <p className="section-label" style={{ marginBottom: 20 }}>Try It Now</p>
        <h2 style={{ fontSize: "clamp(36px, 5vw, 56px)", fontWeight: 700, letterSpacing: "-0.02em", lineHeight: 1.1, marginBottom: 20 }}>
          Ask Lex <em style={{ fontStyle: "italic", fontWeight: 400 }}>anything</em>
        </h2>
        <p style={{ fontFamily: "DM Sans", fontSize: 16, color: "#6a5a48", marginBottom: 40, lineHeight: 1.7, fontWeight: 300 }}>
          Type a legal question below — no account needed to try.
        </p>
        <div style={{
          background: "white",
          borderRadius: 18,
          border: "1.5px solid #ece5db",
          padding: "4px 4px 4px 24px",
          display: "flex", alignItems: "center", gap: 12,
          boxShadow: "0 8px 40px #1a161210",
        }}>
          <input
            value={question}
            onChange={e => setQuestion(e.target.value)}
            placeholder="e.g. What should I check in a rental agreement?"
            style={{
              flex: 1, border: "none", background: "transparent",
              fontFamily: "DM Sans", fontSize: 15, color: "#1a1612",
              padding: "14px 0",
            }}
          />
          <button className="cta-btn" style={{ borderRadius: 14, padding: "14px 28px" }}>
            Ask Lex ▶
          </button>
        </div>
        <div style={{ marginTop: 20, display: "flex", gap: 12, justifyContent: "center", flexWrap: "wrap" }}>
          {["What is a non-compete clause?", "Can my landlord raise rent?", "What is GST input tax credit?"].map(q => (
            <button key={q} onClick={() => setQuestion(q)} style={{
              background: "#b5935a12", border: "1px solid #b5935a30",
              borderRadius: 100, padding: "8px 16px",
              fontFamily: "DM Sans", fontSize: 12, color: "#8a6a3a",
              cursor: "pointer", transition: "all 0.2s",
            }}>{q}</button>
          ))}
        </div>
      </section>

      {/* PRICING */}
      <section id="pricing" style={{ padding: "0 80px 100px", maxWidth: 1200, margin: "0 auto" }}>
        <div style={{ textAlign: "center", marginBottom: 64 }}>
          <p className="section-label" style={{ marginBottom: 16 }}>Pricing</p>
          <h2 style={{ fontSize: "clamp(36px, 5vw, 56px)", fontWeight: 700, letterSpacing: "-0.02em" }}>Simple, transparent.</h2>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 24, maxWidth: 900, margin: "0 auto" }}>
          {[
            { name: "Free", price: "₹0", period: "/month", features: ["10 questions/month", "Document Analyzer (2 docs)", "Basic legal guidance", "Email support"], cta: "Get Started", accent: false },
            { name: "Pro", price: "₹499", period: "/month", features: ["Unlimited questions", "Unlimited documents", "Priority AI analysis", "Download reports", "Priority support"], cta: "Start Free Trial", accent: true },
            { name: "Business", price: "₹1,499", period: "/month", features: ["Everything in Pro", "5 team members", "API access", "Custom templates", "Dedicated support"], cta: "Contact Sales", accent: false },
          ].map(plan => (
            <div key={plan.name} style={{
              background: plan.accent ? "#1a1612" : "white",
              color: plan.accent ? "#f5f0ea" : "#1a1612",
              borderRadius: 20, padding: "36px 28px",
              border: plan.accent ? "none" : "1px solid #ece5db",
              position: "relative",
              boxShadow: plan.accent ? "0 20px 60px #1a161230" : "none",
            }}>
              {plan.accent && (
                <div style={{
                  position: "absolute", top: -12, left: "50%", transform: "translateX(-50%)",
                  background: "#b5935a", color: "white", borderRadius: 100,
                  padding: "4px 16px", fontFamily: "DM Sans", fontSize: 11, fontWeight: 600,
                  letterSpacing: "0.06em",
                }}>MOST POPULAR</div>
              )}
              <div style={{ marginBottom: 8, fontFamily: "DM Sans", fontSize: 13, fontWeight: 500, color: plan.accent ? "#c9a96e" : "#b5935a" }}>{plan.name}</div>
              <div style={{ fontSize: 48, fontWeight: 700, letterSpacing: "-0.03em", lineHeight: 1 }}>{plan.price}</div>
              <div style={{ fontFamily: "DM Sans", fontSize: 13, color: plan.accent ? "#9a8a78" : "#9a8a78", marginBottom: 28 }}>{plan.period}</div>
              {plan.features.map(f => (
                <div key={f} style={{ display: "flex", gap: 10, alignItems: "center", marginBottom: 12, fontFamily: "DM Sans", fontSize: 14, fontWeight: 300 }}>
                  <span style={{ color: plan.accent ? "#c9a96e" : "#b5935a", fontSize: 16 }}>✓</span>
                  {f}
                </div>
              ))}
              <button style={{
                width: "100%", marginTop: 24,
                background: plan.accent ? "#b5935a" : "transparent",
                color: plan.accent ? "white" : "#b5935a",
                border: plan.accent ? "none" : "1.5px solid #b5935a",
                borderRadius: 50, padding: "14px",
                fontFamily: "DM Sans", fontSize: 14, fontWeight: 500,
                cursor: "pointer",
              }}>{plan.cta}</button>
            </div>
          ))}
        </div>
      </section>

      {/* FAQ */}
      <section id="faq" style={{
        background: "white", padding: "100px 80px",
        borderTop: "1px solid #ece5db",
      }}>
        <div style={{ maxWidth: 700, margin: "0 auto" }}>
          <div style={{ marginBottom: 56 }}>
            <p className="section-label" style={{ marginBottom: 16 }}>FAQ</p>
            <h2 style={{ fontSize: "clamp(32px, 4vw, 48px)", fontWeight: 700, letterSpacing: "-0.02em" }}>Common questions</h2>
          </div>
          {faqs.map((faq, i) => (
            <div key={i} className="faq-item" onClick={() => setOpenFaq(openFaq === i ? null : i)}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <span style={{ fontSize: 18, fontWeight: 600, letterSpacing: "-0.01em" }}>{faq.q}</span>
                <span style={{
                  color: "#b5935a", fontSize: 22, transition: "transform 0.2s",
                  transform: openFaq === i ? "rotate(45deg)" : "rotate(0deg)",
                  flexShrink: 0, marginLeft: 20,
                }}>+</span>
              </div>
              {openFaq === i && (
                <p style={{ fontFamily: "DM Sans", fontSize: 14, color: "#6a5a48", lineHeight: 1.75, marginTop: 16, fontWeight: 300 }}>
                  {faq.a}
                </p>
              )}
            </div>
          ))}
        </div>
      </section>

      {/* FOOTER CTA */}
      <section style={{
        background: "#1a1612", color: "#f5f0ea",
        padding: "100px 80px", textAlign: "center",
      }}>
        <div style={{ maxWidth: 700, margin: "0 auto" }}>
          <div style={{
            width: 64, height: 64, background: "#b5935a",
            borderRadius: 18, display: "flex", alignItems: "center",
            justifyContent: "center", fontSize: 28, margin: "0 auto 32px",
          }}>⚖️</div>
          <h2 style={{ fontSize: "clamp(36px, 5vw, 60px)", fontWeight: 700, letterSpacing: "-0.02em", lineHeight: 1.1, marginBottom: 20 }}>
            Ready to understand<br />your legal rights?
          </h2>
          <p style={{ fontFamily: "DM Sans", fontSize: 16, color: "#9a8a78", marginBottom: 40, lineHeight: 1.7, fontWeight: 300 }}>
            Join thousands who trust Lex for legal clarity. Download the app and ask your first question — for free.
          </p>
          <div style={{ display: "flex", gap: 16, justifyContent: "center", flexWrap: "wrap" }}>
            <button className="cta-btn" style={{ fontSize: 16, padding: "18px 48px" }}>Download on App Store</button>
            <button className="cta-btn" style={{ fontSize: 16, padding: "18px 48px", background: "#2a2218" }}>Get it on Google Play</button>
          </div>
        </div>
      </section>

      {/* FOOTER */}
      <footer style={{
        background: "#0f0d0a", color: "#5a5040",
        padding: "40px 80px",
        display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 20,
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{ width: 28, height: 28, background: "#b5935a", borderRadius: 7, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 14 }}>⚖️</div>
          <span style={{ color: "#f5f0ea", fontWeight: 600, fontSize: 18 }}>Lex</span>
        </div>
        <div style={{ fontFamily: "DM Sans", fontSize: 13 }}>
          © 2026 Lex AI. Not a law firm. For informational purposes only.
        </div>
        <div style={{ display: "flex", gap: 28 }}>
          {["Privacy", "Terms", "Contact"].map(l => (
            <a key={l} href="#" style={{ fontFamily: "DM Sans", fontSize: 13, color: "#5a5040", textDecoration: "none" }}>{l}</a>
          ))}
        </div>
      </footer>
    </div>
  );
}