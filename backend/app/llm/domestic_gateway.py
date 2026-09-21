"""顺时国内版自己的模型出口：只连境内供应商，进程内直连。

## 为什么要有这个文件

``app/routers/chat.py`` 原来只会调一个外部「模型网关」
（``SHUNSHI_MODEL_ROUTER_URL`` → ``POST /v1/scene/complete``），注释里写明契约以
``svc-model-router/src/router.py`` 为准——那是**见己**的服务。顺时自己的 compose 里没有
任何模型网关，于是：

- 按顺时自己的部署文档上线，``/api/v1/chat`` 永远 503「模型网关未配置」；
- 要让它能用，只能把 URL 指向见己的 svc-model-router——两条产品线共用一个模型出口、
  共用一份预算与日志，违反「四条产品线互不交叉」的约束。

现在顺时在进程内直连境内供应商：DeepSeek（api.deepseek.com）优先，硅基流动
（api.siliconflow.cn）备用。两家都没配 key 时 503 并写明缺哪个变量；不会回落到任何
境外供应商（``app/llm/openrouter.py`` 不在这条路径上）。
``SHUNSHI_MODEL_ROUTER_URL`` 仍可用，但只应指向顺时自己的网关。
"""

from __future__ import annotations

import logging
import os
from dataclasses import dataclass
from typing import Any

import httpx
from fastapi import HTTPException

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class Provider:
    name: str
    key_vars: tuple[str, ...]
    endpoint: str
    model: str


# 只列境内供应商。地址写死，不从环境变量读——防止被配置成境外地址。
PROVIDERS: tuple[Provider, ...] = (
    Provider(
        "deepseek",
        ("SHUNSHI_DEEPSEEK_API_KEY", "DEEPSEEK_API_KEY"),
        "https://api.deepseek.com/chat/completions",
        "deepseek-chat",
    ),
    Provider(
        "siliconflow",
        ("SHUNSHI_SILICONFLOW_API_KEY", "SILICONFLOW_API_KEY"),
        "https://api.siliconflow.cn/v1/chat/completions",
        "deepseek-ai/DeepSeek-V3",
    ),
)
DOMESTIC_HOSTS = frozenset({"api.deepseek.com", "api.siliconflow.cn"})

# 按会员档位给出的单次回答长度上限（token）。
MAX_TOKENS_BY_TIER = {"free": 600}
DEFAULT_MAX_TOKENS = 1200


def _key_for(provider: Provider, env: dict | None = None) -> str:
    env = os.environ if env is None else env
    for name in provider.key_vars:
        value = (env.get(name) or "").strip()
        if value:
            return value
    return ""


def configured_providers(env: dict | None = None) -> list[tuple[Provider, str]]:
    return [(p, k) for p in PROVIDERS if (k := _key_for(p, env))]


def _extract_text(data: Any) -> str | None:
    if not isinstance(data, dict):
        return None
    choices = data.get("choices") or []
    if choices and isinstance(choices[0], dict):
        content = (choices[0].get("message") or {}).get("content")
        if isinstance(content, str) and content.strip():
            return content.strip()
    return None


async def complete(
    messages: list[dict[str, str]],
    tier: str = "free",
    *,
    client: httpx.AsyncClient | None = None,
    env: dict | None = None,
) -> str:
    """依次尝试已配置的境内供应商，返回第一条有效回答。"""
    providers = configured_providers(env)
    if not providers:
        raise HTTPException(
            status_code=503,
            detail={
                "detail": "境内模型未配置（需要 SHUNSHI_DEEPSEEK_API_KEY 或 SHUNSHI_SILICONFLOW_API_KEY）",
                "configured": False,
            },
        )

    owns_client = client is None
    client = client or httpx.AsyncClient(timeout=60)
    failures: list[str] = []
    try:
        for provider, key in providers:
            host = httpx.URL(provider.endpoint).host
            if host not in DOMESTIC_HOSTS:  # pragma: no cover - 防御性检查
                failures.append(f"{provider.name}:offshore")
                continue
            payload = {
                "model": provider.model,
                "messages": messages,
                "temperature": 0.7,
                "max_tokens": MAX_TOKENS_BY_TIER.get(tier, DEFAULT_MAX_TOKENS),
                "stream": False,
            }
            try:
                response = await client.post(
                    provider.endpoint,
                    json=payload,
                    headers={"Authorization": f"Bearer {key}"},
                )
            except httpx.HTTPError as exc:
                failures.append(f"{provider.name}:{type(exc).__name__}")
                continue
            if response.status_code != 200:
                failures.append(f"{provider.name}:{response.status_code}")
                continue
            try:
                text = _extract_text(response.json())
            except ValueError:
                text = None
            if text:
                return text
            failures.append(f"{provider.name}:empty")
    finally:
        if owns_client:
            await client.aclose()

    # 不把供应商返回的原文带给客户端，只记日志。
    logger.warning("domestic model providers all failed: %s", ", ".join(failures))
    raise HTTPException(
        status_code=502,
        detail={"detail": "模型暂时不可用，请稍后再试", "providers_tried": len(failures)},
    )
