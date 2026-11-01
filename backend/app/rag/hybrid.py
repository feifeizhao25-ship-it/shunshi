"""混合检索：BM25（含标题字段）+ 原有 TF-IDF，用 RRF（倒数排名融合）合并。

为什么加这个（来源与依据，见 docs/RESEARCH_DIGEST_20261101.md）：
- 顺时的检索原来只有 TF-IDF（只索引正文，不索引标题），口语化问法（“晚上睡不着”）对不上标题词时容易排到后面。
- 公开的中文 RAG 实测（VersionRAG README，作者自报、未经人工盲测）：BM25 / 向量 / RRF 混合 / 混合+重排的留出题命中分别为
  73.6% / 52.8% / 62.3% / 83.0%；Memory Tax（arXiv 2610.34073）也指出对原始文本做“混合检索 + 重排”是很强的基线。
  所以这里不引入新模型、不改知识库内容，只把词面信号（含标题）补进来，再保留原有的过期过滤、标题加权和各类过滤。
- 本模块只用本地算法，不调用任何模型；RAG_HYBRID=0 可一键退回原来的纯 TF-IDF。
"""
from __future__ import annotations

import math
import os
import re
from collections import Counter
from typing import Iterable

RRF_K = 60
POOL = 60  # 每一路取前多少个进入融合

_EN_TOKEN = re.compile(r"[a-z0-9]+")
_CJK_RUN = re.compile(r"[\u3400-\u4dbf\u4e00-\u9fff]+")
_CN_STOP_CHARS = set("的了是在有我你他她它们这那个一不也都很而会把被让给跟比等还对才能吗呢吧啊么怎要想该应什么哪些怎样如何可以")
_CN_STOP_WORDS = frozenset({"怎么办", "怎么", "什么", "有哪些", "哪些", "应该", "可以", "需要", "注意", "一下", "怎样", "如何", "是否", "为什么"})
_EN_STOP = frozenset("a an the and or of to in on for with is are be can i my me how what which do does should when why it its at as by from this that these those about into your you we our".split())


def enabled(env=None) -> bool:
    env = os.environ if env is None else env
    return str(env.get("RAG_HYBRID", "1")).strip().lower() not in ("0", "false", "no", "off")


def _stem(w: str) -> str:
    for suf in ("ing", "ed", "es", "s"):
        if len(w) > len(suf) + 3 and w.endswith(suf):
            return w[: -len(suf)]
    return w


def tokenize(text: str, lang: str) -> list[str]:
    text = (text or "").lower()
    if lang != "cn":
        return [_stem(w) for w in _EN_TOKEN.findall(text) if w not in _EN_STOP and len(w) > 1]
    import jieba

    toks: list[str] = []
    for run in _CJK_RUN.findall(text):
        for w in jieba.lcut_for_search(run):
            if len(w) > 1 and w not in _CN_STOP_WORDS and not all(c in _CN_STOP_CHARS for c in w):
                toks.append(w)
        clean = "".join(c for c in run if c not in _CN_STOP_CHARS)
        toks.extend(clean[i:i + 2] for i in range(len(clean) - 1))  # 字二元组：口语问法和书面词不同分词时仍能对上
    toks.extend(_stem(w) for w in _EN_TOKEN.findall(text) if len(w) > 1)
    return toks


class BM25Index:
    """字段加权 BM25：标题重复 3 次再并入正文，等价于标题字段权重 3。"""

    def __init__(self, docs: Iterable[tuple[str, str]], lang: str, k1: float = 1.4, b: float = 0.75, heading_weight: int = 3):
        self.lang, self.k1, self.b = lang, k1, b
        self.tf: list[Counter] = []
        self.dl: list[int] = []
        df: Counter = Counter()
        for heading, content in docs:
            toks = tokenize(heading, lang) * heading_weight + tokenize(content, lang)
            c = Counter(toks)
            self.tf.append(c)
            self.dl.append(len(toks))
            df.update(c.keys())
        self.n = len(self.tf)
        self.avgdl = (sum(self.dl) / self.n) if self.n else 0.0
        self.idf = {t: math.log(1 + (self.n - d + 0.5) / (d + 0.5)) for t, d in df.items()}

    def query(self, q: str, top_k: int = POOL) -> list[tuple[int, float]]:
        qt = [t for t in tokenize(q, self.lang) if t in self.idf]
        if not qt or not self.n:
            return []
        qc = Counter(qt)
        scores: list[tuple[int, float]] = []
        for i, c in enumerate(self.tf):
            s = 0.0
            norm = self.k1 * (1 - self.b + self.b * self.dl[i] / (self.avgdl or 1))
            for t, qn in qc.items():
                f = c.get(t)
                if f:
                    s += self.idf[t] * f * (self.k1 + 1) / (f + norm) * (1 + 0.1 * (qn - 1))
            if s > 0:
                scores.append((i, s))
        scores.sort(key=lambda x: x[1], reverse=True)
        return scores[:top_k]


_CACHE: dict = {}


def index_for(kb, lang: str) -> BM25Index:
    key = (lang, id(kb.chunks), len(kb.chunks))
    idx = _CACHE.get(key)
    if idx is None:
        _CACHE.clear()
        idx = BM25Index(((" ".join(c.heading_path[-2:]), c.content) for c in kb.chunks), lang)
        _CACHE[key] = idx
    return idx


def rrf(rankings: list[list[tuple[int, float]]], k: int = RRF_K) -> list[tuple[int, float]]:
    """倒数排名融合：只看名次，不看各路分数的量纲。返回按融合分归一化（最高=1.0）的列表。"""
    fused: dict[int, float] = {}
    for ranking in rankings:
        for rank, (idx, _s) in enumerate(ranking, 1):
            fused[idx] = fused.get(idx, 0.0) + 1.0 / (k + rank)
    if not fused:
        return []
    top = max(fused.values())
    return sorted(((i, s / top) for i, s in fused.items()), key=lambda x: x[1], reverse=True)


def fuse(kb, lang: str, query: str, tfidf_ranked: list[tuple[int, float]]) -> list[tuple[int, float]]:
    from . import aliases

    bm = index_for(kb, lang).query(aliases.expand(query, lang) if aliases.enabled() else query)
    if not bm:
        return tfidf_ranked
    return rrf([tfidf_ranked[:POOL], bm])
