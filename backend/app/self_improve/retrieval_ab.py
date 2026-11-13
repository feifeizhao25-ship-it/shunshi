"""离线检索对比：BM25 基线 vs bge-m3 + 重排。只写报告，不改线上默认检索。

bge-m3 与 bge-reranker-v2-m3 只有在本机已经有权重、并且推理库可导入时才在 CPU 上跑。
没有权重就不下载、不请求模型接口，报告里记一笔跳过。
"""

from __future__ import annotations

import importlib.util
import inspect
import json
import os
from pathlib import Path

from app.rag import hybrid
from app.rag.embedder import TFIDFEmbedder
from app.rag.embedder_api import EmbeddingClient
from app.self_improve import corpus_eval as ce

DATA = Path(__file__).with_name("data")
REPORT_PATH = DATA / "retrieval_ab_ss5.json"
RETRIEVER_PATH = Path(__file__).resolve().parents[1] / "rag" / "retriever.py"
K = 8
DENSE_MODEL = "BAAI/bge-m3"
RERANKER_MODEL = "BAAI/bge-reranker-v2-m3"


def live_default() -> dict:
    """线上 retrieve() 现在用的配置。对比脚本只读这些值。"""
    signature = inspect.signature(hybrid.BM25Index.__init__)
    source = RETRIEVER_PATH.read_text(encoding="utf-8")
    uses_dense = any(token in source for token in ("bge-m3", "semantic_retriever")) or "reranker" in source.lower()
    return {
        "entry": "app.rag.retriever.retrieve",
        "hybrid_default_on": hybrid.enabled({}),
        "rrf_k": hybrid.RRF_K,
        "pool": hybrid.POOL,
        "bm25_k1": signature.parameters["k1"].default,
        "bm25_b": signature.parameters["b"].default,
        "heading_weight": signature.parameters["heading_weight"].default,
        "lexical_embedder": TFIDFEmbedder.__name__,
        "dense_model": None,
        "reranker": None,
        "retrieve_calls_dense": uses_dense,
        "embedder_api_local_model": EmbeddingClient.DEFAULT_MODELS["local"],
        "embedder_api_default_providers": list(EmbeddingClient.SUPPORTED_PROVIDERS),
    }


def _docs(entries: list[dict]) -> list[tuple[str, str]]:
    docs = []
    for entry in entries:
        heading = " ".join([str(entry.get("title") or ""), " ".join(entry.get("tags") or [])])
        docs.append((heading, ce.entry_text(entry)))
    return docs


def bm25_rank_ids(question: str, entries: list[dict], index: hybrid.BM25Index, k: int = K) -> list[str]:
    ranked = index.query(question, top_k=k)
    return [entries[i]["id"] for i, _score in ranked]


def _recall(cases: list[dict], entries: list[dict], rank) -> dict:
    scored = [case for case in cases if case.get("expect") == "answer" and case.get("corpus_id")]
    hits = hits_at_1 = 0
    misses = []
    for case in scored:
        ranked = rank(case["question"])
        if case["corpus_id"] in ranked:
            hits += 1
        else:
            misses.append(case["id"])
        if ranked and ranked[0] == case["corpus_id"]:
            hits_at_1 += 1
    n = len(scored)
    return {
        "status": "ran",
        "n_scored": n,
        "hits": hits,
        "recall_at_1": round(hits_at_1 / n, 4) if n else 0.0,
        "recall_at_8": round(hits / n, 4) if n else 0.0,
        "misses": misses,
    }


def _weight_dirs() -> list[str]:
    roots = [
        Path.home() / ".cache" / "huggingface" / "hub",
        Path(os.environ["HF_HOME"]) / "hub" if os.environ.get("HF_HOME") else None,
        Path("/opt/models"),
        Path("/models"),
        Path("/workspace/models"),
    ]
    found = []
    for root in roots:
        if root is None or not root.is_dir():
            continue
        for child in root.iterdir():
            name = child.name.lower()
            if "bge-m3" in name or "bge-reranker" in name:
                found.append(str(child))
    return sorted(found)


def probe_dense() -> dict:
    """看 bge-m3 和重排能不能在这台机器上离线跑。不下载、不发请求。"""
    missing = [name for name in ("sentence_transformers", "FlagEmbedding", "torch") if importlib.util.find_spec(name) is None]
    weights = _weight_dirs()
    has_embed = any("bge-m3" in path.lower() and "reranker" not in path.lower() for path in weights)
    has_rerank = any("reranker" in path.lower() for path in weights)
    ready = not missing and has_embed and has_rerank
    reason = ""
    if not ready:
        parts = []
        if missing:
            parts.append("没有推理库（" + "、".join(missing) + "）")
        if not has_embed or not has_rerank:
            parts.append("没有 bge-m3 与 bge-reranker-v2-m3 的本地权重")
        reason = "离线 CPU 上跑不了：" + "；".join(parts) + "。不联网下载，也不调用模型接口。"
    return {
        "status": "ready" if ready else "skipped",
        "ran": False,
        "model": DENSE_MODEL,
        "reranker": RERANKER_MODEL,
        "device": "cpu",
        "offline_only": True,
        "reason": reason,
        "missing_modules": missing,
        "local_weights": weights,
    }


