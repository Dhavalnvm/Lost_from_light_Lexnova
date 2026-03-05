from typing import List, Dict
from core.llm_client import llm_client
from utils.logging import app_logger as logger
from models.schemas import LegalChatResponse


LEGAL_CHATBOT_SYSTEM = """You are a knowledgeable AI legal assistant. You provide general 
legal education and information to help people understand legal concepts, processes, 
and documents.

IMPORTANT RULES:
1. Provide general legal information and education ONLY
2. Always include a disclaimer that this is not legal advice
3. Recommend consulting a qualified lawyer for specific situations
4. Be clear, accurate, and helpful
5. Use plain language when possible; define legal terms when used
6. Be sensitive to users from different jurisdictions (laws vary by country/state)
7. Do not help with anything illegal or unethical

You are especially knowledgeable about:
- Contract law and common contract types
- Employment law basics  
- Tenant and landlord rights
- Loan and financial agreements
- Business agreements and partnerships
- Consumer rights
- Privacy and data protection
- Intellectual property basics
- Family law basics (divorce, wills)
- Insurance terms and conditions"""


class LegalChatbotService:

    async def chat(
        self,
        user_message: str,
        conversation_history: List[Dict[str, str]] = None,
        language: str = "English",
    ) -> LegalChatResponse:
        """General legal Q&A chatbot."""
        history = conversation_history or []

        # Add language instruction if not English
        lang_note = ""
        if language.lower() not in ("english", "en"):
            lang_note = f"\n\nIMPORTANT: Please respond in {language}."

        response = await llm_client.generate_with_history(
            user_message=user_message + lang_note,
            conversation_history=history,
            system_prompt=LEGAL_CHATBOT_SYSTEM,
        )

        logger.info(f"Legal chatbot response generated, lang={language}")

        return LegalChatResponse(
            user_message=user_message,
            ai_response=response,
            disclaimer=(
                "⚠️ This is general legal information for educational purposes only. "
                "It is not legal advice. Please consult a qualified lawyer for guidance "
                "specific to your situation."
            ),
        )


legal_chatbot_service = LegalChatbotService()
