"""Fact corrections found in the 2026-11-23 source check (step 5 items 68/69/71).

- 《中国居民膳食指南》第五次修订是 2025-09-21 启动的（中国科协 2025-09-26 报道），
  2026-06-15～17 是第五次修订工作会议（中国营养学会膳食指南网 2026-06-18）。
- 准则六：男 1700ml、女 1500ml，每杯 200ml → 男约 8.5 杯、女约 7.5 杯。
- 平衡膳食八准则原文页发布时间 2022-04-26。
"""
import json
import re
from pathlib import Path

RAG = Path(__file__).resolve().parents[1] / "app" / "rag"
FILES = ["verified_cn.md", "source_manifest.json", "yearly_sources.json"]


def test_revision_start_date_is_not_june_2026():
    for name in FILES:
        text = (RAG / name).read_text(encoding="utf-8")
        assert not re.search(r"2026\s*(年\s*6\s*月|-06)\s*启动", text), name
        if "第五次修订" in text:
            assert re.search(r"2025\s*(年\s*9\s*月|-09)\s*启动", text), name


def test_cup_counts_match_millilitres():
    text = (RAG / "verified_cn.md").read_text(encoding="utf-8")
    assert "1700毫升" in text and "1500毫升" in text
    assert "男性约8至9杯" in text and "女性约7至8杯" in text
    # 1700/200 = 8.5, 1500/200 = 7.5
    assert 8 <= 1700 / 200 <= 9 and 7 <= 1500 / 200 <= 8


def test_eight_guidelines_page_has_publish_date():
    data = json.loads((RAG / "source_manifest.json").read_text(encoding="utf-8"))
    hit = [r for r in data["authoritative_references"]
           if r.get("url", "").endswith("J4-AsD_DR3OLQMnHG0-jZA.html")]
    assert hit and hit[0]["published_at"] == "2022-04-26"
