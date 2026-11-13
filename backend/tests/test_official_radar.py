"""每月官方清单只写候选和差异报告，默认不联网，空签名不能发布。"""

import json
from datetime import date
from pathlib import Path

import pytest

from app.self_improve import official_radar as radar
from app.self_improve.scheduler import SCHEDULE_DEFAULTS

TODAY = date(2026, 11, 13)
APP = Path(__file__).resolve().parents[1] / "app"
USABLE = {
    "ss-dg-revision-2026": (
        "http://dg.cnsoc.org/article/04/waGfsQ0aR9-yPu6Y_ebl5A.html",
        "政府/学会公开（引用）",
    ),
    "ss-dg-meeting-1029": (
        "https://en.cnsoc.org/news/512601201.html",
        "学会公开（引用）",
    ),
    "ss-nhc-dangshen-9": (
        "https://www.nhc.gov.cn/sps/c100088/202311/5b062dd13fe646198b56c7d76a99aab4.shtml",
        "政府公开文件（引用）",
    ),
    "ss-nhc-dihuang-4": (
        "https://www.nhc.gov.cn/sps/c100088/202408/53150d0918ec40899b5293147ec0dd01.shtml",
        "政府公开文件（引用）",
    ),
    "ss-samr-yaoshi-2026": (
        "https://www.samr.gov.cn/zw/zfxxgk/fdzdgknr/tssps/art/2026/art_fcdb8ed8982e45ed8250cdb0adcdb586.html",
        "政府公开文件（引用）",
    ),
}


def test_fixture_writes_candidates_and_diff_report_without_network(tmp_path, monkeypatch):
    def boom(*_args, **_kwargs):
        raise AssertionError("official list check must not open a network connection")

    monkeypatch.setattr("urllib.request.urlopen", boom, raising=False)
    out = tmp_path / "candidates"
    report = radar.harvest_official_list(candidates_dir=out, today=TODAY)
    assert report["scheduler_registered"] is False
    assert report["production_written"] is False
    assert report["reviewer"] == ""
    assert report["named_reviewer"] is None
    assert report["review_status"] == "待审核"
    assert report["cadence"] == radar.OFFICIAL_LIST_CADENCE_LABEL
    assert report["added"] == list(USABLE)
    assert report["skipped"] == []
    assert report["sections"]["cnsoc-dg"] == ["ss-dg-revision-2026", "ss-dg-meeting-1029"]
    assert report["sections"]["nhc-sps"] == ["ss-nhc-dangshen-9", "ss-nhc-dihuang-4"]
    assert report["sections"]["samr-tssps"] == ["ss-samr-yaoshi-2026"]
    text = (out / "diff-report.md").read_text(encoding="utf-8")
    assert "# 顺时每月官方清单候选差异" in text
    assert "中国营养学会·膳食指南" in text
    assert "国家卫生健康委·食品安全标准与监测评估" in text
    assert "市场监管总局·特殊食品" in text
    assert (out / "diff-report.json").exists()
    for source_id, (url, license_text) in USABLE.items():
        row = json.loads(next(out.rglob(source_id + ".json")).read_text(encoding="utf-8"))
        assert row["url"] == url
        assert row["license"] == license_text
        assert row["reviewer"] == "" and row["named_reviewer"] is None
        assert row["review_status"] == "待审核" and row["state"] == "unpublished"
        assert row["fetch_status"] == "not_fetched"
        assert row["content_hash"] == radar.sha256_bytes(row["excerpt"].encode("utf-8"))
        assert "功效" not in row["excerpt"] or "不新增功效声称" in row["excerpt"]
    revision = json.loads((out / "cnsoc-dg" / "ss-dg-revision-2026.json").read_text(encoding="utf-8"))
    assert revision["edition_status"] == "修订中"
    assert "不提前引用新版内容" in revision["excerpt"]
    assert "宜忌" not in text and "吉凶" not in text


def test_second_run_is_a_diff_and_a_changed_excerpt_stays_unpublished(tmp_path):
    out = tmp_path / "candidates"
    first = radar.harvest_official_list(candidates_dir=out, today=TODAY)
    second = radar.harvest_official_list(candidates_dir=out, today=TODAY)
    assert second["added"] == [] and second["changed"] == []
    assert second["unchanged"] == first["added"]
    catalog = tmp_path / "catalog.json"
    data = radar.load_catalog()
    data["sources"][0]["excerpt"] += " 复核人仍为空。"
    catalog.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
    report = radar.harvest_official_list(candidates_dir=out, today=TODAY, catalog_path=catalog)
    assert report["changed"] == ["ss-dg-revision-2026"]
    row = json.loads((out / "cnsoc-dg" / "ss-dg-revision-2026.json").read_text(encoding="utf-8"))
    assert row["reviewer"] == "" and row["state"] == "unpublished"


