"""2026-11-01 研究补充：混合检索 / 口语评测 / 节气对照 / 变好才上线闸门 / 版本发布与回滚 / 闸门任务。
全部离线、确定性；闸门类开关在测试里打开，出厂保持关闭。"""

import json
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

import pytest

from app.library import releases, review_cli, store
from app.rag import aliases, hybrid
from app.self_improve import continuous as C
from app.self_improve import promote_gate as PG
from app.self_improve.config import SILConfig

TZ = timezone(timedelta(hours=8))
NOW = datetime(2026, 11, 4, 7, 0, tzinfo=TZ)
DATA = Path(__file__).resolve().parents[1] / "app" / "self_improve" / "data"


# ------------------------------------------------------------------ 检索
def test_rrf_is_rank_based_and_normalised():
    out = hybrid.rrf([[(1, 9.0), (2, 1.0)], [(2, 0.3), (3, 0.2)]])
    assert out[0][0] == 2 and out[0][1] == 1.0 and {i for i, _ in out} == {1, 2, 3}
    assert hybrid.rrf([]) == []


def test_flags_default_on_and_kill_switch():
    assert hybrid.enabled({}) and aliases.enabled({})
    assert not hybrid.enabled({"RAG_HYBRID": "0"}) and not aliases.enabled({"RAG_ALIASES": "off"})


def test_alias_expansion_only_appends():
    q = "晚上睡不着怎么办"
    out = aliases.expand(q, "cn")
    assert out.startswith(q) and "失眠" in out
    assert aliases.expand("无关的句子", "cn") == "无关的句子"
    assert "plant-based" in aliases.expand("eating well as a vegetarian", "gl")


def test_tokenizer_cn_and_en():
    assert "失眠" in hybrid.tokenize("慢性失眠怎么办", "cn")
    assert "plant" in hybrid.tokenize("Plant-based eating", "gl")


@pytest.fixture(scope="module")
def baseline():
    return json.loads((DATA / "paraphrase_baseline.json").read_text("utf-8"))


@pytest.mark.parametrize("lang", ["cn", "gl"])
def test_paraphrase_eval_ratchet(lang, baseline):
    """口语检索指标不得低于记录的基线（含留出集）；基线由 paraphrase_eval 实测写入，要调只能调高。"""
    from app.self_improve import paraphrase_eval as P

    for split, held in (("dev", False), ("heldout", True)):
        r = P.run(lang, heldout=held)
        b = baseline[lang][split]
        assert r["n"] == b["n"]
        assert r["recall_at_5"] >= b["recall_at_5"] - 1e-9, (lang, split, r)
        assert r["mrr"] >= b["mrr"] - 1e-9, (lang, split, r)


def test_hybrid_beats_tfidf_on_paraphrase_dev(monkeypatch):
    from app.self_improve import paraphrase_eval as P

    monkeypatch.setenv("RAG_HYBRID", "0")
    off = P.run("cn")
    monkeypatch.setenv("RAG_HYBRID", "1")
    on = P.run("cn")
    assert on["mrr"] > off["mrr"] and on["recall_at_5"] >= off["recall_at_5"]


def test_paraphrase_expected_ids_exist():
    from app.rag.knowledge_base import cn_kb, gl_kb, load_knowledge_bases
    from app.self_improve import paraphrase_eval as P

    load_knowledge_bases(include_legacy=True)  # 口语问法评测语料含 legacy 文档（评测夹具，非运行时）
    for lang, kb in (("cn", cn_kb), ("gl", gl_kb)):
        ids = {P.chunk_uid(c) for c in kb.chunks}
        for held in (False, True):
            for c in P.load(lang, held):
                assert set(c["expected"]) <= ids, c["id"]


# ------------------------------------------------------------------ 节气
def test_solar_terms_match_pmo_2026():
    pmo = json.loads((DATA / "solar_terms_pmo_2026.json").read_text("utf-8"))["terms"]
    ours = json.loads((Path(__file__).resolve().parents[1] / "app" / "data" / "solar_terms.json").read_text("utf-8"))
    ours = ours.get("terms", ours) if isinstance(ours, dict) else ours
    got = {t["name"]: t["beijing_time"] for t in ours if t["date"].startswith("2026-")}
    assert len(pmo) == 24
    for name, ts in pmo.items():
        a = datetime.fromisoformat(ts)
        b = datetime.fromisoformat(got[name])
        assert abs((a - b).total_seconds()) <= 120, (name, ts, got[name])


# ------------------------------------------------------------------ 闸门
def good(**kw):
    e = {"id": "t-1", "title": "测试条目：失眠的作息建议", "summary": "官方指南对作息的概括。", "points": ["每天固定起床时间。"], "plain_tip": "固定作息。", "caution": "仅供了解，身体不适请咨询医生。",
         "tags": ["睡眠"], "probes": ["晚上睡不着怎么调整作息", "睡眠作息建议"], "source": {"title": "指南", "publisher": "国家卫健委", "url": "https://www.nhc.gov.cn/x", "read_scope": "全文", "tier": "A"},
         "publish_date": "2026-05-01", "retrieved_at": "2026-10-30"}
    e.update(kw)
    return e


