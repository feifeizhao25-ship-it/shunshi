"""SIL v1.1 内核测试：效用账本与退役名单、状态字段（征求意见稿）、中英冲突取舍、零英文门、评审去偏与校准、可观测指标。

全部不联网、不调用模型。默认关闭的行为不变。
"""

import importlib
from datetime import date, datetime, timedelta, timezone

import pytest

si = importlib.import_module("app.self_improve")
fresh = importlib.import_module("app.self_improve.freshness")
util = importlib.import_module("app.self_improve.utility")

TZ = timezone(timedelta(hours=8))
NOW = datetime(2026, 11, 1, 3, 0, tzinfo=TZ)
GOOD = {"recall_at_8": 0.90, "faithfulness": 0.95, "citation_accuracy": 1.0, "freshness_correctness": 0.99,
        "redteam_pass_rate": 1.0, "calc_error": 0.005, "cost_ratio": 1.0, "latency_ratio": 1.0}
BASE = {**GOOD, "recall_at_8": 0.89}
NOSKILL = {"recall_at_8": 0.70}
TODAY = date(2026, 11, 1)


# ---------- 效用账本 ----------
def test_ema_first_observation_then_alpha(tmp_path):
    led = si.UtilityLedger(tmp_path, alpha=0.4)
    assert led.utility("skill-a") == 0.5  # 无观测 → 中性先验
    assert led.record("skill-a", 1.0).ema == 1.0
    assert led.record("skill-a", 0.0).ema == pytest.approx(0.6)  # 0.4*0 + 0.6*1
    assert led.record("skill-a", 0.0).ema == pytest.approx(0.36)
    assert led.get("skill-a").n == 3
    with pytest.raises(ValueError):
        led.record("skill-a", 1.5)
    with pytest.raises(ValueError):
        si.UtilityLedger(tmp_path, alpha=0.0)


def test_rank_is_utility_aware_and_weight_zero_is_plain(tmp_path):
    led = si.UtilityLedger(tmp_path)
    led.record("good", 1.0)
    led.record("bad", 0.0)
    items = [("bad", 0.80), ("good", 0.75)]
    assert [n for n, _ in led.rank(items, weight=0.0)] == ["bad", "good"]
    assert [n for n, _ in led.rank(items, weight=0.5)] == ["good", "bad"]
    with pytest.raises(ValueError):
        led.rank(items, weight=2)


def test_graveyard_is_name_level_and_unbury_needs_authorised_reviewer(tmp_path):
    led = si.UtilityLedger(tmp_path)
    led.bury("旧 技能-A", "效用长期偏低", "2026-10-31")
    assert led.is_buried("旧技能a") and led.is_buried("旧 技能-A ") and led.is_buried("旧技能Ａ")  # 空白/标点/全角不能让同名复活
    assert not led.is_buried("旧技能B")
    nobody = lambda r: False  # noqa: E731
    with pytest.raises(PermissionError):
        led.unbury("旧技能a", "alice", nobody)
    assert led.is_buried("旧技能a")
    assert led.unbury("旧技能a", "alice", lambda r: r == "alice") is True
    assert not led.is_buried("旧技能a")
    with pytest.raises(ValueError):
        led.bury("x", "")


def test_retire_candidates_and_capacity_plan_only_suggest(tmp_path):
    led = si.UtilityLedger(tmp_path, capacity=2)
    for _ in range(5):
        led.record("weak", 0.0)
    led.record("new-one", 0.0)  # 观测不足，不建议退役
    assert led.retire_candidates(min_obs=5, below=0.3) == ["weak"]
    assert led.prune_plan(["a", "b"]) == []
    led.record("keep1", 1.0)
    led.record("keep2", 0.9)
    plan = led.prune_plan(["weak", "keep1", "keep2"])
    assert plan == ["weak"]  # 只给名单，不删除任何东西


def test_ledger_persists_atomically(tmp_path):
    si.UtilityLedger(tmp_path).record("x", 1.0)
    assert (tmp_path / "utility_ledger.json").exists()
    assert si.UtilityLedger(tmp_path).utility("x") == 1.0
    assert not [p for p in tmp_path.iterdir() if p.name.startswith(".tmp-")]


# ---------- 状态字段 ----------
def entry(**kw):
    d = dict(id="e1", source_tier="official", license="gov-public", valid_from="2026-01-01", valid_until="2027-01-01",
             content_hash="h", origin="external", url="https://www.gov.cn/x", lang="zh")
    d.update(kw)
    return d


