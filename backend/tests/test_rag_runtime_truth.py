"""RAG运行真实性：文稿必须真实加载，只有已核验且未过期来源可注入。"""

from datetime import date

from app.rag.knowledge_base import cn_kb, gl_kb, load_knowledge_bases
from app.rag.retriever import retrieve


def test_versioned_knowledge_files_load_and_fit_retriever():
    load_knowledge_bases(force=True)
    assert cn_kb.loaded and len(cn_kb.chunks) > 100
    assert gl_kb.loaded and len(gl_kb.chunks) > 100

    results = retrieve("平衡膳食 少盐少油 食物多样", lang="cn", top_k=12)
    verified = [
        item
        for item in results
        if item["metadata"].get("evidence_status") == "verified_official"
    ]
    assert verified, "已核验官方资料必须能被真实检索"
    assert all(
        date.fromisoformat(item["metadata"]["valid_until"]) >= date.today()
        for item in verified
    )


def test_legacy_documents_are_not_mislabeled_as_verified():
    load_knowledge_bases()
    legacy = [
        chunk
        for chunk in cn_kb.chunks
        if chunk.metadata.get("source_file", "").startswith("顺时知识库_")
    ]
    assert legacy
    assert all(
        chunk.metadata["evidence_status"] == "legacy_unverified"
        and chunk.metadata["high_risk_allowed"] is False
        for chunk in legacy
    )


def test_b13_runtime_does_not_load_legacy_and_labels_pending_sources(monkeypatch):
    """B13：用户侧运行时不载入 4 份 legacy 文档；官方来源摘录标「待审核」，且不会被当成已核验。"""
    import json
    from pathlib import Path

    manifest = json.loads((Path(__file__).resolve().parents[1] / "app/rag/source_manifest.json").read_text("utf-8"))
    docs = manifest["documents"]
    assert not any(d["valid_until"] == "2026-11-30" for d in docs.values())
    assert {"pending_cn.md", "pending_global.md"} <= set(docs)
    assert all(docs[n]["evidence_status"] == "pending_review" and docs[n]["review_status"] == "待审核" for n in ("pending_cn.md", "pending_global.md"))

    monkeypatch.delenv("SHUNSHI_KB_LEGACY_EVAL", raising=False)
    try:
        load_knowledge_bases(force=True)
        for kb in (cn_kb, gl_kb):
            files = {c.metadata["source_file"] for c in kb.chunks}
            assert not any(f.startswith(("顺时知识库_", "SEASONS_Knowledge_Base")) for f in files), files
        pend = [c for c in cn_kb.chunks + gl_kb.chunks if c.metadata["source_file"].startswith("pending_")]
        assert pend and all(c.metadata["evidence_status"] == "pending_review" for c in pend)
        from app.rag.evidence import verified_cn_context  # only verified_official may be given to the model

        _ctx, _labels, details = verified_cn_context("睡眠 压力 12356", top_k=8)
        assert all(d["evidence_status"] == "verified_official" for d in details)
    finally:
        monkeypatch.setenv("SHUNSHI_KB_LEGACY_EVAL", "1")
        load_knowledge_bases(force=True)
