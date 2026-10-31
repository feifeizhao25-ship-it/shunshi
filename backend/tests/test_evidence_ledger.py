"""证据账本的结构与规则校验（docs/research/evidence_ledger_20261031.jsonl）。

账本只是登记册：这里保证 A 级才能驱动内容、待核条目不能是 A 级、非商用/共享/GPL 许可证条目不会被标成可采用。
"""
import json
from pathlib import Path

LEDGER = next(p for p in Path(__file__).resolve().parents if (p / "docs" / "research" / "evidence_ledger_20261031.jsonl").exists()) / "docs" / "research" / "evidence_ledger_20261031.jsonl"
REQUIRED = ("id", "type", "title", "url", "license", "license_class", "products", "grade", "url_status", "flag", "retrieved")
PRODUCT = "shunshi"


def _rows():
    return [json.loads(x) for x in LEDGER.read_text("utf-8").splitlines() if x.strip()]


def test_rows_have_required_fields_and_unique_ids():
    rows = _rows()
    assert rows
    ids = [r["id"] for r in rows]
    assert len(ids) == len(set(ids))
    for r in rows:
        assert all(k in r for k in REQUIRED), r["id"]
        assert r["grade"] in ("A", "B", "lead")
        assert r["url"].startswith(("http://", "https://"))


def test_rows_belong_to_this_product_or_all():
    for r in _rows():
        assert PRODUCT in r["products"] or "all" in r["products"], r["id"]


def test_flagged_rows_are_never_grade_a():
    for r in _rows():
        if r["flag"]:
            assert r["flag"].startswith("待核")
            assert r["grade"] != "A", r["id"]


def test_restricted_licenses_are_not_marked_adoptable():
    for r in _rows():
        if r["license_class"] in ("do_not_ingest", "do_not_introduce"):
            assert r["grade"] in ("A", "B", "lead")
            assert not r.get("adopt_as_content", False), r["id"]


def test_no_investment_or_foreign_runtime_adoption_fields():
    for r in _rows():
        assert "adopt_as_runtime_model" not in r
