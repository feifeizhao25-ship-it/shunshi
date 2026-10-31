"""持续改进（金标准评测 / 陈旧扫描 / 雷达暂存 / 月报）测试：默认关闭、只写数据目录、不碰用户可见资料库、候选永不自动通过。"""

import json
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

import pytest

from app.library import store
from app.self_improve import continuous as C
from app.self_improve import golden as G
from app.self_improve import monthly_report as MR
from app.self_improve import radar_stage as RS
from app.self_improve import stale as S
from app.self_improve.config import SILConfig

TZ = timezone(timedelta(hours=8))
NOW = datetime(2026, 11, 1, 5, 0, tzinfo=TZ)


def cfg(tmp_path, enabled=True):
    return SILConfig(product="shunshi", enabled=enabled, data_dir=str(tmp_path / "sil"))


def test_defaults_are_off(monkeypatch, tmp_path):
    for k in ("SIL_ENABLED", "SIL_AUTO_PROMOTE_INTERNAL"):
        monkeypatch.delenv(k, raising=False)
    c = cfg(tmp_path, enabled=False)
    for fn in (C.run_golden, C.run_stale, C.run_radar, C.run_radar_stage, C.run_monthly_report):
        assert fn(NOW, cfg=c) == {"status": "disabled"}
    assert not (tmp_path / "sil").exists()
    assert C.SLOTS["golden_eval"].startswith("weekly:") and C.SLOTS["monthly_report"].startswith("monthly:")


def test_golden_file_valid_and_covers_every_skill():
    cases = G.load(C.GOLDEN_FILE)
    v = G.validate_all(cases, "zh")
    assert v["invalid"] == {}, v
    cov = G.coverage(cases, C.skill_ids())
    assert cov["missing"] == [], cov
    for c in cases:
        assert c["review_status"] == "待审核"  # 没有人审核签字，不能写“已审核”
        assert c["expect"] == "refuse" or (c["sources"] and all(s["url"].startswith("https://") for s in c["sources"]))


def test_golden_run_passes_on_bundled_content_and_writes_only_data_dir(tmp_path):
    out = C.run_golden(NOW, force=True, cfg=cfg(tmp_path))
    assert out["status"] == "ok" and out["n"] >= 30
    assert out["pass_rate"] >= 0.9, out["failures"]
    assert (tmp_path / "sil" / "golden" / "last.json").exists()


def test_golden_regression_goes_to_worklist(tmp_path):
    c = cfg(tmp_path)
    cases = G.load(C.GOLDEN_FILE)[:3]
    good = lambda case: {"text": " ".join(case.get("must_include", [])), "citations": [s["url"] for s in case["sources"]], "refused": case["expect"] == "refuse"}
    good.wants_case = True
    bad = lambda case: {"text": "无关"}
    bad.wants_case = True
    first = C.run_golden(NOW, cases=cases, answer_fn=good, cfg=c)
    assert first["regressions"] == []
    second = C.run_golden(NOW + timedelta(days=7), cases=cases, answer_fn=bad, cfg=c)
    assert set(second["regressions"]) == {x["id"] for x in cases}
    assert len((tmp_path / "sil" / "worklist.jsonl").read_text("utf-8").splitlines()) == len(cases)


def test_stale_flags_expired_expiring_and_unreviewed_manifest(tmp_path):
    out = C.run_stale(datetime(2026, 11, 20, tzinfo=TZ), force=True, cfg=cfg(tmp_path))
    assert out["status"] == "ok"
    rep = json.loads((tmp_path / "sil" / "stale_report.json").read_text("utf-8"))
    kinds = {(f["kind"], f["id"]) for f in rep["findings"]}
    # 旧知识库 valid_until=2026-11-30：20 天内到期要被提前发现
    assert any(k == "expiring_soon" and i.startswith("rag:顺时知识库") for k, i in kinds)
    # 暂存区条目都在“待审核”里被统计，但没有进入用户可见资料库
    assert all(e["id"] not in {x["id"] for x in store.load_document()["entries"]} for e in store.load_staged())


