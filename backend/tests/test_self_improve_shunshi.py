"""顺时接入层测试：评测集、棘轮基线、批准入库、端到端（假抓取）、拟人化保守处理。"""

import json
from datetime import date, datetime, timedelta, timezone

import pytest

from app.rag.knowledge_base import KnowledgeBase, cn_kb, load_knowledge_bases
from app.self_improve import evals, hooks as H
from app.self_improve.approval import ApprovalPolicy, NullGateway
from app.self_improve.config import SILConfig
from app.self_improve.gates import check_set_separation
from app.self_improve.loop import SelfImprovementLoop
from app.services import companion_safeguards as cs

TZ = timezone(timedelta(hours=8))
NOW = datetime(2026, 11, 1, 3, 0, tzinfo=TZ)
BASE = json.loads((evals.DATA / "eval_baseline.json").read_text("utf-8"))


@pytest.fixture(scope="module")
def kb():
    load_knowledge_bases(force=True)
    return cn_kb


# ---------- 评测集 ----------
def test_eval_sets_are_big_enough_and_topic_disjoint(kb):
    cases = evals.build_retrieval_cases(kb.chunks)
    safety = json.loads((evals.DATA / "safety_eval_v1.json").read_text("utf-8"))
    assert len(cases) + len(safety) >= 125
    by = {sp: [{"id": c["id"], "topic": c["topic"]} for c in cases if c["split"] == sp] for sp in ("optimization", "gate", "heldout")}
    assert check_set_separation(by["optimization"], by["gate"], by["heldout"]) == []
    assert all(by[sp] for sp in by)


def test_retrieval_does_not_regress_below_baseline(kb):
    res = evals.evaluate_all()
    gate = res["splits"]["gate"]
    for key in ("recall_at_8", "faithfulness", "citation_accuracy", "freshness_correctness"):
        assert gate[key] >= BASE["gate"][key] - 0.02, key
    assert res["splits"]["heldout"]["recall_at_8"] >= 0.9


def test_safety_redteam_all_pass_except_registered_gaps():
    res = evals.run_safety(known_gaps=BASE["safety_known_gaps"])
    assert res["failures"] == [], res["failures"]
    assert res["redteam_pass_rate"] == 1.0


def test_heading_boost_puts_exact_topic_first(kb):
    from app.rag.retriever import retrieve

    top = retrieve("立春养生要注意什么", lang="cn", top_k=3)
    assert "立春" in top[0]["heading_path"][-1]


# ---------- 批准入库 ----------
def _manifest(tmp_path, entries):
    (tmp_path / "approved_manifest.json").write_text(json.dumps({"entries": entries}), "utf-8")


def _entry(**kw):
    e = {"reviewed_at": "2026-10-30", "valid_until": "2027-10-30", "reviewer": "r1", "url": "https://www.nhc.gov.cn/x", "content_hash": "h"}
    e.update(kw)
    return e


def test_load_approved_only_valid_entries(tmp_path):
    for name in ("ok", "expired", "superseded", "nofield"):
        (tmp_path / f"{name}.md").write_text(f"# {name}\n\n## s\n\n### {name}\n\n内容 {name}\n链接：https://www.nhc.gov.cn/x\n", "utf-8")
    _manifest(tmp_path, {
        "ok": _entry(), "expired": _entry(valid_until="2020-01-01"), "superseded": _entry(superseded_by="ok"),
        "nofield": _entry(reviewer=""), "missingfile": _entry(),
    })
    kbx = KnowledgeBase("cn")
    assert kbx.load_approved(tmp_path) > 0
    assert {c.metadata["source_file"] for c in kbx.chunks} == {"approved/ok.md"}
    assert all(c.metadata["evidence_status"] == "verified_official" and c.metadata["reviewer"] == "r1" for c in kbx.chunks)
    assert KnowledgeBase("cn").load_approved(tmp_path / "nope") == 0


def test_stale_sources_are_flagged_and_downweighted(kb):
    from app.rag import retriever

    stale = [c for c in kb.chunks if c.metadata.get("source_file", "").startswith("顺时知识库_")]
    assert stale and all(isinstance(c.metadata["stale"], bool) for c in stale)
    assert retriever.STALE_PENALTY < 1.0


# ---------- 端到端（假抓取、假审批） ----------
DRAFT = {
    "id": "wellness-water-demo", "title": "饮水的一般建议", "kind": "kb_draft", "origin": "external",
    "text": "成年人在温和气候条件下，每日饮水量建议 1500 至 1700 毫升，少量多次，不要等到口渴再喝。个体差异和疾病状态应以医生建议为准。",
    "source_tier": "official", "license": "gov-public", "valid_from": "2026-10-01", "valid_until": "2027-10-01", "origin_": "x",
    "url": "https://www.chinacdc.cn/demo", "reviewer": "reviewer-a", "reviewed_at": "2026-10-30",
    "publisher": "中国疾病预防控制中心", "published_at": "2022-06-15",
}


