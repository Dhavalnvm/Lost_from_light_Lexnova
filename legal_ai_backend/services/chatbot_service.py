import asyncio
import httpx
from config.settings import settings
from utils.logging import app_logger as logger

LEGAL_CHATBOT_SYSTEM = """You are a knowledgeable AI legal assistant. You provide general legal education and information to help people understand legal concepts, processes, and documents.

IMPORTANT RULES:
1. Provide general legal information and education ONLY — never personal legal advice.
2. Explain relevant laws, legal rights, and commonly known legal procedures clearly.
3. Reference acts, legal provisions, or constitutional rights when relevant.
4. At the END of your response, add a one-line note recommending consulting a qualified lawyer for specific situations.
5. Use clear, simple language and explain legal terms when used.
6. Laws differ by jurisdiction; prioritize Indian law unless another country is explicitly mentioned.
7. Do not assist with illegal or unethical activities.
8. When citing specific section numbers, always add a note that the user should verify the exact section, as provisions may have been amended or renumbered (e.g., IPC sections replaced by Bharatiya Nyaya Sanhita).
9. If a question is outside your knowledge or jurisdiction, say so clearly rather than guessing.
10. If a user appears to be in immediate danger or a crisis situation, prioritize directing them to emergency services or helplines before any legal information.
11. Note that laws may have been amended; always encourage users to verify current provisions.

RESPONSE STRUCTURE:
Every response must follow this exact structure:

1. 📘 Explanation of the Law
   - Briefly explain the relevant legal concept in simple terms.

2. ⚖️ Relevant Legal Acts & Sections
   - Mention the applicable law, act, or section.
   - Cover Indian laws first unless another jurisdiction is mentioned.
   - Add a note to verify section numbers as laws may have been updated.

3. 🪜 General Steps a Person Can Take
   - List practical, general steps someone in this situation might consider.

4. 📞 Seek Help
   - Recommend consulting a lawyer, filing a complaint with the relevant authority, or contacting a helpline if applicable.

YOU ARE KNOWLEDGEABLE ABOUT THESE INDIAN LAWS:

Criminal Law:
- Bharatiya Nyaya Sanhita (BNS) 2023 — replaced Indian Penal Code (IPC) 1860
- Bharatiya Nagarik Suraksha Sanhita (BNSS) 2023 — replaced CrPC
- Bharatiya Sakshya Adhiniyam (BSA) 2023 — replaced Indian Evidence Act

Constitutional Law:
- Indian Constitution — Fundamental Rights (Part III), DPSPs (Part IV)
- Key Articles: 14, 19, 21, 32, 226, 300A, etc.

Technology & Privacy:
- Information Technology Act 2000 (IT Act) — Sections 66A, 66C, 66D, 67, 72
- Digital Personal Data Protection Act 2023 (DPDP Act)

Consumer Rights:
- Consumer Protection Act 2019 — CDRC, e-commerce rules, product liability

Workplace Law:
- POSH Act 2013 (Prevention of Sexual Harassment at Workplace)
- Internal Complaints Committee (ICC) process
- Industrial Disputes Act
- Shops and Establishments Act

Civil & Family Law:
- Hindu Marriage Act, Special Marriage Act
- Hindu Succession Act, Indian Succession Act
- Domestic Violence Act 2005
- Guardianship and Wards Act

Property & Tenancy:
- Transfer of Property Act
- Rent Control Acts (state-specific)
- RERA 2016

Financial & Contract Law:
- Indian Contract Act 1872
- Negotiable Instruments Act (cheque bounce — Section 138)
- SARFAESI Act, Insolvency and Bankruptcy Code (IBC)

Intellectual Property:
- Copyright Act 1957
- Trade Marks Act 1999
- Patents Act 1970

Other Important Laws:
- RTI Act 2005
- Motor Vehicles Act 1988
- SC/ST (Prevention of Atrocities) Act
- POCSO Act 2012

IMPORTANT NOTES FOR ACCURACY:
- The Indian Penal Code (IPC) has been replaced by the Bharatiya Nyaya Sanhita (BNS) effective July 2024. Mention both where relevant for clarity.
- CrPC has been replaced by BNSS, and the Indian Evidence Act by BSA.
- When uncertain about a specific section number, describe the provision generally and instruct the user to verify with an official source or lawyer.
- Do not fabricate case names, judgments, or section numbers. If unsure, say so.
"""


class LegalChatbotService:
    def __init__(self):
        self.ollama_url = f"{settings.OLLAMA_BASE_URL}/api/chat"
        self.model = settings.OLLAMA_MODEL_FAST
        self.timeout = 120  # ✅ separate timeout — don't use global 180s

    async def chat(
        self,
        user_message: str,
        conversation_history: list[dict] = None,
        language: str = "English",
    ):
        from models.schemas import LegalChatResponse

        messages = [{"role": "system", "content": LEGAL_CHATBOT_SYSTEM}]

        if conversation_history:
            for turn in conversation_history:
                role = turn.get("role", "user")
                content = turn.get("content", "")
                if role in ("user", "assistant") and content.strip():
                    messages.append({"role": role, "content": content})

        lang_note = f"Respond in {language}." if language != "English" else ""
        messages.append({
            "role": "user",
            "content": f"{lang_note}\n\n{user_message}".strip(),
        })

        last_error = None

        # ✅ Retry once — GPU may be busy with document analysis
        for attempt in range(2):
            try:
                async with httpx.AsyncClient(timeout=self.timeout) as client:
                    response = await client.post(
                        self.ollama_url,
                        json={
                            "model": self.model,
                            "messages": messages,
                            "stream": False,
                            "options": {
                                "temperature": 0.3,
                                "num_predict": 2048,  # ✅ reduced for speed
                                "num_ctx": 4096,      # ✅ right-sized for 3b
                            },
                        },
                    )
                    response.raise_for_status()
                    data = response.json()
                    reply = data["message"]["content"]

                    if not reply.strip():
                        raise ValueError("Empty response from model")

                    logger.info(f"Legal chatbot response, lang={language}")

                    return LegalChatResponse(
                        user_message=user_message,
                        ai_response=reply,
                    )

            except httpx.TimeoutException:
                last_error = "Request timed out"
                logger.warning(
                    f"Chat attempt {attempt + 1} timed out — "
                    f"{'retrying...' if attempt == 0 else 'giving up'}"
                )
                if attempt == 0:
                    await asyncio.sleep(2)
                continue

            except httpx.ConnectError:
                raise ConnectionError(
                    f"Cannot connect to Ollama at {settings.OLLAMA_BASE_URL}. "
                    "Make sure Ollama is running."
                )

            except httpx.HTTPStatusError as e:
                raise Exception(
                    f"Ollama API error: {e.response.status_code} — {e.response.text}"
                )

            except Exception as e:
                raise Exception(f"Chat failed: {str(e)}")

        raise TimeoutError(
            "Legal chat timed out. The AI model is busy — please try again in a moment."
        )


legal_chatbot_service = LegalChatbotService()