def test_status_validation_and_draft_is_retrievable_but_not_a_fact():
    assert fresh.validate_entry(entry()) == []
    assert "bad_status:foo" in fresh.validate_entry(entry(status="foo"))
    draft = entry(status="draft_consultation", valid_until=None)
    ok, why = fresh.retrievable(draft, TODAY)
    assert ok and why == "draft_consultation"
    assert fresh.fact_allowed(draft) is False
    assert fresh.answer_notice(draft) == fresh.DRAFT_NOTICE_ZH and "征求意见稿" in fresh.DRAFT_NOTICE_ZH
    assert fresh.answer_notice(entry()) == ""
    assert fresh.entry_status(draft, TODAY) == "draft_consultation"


def test_superseded_and_expired_never_retrievable_and_origin_generated_still_blocked():
    assert fresh.retrievable(entry(status="superseded"), TODAY) == (False, "superseded")
    assert fresh.retrievable(entry(superseded_by="e2"), TODAY) == (False, "superseded")
    assert fresh.retrievable(entry(status="expired"), TODAY) == (False, "expired")
    assert fresh.retrievable(entry(valid_until="2026-10-01"), TODAY) == (False, "expired")
    assert fresh.retrievable(entry(origin="generated", status="draft_consultation"), TODAY) == (False, "origin_generated")
    assert fresh.entry_status(entry(valid_until="2026-10-01"), TODAY) == "expired"
    assert fresh.entry_status(entry(superseded_by="e2"), TODAY) == "superseded"
    assert fresh.entry_status(entry(), TODAY) == "in_force"


def test_conflict_resolution_rules():
    inforce, draft = entry(id="a"), entry(id="b", status="draft_consultation")
    assert fresh.resolve_conflict(inforce, draft)["winner"] == "a"
    assert fresh.resolve_conflict(draft, inforce)["rule"] == "status"
    off, med = entry(id="o", source_tier="official"), entry(id="m", source_tier="academic")
    assert fresh.resolve_conflict(med, off)["winner"] == "o"
    zh, en = entry(id="z", lang="zh"), entry(id="n", lang="en")
    r = fresh.resolve_conflict(en, zh)
    assert r["winner"] == "z" and r["rule"] == "prefer_zh_official" and r["annotate"]
    cn = entry(id="c", lang="cn")
    assert fresh.resolve_conflict(cn, en)["winner"] == "c"
    same = fresh.resolve_conflict(entry(id="p", lang="zh"), entry(id="q", lang="zh"))
    assert same["winner"] is None and same["rule"] == "escalate_human"


# ---------- 零英文门 ----------
def test_zh_only_gate():
    assert si.zh_only_ok("该项目年上网电量不超过总可用发电量的 20%，装机 12.97 亿 kW，依据 GB 50797。")
    assert si.english_words("请使用 smart contract 结算") == ["smart", "contract"]
    assert si.zh_only_ok("详见 https://www.gov.cn/zhengce/x 与 a@b.com")
    assert si.zh_only_rate(["全中文回答", "含 hello 的回答"]) == 0.5
    assert si.zh_only_rate([]) == 0.0  # 空集 fail-closed


# ---------- 评审去偏与校准 ----------
def test_debiased_vote_majority_and_ties():
    always_first = lambda x, y: "first"  # noqa: E731  位置偏见：永远选第一个
    prefers_a = lambda x, y: "first" if x.startswith("A") else "second"  # noqa: E731
    prefers_b = lambda x, y: "first" if x.startswith("B") else "second"  # noqa: E731
    a, b = "A答案内容", "B答案内容"
    assert si.debiased_vote([always_first], a, b) == "tie"  # 位置偏见被识别成平局
    assert si.debiased_vote([prefers_a, prefers_a, prefers_b], a, b) == "a"
    assert si.debiased_vote([prefers_a, prefers_b], a, b) == "tie"  # 无严格多数
    assert si.debiased_vote([prefers_a], "A" * 100, "B") == "length_confound"
    with pytest.raises(ValueError):
        si.debiased_vote([], a, b)


def test_prompt_variants_and_kappa_calibration():
    for v in si.PROMPT_VARIANTS:
        p = si.build_prompt(v, "问", "答1", "答2")
        assert "first" in p and "tie" in p
    assert "忽略回答的长度" in si.build_prompt("bias_reminder", "问", "a", "b")
    with pytest.raises(ValueError):
        si.build_prompt("nope", "q", "a", "b")
    human = ["a", "b", "tie"] * 10
    assert si.cohens_kappa(human, human) == pytest.approx(1.0)
    ok, why = si.judge_usable(human, human)
    assert ok and why.startswith("kappa=")
    bad = ["a"] * 30
    assert si.judge_usable(human, bad)[0] is False
    ok2, why2 = si.judge_usable(human[:5], human[:5])
    assert not ok2 and why2.startswith("too_few_human_labels")