def _load_dense_ranker(entries: list[dict]):
    """仅在 probe 认为权重齐全时调用。local_files_only，禁止联网。"""
    os.environ["HF_HUB_OFFLINE"] = "1"
    os.environ["TRANSFORMERS_OFFLINE"] = "1"
    from sentence_transformers import SentenceTransformer

    embedder = SentenceTransformer(DENSE_MODEL, device="cpu", local_files_only=True)
    reranker = None
    try:
        from sentence_transformers import CrossEncoder

        reranker = CrossEncoder(RERANKER_MODEL, device="cpu", local_files_only=True)
    except Exception:
        from FlagEmbedding import FlagReranker

        reranker = FlagReranker(RERANKER_MODEL, use_fp16=False, device="cpu")

    texts = [heading + "\n" + body for heading, body in _docs(entries)]
    vectors = embedder.encode(texts, normalize_embeddings=True, show_progress_bar=False)

    def rank(question: str) -> list[str]:
        import numpy as np

        query = embedder.encode([question], normalize_embeddings=True, show_progress_bar=False)[0]
        scores = vectors @ query
        order = np.argsort(-scores)[:20]
        docs = [texts[int(i)] for i in order]
        if hasattr(reranker, "predict"):
            pairs = [(question, doc) for doc in docs]
            rerank_scores = reranker.predict(pairs)
        else:
            rerank_scores = reranker.compute_score([[question, doc] for doc in docs], normalize=True)
        fused = sorted(zip(order, rerank_scores), key=lambda item: float(item[1]), reverse=True)
        return [entries[int(i)]["id"] for i, _score in fused[:K]]

    return rank


def _arm(cases: list[dict], entries: list[dict], index: hybrid.BM25Index, dense_rank, dense_status: str) -> dict:
    bm25 = _recall(cases, entries, lambda question: bm25_rank_ids(question, entries, index))
    if dense_rank is None:
        dense = {
            "status": dense_status,
            "ran": False,
            "recall_at_1": None,
            "recall_at_8": None,
            "n_scored": bm25["n_scored"],
            "hits": None,
            "misses": [],
        }
    else:
        dense = _recall(cases, entries, dense_rank)
        dense["ran"] = True
    return {"bm25": bm25, "bge_m3_reranker": dense}


def build_report() -> dict:
    before = live_default()
    entries = ce.corpus_entries()
    index = hybrid.BM25Index(_docs(entries), "cn")
    dense = probe_dense()
    dense_rank = None
    if dense["status"] == "ready":
        try:
            dense_rank = _load_dense_ranker(entries)
            dense["status"] = "ran"
            dense["ran"] = True
            dense["reason"] = ""
        except Exception as exc:  # 权重探测通过但加载失败：记跳过，不改默认检索
            dense["status"] = "skipped"
            dense["ran"] = False
            dense["reason"] = f"离线加载失败（{type(exc).__name__}）。不联网重试。"
    golden = ce.load_jsonl(ce.GOLDEN_PATH)
    held = ce.load_jsonl(ce.HELDOUT_PATH)
    after = live_default()
    return {
        "task": "SS-5",
        "title": "检索离线对比：BM25 基线 与 bge-m3 + 重排",
        "default_unchanged": before == after,
        "default_retrieval": after,
        "note": "只出对比报告，不切换线上默认检索。BM25 用现有词面索引，食材名和节气名仍走这条精确匹配。",
        "k": K,
        "corpus_entries": len(entries),
        "sets": {
            "golden": {"n": len(golden), "file": ce.GOLDEN_PATH.name, **_arm(golden, entries, index, dense_rank, dense["status"])},
            "heldout": {"n": len(held), "file": ce.HELDOUT_PATH.name, **_arm(held, entries, index, dense_rank, dense["status"])},
        },
        "dense": {key: value for key, value in dense.items() if key != "ran"} | {"ran": dense["ran"]},
    }


def write_report(path: Path = REPORT_PATH) -> Path:
    report = build_report()
    path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return path


def main() -> None:
    path = write_report()
    print(path)


if __name__ == "__main__":
    main()
