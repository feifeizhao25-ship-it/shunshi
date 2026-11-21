"""库外问题评测：数据合法、指标可算、只许变好不许变差。离线，不调用模型。"""
from app.self_improve import ooc_eval


def test_ooc_sets_are_well_formed():
    main, held = ooc_eval.load(), ooc_eval.load(heldout=True)
    assert len(main) >= 24 and len(held) >= 12
    ids = [c["id"] for c in main + held]
    assert len(ids) == len(set(ids))
    assert all(c["expect_citations"] == 0 and c["query"].strip() for c in main + held)
    assert not {c["query"] for c in main} & {c["query"] for c in held}


def test_metric_counts_cited_cases_with_injected_retriever():
    always = ooc_eval.run(retrieve_fn=lambda q, k: [{"chunk_id": "x"}])
    never = ooc_eval.run(retrieve_fn=lambda q, k: [])
    assert always["ooc_cited_rate"] == 1.0 and never["ooc_cited_rate"] == 0.0
    assert never["cited_ids"] == []


def test_current_retriever_does_not_regress_past_baseline():
    base = ooc_eval.baseline()
    assert ooc_eval.run()["ooc_cited_rate"] <= base["ooc_cited_rate"]
    assert ooc_eval.run(heldout=True)["ooc_cited_rate"] <= base["heldout_ooc_cited_rate"]
