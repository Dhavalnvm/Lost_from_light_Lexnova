from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from enum import Enum


# ─── Enums ────────────────────────────────────────────────────────────────────

class ExplanationMode(str, Enum):
    beginner = "beginner"
    student = "student"
    professional = "professional"


class RiskLevel(str, Enum):
    low = "Low"
    medium = "Medium"
    high = "High"


class DocumentCategory(str, Enum):
    housing = "housing"
    loan = "loan"
    employment = "employment"
    business = "business"
    education = "education"
    insurance = "insurance"
    digital = "digital"
    personal = "personal"


# ─── Document Upload ───────────────────────────────────────────────────────────

class UploadDocumentResponse(BaseModel):
    document_id: str
    filename: str
    number_of_pages: int
    number_of_chunks: int
    file_type: str
    status: str
    message: str


# ─── Document Summary ─────────────────────────────────────────────────────────

class PageSummary(BaseModel):
    page_number: int
    summary: str


class ClauseItem(BaseModel):
    clause_type: str
    extracted_text: str
    page_number: Optional[int] = None


class DocumentSummaryResponse(BaseModel):
    document_id: str
    mode: str
    summary: str
    page_summaries: List[PageSummary]
    important_clauses: List[ClauseItem]
    key_obligations: List[str]
    key_rights: List[str]


# ─── Risk Analysis ────────────────────────────────────────────────────────────

class RedFlag(BaseModel):
    flag_type: str
    description: str
    extracted_text: str
    severity: str  # low / medium / high
    page_reference: Optional[int] = None


class RiskAnalysisResponse(BaseModel):
    document_id: str
    risk_score: int = Field(..., ge=0, le=100)
    risk_level: str
    detected_red_flags: List[RedFlag]
    risk_summary: str


# ─── Clause Fairness ──────────────────────────────────────────────────────────

class ClauseFairnessItem(BaseModel):
    clause_type: str
    contract_value: str
    typical_standard: str
    fairness_rating: str  # Fair / Unfair / Unclear
    ai_insight: str
    severity: Optional[str] = None


class ClauseFairnessResponse(BaseModel):
    document_id: str
    overall_fairness: str
    clauses_analyzed: List[ClauseFairnessItem]


# ─── Document Safety Score ────────────────────────────────────────────────────

class SafetyScoreResponse(BaseModel):
    document_id: str
    safety_score: int = Field(..., ge=0, le=100)
    risk_level: str
    score_breakdown: Dict[str, Any]
    recommendations: List[str]


# ─── Chat With Document ───────────────────────────────────────────────────────

class ChatWithDocumentRequest(BaseModel):
    document_id: str
    user_question: str
    conversation_history: Optional[List[Dict[str, str]]] = []


class ChatWithDocumentResponse(BaseModel):
    document_id: str
    user_question: str
    ai_response: str
    source_chunks: Optional[List[str]] = []


# ─── Legal Chatbot ────────────────────────────────────────────────────────────

class LegalChatRequest(BaseModel):
    user_message: str
    conversation_history: Optional[List[Dict[str, str]]] = []
    language: Optional[str] = "English"


class LegalChatResponse(BaseModel):
    user_message: str
    ai_response: str
    disclaimer: str = "This is general legal information, not legal advice. Consult a qualified lawyer for your specific situation."


# ─── Required Documents Guidance ─────────────────────────────────────────────

class DocumentStep(BaseModel):
    step_number: int
    title: str
    description: str


class RequiredDocumentItem(BaseModel):
    document_name: str
    description: str
    where_to_obtain: str
    steps: List[DocumentStep]
    validity: Optional[str] = None
    notes: Optional[str] = None


class RequiredDocumentsResponse(BaseModel):
    category: str
    process_name: str
    overview: str
    required_documents: List[RequiredDocumentItem]
    general_tips: List[str]


# ─── Translation ──────────────────────────────────────────────────────────────

class TranslateRequest(BaseModel):
    text: str
    target_language: str
    source_language: Optional[str] = "auto"


class TranslateResponse(BaseModel):
    original_text: str
    translated_text: str
    source_language: str
    target_language: str


# ─── Generic Error ────────────────────────────────────────────────────────────

class ErrorResponse(BaseModel):
    error: str
    detail: str
    status_code: int
