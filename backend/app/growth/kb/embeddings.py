"""嵌入与重排的接口。默认是本地哈希，测试不访问网络。

bge-m3 / bge-reranker 只有在配置了地址时才会发 HTTP，且不附带密钥。
"""

from __future__ import annotations

import hashlib
import math
from typing import Protocol


class Embedder(Protocol):
    def embed(self, texts: list[str]) -> list[list[float]]: ...


class Reranker(Protocol):
    def rerank(self, query: str, documents: list[str]) -> list[float]: ...


class LocalHashEmbedder:
    """64 维字符二元组哈希。确定性的，只给测试和离线兜底用，不是 bge-m3。"""

    dim = 64

    def embed(self, texts: list[str]) -> list[list[float]]:
        return [self._one(text) for text in texts]

    def _one(self, text: str) -> list[float]:
        vector = [0.0] * self.dim
        chars = [char for char in text if not char.isspace()] or ["_"]
        if len(chars) == 1:
            chars = chars + ["_"]
        for index in range(len(chars) - 1):
            digest = hashlib.sha256((chars[index] + chars[index + 1]).encode()).digest()
            bucket = digest[0] % self.dim
            sign = 1.0 if digest[1] % 2 == 0 else -1.0
            vector[bucket] += sign
        norm = math.sqrt(sum(value * value for value in vector)) or 1.0
        return [round(value / norm, 6) for value in vector]


class BgeM3Embedder:
    def __init__(self, url: str):
        self.url = url.strip()

    def embed(self, texts: list[str]) -> list[list[float]]:
        if not self.url:
            return LocalHashEmbedder().embed(texts)
        import httpx

        response = httpx.post(
            self.url,
            json={"model": "bge-m3", "input": texts},
            timeout=10.0,
        )
        response.raise_for_status()
        vectors = response.json().get("embeddings")
        if not isinstance(vectors, list) or len(vectors) != len(texts):
            raise RuntimeError("embedding response missing embeddings")
        return vectors


class LocalOverlapReranker:
    def rerank(self, query: str, documents: list[str]) -> list[float]:
        query_grams = set(_bigrams(query))
        scores: list[float] = []
        for document in documents:
            grams = set(_bigrams(document))
            if not query_grams or not grams:
                scores.append(0.0)
            else:
                scores.append(len(query_grams & grams) / len(query_grams | grams))
        return scores


class RemoteReranker:
    def __init__(self, url: str):
        self.url = url.strip()

    def rerank(self, query: str, documents: list[str]) -> list[float]:
        if not self.url:
            return LocalOverlapReranker().rerank(query, documents)
        import httpx

        response = httpx.post(
            self.url,
            json={"model": "bge-reranker-v2-m3", "query": query, "documents": documents},
            timeout=10.0,
        )
        response.raise_for_status()
        scores = response.json().get("scores")
        if not isinstance(scores, list) or len(scores) != len(documents):
            raise RuntimeError("reranker response missing scores")
        return [float(score) for score in scores]


def get_embedder(provider: str, url: str = "") -> Embedder:
    if provider == "bge-m3" and url.strip():
        return BgeM3Embedder(url)
    return LocalHashEmbedder()


def get_reranker(name: str, url: str = "") -> Reranker:
    if name == "bge-reranker-v2-m3" and url.strip():
        return RemoteReranker(url)
    return LocalOverlapReranker()


def _bigrams(text: str) -> list[str]:
    chars = [char for char in text if not char.isspace()]
    return [chars[index] + chars[index + 1] for index in range(len(chars) - 1)]
