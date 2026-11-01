"""复测 B13：RAG 清单 6 份文档中 4 份 legacy_unverified，valid_until=2026-11-30。
过期来源以前只是降权，仍会被检索进回答；现在过期当天起不再引用，同时已核验文稿补上了
饮水 / 身体活动 / 睡眠三个主题（均来自官方出处），不让过期后问答变空。"""
import json
from datetime import date
from pathlib import Path

import pytest

from app.rag import retriever
from app.rag.knowledge_base import KnowledgeChunk, _parse_markdown_into_chunks

MANIFEST = Path(__file__).resolve().parents[1] / "app/rag/source_manifest.json"


class _Embedder:
    def query(self, q, top_k=5):
        return [(0, 1.0), (1, 0.9), (2, 0.8)]


class _KB:
    loaded = True

    def __init__(self):
        mk = lambda i, src, status, until: KnowledgeChunk(
            chunk_id=f"c{i}", content=f"content {i}", heading_path=["h"],
            metadata={"source_file": src, "evidence_status": status, "valid_until": until},
        )
        self.chunks = [
            mk(0, "顺时知识库_中文版.md", "legacy_unverified", "2026-11-30"),
            mk(1, "顺时知识库_补充篇_中文版.md", "legacy_unverified", "2026-11-30"),
            mk(2, "verified_cn.md", "verified_official", "2027-02-28"),
        ]


@pytest.fixture
def kb(monkeypatch):
    stub = _KB()
    monkeypatch.setattr(retriever, "cn_kb", stub)
    monkeypatch.setattr(retriever, "get_embedder", lambda lang: _Embedder())
    return stub


def _ids(monkeypatch, today):
    monkeypatch.setattr(retriever, "_today", lambda: today)
    return [r["chunk_id"] for r in retriever.retrieve("anything", lang="cn", top_k=5)]


def test_unexpired_legacy_documents_are_still_retrievable_until_their_date(kb, monkeypatch):
    assert _ids(monkeypatch, date(2026, 11, 30)) == ["c0", "c1", "c2"]


def test_expired_legacy_documents_are_not_cited_from_the_day_after(kb, monkeypatch):
    # before: only multiplied by 0.5, so they were still returned
    assert _ids(monkeypatch, date(2026, 12, 1)) == ["c2"]


def test_a_source_without_valid_until_is_treated_as_expired():
    assert retriever.is_expired({}, date(2026, 11, 1)) is True
    assert retriever.is_expired({"valid_until": "garbage"}, date(2026, 11, 1)) is True


def test_expiry_is_checked_per_call_not_once_at_load(kb, monkeypatch):
    kb.chunks[0].metadata["stale"] = False  # what load time computed
    assert "c0" in _ids(monkeypatch, date(2026, 11, 1))
    assert "c0" not in _ids(monkeypatch, date(2027, 1, 1))


def test_verified_cn_now_covers_water_activity_and_sleep_with_official_links():
    text = (Path(__file__).resolve().parents[1] / "app/rag/verified_cn.md").read_text(encoding="utf-8")
    chunks = _parse_markdown_into_chunks(text, "cn", source="verified")
    titles = {c.heading_path[-1] for c in chunks}
    assert {"每天喝多少水", "每周动多少", "成年人每周动多少", "成年人睡多久"} & titles
    for needle, url in [
        ("1700毫升", "http://dg.cnsoc.org/article/04/wDCyy7cWSJCN6pwKHOo5Dw.html"),
        ("累计150分钟以上", "http://dg.cnsoc.org/article/04/J4-AsD_DR3OLQMnHG0-jZA.html"),
        ("7至8小时", "https://www.nhc.gov.cn/guihuaxxs/c100133/201907/2a6ed52f1c264203b5351bdbbadd2da8.shtml"),
    ]:
        assert needle in text and f"链接：{url}" in text
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    urls = {r["url"] for r in manifest["authoritative_references"]}
    assert {"http://dg.cnsoc.org/article/04/wDCyy7cWSJCN6pwKHOo5Dw.html", "https://www.nhc.gov.cn/guihuaxxs/c100133/201907/2a6ed52f1c264203b5351bdbbadd2da8.shtml"} <= urls
