from datetime import date

import httpx
import pytest

from app.growth.kb.embeddings import BgeM3Embedder, LocalHashEmbedder, RemoteReranker, get_embedder, get_reranker
from app.growth.kb.ingest import IngestRefused, activate_source, ingest_path, ingest_text, seed_registry
from app.growth.kb.retrieve import retrieve
from app.growth.kb.sources import REGISTRY


def test_refuses_medication_path_without_opening_it(growth_session, tmp_path):
    missing = tmp_path / "nested" / "tcm_medication.py"
    with pytest.raises(IngestRefused, match="refused source"):
        ingest_path(growth_session, str(missing))
    assert not missing.exists()
    secret = tmp_path / ".env"
    with pytest.raises(IngestRefused, match="refused source"):
        ingest_path(growth_session, str(secret))


def test_refuses_dosage_and_long_term_text(growth_session):
    with pytest.raises(IngestRefused, match="refused content"):
        ingest_text(
            growth_session,
            source_id="B01",
            text="这个方子可长期服用",
            license="internal-summary",
            tier="papers",
            url="",
            published_at="2026-01-01",
        )
    with pytest.raises(IngestRefused, match="refused content"):
        ingest_text(
            growth_session,
            source_id="B02",
            text="六味地黄丸每次 9 克",
            license="internal-summary",
            tier="papers",
            url="",
            published_at="2026-01-01",
        )
    from app.growth.models import GrowthKbChunk

    assert growth_session.query(GrowthKbChunk).count() == 0


def test_registry_summaries_are_clean_and_retrievable(growth_session):
    from app.growth.compliance.gate import violation_codes

    for record in REGISTRY:
        assert violation_codes(record.summary) == []
        assert record.license
    seed_registry(growth_session)
    found = retrieve(growth_session, "午间留白", today=date(2026, 10, 20))
    assert found
    assert found[0].chunk_id == "A03#c1"
    assert found[0].citation == "[A03#c1]"
    assert found[0].license == "internal-summary"


def test_candidate_sources_are_hidden_until_a_human_activates_them(growth_session):
    ingest_text(
        growth_session,
        source_id="B03",
        text="新的平台规则备忘：发布前要人看过一眼，只谈作息。",
        license="internal-summary",
        tier="platform_rules",
        url="",
        published_at="2026-10-01",
    )
    assert retrieve(growth_session, "发布前要人看过") == []
    assert activate_source(growth_session, "B03") == 1
    assert retrieve(growth_session, "发布前要人看过")[0].chunk_id == "B03#c1"


def test_stale_chunks_are_downweighted_then_archived(growth_session):
    ingest_text(
        growth_session,
        source_id="B04",
        text="这条平台规则已经写明发布要等人确认，讨论的是作息草稿。",
        license="internal-summary",
        tier="platform_rules",
        url="",
        published_at="2026-01-01",
        status="active",
    )
    fresh = retrieve(growth_session, "等人确认", today=date(2026, 2, 15))
    assert fresh and fresh[0].chunk_id == "B04#c1"
    archived = retrieve(growth_session, "等人确认", today=date(2026, 4, 15))
    assert archived == []
    from app.growth.models import GrowthKbChunk

    row = growth_session.get(GrowthKbChunk, "B04#c1")
    assert row.status == "archived"


def test_embedding_falls_back_locally_and_remote_sends_no_secret(monkeypatch):
    local = get_embedder("bge-m3", "")
    assert isinstance(local, LocalHashEmbedder)
    once = local.embed(["立春作息"])
    assert once == local.embed(["立春作息"])
    assert len(once[0]) == 64

    seen = {}

    def fake_post(url, json=None, timeout=None, headers=None, **kwargs):
        seen["url"] = url
        seen["headers"] = headers
        seen["json"] = json

        class Response:
            def raise_for_status(self):
                return None

            def json(self):
                return {"embeddings": [[0.2, 0.3, 0.5]]}

        return Response()

    monkeypatch.setattr(httpx, "post", fake_post)
    remote = get_embedder("bge-m3", "http://embeddings.test/v1")
    assert isinstance(remote, BgeM3Embedder)
    assert remote.embed(["立春"]) == [[0.2, 0.3, 0.5]]
    assert seen["headers"] is None
    assert "api_key" not in seen["json"]

    def fake_rerank(url, json=None, timeout=None, headers=None, **kwargs):
        assert headers is None

        class Response:
            def raise_for_status(self):
                return None

            def json(self):
                return {"scores": [0.9]}

        return Response()

    monkeypatch.setattr(httpx, "post", fake_rerank)
    assert isinstance(get_reranker("local", "http://unused"), type(get_reranker("local", "")))
    assert isinstance(get_reranker("bge-reranker-v2-m3", "http://rerank.test"), RemoteReranker)
    assert get_reranker("bge-reranker-v2-m3", "http://rerank.test").rerank("作息", ["早睡"]) == [0.9]
