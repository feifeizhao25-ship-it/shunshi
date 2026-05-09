"""
顺时 AI LLM 客户端 - Deepseek 直连
Deepseek API Client (Official)

支持的模型:
- deepseek-chat (DeepSeek-V4)
- deepseek-reasoner (DeepSeek-R1)

作者: Claw 🦅
日期: 2026-05
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


# ==================== 配置 ====================

DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY", "sk-be3af715e1a24dd9be2145a39e0869ec")
DEEPSEEK_BASE_URL = os.getenv("DEEPSEEK_BASE_URL", "https://api.deepseek.com")

# 模型映射
MODEL_NAME_MAP = {
    "deepseek-v4": "deepseek-chat",
    "deepseek-v4-pro": "deepseek-v4-pro",
    "deepseek-v4-flash": "deepseek-v4-flash",
    "deepseek-v3.2": "deepseek-v4-pro",  # v3.2 已下架，映射到 v4-pro
    "deepseek-r1": "deepseek-reasoner",
    "deepseek-chat": "deepseek-chat",
    "deepseek-reasoner": "deepseek-reasoner",
}


# ==================== 数据模型 ====================

class DeepseekMessageRole(str, Enum):
    SYSTEM = "system"
    USER = "user"
    ASSISTANT = "assistant"


@dataclass
class DeepseekChatMessage:
    role: DeepseekMessageRole
    content: str


@dataclass
class DeepseekUsageInfo:
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int


@dataclass
class DeepseekChatResponse:
    content: str
    model: str
    usage: DeepseekUsageInfo
    latency_ms: float
    finish_reason: str = "stop"


# ==================== 客户端 ====================

class DeepseekClient:
    """Deepseek API 客户端（直连）"""

    def __init__(
        self,
        api_key: Optional[str] = None,
        base_url: Optional[str] = None,
        default_model: str = "deepseek-chat",
        timeout: int = 120,
    ):
        self.api_key = api_key or DEEPSEEK_API_KEY
        self.base_url = (base_url or DEEPSEEK_BASE_URL).rstrip("/")
        self.default_model = default_model
        self.timeout = timeout
        self._session: Optional[aiohttp.ClientSession] = None

    async def _get_session(self) -> aiohttp.ClientSession:
        if self._session is None or self._session.closed:
            self._session = aiohttp.ClientSession(
                timeout=aiohttp.ClientTimeout(total=self.timeout)
            )
        return self._session

    async def close(self):
        if self._session and not self._session.closed:
            await self._session.close()
            self._session = None

    def _resolve_model(self, model: str) -> str:
        """将配置名解析为 API 模型名"""
        return MODEL_NAME_MAP.get(model, model)

    async def chat(
        self,
        messages: List[Dict[str, str]],
        model: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 4096,
        stream: bool = False,
        **kwargs,
    ) -> DeepseekChatResponse:
        """发送聊天请求"""
        resolved_model = self._resolve_model(model or self.default_model)
        start_time = time.time()

        # 构建请求
        url = f"{self.base_url}/chat/completions"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": resolved_model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
            "stream": stream,
            **kwargs,
        }

        session = await self._get_session()
        try:
            async with session.post(url, json=payload, headers=headers) as resp:
                latency_ms = (time.time() - start_time) * 1000

                if resp.status != 200:
                    error_text = await resp.text()
                    logger.error(f"[Deepseek] API error {resp.status}: {error_text[:500]}")
                    raise Exception(f"Deepseek API error {resp.status}: {error_text[:300]}")

                data = await resp.json()

                # 解析响应
                choice = data.get("choices", [{}])[0]
                content = choice.get("message", {}).get("content", "")
                finish_reason = choice.get("finish_reason", "stop")
                usage_data = data.get("usage", {})

                usage = DeepseekUsageInfo(
                    prompt_tokens=usage_data.get("prompt_tokens", 0),
                    completion_tokens=usage_data.get("completion_tokens", 0),
                    total_tokens=usage_data.get("total_tokens", 0),
                )

                # 审计日志
                try:
                    from app.llm.audit import get_llm_audit_logger
                    audit = get_llm_audit_logger()
                    if audit:
                        audit.log_call(
                            provider="deepseek",
                            model=resolved_model,
                            prompt_tokens=usage.prompt_tokens,
                            completion_tokens=usage.completion_tokens,
                            latency_ms=latency_ms,
                            status="success",
                        )
                except Exception:
                    pass

                return DeepseekChatResponse(
                    content=content,
                    model=data.get("model", resolved_model),
                    usage=usage,
                    latency_ms=latency_ms,
                    finish_reason=finish_reason,
                )

        except asyncio.TimeoutError:
            latency_ms = (time.time() - start_time) * 1000
            logger.error(f"[Deepseek] Timeout after {self.timeout}s")
            raise Exception(f"Deepseek API timeout after {self.timeout}s")
        except aiohttp.ClientError as e:
            logger.error(f"[Deepseek] Connection error: {e}")
            raise Exception(f"Deepseek connection error: {e}")

    async def chat_stream(
        self,
        messages: List[Dict[str, str]],
        model: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 4096,
    ) -> AsyncIterator[str]:
        """流式聊天"""
        resolved_model = self._resolve_model(model or self.default_model)

        url = f"{self.base_url}/chat/completions"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": resolved_model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
            "stream": True,
        }

        session = await self._get_session()
        async with session.post(url, json=payload, headers=headers) as resp:
            if resp.status != 200:
                error_text = await resp.text()
                raise Exception(f"Deepseek API error {resp.status}: {error_text[:300]}")

            async for line in resp.content:
                line = line.decode("utf-8").strip()
                if not line or not line.startswith("data: "):
                    continue
                data_str = line[6:]
                if data_str == "[DONE]":
                    break
                try:
                    data = json.loads(data_str)
                    delta = data.get("choices", [{}])[0].get("delta", {})
                    content = delta.get("content", "")
                    if content:
                        yield content
                except json.JSONDecodeError:
                    continue


    async def chat_completion(
        self,
        model: str,
        messages: list,
        temperature: float = 0.7,
        max_tokens: int = 4096,
        user_id: str = None,
        skill_chain: list = None,
        route_decision: str = None,
        **kwargs,
    ):
        """
        FallbackChain 兼容接口。
        返回一个带 .choices 和 .usage 属性的对象。
        """
        # 将 messages 转为 dict 格式
        msg_dicts = []
        for m in messages:
            if isinstance(m, dict):
                msg_dicts.append(m)
            elif hasattr(m, "role") and hasattr(m, "content"):
                msg_dicts.append({"role": m.role.value if hasattr(m.role, "value") else str(m.role), "content": m.content})
            else:
                msg_dicts.append(str(m))

        resp = await self.chat(
            messages=msg_dicts,
            model=model,
            temperature=temperature,
            max_tokens=max_tokens,
            **kwargs,
        )

        # 构建兼容响应对象
        return _CompatResponse(
            choices=[{"message": {"content": resp.content}}],
            usage=_CompatUsage(
                prompt_tokens=resp.usage.prompt_tokens,
                completion_tokens=resp.usage.completion_tokens,
                total_tokens=resp.usage.total_tokens,
            ),
        )


# ==================== 兼容响应类 ====================

class _CompatUsage:
    """兼容 SiliconFlow 的 Usage 对象"""
    def __init__(self, prompt_tokens=0, completion_tokens=0, total_tokens=0):
        self.prompt_tokens = prompt_tokens
        self.completion_tokens = completion_tokens
        self.total_tokens = total_tokens


class _CompatResponse:
    """兼容 SiliconFlow 的 ChatCompletionResponse 对象"""
    def __init__(self, choices=None, usage=None):
        self.choices = choices or []
        self.usage = usage


# ==================== 全局单例 ====================

_client: Optional[DeepseekClient] = None


def get_deepseek_client() -> DeepseekClient:
    """获取 Deepseek 客户端单例"""
    global _client
    if _client is None:
        _client = DeepseekClient()
    return _client


async def chat_deepseek(
    messages: List[Dict[str, str]],
    model: str = "deepseek-chat",
    temperature: float = 0.7,
    max_tokens: int = 4096,
    **kwargs,
) -> DeepseekChatResponse:
    """便捷函数：发送 Deepseek 聊天请求"""
    client = get_deepseek_client()
    return await client.chat(
        messages=messages,
        model=model,
        temperature=temperature,
        max_tokens=max_tokens,
        **kwargs,
    )


async def chat_deepseek_stream(
    messages: List[Dict[str, str]],
    model: str = "deepseek-chat",
    temperature: float = 0.7,
    max_tokens: int = 4096,
) -> AsyncIterator[str]:
    """便捷函数：流式 Deepseek 聊天"""
    client = get_deepseek_client()
    async for chunk in client.chat_stream(
        messages=messages,
        model=model,
        temperature=temperature,
        max_tokens=max_tokens,
    ):
        yield chunk