def doc_entries():
    return store.load_document()["entries"]


def test_gate_keep_for_good_candidate():
    r = PG.evaluate(good(), doc_entries(), today=date(2026, 11, 1))
    assert r["decision"] == "keep" and r["evidence"] >= PG.THRESHOLD and r["safety"] >= PG.THRESHOLD and not r["impact"]["regressions"]


def test_gate_rejects_b_tier_without_second_source_and_accepts_with():
    b = good(source={**good()["source"], "tier": "B"})
    assert PG.evaluate(b, doc_entries(), today=date(2026, 11, 1))["decision"] == "reject"
    assert PG.evaluate({**b, "second_source": {"title": "x", "url": "https://y"}}, doc_entries(), today=date(2026, 11, 1))["decision"] == "keep"


def test_gate_rejects_social_lead_and_stale_and_http():
    assert PG.evaluate(good(source={**good()["source"], "tier": "D"}), doc_entries(), today=date(2026, 11, 1))["decision"] == "reject"
    assert PG.evaluate(good(source={**good()["source"], "url": "http://x"}), doc_entries(), today=date(2026, 11, 1))["decision"] == "reject"
    assert PG.evaluate(good(retrieved_at="2026-01-01"), doc_entries(), today=date(2026, 11, 1))["evidence"] < PG.THRESHOLD


def test_gate_safety_hits_and_disclaimer_allowed():
    assert PG.evaluate(good(summary="本方法可以根治失眠"), doc_entries(), today=date(2026, 11, 1))["decision"] == "reject"
    assert PG.safety_score(good(caution="不能替代医生的诊断和治疗。"))[0] == 1.0
    assert PG.safety_score(good(caution=""))[0] == 0.0


def test_gate_needs_probes_and_blocks_duplicates():
    assert PG.evaluate(good(probes=[]), doc_entries(), today=date(2026, 11, 1))["decision"] == "reject"
    dup = good(id="ss-lib-001")
    assert PG.duplicates(dup, doc_entries())
    e0 = doc_entries()[0]
    assert PG.duplicates(good(source={**good()["source"], "url": e0["source"]["url"]}), doc_entries())


def test_gate_detects_regression(monkeypatch):
    """候选把已有条目的探针从前 K 名挤出去 → 退步 → reject。"""
    monkeypatch.setattr(PG, "HIT_K", 1)
    base = [{"id": "a", "title": "八段锦练习", "tags": ["八段锦"], "summary": "八段锦动作要领", "points": ["八段锦"], "probes": ["八段锦练习"]}] + [
        {"id": f"f{i}", "title": f"别的主题{i}", "tags": [], "summary": f"内容{i}", "points": []} for i in range(3)]
    hog = good(id="hog", title="八段锦练习", tags=["八段锦", "练习"], summary="八段锦练习 " * 20, points=["八段锦练习 " * 10], probes=["八段锦练习", "八段锦"])
    r = PG.impact(hog, base, "cn")
    assert r["regressions"] and r["regressions"][0]["entry"] == "a" and r["decision"] == "reject"


def test_staged_shipped_candidates_gate_verdicts():
    rep = PG.evaluate_all(store.load_staged(), doc_entries(), today=date(2026, 11, 1))
    verdict = {r["id"]: r["decision"] for r in rep["rows"]}
    assert verdict["ss-lib-s11"] == "keep" and verdict["ss-lib-s01"] == "keep" and verdict["ss-lib-s03"] == "reject"  # s03 是 B 级且无第二来源


def test_shipped_staged_entries_are_pending_and_invisible():
    staged = {e["id"]: e for e in store.load_staged()}
    assert "ss-lib-s11" in staged and staged["ss-lib-s11"]["review_status"] == "待审核"
    assert "ss-lib-s11" not in {e["id"] for e in store.annotated(date(2026, 11, 1), include_hidden=True)}
    assert staged["ss-lib-s11"]["source"]["url"].startswith("https://pmo.cas.cn/")


# ------------------------------------------------------------------ 发布 / 回滚
def test_release_chain_rollback_and_tamper(tmp_path):
    d = tmp_path
    doc1 = {"entries": [{"id": "a"}]}
    doc2 = {"entries": [{"id": "a"}, {"id": "b"}]}
    releases.record(d, doc1, action="baseline", entry_id="-", reviewer="张三")
    releases.record(d, doc2, action="promote", entry_id="b", reviewer="张三")
    assert releases.verify(d)["ok"]
    with pytest.raises(releases.ReleaseError):
        releases.record(d, doc2, action="x", entry_id="b", reviewer=" ")
    with pytest.raises(releases.ReleaseError):
        releases.rollback(d, 1, "张三", " ")
    assert releases.rollback(d, 1, "张三", "回到基线") == doc1
    assert [r["action"] for r in releases.list_releases(d)] == ["baseline", "promote", "rollback"] and releases.verify(d)["ok"]
    snap = d / "releases" / "0001.json"
    t = json.loads(snap.read_text("utf-8"))
    t["document"]["entries"].append({"id": "evil"})
    snap.write_text(json.dumps(t, ensure_ascii=False), "utf-8")
    assert not releases.verify(d)["ok"]
    with pytest.raises(releases.ReleaseError):
        releases.rollback(d, 2, "张三", "不应成功")


