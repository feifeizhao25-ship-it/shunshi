"""增长知识库检索：二元组打分、向量余弦、RRF，再用本地重叠重排。

只读 status=active 的块，并带上 chunk_id 作为引用。
"""

from __future__ import annotations

import json
import math
from dataclasses import dataclass
from datetime import date

from sqlalchemy.orm import Session

from app.growth.kb.embeddings import Embedder, LocalHashEmbedder, Reranker, LocalOverlapReranker
from app.growth.kb.freshness import weight_and_archive
from app.growth.models import GrowthKbChunk

RRF_K = 60


@dataclass(frozen=True)
class Retrieved:
    chunk_id: str
    source_id: str
    text: str
    license: str
    score: float
    citation: str


def retrieve(
    session: Session,
    query: str,
    *,
    embedder: Embedder | None = None,
    reranker: Reranker | None = None,
    today: date | None = None,
    limit: int = 5,
) -> list[Retrieved]:
    today = today or date.today()
    embedder = embedder or LocalHashEmbedder()
    reranker = reranker or LocalOverlapReranker()
    rows = session.query(GrowthKbChunk).filter(GrowthKbChunk.status == "active").all()
    usable: list[tuple[GrowthKbChunk, float]] = []
    for row in rows:
        weight, archive = weight_and_archive(row.published_at, row.tier, today)
        if archive:
            row.status = "archived"
            continue
        if weight <= 0:
            continue
        usable.append((row, weight))
    if not usable:
        return []

    query_vector = embedder.embed([query])[0]
    query_grams = _bigrams(query)
    dense_rank = sorted(
        usable,
        key=lambda item: _cosine(query_vector, _load_vector(item[0].embedding_json)),
        reverse=True,
    )
    lexical_rank = sorted(usable, key=lambda item: _bm25(query_grams, item[0].text, usable), reverse=True)
    fused = _rrf(
        [[item[0].chunk_id for item in dense_rank], [item[0].chunk_id for item in lexical_rank]]
    )
    weights = {row.chunk_id: weight for row, weight in usable}
    by_id = {row.chunk_id: row for row, _weight in usable}
    ordered = sorted(fused, key=fused.get, reverse=True)[:20]
    documents = [by_id[chunk_id].text for chunk_id in ordered]
    rerank_scores = reranker.rerank(query, documents) if documents else []
    scored = []
    for chunk_id, rerank_score in zip(ordered, rerank_scores):
        scored.append((chunk_id, fused[chunk_id] * weights[chunk_id] + rerank_score))
    scored.sort(key=lambda item: item[1], reverse=True)
    results: list[Retrieved] = []
    for chunk_id, score in scored[:limit]:
        row = by_id[chunk_id]
        results.append(
            Retrieved(
                chunk_id=row.chunk_id,
                source_id=row.source_id,
                text=row.text,
                license=row.license,
                score=round(score, 6),
                citation=f"[{row.chunk_id}]",
            )
        )
    return results


def _load_vector(payload: str) -> list[float]:
    data = json.loads(payload or "[]")
    return [float(value) for value in data]


def _cosine(left: list[float], right: list[float]) -> float:
    if not left or not right or len(left) != len(right):
        return 0.0
    dot = sum(a * b for a, b in zip(left, right))
    left_norm = math.sqrt(sum(a * a for a in left))
    right_norm = math.sqrt(sum(b * b for b in right))
    if left_norm == 0 or right_norm == 0:
        return 0.0
    return dot / (left_norm * right_norm)


def _bigrams(text: str) -> list[str]:
    chars = [char for char in text if not char.isspace()]
    return [chars[index] + chars[index + 1] for index in range(len(chars) - 1)]


def _bm25(query_grams: list[str], document: str, corpus: list[tuple[GrowthKbChunk, float]]) -> float:
    if not query_grams:
        return 0.0
    docs = [_bigrams(row.text) for row, _weight in corpus]
    avgdl = sum(len(grams) for grams in docs) / len(docs) or 1.0
    doc_grams = _bigrams(document)
    tf: dict[str, int] = {}
    for gram in doc_grams:
        tf[gram] = tf.get(gram, 0) + 1
    score = 0.0
    k1 = 1.2
    b = 0.75
    for gram in set(query_grams):
        document_frequency = sum(1 for grams in docs if gram in grams) or 1
        idf = math.log(1 + (len(docs) - document_frequency + 0.5) / (document_frequency + 0.5))
        frequency = tf.get(gram, 0)
        denom = frequency + k1 * (1 - b + b * len(doc_grams) / avgdl)
        score += idf * (frequency * (k1 + 1) / denom) if denom else 0.0
    return score


def _rrf(rankings: list[list[str]]) -> dict[str, float]:
    scores: dict[str, float] = {}
    for ranking in rankings:
        for rank, chunk_id in enumerate(ranking, start=1):
            scores[chunk_id] = scores.get(chunk_id, 0.0) + 1.0 / (RRF_K + rank)
    return scores
