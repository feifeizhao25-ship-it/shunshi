"""ss-lib-011: the 2026 online-food false-advertising campaign was announced as
"2026 年 4 月起为期半年" (市监特食发〔2026〕33号). By 2026-11 the summary must not
read as if the campaign is just starting, and the document number must be cited."""
import json
from pathlib import Path

DATA = Path(__file__).resolve().parents[1] / "app" / "library" / "data" / "reference_entries_v1.json"


def _entry():
    d = json.loads(DATA.read_text(encoding="utf-8"))
    rows = d if isinstance(d, list) else d.get("entries", [])
    return next(e for e in rows if e["id"] == "ss-lib-011")


def test_doc_number_cited():
    assert "市监特食发〔2026〕33号" in _entry()["source"]["doc_no"]


def test_summary_marks_campaign_period():
    e = _entry()
    assert "为期半年" in e["summary"]
    assert "一直违法" in e["summary"]
    assert "2026-11-23" in e["status_note"]
    assert e["status"] == "待核实"