def test_cli_promote_approve_rollback_roundtrip(monkeypatch, tmp_path):
    monkeypatch.setenv("SHUNSHI_LIBRARY_DIR", str(tmp_path / "lib"))
    lib = tmp_path / "lib"
    assert review_cli.main(["promote", "ss-lib-s11", "--reviewer", "张三"]) == 0
    assert review_cli.main(["approve", "ss-lib-s11", "--reviewer", "张三"]) == 0
    doc = json.loads((lib / "reference_entries.json").read_text("utf-8"))
    assert next(e for e in doc["entries"] if e["id"] == "ss-lib-s11")["review_status"] == "已审核"
    rel = releases.list_releases(lib)
    assert [r["action"] for r in rel] == ["baseline", "promote", "approve"] and releases.verify(lib)["ok"]
    assert review_cli.main(["rollback", "v1", "--reviewer", "张三"]) == 2  # 回滚必须写原因
    assert review_cli.main(["rollback", "v1", "--reviewer", "张三", "--note", "演练回滚"]) == 0
    doc = json.loads((lib / "reference_entries.json").read_text("utf-8"))
    assert all(e["id"] != "ss-lib-s11" for e in doc["entries"])
    assert review_cli.main(["releases", "x", "--reviewer", "张三"]) == 0


def test_cli_gate_reports_and_approve_blocked_when_enforced(monkeypatch, tmp_path, capsys):
    monkeypatch.setenv("SHUNSHI_LIBRARY_DIR", str(tmp_path / "lib"))
    assert review_cli.main(["gate", "ss-lib-s11", "--reviewer", "张三"]) == 0
    assert review_cli.main(["gate", "ss-lib-s03", "--reviewer", "张三"]) == 4
    assert review_cli.main(["promote", "ss-lib-s03", "--reviewer", "张三"]) == 0  # 暂存→待审核仍允许（用户看不到）
    monkeypatch.setenv("LIBRARY_PROMOTE_GATE", "1")
    assert review_cli.main(["approve", "ss-lib-s03", "--reviewer", "张三"]) == 2  # 开关打开后，闸门不过就不能上线
    doc = json.loads((tmp_path / "lib" / "reference_entries.json").read_text("utf-8"))
    assert next(e for e in doc["entries"] if e["id"] == "ss-lib-s03")["review_status"] == "待审核"
    monkeypatch.delenv("LIBRARY_PROMOTE_GATE")
    assert not PG.enforced()


def test_approve_unchanged_when_gate_off(monkeypatch, tmp_path):
    monkeypatch.delenv("LIBRARY_PROMOTE_GATE", raising=False)
    monkeypatch.setenv("SHUNSHI_LIBRARY_DIR", str(tmp_path / "lib"))
    assert review_cli.main(["approve", "ss-lib-005", "--reviewer", "张三"]) == 0


# ------------------------------------------------------------------ 任务
def test_promote_gate_job_off_by_default_and_never_promotes(tmp_path, monkeypatch):
    monkeypatch.setenv("SHUNSHI_LIBRARY_DIR", str(tmp_path / "lib"))
    off = SILConfig(product="shunshi", enabled=False, data_dir=str(tmp_path / "sil"))
    assert C.run_promote_gate(NOW, cfg=off) == {"status": "disabled"}
    on = SILConfig(product="shunshi", enabled=True, data_dir=str(tmp_path / "sil"))
    r = C.run_promote_gate(NOW, cfg=on)
    assert r["status"] == "ok" and "ss-lib-s11" in r["keep"] and "ss-lib-s03" in r["reject"]
    assert (tmp_path / "sil" / "promote_gate_report.md").exists()
    assert not (tmp_path / "lib" / "reference_entries.json").exists()  # 没有写工作文档
    assert C.run_promote_gate(NOW, cfg=on)["new_keep"] == []  # 第二次不重复提醒
    lines = (tmp_path / "sil" / "worklist.jsonl").read_text("utf-8").splitlines()
    assert sum("promote-ready-ss-lib-s11" in x for x in lines) == 1


def test_promote_gate_slot_registered_and_valid():
    from app.self_improve.scheduler import next_run

    assert C.SLOTS["promote_gate"] == "weekly:WED@07:00" and "promote_gate" in C.jobs()
    assert next_run(C.SLOTS["promote_gate"], NOW).weekday() == 2
