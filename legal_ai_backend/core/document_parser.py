import io
import os
from pathlib import Path
from typing import Tuple, List, Optional
from utils.logging import app_logger as logger


class DocumentParser:
    """Handles text extraction from PDF, DOCX, and image files."""

    def parse(self, file_path: str) -> Tuple[str, int, List[str]]:
        """
        Parse a document and return (full_text, page_count, page_texts).
        Dispatches based on file extension.
        """
        ext = Path(file_path).suffix.lower()
        logger.info(f"Parsing document: {file_path} (type: {ext})")

        if ext == ".pdf":
            return self._parse_pdf(file_path)
        elif ext in (".docx", ".doc"):
            return self._parse_docx(file_path)
        elif ext in (".png", ".jpg", ".jpeg", ".tiff", ".bmp", ".webp"):
            return self._parse_image(file_path)
        else:
            raise ValueError(f"Unsupported file type: {ext}")

    def _parse_pdf(self, file_path: str) -> Tuple[str, int, List[str]]:
        """Extract text from PDF, falling back to OCR for scanned pages."""
        try:
            import pdfplumber
        except ImportError:
            raise ImportError("pdfplumber is required: pip install pdfplumber")

        page_texts = []
        full_text_parts = []

        with pdfplumber.open(file_path) as pdf:
            page_count = len(pdf.pages)
            for i, page in enumerate(pdf.pages):
                text = page.extract_text() or ""

                # If no text extracted, try OCR
                if not text.strip():
                    logger.warning(f"Page {i+1} has no extractable text — attempting OCR")
                    text = self._ocr_page(page)

                page_texts.append(text)
                full_text_parts.append(f"[Page {i+1}]\n{text}")

        full_text = "\n\n".join(full_text_parts)
        logger.info(f"PDF parsed: {page_count} pages, {len(full_text)} chars")
        return full_text, page_count, page_texts

    def _parse_docx(self, file_path: str) -> Tuple[str, int, List[str]]:
        """Extract text from DOCX file."""
        try:
            from docx import Document
        except ImportError:
            raise ImportError("python-docx is required: pip install python-docx")

        doc = Document(file_path)
        paragraphs = [p.text for p in doc.paragraphs if p.text.strip()]

        # Group paragraphs into simulated "pages" (~500 words each)
        page_texts = []
        current_page = []
        word_count = 0

        for para in paragraphs:
            current_page.append(para)
            word_count += len(para.split())
            if word_count >= 500:
                page_texts.append("\n".join(current_page))
                current_page = []
                word_count = 0

        if current_page:
            page_texts.append("\n".join(current_page))

        full_text = "\n\n".join(paragraphs)
        page_count = max(1, len(page_texts))

        logger.info(f"DOCX parsed: {page_count} simulated pages, {len(full_text)} chars")
        return full_text, page_count, page_texts

    def _parse_image(self, file_path: str) -> Tuple[str, int, List[str]]:
        """Extract text from image using OCR."""
        text = self._ocr_image_file(file_path)
        logger.info(f"Image OCR complete: {len(text)} chars")
        return text, 1, [text]

    def _ocr_page(self, page) -> str:
        """Run OCR on a pdfplumber page object."""
        try:
            import pytesseract
            from PIL import Image
            img = page.to_image(resolution=300).original
            return pytesseract.image_to_string(img)
        except Exception as e:
            logger.error(f"OCR failed on page: {e}")
            return ""

    def _ocr_image_file(self, file_path: str) -> str:
        """Run OCR on a standalone image file."""
        try:
            import pytesseract
            from PIL import Image
            img = Image.open(file_path)
            return pytesseract.image_to_string(img)
        except Exception as e:
            logger.error(f"OCR failed for {file_path}: {e}")
            return ""


document_parser = DocumentParser()
