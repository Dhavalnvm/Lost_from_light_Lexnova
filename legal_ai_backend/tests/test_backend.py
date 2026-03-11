"""
Unit tests for Legal AI Backend.
Run with: pytest tests/ -v
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch

# ─── Helpers tests ────────────────────────────────────────────────────────────

def test_chunk_text_basic():
    from utils.helpers import chunk_text
    text = "This is a test. " * 100
    chunks = chunk_text(text, chunk_size=200, overlap=20)
    assert len(chunks) > 1
    for chunk in chunks:
        assert len(chunk) <= 220  # chunk_size + small buffer


def test_chunk_text_short():
    from utils.helpers import chunk_text
    text = "Short text."
    chunks = chunk_text(text, chunk_size=500, overlap=50)
    assert chunks == ["Short text."]


def test_chunk_text_empty():
    from utils.helpers import chunk_text
    assert chunk_text("") == []


def test_estimate_risk_score_no_flags():
    from utils.helpers import estimate_risk_score
    result = estimate_risk_score([])
    assert result["risk_score"] == 10
    assert result["risk_level"] == "Low"


def test_estimate_risk_score_high():
    from utils.helpers import estimate_risk_score
    flags = [{"severity": "high"}] * 4  # 4 * 25 = 100
    result = estimate_risk_score(flags)
    assert result["risk_score"] == 100
    assert result["risk_level"] == "High"


def test_estimate_risk_score_medium():
    from utils.helpers import estimate_risk_score
    flags = [{"severity": "medium"}] * 3  # 3 * 15 = 45
    result = estimate_risk_score(flags)
    assert result["risk_score"] == 45
    assert result["risk_level"] == "Medium"


def test_is_allowed_file():
    from utils.helpers import is_allowed_file
    assert is_allowed_file("contract.pdf") is True
    assert is_allowed_file("agreement.docx") is True
    assert is_allowed_file("scan.png") is True
    assert is_allowed_file("virus.exe") is False
    assert is_allowed_file("data.xlsx") is False


def test_clean_text():
    from utils.helpers import clean_text
    messy = "  Hello   \n\n\n\n  World  "
    cleaned = clean_text(messy)
    assert "Hello" in cleaned
    assert "World" in cleaned
    assert "\n\n\n" not in cleaned


# ─── Knowledge Base tests ─────────────────────────────────────────────────────

def test_knowledge_base_housing():
    from data.knowledge_base import get_knowledge_base
    data = get_knowledge_base("housing")
    assert "required_documents" in data
    assert len(data["required_documents"]) > 0
    assert "general_tips" in data


def test_knowledge_base_loan():
    from data.knowledge_base import get_knowledge_base
    data = get_knowledge_base("loan")
    assert data["process_name"] is not None


def test_knowledge_base_invalid():
    from data.knowledge_base import get_knowledge_base
    with pytest.raises(KeyError):
        get_knowledge_base("nonexistent_category")


def test_get_all_categories():
    from data.knowledge_base import get_all_categories
    cats = get_all_categories()
    assert "housing" in cats
    assert "loan" in cats
    assert "employment" in cats
    assert "business" in cats
    assert "education" in cats


# ─── Schemas tests ────────────────────────────────────────────────────────────

def test_upload_response_schema():
    from models.schemas import UploadDocumentResponse
    r = UploadDocumentResponse(
        document_id="abc-123",
        filename="test.pdf",
        number_of_pages=5,
        number_of_chunks=20,
        file_type=".pdf",
        status="success",
        message="OK",
    )
    assert r.document_id == "abc-123"
    assert r.number_of_pages == 5


def test_risk_analysis_schema():
    from models.schemas import RiskAnalysisResponse, RedFlag
    r = RiskAnalysisResponse(
        document_id="abc",
        risk_score=75,
        risk_level="High",
        detected_red_flags=[
            RedFlag(
                flag_type="Auto Renewal",
                description="Contract auto-renews",
                extracted_text="...shall automatically renew...",
                severity="high",
            )
        ],
        risk_summary="High risk contract",
    )
    assert r.risk_score == 75
    assert len(r.detected_red_flags) == 1


def test_safety_score_bounds():
    from models.schemas import SafetyScoreResponse
    with pytest.raises(Exception):
        SafetyScoreResponse(
            document_id="x",
            safety_score=150,  # Invalid: > 100
            risk_level="Low",
            score_breakdown={},
            recommendations=[],
        )


# ─── Guidance Service tests ───────────────────────────────────────────────────

def test_guidance_service_housing():
    from services.guidance_service import GuidanceService
    svc = GuidanceService()
    result = svc.get_required_documents("housing")
    assert result.category == "housing"
    assert len(result.required_documents) > 0
    assert len(result.general_tips) > 0


def test_guidance_service_invalid():
    from services.guidance_service import GuidanceService
    svc = GuidanceService()
    with pytest.raises(ValueError):
        svc.get_required_documents("invalid_category")


def test_guidance_service_all_categories():
    from services.guidance_service import GuidanceService
    svc = GuidanceService()
    result = svc.get_all_categories()
    assert "categories" in result
    assert len(result["categories"]) >= 7


# ─── Chat Service tests ───────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_safety_score_calculation():
    from services.chat_service import ChatService
    svc = ChatService()
    result = await svc.calculate_safety_score(
        document_id="test-doc",
        risk_score=60,
        fairness_issues=3,
        total_red_flags=4,
        high_severity_flags=2,
    )
    assert 0 <= result.safety_score <= 100
    assert result.risk_level in ("Low", "Medium", "High")
    assert len(result.recommendations) > 0


@pytest.mark.asyncio
async def test_safety_score_safe_contract():
    from services.chat_service import ChatService
    svc = ChatService()
    result = await svc.calculate_safety_score(
        document_id="test-doc-safe",
        risk_score=5,
        fairness_issues=0,
        total_red_flags=0,
        high_severity_flags=0,
    )
    assert result.safety_score >= 70
    assert result.risk_level == "Low"
