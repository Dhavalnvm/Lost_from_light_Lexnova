"""
Legal AI Backend - FastAPI Application
AI-Powered Legal Document Simplification and Guidance System
"""

import time
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from config.settings import settings
from utils.logging import app_logger as logger
from api.routes import documents, guidance, chatbot, translation
from core.llm_client import llm_client


# ─── Lifespan ─────────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events."""
    logger.info(f"🚀 Starting {settings.APP_NAME} v{settings.APP_VERSION}")

    # Check Ollama connectivity
    ollama_ok = await llm_client.health_check()
    if not ollama_ok:
        logger.warning(
            f"⚠️  Ollama is NOT reachable at {settings.OLLAMA_BASE_URL}. "
            "LLM features will fail until Ollama is started."
        )
    else:
        logger.info(f"✅ Ollama connected at {settings.OLLAMA_BASE_URL} (model: {settings.OLLAMA_MODEL})")

    logger.info("✅ Application startup complete")

    yield  # Application runs here

    logger.info("🛑 Application shutdown")


# ─── App Factory ──────────────────────────────────────────────────────────────

def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        description="""
## 🏛️ Legal AI Backend

An AI-powered backend for legal document simplification, risk analysis, and guidance.

### Features
- **Document Upload** — PDF, DOCX, and scanned image support with OCR
- **AI Summaries** — Plain language explanations (Beginner / Student / Professional modes)
- **Risk Analysis** — Automatic detection of risky clauses and red flags
- **Clause Fairness** — Comparison against industry benchmark standards
- **Safety Score** — Overall contract safety rating (0–100)
- **RAG Chat** — Ask questions about uploaded documents
- **Legal Chatbot** — General legal Q&A
- **Documents Guidance** — Required documents for housing, loan, employment, etc.
- **Translation** — Multi-language support

### LLM Runtime
Uses **Ollama** with **Llama3 / Mistral** running locally.
        """,
        docs_url="/docs",
        redoc_url="/redoc",
        lifespan=lifespan,
    )

    # ── CORS ──────────────────────────────────────────────────────────────────
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # Restrict in production
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # ── Request Timing Middleware ──────────────────────────────────────────────
    @app.middleware("http")
    async def log_requests(request: Request, call_next):
        start = time.time()
        logger.info(f"→ {request.method} {request.url.path}")
        response = await call_next(request)
        duration = time.time() - start
        logger.info(f"← {request.method} {request.url.path} [{response.status_code}] {duration:.2f}s")
        return response

    # ── Global Exception Handler ───────────────────────────────────────────────
    @app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception):
        logger.error(f"Unhandled exception: {exc}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"error": "Internal Server Error", "detail": str(exc), "status_code": 500},
        )

    # ── Routes ─────────────────────────────────────────────────────────────────
    app.include_router(documents.router)
    app.include_router(guidance.router)
    app.include_router(chatbot.router)
    app.include_router(translation.router)

    # ── Health & Info ──────────────────────────────────────────────────────────
    @app.get("/", tags=["System"])
    async def root():
        return {
            "name": settings.APP_NAME,
            "version": settings.APP_VERSION,
            "status": "running",
            "docs": "/docs",
            "redoc": "/redoc",
        }

    @app.get("/health", tags=["System"])
    async def health():
        ollama_ok = await llm_client.health_check()
        return {
            "status": "healthy" if ollama_ok else "degraded",
            "ollama": "connected" if ollama_ok else "disconnected",
            "ollama_url": settings.OLLAMA_BASE_URL,
            "model": settings.OLLAMA_MODEL,
        }

    @app.get("/api/v1/document-types", tags=["Document Analyzer"])
    async def list_document_types():
        """List all supported document types for analysis."""
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


# ─── Entry Point ──────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        log_level=settings.LOG_LEVEL.lower(),
    )
