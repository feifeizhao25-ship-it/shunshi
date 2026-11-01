"""口语化检索评测：问法不照抄标题，衡量“用户随口一问能不能检索到对的片段”。

和 evals.py 的区别：evals.py 的题是从标题自动生成的（问法含标题原词，容易满分）；这里的题是人写的口语问法。
指标：Recall@1/3/5、MRR。只依赖已加载的知识库，离线、确定性、不调用模型。
"""
from __future__ import annotations

import json
from pathlib import Path

DATA = Path(__file__).with_name("data")
FILES = {"cn": DATA / "paraphrase_retrieval_zh.jsonl", "gl": DATA / "paraphrase_retrieval_en.jsonl"}
HELDOUT = {"cn": DATA / "paraphrase_retrieval_heldout_zh.jsonl", "gl": DATA / "paraphrase_retrieval_heldout_en.jsonl"}


def load(lang: str, heldout: bool = False) -> list[dict]:
    f = (HELDOUT if heldout else FILES)[lang]
    return [json.loads(x) for x in f.read_text("utf-8").splitlines() if x.strip() and not x.startswith("#")]


def chunk_uid(ch) -> str:
    return f"{ch.metadata.get('source_file', '?')}:{ch.chunk_id}"


def run(lang: str, retrieve_fn=None, ks=(1, 3, 5), heldout: bool = False) -> dict:
    from app.rag.knowledge_base import load_knowledge_bases
    from app.rag.retriever import retrieve

    load_knowledge_bases(include_legacy=True)  # 口语问法评测语料含 legacy 文档（评测夹具，非运行时）
    fn = retrieve_fn or (lambda q, k: retrieve(q, lang=lang, top_k=k))
    cases = load(lang, heldout)
    hits = {k: 0 for k in ks}
    rr = 0.0
    misses = []
    for c in cases:
        res = fn(c["query"], max(ks))
        uids = [f"{(r.get('metadata') or {}).get('source_file', '?')}:{r['chunk_id']}" for r in res]
        rank = next((i + 1 for i, u in enumerate(uids) if u in set(c["expected"])), None)
        for k in ks:
            hits[k] += 1 if rank and rank <= k else 0
        rr += 1.0 / rank if rank else 0.0
        if not rank or rank > 3:
            misses.append({"id": c["id"], "query": c["query"], "rank": rank})
    n = len(cases)
    return {"n": n, **{f"recall_at_{k}": round(hits[k] / n, 4) for k in ks}, "mrr": round(rr / n, 4), "misses": misses}