def test_staged_entries_never_visible_and_all_pending():
    staged = store.load_staged()
    assert {e["id"] for e in staged} >= {"ss-lib-s01", "ss-lib-s02", "ss-lib-s03"}
    visible = {e["id"] for e in store.annotated(date(2026, 11, 1), include_hidden=True)}
    assert not (visible & {e["id"] for e in staged})
    for e in staged:
        assert e["review_status"] == "待审核" and e["source"]["url"].startswith("https://")


def test_promote_keeps_pending_and_requires_reviewer(monkeypatch, tmp_path):
    from app.library import review_cli

    monkeypatch.setenv("SHUNSHI_LIBRARY_DIR", str(tmp_path / "lib"))
    assert review_cli.main(["promote", "ss-lib-s01", "--reviewer", "张三"]) == 0
    doc = json.loads((tmp_path / "lib" / "reference_entries.json").read_text("utf-8"))
    e = next(x for x in doc["entries"] if x["id"] == "ss-lib-s01")
    assert e["review_status"] == "待审核" and "reviewer" not in e
    assert review_cli.main(["promote", "ss-lib-s01", "--reviewer", "张三"]) == 2  # 不能重复
    assert review_cli.main(["promote", "nope", "--reviewer", "张三"]) == 2


def test_radar_stage_lead_only(tmp_path):
    c = cfg(tmp_path)
    radar_dir = tmp_path / "sil" / "radar"
    radar_dir.mkdir(parents=True)
    items = [
        {"source": "arxiv", "id": "2611.00001", "title": "Solar term wellness diet dataset", "summary": "tcm diet", "url": "https://arxiv.org/abs/2611.00001", "license": None},
        {"source": "github", "id": "a/gpl", "title": "TCM wellness tool", "summary": "x", "url": "https://github.com/a/gpl", "license": "GPL-2.0"},
        {"source": "arxiv", "id": "2611.00002", "title": "Unrelated rocket paper", "summary": "rocket", "url": "https://arxiv.org/abs/2611.00002", "license": None},
    ]
    (radar_dir / "items_20261101.json").write_text(json.dumps(items), "utf-8")
    out = C.run_radar_stage(NOW, force=True, cfg=c)
    assert out["staged"] == 2
    rows = RS.load_staged(tmp_path / "sil" / "library_staged.jsonl")
    assert all(r["review_status"] == "待审核" and r["kind"] == "lead" and not r["visible"] and not r["auto_approved"] for r in rows)
    assert {r["title"]: r["ingest_allowed"] for r in rows}["TCM wellness tool"] is False
    assert C.run_radar_stage(NOW, force=True, cfg=c)["staged"] == 0  # 去重


def test_monthly_report_md_json_pdf(tmp_path):
    c = cfg(tmp_path)
    C.run_golden(datetime(2026, 10, 25, 3, 30, tzinfo=TZ), force=True, cfg=c)
    out = C.run_monthly_report(NOW, force=True, cfg=c, env={})
    assert out["month"] == "2026-10"
    md = Path(out["markdown"]).read_text("utf-8")
    for h in ("改了什么", "评测", "陈旧", "等人审核"):
        assert h in md
    assert json.loads(Path(out["json"]).read_text("utf-8"))["month"] == "2026-10"
    assert "人工批准" in md
    if out.get("pdf"):
        assert Path(out["pdf"]).read_bytes()[:4] == b"%PDF"


def test_constitution_endpoint_says_it_is_not_the_national_standard():
    from app.router import constitution as K

    doc = (K._determine_levels.__doc__ or "")
    assert "GB/T 46939-2025" in doc and "自编" in doc
    assert "GB/T 46939-2025" in K.SubmitResponse.model_fields["standard_note"].default
