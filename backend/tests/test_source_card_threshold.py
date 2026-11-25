"""顺4：低相关来源不挂卡；候选资料保持待审核，不进入现行引用。"""
import json
from pathlib import Path

from app.rag.evidence import CN_SOURCE_CARD_MIN, verified_cn_context

CANDIDATES = Path(__file__).resolve().parents[1] / "app" / "library" / "data" / "candidates_20261124.json"


def test_candidate_library_stays_unreviewed():
    data = json.loads(CANDIDATES.read_text(encoding="utf-8"))
    assert data["reviewer"] is None
    assert len(data["entries"]) >= 12
    for entry in data["entries"]:
        assert entry["review_status"] == "待审核"
        assert entry["reviewer"] is None
        assert entry["source"] and entry["valid_until"]


def test_source_cards_never_below_threshold():
    _, _, loose = verified_cn_context("气郁质住在北京，小雪这天该不该温肾助阳")
    assert all(item["relevance"] >= CN_SOURCE_CARD_MIN for item in loose)
    assert "平衡膳食" not in " ".join(item["title"] for item in loose)
    _, _, water = verified_cn_context("每天喝多少水", today=__import__("datetime").date(2026, 11, 13))
    assert any(item["title"] == "每天喝多少水" for item in water)
    _, labels, matched = verified_cn_context("怎样做到食物多样、少盐少油的平衡膳食？")
    titles = [item["title"] for item in matched]
    assert "平衡膳食八项基本原则" in titles
    assert "成年人每周动多少" not in titles
    assert labels
    assert all(item["relevance"] >= CN_SOURCE_CARD_MIN for item in matched)
    assert all(item["evidence_status"] == "verified_official" for item in matched)


def test_candidates_are_not_cited_as_verified_sources():
    _, _, details = verified_cn_context("怎样做到食物多样、少盐少油的平衡膳食？")
    cited = {item.get("chunk_id") for item in details}
    raw = CANDIDATES.read_text(encoding="utf-8")
    for entry in json.loads(raw)["entries"]:
        assert entry["id"] not in cited
        assert entry["id"] not in raw or entry["review_status"] == "待审核"
