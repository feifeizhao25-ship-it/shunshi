"""库外问题评测：问资料库里没有的东西（股票、签证、烤鸭做法……），检索不该挂任何养生来源。

指标 ooc_cited_rate = 返回了至少一条来源的库外题 / 库外题总数，越低越好。离线、确定性、不调用模型。

为什么先只做评测、不改检索（2026-11-21 离线测量，脚本见 PR 说明）：
- 新能源 #179 用“问句词按全库逆文档频率加权的覆盖率”做下限，库外 20 题挂来源 18 → 0。
- 同样的信号在顺时分不开：口语问法评测里命中正确片段的覆盖率最低 0.027（留出 0.059），
  而库外题最高 0.215。顺时只有 232 个片段，口语问法靠别名表扩展，词面信号不够。
- 外部经验也一致（公开帖子，作者自报、未复现）：同一阈值放在 BM25 / 混合 / 向量检索上结果相反
  https://x.com/maxtushar29/status/2117979675897348119 ；换嵌入模型后旧阈值失效
  https://x.com/Abhishe04755332/status/2115060466624209021 。要真正降下来，需要语义打分（嵌入或重排模型），那要走模型调用审批。
所以这里把问题量化成一个只许变好不许变差的指标，接进持续改进的门禁，等语义打分方案批准后再调下限。
"""
from __future__ import annotations

import json
from pathlib import Path

DATA = Path(__file__).with_name("data")
FILES = {False: DATA / "out_of_corpus_zh_v1.jsonl", True: DATA / "out_of_corpus_zh_heldout.jsonl"}
BASELINE = DATA / "ooc_baseline.json"


def load(heldout: bool = False) -> list[dict]:
    return [json.loads(x) for x in FILES[heldout].read_text("utf-8").splitlines() if x.strip() and not x.startswith("#")]


def run(retrieve_fn=None, heldout: bool = False, top_k: int = 5) -> dict:
    if retrieve_fn is None:
        from app.rag.knowledge_base import load_knowledge_bases
        from app.rag.retriever import retrieve

        load_knowledge_bases(include_legacy=True)  # 与口语问法评测同一语料口径
        retrieve_fn = lambda q, k: retrieve(q, lang="cn", top_k=k)  # noqa: E731
    cases = load(heldout)
    cited = [c["id"] for c in cases if retrieve_fn(c["query"], top_k)]
    n = len(cases)
    return {"n": n, "cited": len(cited), "ooc_cited_rate": round(len(cited) / n, 4) if n else 0.0, "cited_ids": cited}


def baseline() -> dict:
    return json.loads(BASELINE.read_text("utf-8"))
