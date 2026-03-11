"""
core/llm_client.py
-------------------
Async Ollama client.

num_gpu=99 → Ollama with CUDA puts as many layers as possible on the RTX 3050,
             automatically overflows the rest to CPU. No manual layer counting needed.
"""
import httpx
from typing import Optional, List, Dict
from config.settings import settings
from utils.logging import app_logger as logger


class OllamaClient:

    def __init__(
        self,
        model: Optional[str] = None,
        gpu_layers: int = 99,
        num_ctx: int = 4096,
        num_predict: int = 2048,
    ):
        self.base_url = settings.OLLAMA_BASE_URL
        self.model = model or settings.OLLAMA_MODEL
        self.timeout = settings.OLLAMA_TIMEOUT
        self.gpu_layers = gpu_layers
        self.num_ctx = num_ctx
        self.num_predict = num_predict

    def _options(self, temperature: float) -> dict:
        return {
            "temperature": temperature,
            "num_predict": self.num_predict,
            "num_ctx": self.num_ctx,
            "num_gpu": self.gpu_layers,  # 99 = auto-max on CUDA
        }

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
            "options": self._options(temperature),
        }

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/api/chat", json=payload)
                response.raise_for_status()
                result = response.json().get("message", {}).get("content", "")
                if not result:
                    logger.warning(f"[{self.model}] Empty response from Ollama")
                    return "I was unable to generate a response. Please try again."
                logger.debug(f"[{self.model}] response_len={len(result)}")
                return result.strip()
        except httpx.ConnectError:
            raise ConnectionError(
                f"Ollama not reachable at {self.base_url} (model: {self.model})")
        except httpx.TimeoutException:
            raise TimeoutError("LLM request timed out.")
        except Exception as e:
            logger.error(f"Ollama generate error [{self.model}]: {e}")
            raise

    async def generate_with_history(
        self,
        user_message: str,
        conversation_history: List[Dict[str, str]],
        system_prompt: Optional[str] = None,
        temperature: float = 0.4,
    ) -> str:
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})

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
            "options": self._options(temperature),
        }

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/api/chat", json=payload)
                response.raise_for_status()
                result = response.json().get("message", {}).get("content", "").strip()
                if not result:
                    logger.warning(
                        f"[{self.model}] Empty response from generate_with_history")
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


# Default client (fast model)
llm_client = OllamaClient(
    model=settings.OLLAMA_MODEL_FAST,
    gpu_layers=settings.FAST_GPU_LAYERS,
    num_ctx=settings.FAST_NUM_CTX,
    num_predict=settings.FAST_NUM_PREDICT,
)