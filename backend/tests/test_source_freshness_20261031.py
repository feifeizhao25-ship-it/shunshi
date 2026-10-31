"""Chat sources carry last_verified_at and an honest freshness state."""
from datetime import date

from app.rag import evidence
from app.rag.evidence import freshness


class _Chunk:
    chunk_id = "c1"
    heading_path = ["Sleep"]
    content = "Link: https://example.org/x"

    def __init__(self, valid_until):
        self.metadata = {"source_file": "a.md", "evidence_status": "verified_official", "reviewed_at": "2026-08-30", "valid_until": valid_until}


def test_freshness_states():
    t = date(2026, 10, 31)
    assert freshness("2027-04-30", t)[0] == "current"
    assert freshness("2026-11-30", t) == ("review_due", 30)
    assert freshness("2026-10-31", t) == ("review_due", 0)
    assert freshness("2026-10-30", t)[0] == "expired"


def test_details_expose_last_verified_at_and_days():
    d = evidence._details([(_Chunk("2027-04-30"), 0.5)], "x", date(2026, 10, 31))[0]
    assert d["last_verified_at"] == "2026-08-30" == d["reviewed_at"]
    assert d["freshness"] == "current" and d["days_until_expiry"] == 181


def test_labels_downgrade_only_when_review_is_due():
    t = date(2026, 10, 31)
    due = evidence._details([(_Chunk("2026-11-30"), 0.5)], "x", t)[0]
    ok = evidence._details([(_Chunk("2027-04-30"), 0.5)], "x", t)[0]
    assert "Review due soon" in evidence._label_en(due) and "Review due soon" not in evidence._label_en(ok)
    assert "即将到期" in evidence._label_cn(due) and "官方资料已核验" in evidence._label_cn(due)
    assert "即将到期" not in evidence._label_cn(ok)


def test_real_context_returns_the_new_fields():
    from app.rag.knowledge_base import load_knowledge_bases

    load_knowledge_bases(force=True)
    _, labels, details = evidence.verified_global_context("how can I sleep better", 3)
    assert labels and all("last_verified_at" in x and x["freshness"] in {"current", "review_due"} for x in details)
