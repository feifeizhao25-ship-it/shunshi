"""顺时国内版自己的模型出口：只连境内供应商，进程内直连。

## 为什么要有这个文件

``app/routers/chat.py`` 原来只会调一个外部「模型网关」
（``SHUNSHI_MODEL_ROUTER_URL`` → ``POST /v1/scene/complete``），注释里写明契约以
``svc-model-router/src/router.py`` 为准——那是**见己**的服务。顺时自己的 compose 里没有
任何模型网关，于是：

- 按顺时自己的部署文档上线，``/api/v1/chat`` 永远 503「模型网关未配置」；
- 要让它能用，只能把 URL 指向见己的 svc-model-router——两条产品线共用一个模型出口、
  共用一份预算与日志，违反「四条产品线互不交叉」的约束。

现在顺时在进程内直连境内供应商：DeepSeek Flash 跑量，豆包 lite 与千问 plus 作备选，
硅基流动仅在迁移完成前保留。都没配产品密钥时 503，并写明缺哪个变量。
不会回落到境外供应商。
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
    # 待核实的模型名可以改环境变量，缺省仍是官方文档里的 id。
    model_env: str = ""


# 只列境内供应商。缺省地址写死，不接受境外主机。
# 跑量：DeepSeek V4.1 Flash。备选：豆包 2.0-lite → qwen-plus。
# 硅基流动只在迁移到百炼完成前保留（文档 12）。
# 密钥只用顺时产品服务器的变量，不用 OpenClaw 的 DEEPSEEK_API_KEY / DASHSCOPE_API_KEY / ARK_API_KEY。
PROVIDERS: tuple[Provider, ...] = (
    Provider(
        "deepseek",
        ("SHUNSHI_DEEPSEEK_API_KEY",),
        "https://api.deepseek.com/chat/completions",
        "deepseek-flash",
        "SHUNSHI_DEEPSEEK_MODEL",
    ),
    Provider(
        "ark",
        ("SHUNSHI_ARK_API_KEY",),
        "https://ark.cn-beijing.volces.com/api/v3/chat/completions",
        "doubao-seed-2-0-lite-260428",
        "SHUNSHI_ARK_CHAT_MODEL",
    ),
    Provider(
        "dashscope",
        ("SHUNSHI_DASHSCOPE_API_KEY",),
        "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
        "qwen-plus",
        "SHUNSHI_QWEN_FALLBACK_MODEL",
    ),
    Provider(
        "siliconflow",
        ("SHUNSHI_SILICONFLOW_API_KEY", "SILICONFLOW_API_KEY"),
        "https://api.siliconflow.cn/v1/chat/completions",
        "deepseek-ai/DeepSeek-V3",
    ),
)
DOMESTIC_HOSTS = frozenset({
    "api.deepseek.com",
    "api.siliconflow.cn",
    "ark.cn-beijing.volces.com",
    "dashscope.aliyuncs.com",
    # MiniMax 开放平台（境内）：官方文档域名 api.minimax.cn，旧域名 api.minimaxi.com 同样在境内。
    "api.minimax.cn",
    "api.minimaxi.com",
    "green-cip.cn-beijing.aliyuncs.com",
    "green-cip-vpc.cn-beijing.aliyuncs.com",
})
BAILIAN_HOST_SUFFIX = ".cn-beijing.maas.aliyuncs.com"

# 按会员档位给出的单次回答长度上限（token）。
MAX_TOKENS_BY_TIER = {"free": 600}
DEFAULT_MAX_TOKENS = 1200


def host_allowed(host: str | None) -> bool:
    if not host:
        return False
    if host in DOMESTIC_HOSTS:
        return True
    # 百炼业务空间域名。WorkspaceId 待核实，只接受华北 2（北京）后缀。
    return host.endswith(BAILIAN_HOST_SUFFIX) and host != BAILIAN_HOST_SUFFIX.lstrip(".")


def llm_timeout(env: dict | None = None) -> float:
    source = os.environ if env is None else env
    raw = (source.get("SHUNSHI_LLM_TIMEOUT_SECONDS") or "20").strip()
    try:
        value = float(raw)
    except ValueError:
        value = 20.0
    return min(max(value, 1.0), 60.0)


def _model_for(provider: Provider, env: dict) -> str:
    if provider.model_env:
        override = (env.get(provider.model_env) or "").strip()
        if override:
            return override
    return provider.model


def _key_for(provider: Provider, env: dict | None = None) -> str:
    env = os.environ if env is None else env
    for name in provider.key_vars:
        value = (env.get(name) or "").strip()
        if value:
            return value
    return ""


def configured_providers(env: dict | None = None) -> list[tuple[Provider, str]]:
    return [(p, k) for p in PROVIDERS if (k := _key_for(p, env))]


_STUB_FLAGS = frozenset({"1", "true", "yes", "on"})
# 只给本地界面测试用。生产环境即使误设了开关也不走这里，避免绕过真实供应商。
LOCAL_STUB_REPLY = (
    "这是本地演示回复。你在和人工智能对话，不是真人。"
    "可以按节气把作息安排得松一点：早一点睡、白天起来走动、晚饭清淡。"
    "身体不舒服请去医院，我不能提供用药建议。"
)


def local_stub_reply(env: dict | None = None) -> str | None:
    source = os.environ if env is None else env
    flag = (source.get("SHUNSHI_LLM_STUB") or "").strip().lower()
    if flag not in _STUB_FLAGS:
        return None
    if (source.get("SHUNSHI_ENV") or "development").strip().lower() == "production":
        return None
    return LOCAL_STUB_REPLY


def _payload(provider: Provider, model: str, messages: list, tier: str) -> dict:
    payload: dict[str, Any] = {
        "model": model,
        "messages": messages,
        "temperature": 0.7,
        "max_tokens": MAX_TOKENS_BY_TIER.get(tier, DEFAULT_MAX_TOKENS),
        "stream": False,
    }
    # qwen3.5 默认开思考，文档 12 的价格按非思考档。
    # deepseek-flash 同样默认开思考（https://api-docs.deepseek.com/guides/thinking_mode ）：
    # 免费档 600 token 会先被推理过程吃光，正文只剩半句或干脆为空（2026-11-21 真实模型测试，
    # 顺时国内 4/5 首答截断、SEASONS 4/10 次 502）。陪伴类短问答不需要推理，显式关掉。
    if provider.name == "deepseek":
        payload["thinking"] = {"type": "disabled"}
    if provider.name == "dashscope":
        payload["enable_thinking"] = False
    if provider.name == "ark":
        payload["thinking"] = {"type": "disabled"}
    return payload


async def _post_provider(
    client: httpx.AsyncClient,
    provider: Provider,
    key: str,
    messages: list,
    tier: str,
    env: dict,
    failures: list[str],
    timeout: float,
    *,
    model: str | None = None,
    endpoint: str | None = None,
) -> str | None:
    url = endpoint or provider.endpoint
    host = httpx.URL(url).host
    if not host_allowed(host):
        failures.append(f"{provider.name}:offshore")
        return None
    body = _payload(provider, model or _model_for(provider, env), messages, tier)
    try:
        response = await client.post(
            url,
            json=body,
            headers={"Authorization": f"Bearer {key}"},
            timeout=timeout,
        )
    except httpx.HTTPError as exc:
        failures.append(f"{provider.name}:{type(exc).__name__}")
        return None
    if response.status_code != 200:
        failures.append(f"{provider.name}:{response.status_code}")
        return None
    try:
        text, truncated = _extract_answer(response.json())
    except ValueError:
        text, truncated = None, False
    if text:
        if truncated:
            logger.info("%s answer hit max_tokens; trimmed to last full sentence", provider.name)
            text += TRUNCATED_NOTE_EN if _is_english(messages) else TRUNCATED_NOTE_ZH
        return text
    # 上游 200 但正文为空（多半是推理把额度吃光）：记成 empty，交给下一家；都这样时给可读的话而不是 502。
    failures.append(f"{provider.name}:{'empty_length' if truncated else 'empty'}")
    return None


def provider_by_name(name: str) -> Provider | None:
    for provider in PROVIDERS:
        if provider.name == name:
            return provider
    return None


def _extract_text(data: Any) -> str | None:
    text, _ = _extract_answer(data)
    return text


_SENTENCE_END = "。！？!?…\n"


def _trim_to_sentence(text: str) -> str:
    """被长度上限截断的回答：退回到最后一个完整句子；一句都没有就原样返回。"""
    cut = max(text.rfind(ch) for ch in _SENTENCE_END)
    # 英文句号要求后面原本跟空格或结尾，避免把 3.5 这类小数当句末
    for i in range(len(text) - 1, -1, -1):
        if text[i] == "." and (i + 1 == len(text) or text[i + 1] in " \n"):
            cut = max(cut, i)
            break
    if cut <= 0:
        return text.rstrip()
    return text[: cut + 1].rstrip()


def _extract_answer(data: Any) -> tuple[str | None, bool]:
    """返回 (正文, 是否被长度上限截断)。截断时正文已退回到最后一个完整句子。"""
    if not isinstance(data, dict):
        return None, False
    choices = data.get("choices") or []
    if choices and isinstance(choices[0], dict):
        content = (choices[0].get("message") or {}).get("content")
        truncated = choices[0].get("finish_reason") == "length"
        if isinstance(content, str) and content.strip():
            text = content.strip()
            if truncated:
                text = _trim_to_sentence(text)
            return text, truncated
        return None, truncated
    return None, False


def _is_english(messages: list) -> bool:
    for message in messages:
        if message.get("role") == "system":
            return "Always answer in clear, plain English" in str(message.get("content") or "")
    return False


TRUNCATED_NOTE_ZH = "\n\n（回答较长，这里先说到这。想了解哪一点，可以接着问。）"
TRUNCATED_NOTE_EN = "\n\n(That answer ran long, so I stopped here. Ask me about any part you'd like more on.)"
EMPTY_REPLY_ZH = (
    "这次没能生成完整的回答，请换个说法或稍后再问一次。\n\n"
    "仅供作息安排参考，不是医疗诊断或治疗建议。"
)
EMPTY_REPLY_EN = (
    "I couldn't put together a complete answer this time. Please try rephrasing, or ask again in a moment.\n\n"
    "This is general wellness information, not medical advice."
)


async def complete(
    messages: list[dict[str, str]],
    tier: str = "free",
    *,
    client: httpx.AsyncClient | None = None,
    env: dict | None = None,
) -> str:
    """依次尝试已配置的境内供应商，返回第一条有效回答。"""
    stub = local_stub_reply(env)
    if stub is not None:
        return stub
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
    timeout = llm_timeout(env)
    client = client or httpx.AsyncClient(timeout=timeout)
    source = os.environ if env is None else env
    failures: list[str] = []
    try:
        for provider, key in providers:
            text = await _post_provider(
                client, provider, key, messages, tier, source, failures, timeout
            )
            if text:
                return text
    finally:
        if owns_client:
            await client.aclose()

    # 不把供应商返回的原文带给客户端，只记日志。
    logger.warning("domestic model providers all failed: %s", ", ".join(failures))
    if failures and all(item.split(":", 1)[1].startswith("empty") for item in failures):
        # 供应商都回了 200，只是没给正文：这不是“服务不可用”，给用户一句能看懂的话。
        return EMPTY_REPLY_EN if _is_english(messages) else EMPTY_REPLY_ZH
    raise HTTPException(
        status_code=502,
        detail={"detail": "模型暂时不可用，请稍后再试", "providers_tried": len(failures)},
    )