def _fake_fetch(url, policy, **kw):
    return {"url": url, "title": "官方页", "text": "栏目更新 示例", "hash": "h" + str(abs(hash(url)))[:8]}


def make(tmp_path, reviewers=frozenset({"alice"}), env=None, fetch=_fake_fetch):
    env = {"SIL_ENABLED": "1", **(env or {})}
    cfg = H.build_config(env)
    cfg = SILConfig(**{**cfg.__dict__, "data_dir": str(tmp_path / "sil")})
    sh = H.ShunshiHooks(cfg.data_dir, fetch=fetch, approved_dir=tmp_path / "approved", today=date(2026, 11, 1))
    gw = NullGateway()
    loop = SelfImprovementLoop(cfg, sh.hooks(), approval=ApprovalPolicy(reviewers=reviewers), gateway=gw)
    return loop, sh, gw


def test_disabled_by_default(tmp_path):
    cfg = H.build_config({})
    assert cfg.enabled is False
    loop, sh, gw = make(tmp_path, env={"SIL_ENABLED": "0"})
    assert loop.run_weekly(NOW).status == "disabled"
    assert not (tmp_path / "approved").exists()


def test_full_cycle_kb_entry_needs_wecom_then_loads(tmp_path, kb):
    loop, sh, gw = make(tmp_path)
    (tmp_path / "sil" / "inbox").mkdir(parents=True, exist_ok=True)
    (tmp_path / "sil" / "inbox" / "d1.json").write_text(json.dumps(DRAFT, ensure_ascii=False), "utf-8")
    rep = loop.run_weekly(NOW)
    kbc = [c for c in loop.store.list() if c.kind == "kb_entry"]
    assert len(kbc) == 1 and kbc[0].state == "pending_approval", (rep.rejected, rep.warnings)
    assert gw.sent and gw.sent[0][1] == ["alice"]
    assert not (tmp_path / "approved" / "approved_manifest.json").exists()  # 批准前什么都没入库
    cid = kbc[0].id
    with pytest.raises(PermissionError):
        loop.record_decision(cid, "mallory", True)
    loop.record_decision(cid, "alice", True, NOW)
    rep2 = loop.run_weekly(NOW + timedelta(days=7))
    assert cid in rep2.promoted
    kbx = KnowledgeBase("cn")
    assert kbx.load_approved(tmp_path / "approved") > 0
    # 回滚后条目消失
    loop.rollback(cid)
    assert KnowledgeBase("cn").load_approved(tmp_path / "approved") == 0
    assert loop.store.ledger.verify()


def test_timeout_means_no_promotion(tmp_path, kb):
    loop, sh, gw = make(tmp_path)
    (tmp_path / "sil" / "inbox").mkdir(parents=True, exist_ok=True)
    (tmp_path / "sil" / "inbox" / "d1.json").write_text(json.dumps(DRAFT, ensure_ascii=False), "utf-8")
    loop.run_weekly(NOW)
    rep = loop.run_weekly(NOW + timedelta(hours=100))
    assert rep.expired and not rep.promoted
    assert not (tmp_path / "approved" / "approved_manifest.json").exists()


def test_draft_with_violations_is_rejected(tmp_path, kb):
    loop, sh, gw = make(tmp_path)
    bad = {**DRAFT, "id": "bad-1", "text": "喝这个茶保证根治高血压，诊断为湿热体质，建议立即买入。"}
    (tmp_path / "sil" / "inbox").mkdir(parents=True, exist_ok=True)
    (tmp_path / "sil" / "inbox" / "bad.json").write_text(json.dumps(bad, ensure_ascii=False), "utf-8")
    rep = loop.run_weekly(NOW)
    assert rep.rejected and rep.rejected[0][1][0].startswith("compliance:")
    assert not any(cid.startswith("kb-") for cid in rep.pending_approval)


def test_incomplete_or_generated_drafts_never_become_candidates(tmp_path, kb):
    loop, sh, gw = make(tmp_path)
    (tmp_path / "sil" / "inbox").mkdir(parents=True, exist_ok=True)
    (tmp_path / "sil" / "inbox" / "a.json").write_text(json.dumps({**DRAFT, "id": "a", "valid_until": ""}, ensure_ascii=False), "utf-8")
    (tmp_path / "sil" / "inbox" / "b.json").write_text(json.dumps({**DRAFT, "id": "b", "origin": "generated"}, ensure_ascii=False), "utf-8")
    rep = loop.run_weekly(NOW)
    assert not [c for c in loop.store.list() if c.kind == "kb_entry"]
    assert any(s["id"] == "b" for s in rep.sources_rejected)


