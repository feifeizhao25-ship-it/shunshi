"""2026-11-23 步骤6：暂存区新增 3 条候选（外部资料汇总）。全部离线、确定性，不调用模型。
候选永远是“待审核”、用户看不到；加进来以后金标准/留出集不能变差、库外题挂出处不能变多，补充题要能答对。"""

import json
from datetime import date, datetime
from pathlib import Path

from app.library import store
from app.self_improve import corpus_eval as ce
from app.self_improve import golden as G
from app.self_improve import promote_gate as PG
from app.self_improve.continuous import library_answer, library_entries, make_answer_fn

APP = Path(__file__).resolve().parents[1] / "app"
STAGED = APP / "library" / "data" / "staged_entries_20261123g.json"
EXTRA = APP / "self_improve" / "data" / "golden_shunshi_zh_staged_20261123.jsonl"
NEW = ("ss-lib-s21", "ss-lib-s22", "ss-lib-s24")
KNOWN_MISS = {"ss-gs-1123-01"}

# 库外问题（与 PR #157 的 out_of_corpus_zh_v1 同类：资料库里没有、也不该挂养生来源）
OOC = ["世界杯决赛谁赢了", "二手房过户需要哪些材料", "欧洲旅游申根签证材料", "明天股市会涨吗", "怎么给手机换电池",
       "北京烤鸭的做法", "考研数学怎么复习", "新能源车补贴怎么申请", "公司注册流程", "如何学习Python编程"]


def _new():
    return {e["id"]: e for e in json.loads(STAGED.read_text("utf-8"))["entries"]}


def _without_new(entries):
    return [e for e in entries if e["id"] not in NEW]


def test_candidates_are_pending_invisible_and_fully_sourced():
    new = _new()
    assert set(new) == set(NEW)
    visible = {e["id"] for e in store.annotated(date(2026, 11, 23), include_hidden=True)}
    for e in new.values():
        assert e["review_status"] == "待审核" and not e.get("reviewer")
        assert e["id"] not in visible
        src = e["source"]
        for k in ("title", "publisher", "url", "read_scope", "read_via", "tier", "license_note", "quote"):
            assert src.get(k), (e["id"], k)
        for k in ("publish_date", "retrieved_at", "valid_until", "status", "caution"):
            assert e.get(k), (e["id"], k)
        assert len(e["probes"]) >= 2
    assert {e["id"] for e in store.load_staged()} >= set(NEW)


def test_golden_and_heldout_do_not_get_worse():
    entries = library_entries()
    base = _without_new(entries)
    for path in (ce.GOLDEN_PATH, ce.HELDOUT_PATH):
        cases = ce.load_jsonl(path)
        before, after = ce.evaluate_retrieval(cases, base), ce.evaluate_retrieval(cases, entries)
        assert after["recall_at_8"] >= before["recall_at_8"] and after["citation_accuracy"] >= before["citation_accuracy"], path.name
        now = datetime(2026, 11, 13, 3, 30)
        pb = G.run_golden(cases, make_answer_fn(base), edition="zh", now=now)["pass_rate"]
        pa = G.run_golden(cases, make_answer_fn(entries), edition="zh", now=now)["pass_rate"]
        assert pa >= pb, (path.name, pb, pa)


def test_out_of_corpus_citations_do_not_increase():
    entries = library_entries()
    base = _without_new(entries)
    cited = lambda ents: sum(bool(library_answer(q, ents).get("citations")) for q in OOC)
    assert cited(entries) <= cited(base)
    for q in OOC:
        url = (library_answer(q, entries).get("citations") or [""])[0]
        assert url not in {e["source"]["url"] for e in _new().values()}, q


def test_extra_questions_for_new_candidates_are_answered():
    cases = ce.load_jsonl(EXTRA)
    assert len(cases) == 6 and all(c["review_status"] == "待审核" for c in cases)
    entries = library_entries()
    r = ce.evaluate_retrieval(cases, entries)
    assert r["recall_at_8"] == 1.0 and r["citation_accuracy"] == 1.0, r
    scored = G.run_golden(cases, make_answer_fn(entries), edition="zh", now=datetime(2026, 11, 23, 9, 0))
    failed = {k for k, v in scored["results"].items() if not v.get("ok")}
    # 已知漏答（如实记录，不为它改候选措辞）：“怀孕了……”和“孕妇”二字不重合，资料库答题路径第一名落到 ss-lib-003
    # （2023 年 9 种的条目，没有写官方的孕妇提示）。修法属于步骤 7：给 003/004 补官方提示，或给资料库答题加同义词。
    assert failed <= KNOWN_MISS, failed
    assert scored["pass_rate"] >= 5 / 6


def test_gate_verdicts_are_recorded():
    """闸门只给结论，上线仍要人名。三条都应 keep：证据、安全满分，探针命中，已有条目零退步。"""
    new = _new()
    rep = PG.evaluate_all(list(new.values()), store.load_document()["entries"], today=date(2026, 11, 23))
    verdict = {r["id"]: r["decision"] for r in rep["rows"]}
    assert verdict == {"ss-lib-s21": "keep", "ss-lib-s22": "keep", "ss-lib-s24": "keep"}
    for r in rep["rows"]:
        assert r["safety"] == 1.0 and not r["impact"]["regressions"]
