/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,jsx,ts,tsx}"],
  theme: {
    extend: {
      // ── Color palette ─────────────────────────────────────────────────────
      colors: {
        dark: {
          900: "#0b0a08",
          800: "#111009",
          700: "#1a1810",
          600: "#242118",
          500: "#332f22",
          400: "#4a4535",
        },
        gold: {
          300: "#dfc07e",
          400: "#c9a96e",
          500: "#b5935a",
          600: "#9a7a48",
          700: "#7d6238",
        },
        ink: {
          primary:   "#f0ebe4",
          secondary: "#9a8a78",
          muted:     "#5a5040",
        },
      },

      // ── Typography ─────────────────────────────────────────────────────────
      fontFamily: {
        display: ["'Cormorant Garamond'", "serif"],
        sans:    ["'DM Sans'", "sans-serif"],
        mono:    ["'DM Mono'", "monospace"],
      },

      // ── Border radius ──────────────────────────────────────────────────────
      borderRadius: {
        "2xl": "16px",
        "3xl": "20px",
        "4xl": "28px",
      },

      // ── Box shadows ────────────────────────────────────────────────────────
      boxShadow: {
        gold:    "0 0 32px rgba(201,169,110,0.08)",
        "gold-lg": "0 0 64px rgba(201,169,110,0.12)",
        card:    "0 4px 24px rgba(0,0,0,0.4)",
        "card-lg": "0 24px 80px rgba(0,0,0,0.5)",
        "glow-emerald": "0 0 6px rgba(52,211,153,0.5)",
        "glow-rose":    "0 0 6px rgba(251,113,133,0.5)",
        "glow-gold":    "0 0 6px rgba(201,169,110,0.5)",
      },

      // ── Keyframe animations ────────────────────────────────────────────────
      keyframes: {
        fadeUp: {
          "0%":   { opacity: "0", transform: "translateY(18px)" },
          "100%": { opacity: "1", transform: "translateY(0)"    },
        },
        scaleIn: {
          "0%":   { opacity: "0", transform: "scale(0.96)" },
          "100%": { opacity: "1", transform: "scale(1)"    },
        },
        shimmer: {
          "0%,100%": { backgroundColor: "#1a1810" },
          "50%":     { backgroundColor: "#242118" },
        },
        pulseDot: {
          "0%,100%": { opacity: "1" },
          "50%":     { opacity: "0.35" },
        },
        spin: {
          to: { transform: "rotate(360deg)" },
        },
        goldPulse: {
          "0%,100%": { boxShadow: "0 0 0 0 rgba(201,169,110,0.3)" },
          "50%":     { boxShadow: "0 0 0 6px rgba(201,169,110,0)"  },
        },
      },

      animation: {
        "fade-up":   "fadeUp 0.5s cubic-bezier(0.16,1,0.3,1) both",
        "scale-in":  "scaleIn 0.45s cubic-bezier(0.16,1,0.3,1) both",
        shimmer:     "shimmer 1.8s ease-in-out infinite",
        "pulse-dot": "pulseDot 2s ease infinite",
        spin:        "spin 0.75s linear infinite",
        "gold-pulse":"goldPulse 2s ease infinite",
      },

      // ── Background gradients (used via bg-[…] arbitrary values) ───────────
      backgroundImage: {
        "hero-glow":
          "radial-gradient(ellipse 80% 50% at 20% -10%, rgba(201,169,110,0.07) 0%, transparent 60%)," +
          "radial-gradient(ellipse 60% 40% at 80% 110%, rgba(96,165,250,0.05) 0%, transparent 55%)",
        "gold-gradient": "linear-gradient(135deg, #c9a96e 0%, #f0ebe4 60%, #c9a96e 100%)",
        "gold-diagonal": "linear-gradient(135deg, #b5935a, #c9a96e)",
        "card-blue":
          "linear-gradient(135deg, rgba(147,197,253,0.1), rgba(17,17,21,0.94))",
        "card-gold":
          "linear-gradient(135deg, rgba(201,169,110,0.1), rgba(17,16,9,0.95))",
        "gold-divider":
          "linear-gradient(90deg, transparent, rgba(201,169,110,0.3), transparent)",
      },
    },
  },
  plugins: [],
};