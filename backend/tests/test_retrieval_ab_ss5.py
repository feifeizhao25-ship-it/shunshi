"""SS-5：离线对比只出报告。线上默认检索配置必须和改动前一致。"""

import json
import os

from app.self_improve import retrieval_ab as ab

# 字面量，不从被测模块再算一遍。retrieve() 仍是 TF-IDF + BM25，不接 bge-m3，也不接重排。
EXPECTED_DEFAULT = {
    "entry": "app.rag.retriever.retrieve",
    "hybrid_default_on": True,
    "rrf_k": 60,
    "pool": 60,
    "bm25_k1": 1.4,
    "bm25_b": 0.75,
    "heading_weight": 3,
    "lexical_embedder": "TFIDFEmbedder",
    "dense_model": None,
    "reranker": None,
    "retrieve_calls_dense": False,
    "embedder_api_local_model": "BAAI/bge-small-zh-v1.5",
    "embedder_api_default_providers": ["bailian", "siliconflow", "local"],
}


def test_default_retrieval_config_is_unchanged():
    assert ab.live_default() == EXPECTED_DEFAULT
    source = ab.RETRIEVER_PATH.read_text(encoding="utf-8")
    assert "bge-m3" not in source
    assert "reranker" not in source.lower()
    assert "semantic_retriever" not in source
    assert "get_embedder" in source and "hybrid.fuse" in source


def test_comparison_report_covers_both_sets_and_does_not_touch_the_default(tmp_path, monkeypatch):
    monkeypatch.delenv("RAG_HYBRID", raising=False)
    before = ab.live_default()
    report = ab.build_report()
    assert ab.live_default() == before == EXPECTED_DEFAULT
    assert os.environ.get("RAG_HYBRID") is None
    assert report["default_unchanged"] is True
    assert report["default_retrieval"] == EXPECTED_DEFAULT
    assert report["sets"]["golden"]["n"] == 165
    assert report["sets"]["heldout"]["n"] == 60
    for name in ("golden", "heldout"):
        bm25 = report["sets"][name]["bm25"]
        dense = report["sets"][name]["bge_m3_reranker"]
        assert bm25["status"] == "ran"
        assert bm25["n_scored"] > 0
        assert 0.0 <= bm25["recall_at_1"] <= bm25["recall_at_8"] <= 1.0
        assert dense["status"] in ("ran", "skipped")
        if dense["status"] == "skipped":
            assert dense["ran"] is False and dense["recall_at_8"] is None
        else:
            assert dense["ran"] is True and 0.0 <= dense["recall_at_8"] <= 1.0
    if report["dense"]["status"] == "skipped":
        assert report["dense"]["ran"] is False
        assert "不联网" in report["dense"]["reason"]
        assert report["dense"]["model"] == "BAAI/bge-m3"
        assert report["dense"]["reranker"] == "BAAI/bge-reranker-v2-m3"
    path = tmp_path / "retrieval_ab_ss5.json"
    path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    saved = json.loads(ab.REPORT_PATH.read_text(encoding="utf-8"))
    assert saved == report
    assert saved["note"]
