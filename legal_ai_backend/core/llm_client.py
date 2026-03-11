import httpx
from typing import Optional, List, Dict
from config.settings import settings
from utils.logging import app_logger as logger


class OllamaClient:
    """Async client for communicating with the Ollama inference server."""

    def __init__(self, model: Optional[str] = None):
        self.base_url = settings.OLLAMA_BASE_URL
        self.model = model or settings.OLLAMA_MODEL
        self.timeout = settings.OLLAMA_TIMEOUT

    async def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        temperature: float = 0.3,
    ) -> str:
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
                "num_predict": 4096,   # ✅ increased from 2048
                "num_ctx": 8192,       # ✅ larger context window
            },
        }

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(f"{self.base_url}/api/chat", json=payload)
                response.raise_for_status()
                data = response.json()
                result = data.get("message", {}).get("content", "")
                if not result:
                    logger.warning(f"[{self.model}] Empty response from Ollama")
                    return "I was unable to generate a response. Please try again."
                logger.debug(f"[{self.model}] LLM response length: {len(result)} chars")
                return result.strip()
        except httpx.ConnectError:
            logger.error(f"Cannot connect to Ollama at {self.base_url}")
            raise ConnectionError(f"Ollama not reachable at {self.base_url} (model: {self.model})")
        except httpx.TimeoutException:
            logger.error(f"Ollama request timed out (model: {self.model})")
            raise TimeoutError("LLM request timed out.")
        except Exception as e:
            logger.error(f"Ollama generate error [{self.model}]: {e}")
            raise

    async def generate_with_history(
        self,
        user_message: str,
        conversation_history: List[Dict[str, str]],
        system_prompt: Optional[str] = None,
    ) -> str:
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})

        # ✅ Filter out invalid turns
        for turn in conversation_history:
            role = turn.get("role", "")
            content = turn.get("content", "")
            if role in ("user", "assistant") and content.strip():
                messages.append({"role": role, "content": content})

        messages.append({"role": "user", "content": user_message})

        payload = {
            "model": self.model,
            "messages": messages,
            "stream": False,
            "options": {
                "temperature": 0.4,
                "num_predict": 4096,   # ✅ increased from 2048
                "num_ctx": 8192,       # ✅ larger context window
            },
        }

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(f"{self.base_url}/api/chat", json=payload)
                response.raise_for_status()
                data = response.json()
                result = data.get("message", {}).get("content", "").strip()
                if not result:
                    logger.warning(f"[{self.model}] Empty response from generate_with_history")
                    return "I was unable to generate a response. Please try again."
                return result
        except httpx.ConnectError:
            raise ConnectionError(f"Ollama not reachable at {self.base_url}")
        except httpx.TimeoutException:
            raise TimeoutError("LLM request timed out.")
        except Exception as e:
            logger.error(f"generate_with_history error [{self.model}]: {e}")
            raise

    async def health_check(self) -> bool:
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                r = await client.get(f"{self.base_url}/api/tags")
                return r.status_code == 200
        except Exception:
            return False


# Default client (used by legacy code paths)
llm_client = OllamaClient()