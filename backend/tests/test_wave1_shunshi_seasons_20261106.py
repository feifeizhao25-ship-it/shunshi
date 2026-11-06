"""第一波：节气之外的膳食、作息、引用与日照规则。"""

import hashlib
import json
from datetime import date
from pathlib import Path

from app.aigc import AI_IDENTITY_NOTICE
from app.entitlements import citation_depth_for_tier
from app.rag import claim_policy, evidence
from app.rag.knowledge_base import _apply_section_policies, _parse_markdown_into_chunks, _source_metadata
from app.rag.sleep_light import SLEEP_LIGHT_SOURCES, light_habit_brief, sleep_schedule_brief, two_minute_calm_note
from app.services.continuous_use import REMINDER_INTERVAL_SECONDS
from app.utils.noaa_solar import day_length_hours, sun_times

RAG = Path(__file__).resolve().parents[1] / "app" / "rag"
MANIFEST = json.loads((RAG / "source_manifest.json").read_text(encoding="utf-8"))


def _verified_cn_chunks():
    text = (RAG / "verified_cn.md").read_text(encoding="utf-8")
    chunks = _parse_markdown_into_chunks(text, "cn", source="verified")
    meta = _source_metadata(RAG / "verified_cn.md")
    for chunk in chunks:
        chunk.metadata.update(meta)
        _apply_section_policies("verified_cn.md", chunk)
    return text, chunks


def test_diet_entries_are_principles_with_a_review_by_date_and_disease_guides_stay_out():
    text, chunks = _verified_cn_chunks()
    diet = [c for c in chunks if "膳食指南" in c.content]
    assert diet
    for chunk in diet:
        assert chunk.metadata["principle_only"] is True
        assert chunk.metadata["medical_efficacy"] is False
        assert chunk.metadata["valid_until"] == "2026-12-31"
        assert chunk.metadata["review_by"] == "2026-12-31"
    assert "医疗功效" in text and "2026-12-31" in text
    assert "肥胖食养指南" not in text
    assert "高脂血症" not in text
    blob = json.dumps(MANIFEST["authoritative_references"], ensure_ascii=False)
    excluded = {item["id"] for item in MANIFEST["excluded_from_main_rag"]}
    assert {"SS-12", "SS-19", "NHC-child-obesity-diet-2024"} <= excluded
    assert "肥胖食养指南" not in blob
    assert "svjack" not in blob
    assert all(item["reviewer"] == "" and item["review_status"] == "待审核" for item in MANIFEST["excluded_from_main_rag"])


def test_sleep_copy_cites_duration_and_schedule_not_disease_or_cdc_benefits():
    text, chunks = _verified_cn_chunks()
    sleep = next(c for c in chunks if c.heading_path[-1] == "成年人睡多久")
    for banned in ("心脑血管", "抑郁症", "糖尿病", "肥胖", "免疫系统"):
        assert banned not in sleep.content
    assert "7至8小时" in sleep.content and "起居有常" in sleep.content
    global_text = (RAG / "verified_global.md").read_text(encoding="utf-8")
    for phrase in claim_policy.CDC_BENEFIT_PHRASES:
        assert phrase not in global_text.lower()
    assert "7 or more hours" in global_text
    assert "does not restate health-benefit claims" in global_text
    brief = sleep_schedule_brief("zh")
    assert brief["reviewer"] == "" and brief["cites_disease"] is False
    assert len(brief["grounds"]) == 3 and brief["today_action"]
    light = light_habit_brief("en")
    assert "lux" not in light["conclusion"].lower()
    note = two_minute_calm_note("en")
    assert note["studied_source_citable_for_two_minutes"] is False
    assert note["duration_minutes"] == 2 and note["studied_minutes"] == 5
    assert "five-minute" in note["text"]


def test_pending_or_expired_sources_cannot_solely_ground_a_high_risk_claim():
    pending = [{"chunk_id": "p", "evidence_status": "pending_review", "review_status": "待审核", "valid_until": "2027-01-01"}]
    assert claim_policy.sole_basis_blocks_high_risk(pending, date(2026, 11, 6))
    context, sources, details = claim_policy.ground_high_risk("这个能治疗失眠吗", "ctx", ["待审核"], pending, date(2026, 11, 6))
    assert context == "" and sources == [] and details == []
    verified = [{"chunk_id": "v", "evidence_status": "verified_official", "valid_until": "2027-04-30", "freshness": "current"}]
    kept = claim_policy.ground_high_risk("这个能治疗失眠吗", "ctx", ["ok"], verified, date(2026, 11, 6))
    assert kept[0] == "ctx" and kept[2] == verified
    principle = [{"chunk_id": "d", "evidence_status": "verified_official", "valid_until": "2026-12-31", "principle_only": True}]
    blocked = claim_policy.ground_high_risk("这茶有什么功效", "diet", ["原则"], principle, date(2026, 11, 6))
    assert blocked[0] == ""


def test_citation_depth_follows_the_existing_library_entitlement():
    assert citation_depth_for_tier("free") == "basic"
    assert citation_depth_for_tier("plus") == "full"
    assert citation_depth_for_tier("pro") == "full"
    assert citation_depth_for_tier("family") == "full"
    assert citation_depth_for_tier("no-such-tier") == "basic"
    details = evidence._details(
        [(_chunk(), 0.2)],
        "官方健康资料",
        today=date(2026, 11, 6),
        citation_depth="full",
    )
    assert details[0]["knowledge_version"] == "rag-shunshi@2026.11.06"
    assert details[0]["reviewed_at"] == "2026-11-01"
    assert "excerpt" in details[0]
    basic = evidence._details([(_chunk(), 0.2)], "官方健康资料", today=date(2026, 11, 6), citation_depth="basic")
    assert "excerpt" not in basic[0]


def test_new_sources_keep_an_empty_reviewer_and_a_content_hash():
    for source in SLEEP_LIGHT_SOURCES:
        assert source["reviewer"] == "" and source["review_status"] == "待审核"
        assert source["url"].startswith("https://")
        assert source["publisher"] and source["excerpt"] and source["retrieved_at"]
        digest = hashlib.sha256(source["excerpt"].encode("utf-8")).hexdigest()
        assert source["content_hash"] == digest


def test_noaa_day_length_follows_the_hemisphere_and_names_polar_day():
    june = date(2026, 6, 21)
    december = date(2026, 12, 21)
    assert day_length_hours(51.5, -0.12, june) > day_length_hours(51.5, -0.12, december)
    assert day_length_hours(-33.87, 151.21, june) < day_length_hours(-33.87, 151.21, december)
    polar = sun_times(69.65, 18.96, june)
    assert polar["status"] == "polar_day_or_night"
    assert polar["sunrise_utc"] is None and polar["sunset_utc"] is None


def test_companion_identity_and_two_hour_reminder_stay_explicit():
    assert "人工智能" in AI_IDENTITY_NOTICE and "不是真人" in AI_IDENTITY_NOTICE
    assert REMINDER_INTERVAL_SECONDS == 2 * 60 * 60


class _Chunk:
    def __init__(self):
        self.chunk_id = "c"
        self.content = "成年人每天大约 7 至 8 小时，起居有常。\n链接：https://www.nhc.gov.cn/example"
        self.heading_path = ["睡眠", "成年人睡多久"]
        self.metadata = {
            "source_file": "verified_cn.md",
            "evidence_status": "verified_official",
            "reviewed_at": "2026-11-01",
            "valid_until": "2027-02-28",
            "knowledge_version": "rag-shunshi@2026.11.06",
        }


def _chunk():
    return _Chunk()
