"""年度收获只写候选和差异报告，空签名不能发布。"""

import json
from datetime import date
from pathlib import Path

import pytest

from app.rag import yearly_harvest as harvest
from app.self_improve import library_job

TODAY = date(2026, 11, 6)
REPO = Path(__file__).resolve().parents[2]
APP = REPO / "backend" / "app"
OFFICIAL = APP / "self_improve" / "data" / "solar_terms_pmo_2026.json"
PRODUCTION_DIRS = (
    APP / "rag",
    APP / "skills",
    APP / "growth" / "skills",
    APP / "library" / "data",
    APP / "data",
    APP / "self_improve" / "data",
    REPO / "ios-cn" / "assets" / "library",
    REPO / "android-cn" / "assets" / "library",
)


def _files(root: Path) -> dict[str, bytes]:
    out = {}
    if not root.exists():
        return out
    for path in root.rglob("*"):
        if not path.is_file() or "__pycache__" in path.parts or path.suffix == ".pyc":
            continue
        out[path.relative_to(root).as_posix()] = path.read_bytes()
    return out


def _tree(root: Path) -> str:
    parts = []
    for path in sorted(root.rglob("*")):
        if path.is_file():
            parts.append(path.read_text(encoding="utf-8"))
    return "\n".join(parts)


def test_harvest_writes_sectioned_candidates_and_leaves_production_untouched(tmp_path):
    production = {path: _files(path) for path in PRODUCTION_DIRS}
    watched = [(path, path.read_bytes()) for path in harvest.default_production_paths()]
    assert any(path.name == "source_manifest.json" for path, _ in watched)
    assert any(path.name == "solar_terms.json" for path, _ in watched)
    assert any(path.name == "solar_terms_pmo_2026.json" for path, _ in watched)
    assert any(path.name == "reference_entries_v1.json" for path, _ in watched)
    assert any(path.name == "staged_entries_20261101c.json" for path, _ in watched)
    assert any(path.name == "core_skills.py" for path, _ in watched)
    skill = tmp_path / "skills" / "solar.md"
    skill.parent.mkdir()
    skill.write_text("production skill\n", encoding="utf-8")
    out = tmp_path / "candidates"
    report = harvest.harvest_yearly(candidates_dir=out, today=TODAY, production_paths=[skill])

    assert report["state"] == "unpublished"
    assert report["production_written"] is False
    assert report["auto_promoted"] is False
    assert report["scheduler_registered"] is False
    assert report["reviewer"] == ""
    assert report["named_reviewer"] is None
    assert report["review_status"] == "待审核"
    assert report["cadence"] == harvest.HARVEST_CADENCE_LABEL
    assert report["timezone"] == "Asia/Shanghai"
    assert report["added"] == [
        "SS-01",
        "SS-02",
        "SS-03",
        "SS-11",
        "SS-DIET-CORE",
        "SS-DIET-WATER",
        "SS-DIET-ACTIVITY",
        "SS-DIET-OIL",
    ]
    assert report["skipped"] == []
    assert report["sections"]["solar-terms"] == ["SS-01", "SS-02", "SS-03"]
    assert report["sections"]["dietary-guidelines"] == ["SS-11", "SS-DIET-CORE", "SS-DIET-WATER", "SS-DIET-ACTIVITY", "SS-DIET-OIL"]
    assert {item["id"] for item in report["left_out"]} >= {"SS-04", "SS-12", "SS-19", "USDA-seasonal-produce", "AU-eat-for-health"}

    official = json.loads(OFFICIAL.read_text(encoding="utf-8"))
    ss01 = json.loads((out / "solar-terms" / "SS-01.json").read_text(encoding="utf-8"))
    assert ss01["reviewer"] == "" and ss01["named_reviewer"] is None
    assert ss01["review_status"] == "待审核" and ss01["state"] == "unpublished"
    assert ss01["almanac_published"] is False
    assert ss01["url"] == official["url"]
    assert ss01["publisher"] == "中国科学院紫金山天文台"
    assert ss01["doi"] == ""
    assert ss01["content_hash"] == harvest.sha256_bytes(ss01["excerpt"].encode("utf-8"))
    for field in harvest.CANDIDATE_FIELDS:
        assert field in ss01 and ss01[field] is not None
    for minute in official["terms"].values():
        assert minute in ss01["excerpt"]
    assert official["terms"]["大寒"].endswith("09:45")
    assert official["terms"]["大雪"].endswith("10:53")
    assert "09:44:41" in ss01["excerpt"] and "10:52:17" in ss01["excerpt"]
    assert "宜忌" not in ss01["excerpt"] and "吉凶" not in ss01["excerpt"]

    ss02 = json.loads((out / "solar-terms" / "SS-02.json").read_text(encoding="utf-8"))
    for minute in official["hko_zhongqi"].values():
        assert minute in ss02["excerpt"]
    assert ss02["url"].endswith("2026SolarTerms24.pdf")
    ss03 = json.loads((out / "solar-terms" / "SS-03.json").read_text(encoding="utf-8"))
    assert ss03["url"].endswith("/Solar_Term.htm")

    diet = json.loads((out / "dietary-guidelines" / "SS-DIET-CORE.json").read_text(encoding="utf-8"))
    assert diet["principle_only"] is True
    assert diet["expires_at"] == "2026-12-31"
    assert diet["reviewer"] == "" and "医疗功效" in diet["excerpt"]
    assert "dg.cnsoc.org" in json.loads((out / "dietary-guidelines" / "SS-11.json").read_text(encoding="utf-8"))["url"]
    water = json.loads((out / "dietary-guidelines" / "SS-DIET-WATER.json").read_text(encoding="utf-8"))
    assert "1700毫升" in water["excerpt"] and water["principle_only"] is True

    text = _tree(out)
    assert "# 顺时节气与膳食指南候选差异" in text
    assert "## 节气表" in text and "## 膳食指南一般原则" in text
    assert "本轮不写入" in text
    assert (out / "diff-report.md").exists() and (out / "diff-report.json").exists()
    records = []
    for path in out.rglob("*.json"):
        if path.name in {"diff-report.json", "manifest.json", "publish-receipt.json"}:
            continue
        records.append(json.loads(path.read_text(encoding="utf-8")))
    record_blob = json.dumps(records, ensure_ascii=False)
    for banned in (
        "f01895a06c5349ef999f25da833c166d",
        "svjack",
        "The_24_Solar_Terms_Scene_Caption",
        "snaped.fns.usda.gov",
        "eatforhealth.gov.au",
        "disclosures-101-social-media-influencers",
        "Balban",
        "高脂血症",
        "肥胖食养",
        "宜忌",
        "吉凶",
    ):
        assert banned not in record_blob
    assert "90c64c79708740a1bca0ee31e524caf7" in record_blob

    for path, files in production.items():
        assert _files(path) == files
    for path, blob in watched:
        assert path.read_bytes() == blob
    assert skill.read_text(encoding="utf-8") == "production skill\n"
    assert not (REPO / "ios-global" / "assets" / "library").exists()
    assert not (REPO / "android-global" / "assets" / "library").exists()