# ---------- 循环：退役名单、自引用、效用记录、指标 ----------
def cand(cid="c1", **kw):
    d = dict(id=cid, kind="kb_entry", target="kb/x", summary="更新电价条目", payload={"text": "分时电价机制说明"},
             evidence=[{"url": "https://www.ndrc.gov.cn/x"}], user_visible=True)
    d.update(kw)
    return si.Candidate(**d)


class Env:
    def __init__(self, tmp):
        self.applied, self.rolled = [], []
        self.records = [{"id": "s1", "url": "https://www.ndrc.gov.cn/a", "license": "gov-public", "origin": "external", "text": "分时电价"}]
        self.cfg = si.SILConfig.from_env("t", {"SIL_ENABLED": "1"}, data_dir=str(tmp), allowed_domains=("gov.cn",))
        self.cands = [cand("c1")]
        self.hooks = si.Hooks(
            collect=lambda: self.records,
            propose=lambda recs, budget: list(self.cands),
            evaluate=lambda c: si.EvalOutcome(BASE, GOOD, NOSKILL),
            apply=lambda c: (self.applied.append(c.id) or {"prev": "v1"}),
            rollback=lambda c: self.rolled.append(c.id),
        )

    def loop(self, reviewers=frozenset({"alice"})):
        return si.SelfImprovementLoop(self.cfg, self.hooks, approval=si.ApprovalPolicy(reviewers=reviewers, timeout_hours=72), gateway=si.NullGateway())


def test_graveyard_blocks_same_name_candidate(tmp_path):
    e = Env(tmp_path)
    lp = e.loop()
    lp.retire("KB/x", "长期无命中", NOW)
    rep = lp.run_weekly(NOW)
    assert rep.rejected and "graveyard" in rep.rejected[0][1]
    assert not rep.pending_approval and not e.applied
    assert rep.metrics["rejected_by_reason"].get("graveyard") == 1 and rep.metrics["graveyard_size"] == 1
    assert lp.store.ledger.verify()


def test_unretire_only_by_listed_reviewer_and_empty_list_means_nobody(tmp_path):
    e = Env(tmp_path)
    lp = e.loop()
    lp.retire("kb/x", "r", NOW)
    with pytest.raises(PermissionError):
        lp.unretire("kb/x", "mallory")
    assert lp.unretire("kb/x", "alice") is True
    lp2 = Env(tmp_path / "other").loop(reviewers=frozenset())
    lp2.retire("kb/y", "r", NOW)
    with pytest.raises(PermissionError):
        lp2.unretire("kb/y", "alice")


def test_self_citation_is_rejected(tmp_path):
    e = Env(tmp_path)
    e.cands = [cand("c1", evidence=[{"url": "file:///var/self_improve/t/reports/weekly.json"}]),
               cand("c2", target="kb/y", evidence=[{"url": "https://x/var/self_improve/t/candidates/c1.json"}])]
    rep = e.loop().run_weekly(NOW)
    assert {i for i, _ in rep.rejected} == {"c1", "c2"}
    assert all("self_citation" in r for _, r in rep.rejected)


def test_monitor_records_utility_and_metrics_exposed(tmp_path):
    e = Env(tmp_path)
    lp = e.loop()
    rep = lp.run_weekly(NOW)
    assert rep.pending_approval == ["c1"] and rep.metrics["pending_approval"] == 1 and rep.metrics["proposed"] == 1
    lp.record_decision("c1", "alice", True)
    lp.run_weekly(NOW + timedelta(days=7))
    assert lp.monitor("c1", GOOD, GOOD) is False
    assert lp.utility.utility("kb/x") == 1.0
    assert lp.monitor("c1", GOOD, GOOD) is False  # 幂等，仍在 promoted
    assert lp.monitor("c1", {**GOOD, "redteam_pass_rate": 0.9}, GOOD) is True
    assert lp.utility.utility("kb/x") == pytest.approx(0.6)  # 1.0 → 记一次 0.0：0.4*0+0.6*1


def test_default_off_and_extra_floors_available(tmp_path):
    assert si.SILConfig.from_env("x", {}).enabled is False
    th = si.GateThresholds(extra_floors=(("refusal_accuracy", 1.0),))
    assert "missing_metric:refusal_accuracy" in si.evaluate_gates(BASE, GOOD, th, no_skill=NOSKILL).reasons
    assert si.evaluate_gates(BASE, {**GOOD, "refusal_accuracy": 1.0}, th, no_skill=NOSKILL).passed
    assert si.GateThresholds().extra_floors == ()
