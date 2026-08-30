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
