"""检索结果和冷启动文案不得把功效承诺原样交给用户。"""
import re

from app.rag.knowledge_base import load_knowledge_bases
from app.rag.retriever import retrieve
from app.safety.efficacy import redact_efficacy_claims

BANNED = re.compile("排毒|利尿|消肿|增强免疫")


def test_redact_replaces_known_claims():
    text = redact_efficacy_claims("足三里可增强免疫力，适当出汗排毒，冬瓜利水消肿。")
    assert BANNED.search(text) is None
    assert "日常调养" in text
    assert "清淡饮食" in text


def test_cn_retrieval_drops_efficacy_claims():
    load_knowledge_bases()
    results = retrieve("足三里 增强免疫力", lang="cn", top_k=12)
    assert results
    assert any("足三里" in item["content"] for item in results)
    leaked = [
        item["chunk_id"]
        for item in results
        if BANNED.search(item["content"])
    ]
    assert leaked == []