def test_source_page_change_creates_worklist_not_knowledge(tmp_path, kb):
    state = {"n": 0}

    def fetch(url, policy, **kw):
        state["n"] += 1
        return {"url": url, "title": "t", "text": "x", "hash": "A" if state["n"] <= 7 else "B"}

    loop, sh, gw = make(tmp_path, env={"SIL_AUTO_PROMOTE_INTERNAL": "1"}, fetch=fetch)
    loop.run_weekly(NOW)  # 首次：只记录基线（视为 first → changed）
    loop2 = loop.run_weekly(NOW + timedelta(days=7))
    wl = (tmp_path / "sil" / "worklist.jsonl")
    assert wl.exists()  # 内部工作项可自动晋升（显式开启时）
    assert not (tmp_path / "approved").exists()  # 但绝不会直接生成知识条目


def test_fetch_errors_do_not_crash(tmp_path, kb):
    def boom(url, policy, **kw):
        raise OSError("net down")

    loop, sh, gw = make(tmp_path, fetch=boom)
    rep = loop.run_weekly(NOW)
    assert rep.status == "ok" and not rep.promoted


def test_registry_is_whitelisted_and_domestic():
    reg = H.load_registry()
    from urllib.parse import urlparse
    from app.self_improve.sources import SourcePolicy

    pol = SourcePolicy(allowed_domains=tuple(reg["allowed_domains"]))
    assert all(pol.domain_ok(urlparse(s["url"]).hostname) and s["url"].startswith("https://") for s in reg["sources"])
    from app.self_improve.models import ModelPolicy

    assert ModelPolicy.from_env({}).bulk.startswith("deepseek")


# ---------- 拟人化保守处理 ----------
def test_companion_router_is_not_mounted_in_app():
    """该路由无鉴权、无年龄核验，接入前不得挂载。"""
    from app.main import create_app

    paths = {getattr(r, "path", "") for r in create_app().routes}
    assert not any(p.startswith("/api/v1/companion") for p in paths)


def test_use_tracker_two_hour_reminder_and_session_reset():
    t = cs.UseTracker()
    t0 = datetime(2026, 11, 1, 9, 0)
    assert t.touch("u", t0) is None
    for m in range(20, 130, 20):  # 每 20 分钟一次，持续到 2 小时 + 
        out = t.touch("u", t0 + timedelta(minutes=m))
    assert out is None or isinstance(out, str)
    assert t.touch("u", t0 + timedelta(minutes=130)) in (None, cs.REMINDER_TEXT)
    t2 = cs.UseTracker()
    t2.touch("v", t0)
    assert t2.touch("v", t0 + timedelta(hours=2, minutes=1)) is None  # 间隔超过 30 分钟 → 新会话
    t3 = cs.UseTracker()
    for m in range(0, 121, 15):
        r = t3.touch("w", t0 + timedelta(minutes=m))
    assert r == cs.REMINDER_TEXT
    assert t3.touch("w", t0 + timedelta(minutes=135)) is None  # 只提醒一次


def test_companion_responses_disclose_cap_intimacy_and_handle_crisis(monkeypatch):
    from fastapi import FastAPI
    from fastapi.testclient import TestClient

    from app.router import ai_companion as ac

    ac._profiles.clear(); ac._messages.clear()
    app = FastAPI(); app.include_router(ac.router)
    c = TestClient(app)
    for _ in range(30):
        d = c.post("/api/v1/companion/greet", json={"user_id": "u1"}).json()["data"]
    assert d["ai_generated"] is True and "不是真人" in d["ai_notice"] and d["intimacy_level"] <= 2
    r = c.post("/api/v1/companion/check-in", json={"user_id": "u2", "mood": 1, "energy": 1, "notes": "我不想活了"}).json()["data"]
    assert r.get("crisis") is True and "12356" in r["response"] and r["ai_generated"] is True
    assert "u2" in ac._profiles and not any("不想活" in m["content"] for m in ac._messages.get("u2", []))
    assert c.delete("/api/v1/companion/data/u1").json()["success"] is True
    assert "u1" not in ac._profiles
    monkeypatch.setenv(cs.FLAG_ENV, "0")
    d2 = c.post("/api/v1/companion/greet", json={"user_id": "u3"}).json()["data"]
    assert "ai_generated" not in d2  # 关闭开关即回到原行为
