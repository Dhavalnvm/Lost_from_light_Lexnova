"""
Dual Ollama client — smart (8b) and fast (3b) model instances.
RTX 3050 6GB: 3b fully on GPU, 8b with partial layer offload to DDR5.
"""

import httpx
from typing import Optional, List, Dict
from config.settings import settings
from utils.logging import app_logger as logger


class OllamaClient:
    """Async HTTP client for a specific Ollama model."""

    def __init__(self, model: str):
        self.base_url = settings.OLLAMA_BASE_URL
        self.model = model
        self.timeout = settings.OLLAMA_TIMEOUT

    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.3,
    ) -> str:
        """Send a completion request to Ollama and return the response text."""
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})

        payload = {
            "model": self.model,
            "messages": messages,
            "stream": False,
            "options": {
                "temperature": temperature,
                "num_predict": 2048,
            },
        }

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/api/chat",
                    json=payload,
                )
                response.raise_for_status()
                data = response.json()
                result = data.get("message", {}).get("content", "")
                logger.debug(f"[{self.model}] Response: {len(result)} chars")
                return result.strip()

        except httpx.ConnectError:
            logger.error(f"[{self.model}] Cannot connect to Ollama.")
            raise ConnectionError(
                f"Ollama is not reachable at {self.base_url}. "
                f"Ensure Ollama is running with model '{self.model}' pulled."
            )
        except httpx.TimeoutException:
            logger.error(f"[{self.model}] Request timed out.")
            raise TimeoutError("LLM request timed out. Try again or use a shorter document.")
        except Exception as e:
            logger.error(f"[{self.model}] Generate error: {e}")
            raise

    async def generate_with_history(
        self,
        user_message: str,
        conversation_history: List[Dict[str, str]],
        system_prompt: Optional[str] = None,
    ) -> str:
        """Multi-turn conversation with full conversation history."""
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})

        for turn in conversation_history:
            messages.append({
                "role": turn.get("role", "user"),
                "content": turn.get("content", ""),
            })

        messages.append({"role": "user", "content": user_message})

        payload = {
            "model": self.model,
            "messages": messages,
            "stream": False,
            "options": {"temperature": 0.4, "num_predict": 2048},
        }

        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(f"{self.base_url}/api/chat", json=payload)
            response.raise_for_status()
            data = response.json()
            return data.get("message", {}).get("content", "").strip()

    async def health_check(self) -> bool:
        """Check if Ollama is reachable."""
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                r = await client.get(f"{self.base_url}/api/tags")
                return r.status_code == 200
        except Exception:
            return False


# ─── Two singletons ───────────────────────────────────────────────────────────

# Deep reasoning — summary, risk analysis, clause fairness
# llama3.1:8b: ~4.7GB VRAM (Q4_K_M). Ollama auto-offloads overflow layers to DDR5.
llm_client_smart = OllamaClient(model=settings.OLLAMA_MODEL_SMART)

# Fast tasks — chatbot, translation, safety score
# llama3.2:3b: ~2.0GB VRAM. Fully on GPU.
llm_client_fast = OllamaClient(model=settings.OLLAMA_MODEL_FAST)

# Legacy alias — points to smart client for backward compatibility
llm_client = llm_client_smart