def test_second_harvest_is_a_diff_not_a_publish(tmp_path):
    out = tmp_path / "candidates"
    first = harvest.harvest_yearly(candidates_dir=out, today=TODAY)
    second = harvest.harvest_yearly(candidates_dir=out, today=TODAY)
    assert first["added"]
    assert second["added"] == []
    assert second["changed"] == []
    assert second["unchanged"] == first["added"]
    assert second["production_written"] is False
    assert second["auto_promoted"] is False


def test_a_source_removed_from_the_catalog_is_dropped_from_the_tree(tmp_path):
    catalog = tmp_path / "catalog.json"
    catalog.write_bytes(harvest.CATALOG_PATH.read_bytes())
    out = tmp_path / "candidates"
    harvest.harvest_yearly(candidates_dir=out, today=TODAY, catalog_path=catalog)
    data = json.loads(catalog.read_text(encoding="utf-8"))
    data["sources"] = [source for source in data["sources"] if source["id"] != "SS-11"]
    catalog.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
    report = harvest.harvest_yearly(candidates_dir=out, today=TODAY, catalog_path=catalog)
    assert report["removed"] == ["SS-11"]
    assert report["production_written"] is False
    assert not (out / "dietary-guidelines" / "SS-11.json").exists()


def test_changed_excerpt_shows_up_in_the_diff_and_stays_unpublished(tmp_path):
    catalog = tmp_path / "catalog.json"
    catalog.write_text(harvest.CATALOG_PATH.read_text(encoding="utf-8"), encoding="utf-8")
    out = tmp_path / "candidates"
    harvest.harvest_yearly(candidates_dir=out, today=TODAY, catalog_path=catalog)
    data = json.loads(catalog.read_text(encoding="utf-8"))
    data["sources"][0]["excerpt"] += " 复核人仍为空。"
    catalog.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
    report = harvest.harvest_yearly(candidates_dir=out, today=TODAY, catalog_path=catalog)
    assert report["changed"] == ["SS-01"]
    row = json.loads((out / "solar-terms" / "SS-01.json").read_text(encoding="utf-8"))
    assert row["reviewer"] == "" and row["state"] == "unpublished"
    assert "有变化" in (out / "diff-report.md").read_text(encoding="utf-8")


