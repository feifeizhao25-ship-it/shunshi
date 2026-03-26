"""
顺时 AI LLM 客户端 - OpenRouter
OpenRouter API Client

支持的模型（通过OpenRouter路由）:
- Qwen/Qwen3-235B-A22B-Thinking-2507
- Kimi K2 Thinking
- MiniMax M2
- GLM-4.6
- DeepSeek-V3.2

国际版额外支持:
- Google Gemini
- Anthropic Claude
- OpenAI GPT

环境变量:
  OPENROUTER_API_KEY - OpenRouter API密钥
  OPENROUTER_BASE_URL - OpenRouter基础URL (默认 https://openrouter.ai/api/v1)

作者: Claw 🦅
日期: 2026-03-17
"""

import os
import json
import logging
from typing import Optional, List, Dict, Any, AsyncIterator
from enum import Enum
from dataclasses import dataclass
import aiohttp
import asyncio
import time

logger = logging.getLogger(__name__)


# ==================== 审计集成 ====================

def _get_audit_logger():
    """延迟获取审计日志实例，避免循环导入"""
    try:
        from app.llm.audit import get_llm_audit_logger
        return get_llm_audit_logger()
    except Exception:
        return None


# ==================== 配置 ====================

OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY", "")
OPENROUTER_BASE_URL = os.getenv("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")

# 国内版模型映射 (配置名 → OpenRouter 模型名)
CN_MODEL_MAP = {
    "deepseek-v3.2": "deepseek/deepseek-v3.2",
    "glm-4.6": "z-ai/glm-4.6",
    "qwen3-235b": "qwen/qwen3-max-thinking",
    "kimi-k2-thinking": "moonshotai/kimi-k2-thinking",
    "minimax-m2": "minimax/minimax-m2.5",
}

# 国际版模型映射
GL_MODEL_MAP = {
    "gpt-5.4": "openai/gpt-5.4",
    "claude-sonnet-4.6": "anthropic/claude-sonnet-4-20250514",
    "claude-opus-4.6": "anthropic/claude-opus-4-20250514",
    "gemini-3-pro": "google/gemini-3-pro",
    "gemini-3-flash": "google/gemini-3-flash",
}

ALL_MODEL_MAP = {**CN_MODEL_MAP, **GL_MODEL_MAP}


class MessageRole(str, Enum):
    SYSTEM = "system"
    USER = "user"
    ASSISTANT = "assistant"


@dataclass
class ChatMessage:
    role: MessageRole
    content: str


@dataclass
class UsageInfo:
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int


@dataclass
class ChatCompletionResponse:
    id: str
    model: str
    choices: List[Dict[str, Any]]
    usage: UsageInfo
    finish_reason: str
    raw_response: Dict[str, Any]


