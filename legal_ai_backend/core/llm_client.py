import httpx
from typing import Optional, List, Dict
from config.settings import settings
from utils.logging import app_logger as logger


class OllamaClient:
    """Async client for communicating with the Ollama inference server."""

    def __init__(self):
        self.base_url = settings.OLLAMA_BASE_URL
        self.model = settings.OLLAMA_MODEL
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
                logger.debug(f"LLM response length: {len(result)} chars")
                return result.strip()

        except httpx.ConnectError:
            logger.error("Cannot connect to Ollama. Is it running?")
            raise ConnectionError(
                "Ollama LLM server is not reachable. "
                f"Ensure Ollama is running at {self.base_url} with model '{self.model}' pulled."
            )
        except httpx.TimeoutException:
            logger.error("Ollama request timed out")
            raise TimeoutError("LLM request timed out. Try again or use a shorter document.")
        except Exception as e:
            logger.error(f"Ollama generate error: {e}")
            raise

    async def generate_with_history(
        self,
        user_message: str,
        conversation_history: List[Dict[str, str]],
        system_prompt: Optional[str] = None,
    ) -> str:
        """Multi-turn conversation with conversation history."""
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})

        for turn in conversation_history:
            messages.append({"role": turn.get("role", "user"), "content": turn.get("content", "")})

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


llm_client = OllamaClient()