def test_blocked_and_unconfirmed_urls_are_not_written(tmp_path):
    catalog = harvest.load_catalog()
    urls = {source["url"].rstrip("/") for source in catalog["sources"]}
    blocked = {url.rstrip("/") for url in catalog["blocked_urls"]}
    assert urls.isdisjoint(blocked)
    assert not any("huggingface.co" in url or "usda.gov" in url or "eatforhealth" in url for url in urls)
    ss12 = next(url for url in catalog["blocked_urls"] if "f01895a06c5349ef999f25da833c166d" in url)
    usda = next(url for url in catalog["blocked_urls"] if "snaped.fns.usda.gov" in url)
    ftc = next(url for url in catalog["blocked_urls"] if "disclosures-101-social-media-influencers" in url)
    path = tmp_path / "catalog.json"
    path.write_text(
        json.dumps(
            {
                **catalog,
                "sources": [
                    {"id": "BLOCKED-1", "section": "solar-terms", "url": ss12, "publisher": "国家卫生健康委", "excerpt": "must not land", "language": "zh"},
                    {"id": "BLOCKED-2", "section": "dietary-guidelines", "url": usda, "publisher": "USDA", "excerpt": "must not land", "language": "en"},
                    {"id": "BLOCKED-3", "section": "solar-terms", "url": ftc, "publisher": "FTC", "excerpt": "must not land", "language": "en"},
                    {"id": "MISSING-1", "section": "solar-terms", "url": "", "publisher": "未知", "excerpt": "must not land", "language": "zh"},
                    {"id": "THIRD-1", "section": "solar-terms", "url": "https://24jieqi.aboutchn.com/2026", "publisher": "第三方", "excerpt": "must not land", "language": "zh"},
                    {"id": "LUCK-1", "section": "solar-terms", "url": "https://www.hko.gov.hk/example", "宜": "出行", "excerpt": "must not land", "language": "zh"},
                ],
            },
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )
    out = tmp_path / "candidates"
    report = harvest.harvest_yearly(candidates_dir=out, today=TODAY, catalog_path=path)
    assert report["added"] == []
    assert [row["status"] for row in report["skipped"]] == [
        "blocked_unverified_url",
        "blocked_unverified_url",
        "blocked_unverified_url",
        "unconfirmed_url",
        "unconfirmed_url",
        "almanac_unpublished",
    ]
    assert _tree(out).count("must not land") == 0
    assert not (out / "solar-terms" / "BLOCKED-1.json").exists()


def test_fetcher_hashes_bytes_and_keeps_the_catalog_excerpt(tmp_path):
    out = tmp_path / "candidates"

    def fetch(_url: str) -> bytes:
        return "official-page".encode("utf-8")

    harvest.harvest_yearly(candidates_dir=out, today=TODAY, fetcher=fetch)
    row = json.loads((out / "solar-terms" / "SS-01.json").read_text(encoding="utf-8"))
    assert row["fetch_status"] == "fetched"
    assert row["content_hash"] == harvest.sha256_bytes(b"official-page")
    assert "大寒 2026-01-20 09:45" in row["excerpt"]
    assert row["reviewer"] == ""

    def fail(_url: str) -> bytes:
        raise OSError("offline")

    report = harvest.harvest_yearly(candidates_dir=out, today=TODAY, fetcher=fail)
    failed = json.loads((out / "solar-terms" / "SS-01.json").read_text(encoding="utf-8"))
    assert failed["fetch_status"] == "fetch_failed"
    assert "offline" in failed["fetch_error"]
    assert failed["content_hash"] == harvest.sha256_bytes(failed["excerpt"].encode("utf-8"))
    assert "SS-01" in report["changed"]


def test_publish_refuses_empty_signature_and_does_not_copy_into_production(tmp_path):
    out = tmp_path / "candidates"
    harvest.harvest_yearly(candidates_dir=out, today=TODAY)
    watched = [(path, path.read_bytes()) for path in harvest.default_production_paths()]
    candidate = (out / "solar-terms" / "SS-01.json").read_bytes()
    with pytest.raises(ValueError, match="reviewer_signature is empty"):
        harvest.publish_candidates("", candidates_dir=out)
    with pytest.raises(ValueError, match="reviewer_signature is empty"):
        harvest.publish_candidates("   ", candidates_dir=out)
    assert not (out / "publish-receipt.json").exists()
    receipt = harvest.publish_candidates("reviewer-signed-in-the-call", candidates_dir=out)
    assert receipt["production_written"] is False
    assert receipt["auto_promoted"] is False
    assert receipt["reviewer_on_candidates"] == ""
    assert receipt["named_reviewer"] is None
    assert receipt["state"] == "queued_unpublished"
    assert receipt["review_status"] == "待审核"
    assert (out / "solar-terms" / "SS-01.json").read_bytes() == candidate
    row = json.loads(candidate.decode("utf-8"))
    assert row["reviewer"] == "" and row["state"] == "unpublished"
    assert "大雪 2026-12-07 10:53" in row["excerpt"]
    for path, blob in watched:
        assert path.read_bytes() == blob
    staged = json.loads((APP / "library" / "data" / "staged_entries_20261101c.json").read_text(encoding="utf-8"))
    assert staged["entries"][0]["review_status"] == "待审核"
    assert "reviewer" not in staged["entries"][0] or staged["entries"][0].get("reviewer", "") == ""


def test_publish_refuses_a_filled_reviewer_without_writing_a_receipt(tmp_path):
    out = tmp_path / "candidates"
    harvest.harvest_yearly(candidates_dir=out, today=TODAY)
    path = out / "dietary-guidelines" / "SS-11.json"
    row = json.loads(path.read_text(encoding="utf-8"))
    row["reviewer"] = "不该出现的名字"
    path.write_text(json.dumps(row, ensure_ascii=False), encoding="utf-8")
    with pytest.raises(RuntimeError, match="reviewer empty"):
        harvest.publish_candidates("signed-in-the-call", candidates_dir=out)
    assert not (out / "publish-receipt.json").exists()
    assert json.loads(path.read_text(encoding="utf-8"))["review_status"] == "待审核"


def test_harvest_refuses_production_registry_rag_and_skills_directories(tmp_path):
    roots = harvest.production_roots()
    assert any(path.name == "rag" for path in roots)
    assert any(path.name == "skills" and path.parent.name == "app" for path in roots)
    assert any(path.name == "data" and path.parent.name == "library" for path in roots)
    for root in roots:
        with pytest.raises(PermissionError, match="production registry, RAG, or skills"):
            harvest.harvest_yearly(candidates_dir=root, today=TODAY)
        with pytest.raises(PermissionError, match="production registry, RAG, or skills"):
            harvest.publish_candidates("signed-in-the-call", candidates_dir=root)
    with pytest.raises(PermissionError):
        harvest.harvest_yearly(candidates_dir=APP / "rag" / "nested-candidates", today=TODAY)
    assert not (APP / "rag" / "nested-candidates").exists()


def test_hook_is_manual_and_does_not_enable_gates_or_the_scheduler(tmp_path, monkeypatch):
    monkeypatch.delenv("LIBRARY_FRESHNESS_ENABLED", raising=False)
    monkeypatch.delenv("SIL_ENABLED", raising=False)
    assert library_job.enabled() is False
    assert "harvest" not in library_job.jobs()
    from app.self_improve import continuous
    from app.self_improve.scheduler import SCHEDULE_DEFAULTS

    assert "harvest" not in continuous.jobs()
    assert all(not str(spec).startswith("yearly") for spec in SCHEDULE_DEFAULTS.values())
    serve = Path(continuous.__file__).read_text(encoding="utf-8").split("def jobs", 1)[0]
    run_src = (APP / "self_improve" / "run.py").read_text(encoding="utf-8")
    serve_branch = run_src.split('if cmd == "serve":', 1)[1]
    assert "harvest" not in serve_branch
    assert "yearly_harvest" not in serve
    module = Path(harvest.__file__).read_text(encoding="utf-8")
    assert "urlopen" not in module
    assert "review_cli" not in module
    assert "LIBRARY_FRESHNESS_ENABLED" not in module.split('"""', 2)[2]

    def boom(*_args, **_kwargs):
        raise AssertionError("SIL loop must stay stopped")

    monkeypatch.setattr("app.self_improve.run.build_loop", boom)
    from app.self_improve import run

    out = tmp_path / "candidates"
    assert run.main(["harvest", "--out", str(out)]) == 0
    assert (out / "diff-report.md").exists()
    assert run.main(["publish-candidates", "--out", str(out), "--signature", ""]) == 2
    assert run.main(["publish-candidates", "--out", str(out)]) == 2
    assert not (out / "publish-receipt.json").exists()
    assert run.main(["publish-candidates", "--signature", "signed-in-the-call", "--out", str(out)]) == 0
    row = json.loads((out / "solar-terms" / "SS-02.json").read_text(encoding="utf-8"))
    assert row["reviewer"] == "" and row["review_status"] == "待审核" and row["state"] == "unpublished"
    assert library_job.enabled() is False
    assert os_flags_unchanged()


def os_flags_unchanged() -> bool:
    import os

    return os.environ.get("LIBRARY_FRESHNESS_ENABLED") in (None, "", "0") and os.environ.get("SIL_ENABLED") in (None, "", "0")


def test_module_cli_refuses_an_empty_signature(tmp_path, capsys):
    out = tmp_path / "candidates"
    assert harvest.main(["harvest", "--out", str(out)]) == 0
    assert "未写入生产库" in capsys.readouterr().out
    assert harvest.main(["publish-candidates", "--out", str(out), "--signature", " "]) == 2
    err = capsys.readouterr().err
    assert "reviewer_signature is empty" in err
    assert not (out / "publish-receipt.json").exists()
