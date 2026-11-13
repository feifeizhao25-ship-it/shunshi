"""膳食指南过了 valid_until 之后，2022 版不能再当现行的唯一依据，回答要写明版本。"""

from datetime import date

from app.rag import evidence
from app.rag.freshness_gate import REVISION_NOTICE, select_verified
from app.rag.knowledge_base import cn_kb, load_knowledge_bases
from app.rag.retriever import retrieve
from app.self_improve import evals

CLOCK = date(2027, 1, 1)
BEFORE = date(2026, 11, 13)


def test_before_expiry_the_answer_names_the_2022_edition():
    load_knowledge_bases(force=True)
    picked = select_verified("每天喝多少水", today=BEFORE, top_k=3)
    assert picked["edition"] == "2022"
    assert picked["notice"] == ""
    assert picked["sole_basis"] is True
    assert picked["current"]
    assert "2022" in picked["text"]
    _context, labels, details = evidence.verified_cn_context("每天喝多少水", top_k=3, today=BEFORE)
    assert details
    assert any(item.get("edition") == "2022" for item in details)
    assert any("2022版" in label for label in labels)
    assert all(item["evidence_status"] == "verified_official" for item in details)


def test_on_2027_01_01_the_2022_edition_is_not_the_sole_basis_and_the_answer_says_so():
    load_knowledge_bases(force=True)
    picked = select_verified("每天喝多少水", today=CLOCK, top_k=3)
    assert picked["revision_in_progress"] is True
    assert picked["sole_basis"] is False
    assert picked["edition"] == "2022"
    assert picked["text"].startswith(REVISION_NOTICE)
    assert "2022" in picked["text"]
    expired_ids = {chunk.chunk_id for chunk, _ in picked["expired_2022"]}
    current_ids = {chunk.chunk_id for chunk, _ in picked["current"]}
    assert expired_ids
    assert expired_ids.isdisjoint(current_ids)
    for chunk, _ in picked["current"]:
        assert chunk.metadata["valid_until"] >= "2027-01-01"
    context, labels, details = evidence.verified_cn_context("每天喝多少水", top_k=3, today=CLOCK)
    assert context.startswith(REVISION_NOTICE)
    assert all(item["chunk_id"] not in expired_ids for item in details)
    assert all("2022版" not in label or item["valid_until"] >= "2027-01-01" for label, item in zip(labels, details))


def test_freshness_correctness_stays_one_when_the_clock_is_2027_01_01():
    load_knowledge_bases(include_legacy=True, force=True)
    cases = [case for case in evals.build_retrieval_cases(cn_kb.chunks) if case["split"] == "gate"]
    metrics = evals.run_retrieval(
        cases,
        lambda query, k: retrieve(query, lang="cn", top_k=k, today=CLOCK),
        today=CLOCK,
    )
    assert metrics["freshness_correctness"] == 1.0
    module = open(evidence.__file__, encoding="utf-8").read().split('"""', 2)[-1]
    assert "LIBRARY_FRESHNESS_ENABLED" not in module
