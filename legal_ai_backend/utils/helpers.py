import re
import uuid
from pathlib import Path
from typing import List
from config.settings import settings


def generate_document_id() -> str:
    """Generate a unique document ID."""
    return str(uuid.uuid4())


def get_file_extension(filename: str) -> str:
    return Path(filename).suffix.lower()


def is_allowed_file(filename: str) -> bool:
    allowed = {".pdf", ".docx", ".doc", ".png", ".jpg", ".jpeg", ".tiff", ".bmp"}
    return get_file_extension(filename) in allowed


def chunk_text(text: str, chunk_size: int = None, overlap: int = None) -> List[str]:
    """Split text into overlapping chunks for embedding."""
    chunk_size = chunk_size or settings.CHUNK_SIZE
    overlap = overlap or settings.CHUNK_OVERLAP

    # Clean text
    text = re.sub(r'\s+', ' ', text).strip()

    if len(text) <= chunk_size:
        return [text] if text else []

    chunks = []
    start = 0
    while start < len(text):
        end = start + chunk_size

        # Try to break at sentence boundary
        if end < len(text):
            sentence_break = text.rfind('. ', start, end)
            if sentence_break > start + chunk_size // 2:
                end = sentence_break + 1

        chunk = text[start:end].strip()
        if chunk:
            chunks.append(chunk)

        start = end - overlap
        if start >= len(text):
            break

    return chunks


def clean_text(text: str) -> str:
    """Clean and normalize extracted text."""
    text = re.sub(r'\n{3,}', '\n\n', text)
    text = re.sub(r' {2,}', ' ', text)
    text = text.strip()
    return text


def estimate_risk_score(red_flags: list) -> dict:
    """Calculate risk score from detected red flags."""
    if not red_flags:
        return {"risk_score": 10, "risk_level": "Low"}

    severity_weights = {"high": 25, "medium": 15, "low": 8}
    total = sum(severity_weights.get(flag.get("severity", "low"), 8) for flag in red_flags)
    score = min(100, total)

    if score >= 70:
        level = "High"
    elif score >= 40:
        level = "Medium"
    else:
        level = "Low"

    return {"risk_score": score, "risk_level": level}
