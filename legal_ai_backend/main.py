"""
LexNova Legal AI Backend v2.0 — FastAPI Application
AI-Powered Legal Document Simplification, Analysis & Guidance
"""
import time
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from config.settings import settings
from utils.logging import app_logger as logger
from core.database import connect_db, close_db
from core.llm_client import llm_client
from api.routes import documents, guidance, chatbot, translation
from api.routes.auth import router as auth_router
from api.routes.features import router as features_router

# ── NEW routers ────────────────────────────────────────────────────────────────
from api.routes.enterprise import router as enterprise_router
from api.routes.user_dashboard import router as user_dashboard_router


# ─── Lifespan ─────────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup: connect MongoDB + check Ollama. Shutdown: close DB."""
    logger.info(f"🚀 Starting {settings.APP_NAME} v{settings.APP_VERSION}")

    # MongoDB
    try:
        await connect_db()
    except Exception as e:
        logger.error(f"❌ MongoDB connection failed: {e}")

    # Ollama health check
    ollama_ok = await llm_client.health_check()
    if not ollama_ok:
        logger.warning(f"⚠️  Ollama NOT reachable at {settings.OLLAMA_BASE_URL}")
    else:
        logger.info(f"✅ Ollama connected — smart={settings.OLLAMA_MODEL_SMART}  fast={settings.OLLAMA_MODEL_FAST}")

    logger.info("✅ Startup complete")
    yield

    await close_db()
    logger.info("🛑 Shutdown complete")


# ─── App Factory ──────────────────────────────────────────────────────────────

def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        description="""
## 🏛️ LexNova Legal AI Backend v2.0

### Features
- **Auth** — JWT register/login, user profiles, document history (MongoDB)
- **Document Upload** — PDF, DOCX, image OCR
- **AI Summaries** — Beginner / Student / Professional modes
- **Risk Analysis** — Red flags + severity scoring
- **Clause Fairness** — Clause-by-clause benchmark comparison
- **Safety Score** — Overall contract safety 0–100
- **RAG Chat** — Ask questions about uploaded documents
- **Legal Chatbot** — General legal Q&A ("Lex")
- **Contract Safety Comparison** — Two docs side-by-side
- **Clause Rewriting** — Safer rewrites with negotiation tips
- **Smart Checklist** — Dynamic clause checklist by document type
- **Version Diff** — Compare contract v1 vs v2
- **Required Documents Guidance** — Housing, loan, employment etc.
- **Translation** — Multi-language support
- **User Dashboard** — Per-user analytics and document history
- **Enterprise Dashboard** — Company-level analytics, team management, billing

### Model Routing
- `llama3.1:8b` — reasoning: summary, risk, fairness, comparison, rewrite, version diff
- `llama3.2:3b` — speed: chatbot, RAG chat, checklist, translation, safety score
        """,
        docs_url="/docs",
        redoc_url="/redoc",
        lifespan=lifespan,
    )

    # ── CORS ──────────────────────────────────────────────────────────────────
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # ── Request Timing ─────────────────────────────────────────────────────────
    @app.middleware("http")
    async def log_requests(request: Request, call_next):
        start = time.time()
        response = await call_next(request)
        dur = time.time() - start
        logger.info(f"← {request.method} {request.url.path} [{response.status_code}] {dur:.2f}s")
        return response

    # ── Global Exception Handler ───────────────────────────────────────────────
    @app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception):
        logger.error(f"Unhandled exception on {request.url.path}: {exc}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"error": "Internal Server Error", "detail": str(exc), "status_code": 500},
        )

    # ── Routes ─────────────────────────────────────────────────────────────────
    app.include_router(auth_router)
    app.include_router(documents.router)
    app.include_router(guidance.router)
    app.include_router(chatbot.router)
    app.include_router(translation.router)
    app.include_router(features_router)

    # ── New dashboard routers ───────────────────────────────────────────────────
    app.include_router(enterprise_router)
    app.include_router(user_dashboard_router)

    # ── System endpoints ───────────────────────────────────────────────────────
    @app.get("/", tags=["System"])
    async def root():
        return {
            "name": settings.APP_NAME,
            "version": settings.APP_VERSION,
            "status": "running",
            "docs": "/docs",
        }

    @app.get("/health", tags=["System"])
    async def health():
        ollama_ok = await llm_client.health_check()
        return {
            "status": "healthy" if ollama_ok else "degraded",
            "ollama": "connected" if ollama_ok else "disconnected",
            "model_smart": settings.OLLAMA_MODEL_SMART,
            "model_fast": settings.OLLAMA_MODEL_FAST,
        }

    @app.get("/api/v1/document-types", tags=["Document Analyzer"])
    async def list_document_types():
        return {
            "housing_property": [
                "Rental Agreement", "Lease Agreement", "Leave and License Agreement",
                "Property Purchase Agreement", "Property Sale Deed", "Builder Buyer Agreement",
                "Housing Society Agreement", "Maintenance Agreement", "Sublease Agreement",
            ],
            "financial_banking": [
                "Personal Loan Agreement", "Home Loan Agreement", "Car Loan Agreement",
                "Credit Card Terms and Conditions", "Mortgage Agreement",
                "Loan Guarantee Agreement", "Bank Account Terms and Conditions",
                "Investment Agreement", "Mutual Fund Terms",
            ],
            "employment": [
                "Employment Contract", "Offer Letter", "Internship Agreement",
                "Freelance Contract", "Non Disclosure Agreement", "Non Compete Agreement",
                "Consultant Agreement", "Contractor Agreement",
                "Employee Handbook Policies", "Termination Agreement",
            ],
            "business": [
                "Partnership Agreement", "Shareholder Agreement", "Vendor Agreement",
                "Service Agreement", "Licensing Agreement", "Franchise Agreement",
                "Joint Venture Agreement", "Memorandum of Understanding",
                "Business Loan Agreement",
            ],
            "insurance": [
                "Health Insurance Policy", "Life Insurance Policy", "Car Insurance Policy",
                "Travel Insurance Policy", "Property Insurance Policy",
                "Insurance Claim Terms", "Insurance Rider Agreements",
            ],
            "digital": [
                "Website Terms of Service", "Privacy Policy",
                "End User License Agreement", "App Terms and Conditions",
                "Data Sharing Agreements", "Platform User Agreements",
            ],
            "education": [
                "University Admission Agreement", "Scholarship Agreement",
                "Student Housing Agreement", "Internship Contract",
                "Research Collaboration Agreement",
            ],
            "personal_legal": [
                "Power of Attorney", "Affidavit", "Legal Notice",
                "Settlement Agreement", "Divorce Agreement",
                "Prenuptial Agreement", "Will / Testament",
            ],
        }

    return app


app = create_app()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        log_level=settings.LOG_LEVEL.lower(),
    )