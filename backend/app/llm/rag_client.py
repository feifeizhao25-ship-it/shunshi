"""百炼向量与重排。迁移完成前，没有百炼密钥时才退回硅基流动。

端点取自阿里云百炼 OpenAI 兼容文档（北京）：
- text-embedding-v4：POST /compatible-mode/v1/embeddings
- qwen3-rerank：POST /compatible-api/v1/reranks
WorkspaceId 待核实。配了 SHUNSHI_BAILIAN_WORKSPACE_ID 就改用业务空间域名。
"""

from __future__ import annotations

import os

import httpx

from app.llm.domestic_gateway import BAILIAN_HOST_SUFFIX, host_allowed, llm_timeout

EMBED_MODEL = "text-embedding-v4"
RERANK_MODEL = "qwen3-rerank"
RERANK_LIMIT = 20


def _source(env: dict | None) -> dict:
    return os.environ if env is None else env


def _workspace_host(env: dict) -> str | None:
    workspace = (env.get("SHUNSHI_BAILIAN_WORKSPACE_ID") or "").strip()
    if not workspace or any(char not in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-" for char in workspace):
        return None
    host = f"{workspace}{BAILIAN_HOST_SUFFIX}"
    return host if host_allowed(host) else None


def _base(env: dict, kind: str) -> str:
    host = _workspace_host(env)
    if host:
        path = "compatible-mode/v1" if kind == "embed" else "compatible-api/v1"
        return f"https://{host}/{path}"
    if kind == "embed":
        return "https://dashscope.aliyuncs.com/compatible-mode/v1"
    return "https://dashscope.aliyuncs.com/compatible-api/v1"


def dashscope_key(env: dict | None = None) -> str:
    return (_source(env).get("SHUNSHI_DASHSCOPE_API_KEY") or "").strip()


def siliconflow_key(env: dict | None = None) -> str:
    source = _source(env)
    return (source.get("SHUNSHI_SILICONFLOW_API_KEY") or source.get("SILICONFLOW_API_KEY") or "").strip()


def embed_sync(texts: list[str], env: dict | None = None, client: httpx.Client | None = None) -> list[list[float]] | None:
    source = _source(env)
    key = dashscope_key(source)
    if not key or not texts:
        return None
    model = (source.get("SHUNSHI_EMBEDDING_MODEL") or EMBED_MODEL).strip() or EMBED_MODEL
    owns = client is None
    client = client or httpx.Client(timeout=llm_timeout(source))
    try:
        response = client.post(
            f"{_base(source, 'embed')}/embeddings",
            json={"model": model, "input": texts, "encoding_format": "float"},
            headers={"Authorization": f"Bearer {key}"},
        )
        response.raise_for_status()
        rows = response.json().get("data") or []
        vectors = [row.get("embedding") for row in rows]
        if len(vectors) != len(texts) or any(not isinstance(item, list) for item in vectors):
            return None
        return vectors
    except (httpx.HTTPError, ValueError):
        return None
    finally:
        if owns:
            client.close()


def rerank_sync(
    query: str,
    documents: list[str],
    env: dict | None = None,
    client: httpx.Client | None = None,
) -> list[float] | None:
    source = _source(env)
    key = dashscope_key(source)
    if not key or not documents:
        return None
    limited = documents[:RERANK_LIMIT]
    model = (source.get("SHUNSHI_RERANK_MODEL") or RERANK_MODEL).strip() or RERANK_MODEL
    owns = client is None
    client = client or httpx.Client(timeout=llm_timeout(source))
    try:
        response = client.post(
            f"{_base(source, 'rerank')}/reranks",
            json={"model": model, "query": query, "documents": limited, "top_n": len(limited)},
            headers={"Authorization": f"Bearer {key}"},
        )
        response.raise_for_status()
        body = response.json()
        rows = body.get("results") or body.get("output", {}).get("results") or []
        scores = [0.0] * len(limited)
        for row in rows:
            if not isinstance(row, dict):
                continue
            index = row.get("index")
            score = row.get("relevance_score", row.get("score"))
            if isinstance(index, int) and 0 <= index < len(scores) and isinstance(score, (int, float)):
                scores[index] = float(score)
        if len(documents) > len(limited):
            scores.extend([0.0] * (len(documents) - len(limited)))
        return scores
    except (httpx.HTTPError, ValueError):
        return None
    finally:
        if owns:
            client.close()
