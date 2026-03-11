from models.schemas import TranslateResponse
from utils.logging import app_logger as logger


SUPPORTED_LANGUAGES = {
    "english": "en",
    "hindi": "hi",
    "marathi": "mr",
    "spanish": "es",
    "french": "fr",
    "german": "de",
    "portuguese": "pt",
    "arabic": "ar",
    "chinese": "zh-CN",
    "japanese": "ja",
}


class TranslationService:

    async def translate(
        self,
        text: str,
        target_language: str,
        source_language: str = "auto",
    ) -> TranslateResponse:
        """Translate text using deep-translator (Google Translate backend)."""

        target_lang_code = self._resolve_language(target_language)
        source_lang_code = "auto" if source_language == "auto" else self._resolve_language(source_language)

        try:
            from deep_translator import GoogleTranslator
            translator = GoogleTranslator(
                source=source_lang_code,
                target=target_lang_code,
            )
            translated = translator.translate(text)
            detected_source = source_language if source_language != "auto" else "auto-detected"

        except ImportError:
            raise ImportError("deep-translator required: pip install deep-translator")
        except Exception as e:
            logger.error(f"Translation error: {e}")
            raise ValueError(f"Translation failed: {str(e)}")

        return TranslateResponse(
            original_text=text,
            translated_text=translated,
            source_language=detected_source,
            target_language=target_language,
        )

    def _resolve_language(self, language: str) -> str:
        """Resolve a human-readable language name to a language code."""
        lang_lower = language.lower().strip()
        if lang_lower in SUPPORTED_LANGUAGES:
            return SUPPORTED_LANGUAGES[lang_lower]
        # Assume it's already a code
        return lang_lower

    def get_supported_languages(self) -> dict:
        return SUPPORTED_LANGUAGES


translation_service = TranslationService()
