"""模型策略：只允许国产模型。只写环境变量名，不含任何密钥。"""

from __future__ import annotations

import os
from dataclasses import dataclass

DOMESTIC_PREFIXES = ("deepseek", "qwen", "qwq", "kimi", "moonshot", "glm", "chatglm", "minimax", "abab", "bge-", "baai/")
FOREIGN_MARKERS = ("gpt", "openai", "claude", "anthropic", "gemini", "llama", "mistral", "grok", "jina")


def is_domestic(model: str) -> bool:
    m = (model or "").lower().strip()
    if not m or any(x in m for x in FOREIGN_MARKERS):
        return False
    return m.startswith(DOMESTIC_PREFIXES) or any(p in m for p in ("deepseek", "qwen", "kimi", "glm", "minimax"))


def assert_domestic(model: str) -> str:
    if not is_domestic(model):
        raise ValueError(f"non_domestic_model_refused:{model!r}")
    return model


@dataclass(frozen=True)
class ModelPolicy:
    """批量任务用 bulk（DeepSeek Flash 档）；评审与合规复核用 judge（Qwen Plus 档，与生成异源）。

    模型名可由环境变量覆盖；密钥只通过环境变量名间接读取：
    SIL_BULK_API_KEY / SIL_JUDGE_API_KEY（本模块从不读取其值，由各产品的 LLM 客户端读取）。
    """

    bulk: str = "deepseek-chat"
    judge: str = "qwen-plus"
    embedding: str = "bge-m3"
    embedding_ab: str = "qwen3-embedding"

    @classmethod
    def from_env(cls, env=None) -> "ModelPolicy":
        env = os.environ if env is None else env
        p = cls(
            bulk=env.get("SIL_BULK_MODEL", cls.bulk),
            judge=env.get("SIL_JUDGE_MODEL", cls.judge),
            embedding=env.get("SIL_EMBEDDING_MODEL", cls.embedding),
            embedding_ab=env.get("SIL_EMBEDDING_AB_MODEL", cls.embedding_ab),
        )
        for m in (p.bulk, p.judge, p.embedding, p.embedding_ab):
            assert_domestic(m)
        if p.bulk.lower().split("-")[0] == p.judge.lower().split("-")[0]:
            raise ValueError("judge_must_differ_from_bulk_vendor")
        return p