def test_bad_license_almanac_and_blank_url_are_not_written(tmp_path):
    catalog = radar.load_catalog()
    path = tmp_path / "catalog.json"
    path.write_text(
        json.dumps(
            {
                **catalog,
                "sources": [
                    {"id": "NC-1", "section": "cnsoc-dg", "url": "https://example.com/nc", "publisher": "x", "license": "CC-BY-NC-4.0", "excerpt": "must not land"},
                    {"id": "GPL-1", "section": "nhc-sps", "url": "https://example.com/gpl", "publisher": "x", "license": "GPL-3.0", "excerpt": "must not land"},
                    {"id": "UNK-1", "section": "samr-tssps", "url": "https://example.com/unk", "publisher": "x", "license": "", "excerpt": "must not land"},
                    {"id": "BLANK-1", "section": "cnsoc-dg", "url": "", "publisher": "x", "license": "政府公开文件（引用）", "excerpt": "must not land"},
                    {"id": "LUCK-1", "section": "cnsoc-dg", "url": "https://example.com/luck", "publisher": "x", "license": "政府公开文件（引用）", "宜": "出行", "excerpt": "must not land"},
                ],
            },
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )
    out = tmp_path / "candidates"
    report = radar.harvest_official_list(candidates_dir=out, today=TODAY, catalog_path=path)
    assert report["added"] == []
    assert [row["status"] for row in report["skipped"]] == [
        "license_rejected",
        "license_rejected",
        "license_rejected",
        "unconfirmed_url",
        "almanac_unpublished",
    ]
    blob = "\n".join(path.read_text(encoding="utf-8") for path in out.rglob("*") if path.is_file())
    assert "must not land" not in blob


def test_injected_fetcher_is_optional_and_hashes_fixture_bytes(tmp_path):
    out = tmp_path / "candidates"
    seen = []

    def fetch(url: str) -> bytes:
        seen.append(url)
        return b"fixture-page"

    radar.harvest_official_list(candidates_dir=out, today=TODAY, fetcher=fetch)
    row = json.loads((out / "samr-tssps" / "ss-samr-yaoshi-2026.json").read_text(encoding="utf-8"))
    assert seen and row["fetch_status"] == "fetched"
    assert row["content_hash"] == radar.sha256_bytes(b"fixture-page")
    assert "106" in row["excerpt"]
    assert row["reviewer"] == ""


def test_empty_signature_is_refused_and_a_signature_does_not_fill_the_reviewer(tmp_path):
    out = tmp_path / "candidates"
    radar.harvest_official_list(candidates_dir=out, today=TODAY)
    candidate = (out / "nhc-sps" / "ss-nhc-dihuang-4.json").read_bytes()
    with pytest.raises(ValueError, match="reviewer_signature is empty"):
        radar.publish_official_list("", candidates_dir=out)
    with pytest.raises(ValueError, match="reviewer_signature is empty"):
        radar.publish_official_list("   ", candidates_dir=out)
    assert not (out / "publish-receipt.json").exists()
    receipt = radar.publish_official_list("reviewer-signed-in-the-call", candidates_dir=out)
    assert receipt["production_written"] is False
    assert receipt["reviewer_on_candidates"] == ""
    assert receipt["named_reviewer"] is None
    assert receipt["review_status"] == "待审核"
    assert (out / "nhc-sps" / "ss-nhc-dihuang-4.json").read_bytes() == candidate
    row = json.loads(candidate.decode("utf-8"))
    assert row["reviewer"] == "" and row["state"] == "unpublished"


def test_publish_refuses_a_filled_reviewer_without_writing_a_receipt(tmp_path):
    out = tmp_path / "candidates"
    radar.harvest_official_list(candidates_dir=out, today=TODAY)
    path = out / "cnsoc-dg" / "ss-dg-meeting-1029.json"
    row = json.loads(path.read_text(encoding="utf-8"))
    row["reviewer"] = "不该出现的名字"
    path.write_text(json.dumps(row, ensure_ascii=False), encoding="utf-8")
    with pytest.raises(RuntimeError, match="reviewer empty"):
        radar.publish_official_list("signed-in-the-call", candidates_dir=out)
    assert not (out / "publish-receipt.json").exists()


def test_hook_is_not_scheduled_and_cli_refuses_an_empty_signature(tmp_path, monkeypatch, capsys):
    monkeypatch.delenv("LIBRARY_FRESHNESS_ENABLED", raising=False)
    monkeypatch.delenv("SIL_ENABLED", raising=False)
    from app.self_improve import continuous, library_job

    assert radar.SCHEDULER_REGISTERED is False
    assert library_job.enabled() is False
    assert "official-list" not in library_job.jobs()
    assert "official_radar" not in continuous.jobs()
    assert all("15@03:00" not in str(spec) for spec in SCHEDULE_DEFAULTS.values())
    module = Path(radar.__file__).read_text(encoding="utf-8")
    body = module.split('"""', 2)[2]
    for token in ("urlopen", "httpx", "requests", "socket"):
        assert token not in body
    run_src = (APP / "self_improve" / "run.py").read_text(encoding="utf-8")
    serve_branch = run_src.split('if cmd == "serve":', 1)[1]
    assert "official-list" not in serve_branch
    assert "official_radar" not in serve_branch
    out = tmp_path / "candidates"
    from app.self_improve import run

    assert run.main(["official-list", "--out", str(out)]) == 0
    assert (out / "diff-report.md").exists()
    assert run.main(["publish-official-list", "--out", str(out), "--signature", ""]) == 2
    assert "reviewer_signature is empty" in capsys.readouterr().err
    assert not (out / "publish-receipt.json").exists()
    herbs = (APP / "router" / "maternity.py").read_text(encoding="utf-8")
    assert "FORBIDDEN_HERBS_DATA" in herbs