class OpenRouterClient:
    """
    OpenRouter API 客户端
    
    - 支持国内版和国际版模型
    - 自动重试
    - 限流处理
    - 错误处理
    """

    def __init__(
        self,
        api_key: str = None,
        base_url: str = None,
        timeout: int = 60,
        max_retries: int = 3,
    ):
        self.api_key = api_key or OPENROUTER_API_KEY
        self.base_url = base_url or OPENROUTER_BASE_URL
        self.timeout = timeout
        self.max_retries = max_retries

        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://shunshi.ai",
            "X-Title": "ShunShi AI",
        }

    def _get_model_name(self, config_name: str) -> str:
        return ALL_MODEL_MAP.get(config_name, config_name)

    async def chat_completion(
        self,
        model: str,
        messages: List[ChatMessage],
        temperature: float = 0.7,
        max_tokens: int = 8192,
        stream: bool = False,
        user_id: str = "",
        skill_chain: List[str] = None,
        route_decision: str = "",
        prompt_version: str = "",
        **kwargs,
    ) -> ChatCompletionResponse:
        or_model = self._get_model_name(model)

        # 审计准备
        audit_logger = _get_audit_logger()
        start_time_ms = 0
        request_id = ""
        if audit_logger:
            import uuid
            start_time_ms = time.time() * 1000
            request_id = str(uuid.uuid4())

        payload = {
            "model": or_model,
            "messages": [
                {"role": m.role.value, "content": m.content}
                for m in messages
            ],
            "temperature": temperature,
            "max_tokens": max_tokens,
            "stream": stream,
            **kwargs,
        }

        url = f"{self.base_url}/chat/completions"
        prompt_text = " ".join(m.content for m in messages)

        for attempt in range(self.max_retries):
            try:
                async with aiohttp.ClientSession() as session:
                    async with session.post(
                        url,
                        headers=self.headers,
                        json=payload,
                        timeout=aiohttp.ClientTimeout(total=self.timeout),
                    ) as response:
                        if response.status == 200:
                            data = await response.json()
                            result = self._parse_response(model, data)

                            # 审计记录
                            if audit_logger and user_id:
                                try:
                                    from app.llm.audit import create_audit
                                    audit_record = create_audit(
                                        user_id=user_id,
                                        provider="openrouter",
                                        model=model,
                                        prompt=prompt_text,
                                        tokens_in=result.usage.prompt_tokens,
                                        tokens_out=result.usage.completion_tokens,
                                        latency_ms=int(time.time() * 1000 - start_time_ms),
                                        request_id=request_id,
                                        skill_chain=skill_chain,
                                        prompt_version=prompt_version,
                                        route_decision=route_decision,
                                    )
                                    audit_logger.log_call(audit_record)
                                except Exception as audit_err:
                                    logger.warning(f"[OpenRouter] 审计记录失败: {audit_err}")

                            return result
                        elif response.status == 429:
                            logger.warning(f"[OpenRouter] 限流，等待重试...")
                            await asyncio.sleep(2 ** attempt)
                            continue
                        else:
                            error_text = await response.text()
                            logger.error(f"[OpenRouter] API 错误: {response.status} - {error_text}")

                            if audit_logger and user_id:
                                try:
                                    from app.llm.audit import create_audit
                                    audit_record = create_audit(
                                        user_id=user_id,
                                        provider="openrouter",
                                        model=model,
                                        prompt=prompt_text,
                                        latency_ms=int(time.time() * 1000 - start_time_ms),
                                        response_status="error",
                                        error_message=f"API {response.status}: {error_text[:200]}",
                                        request_id=request_id,
                                        skill_chain=skill_chain,
                                        route_decision=route_decision,
                                    )
                                    audit_logger.log_call(audit_record)
                                except Exception:
                                    pass

                            raise Exception(f"API 错误: {response.status}")
            except asyncio.TimeoutError:
                logger.warning(f"[OpenRouter] 超时 (尝试 {attempt + 1}/{self.max_retries})")

                if audit_logger and user_id and attempt == self.max_retries - 1:
                    try:
                        from app.llm.audit import create_audit
                        audit_record = create_audit(
                            user_id=user_id,
                            provider="openrouter",
                            model=model,
                            prompt=prompt_text,
                            latency_ms=int(self.timeout * 1000),
                            response_status="timeout",
                            error_message=f"超时 ({self.timeout}s, {self.max_retries} 次重试)",
                            request_id=request_id,
                            skill_chain=skill_chain,
                            route_decision=route_decision,
                        )
                        audit_logger.log_call(audit_record)
                    except Exception:
                        pass

                if attempt == self.max_retries - 1:
                    raise
                await asyncio.sleep(1)
            except Exception as e:
                if "API 错误" in str(e):
                    raise
                logger.error(f"[OpenRouter] 异常: {e}")
                if attempt == self.max_retries - 1:
                    raise
                await asyncio.sleep(1)

        raise Exception("达到最大重试次数")

    def _parse_response(self, original_model: str, data: Dict) -> ChatCompletionResponse:
        usage = data.get("usage", {})
        return ChatCompletionResponse(
            id=data.get("id", ""),
            model=original_model,
            choices=data.get("choices", []),
            usage=UsageInfo(
                prompt_tokens=usage.get("prompt_tokens", 0),
                completion_tokens=usage.get("completion_tokens", 0),
                total_tokens=usage.get("total_tokens", 0),
            ),
            finish_reason=data.get("choices", [{}])[0].get("finish_reason", "stop"),
            raw_response=data,
        )

    async def chat_completion_stream(
        self,
        model: str,
        messages: List[ChatMessage],
        temperature: float = 0.7,
        max_tokens: int = 8192,
    ) -> AsyncIterator[str]:
        or_model = self._get_model_name(model)

        payload = {
            "model": or_model,
            "messages": [
                {"role": m.role.value, "content": m.content}
                for m in messages
            ],
            "temperature": temperature,
            "max_tokens": max_tokens,
            "stream": True,
        }

        url = f"{self.base_url}/chat/completions"

        async with aiohttp.ClientSession() as session:
            async with session.post(
                url,
                headers=self.headers,
                json=payload,
                timeout=aiohttp.ClientTimeout(total=self.timeout),
            ) as response:
                async for line in response.content:
                    if line:
                        line = line.decode("utf-8")
                        if line.startswith("data: "):
                            data = line[6:]
                            if data == "[DONE]":
                                break
                            try:
                                chunk = json.loads(data)
                                content = chunk.get("choices", [{}])[0].get("delta", {}).get("content", "")
                                if content:
                                    yield content
                            except:
                                pass


# ==================== 便捷函数 ====================

_default_client: Optional[OpenRouterClient] = None


def get_openrouter_client() -> OpenRouterClient:
    global _default_client
    if _default_client is None:
        _default_client = OpenRouterClient()
    return _default_client


async def chat_openrouter(
    model: str,
    prompt: str,
    system_prompt: str = None,
    temperature: float = 0.7,
    max_tokens: int = 4096,
) -> ChatCompletionResponse:
    client = get_openrouter_client()
    messages = []
    if system_prompt:
        messages.append(ChatMessage(role=MessageRole.SYSTEM, content=system_prompt))
    messages.append(ChatMessage(role=MessageRole.USER, content=prompt))
    return await client.chat_completion(
        model=model,
        messages=messages,
        temperature=temperature,
        max_tokens=max_tokens,
    )
