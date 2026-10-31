"""顺时资料库：自动更新（来源核对任务）+ 个性化推荐。

模拟 5 个用户 × 7 天，周四来源发生变化：
  * 来源内容变了（数字改了）的条目，核对后必须立刻停止被推荐、挂「来源有更新」提示；
  * 周五审核人看过并写了变更说明，条目回到推荐里并带「更新于」和变更说明，且只出现在相关用户的推荐里；
  * 来源页出现「已废止」的条目，从周四起任何人的列表、推荐、首页卡片里都不能出现，直接打开只看到「已废止」横幅。
所有网络都用假的抓取函数，不联网。
"""

import json
import re
from datetime import date, datetime, timedelta, timezone
from urllib.error import HTTPError
from zoneinfo import ZoneInfo

import pytest

from app.library import feed as fd, service, store
from app.library_live import review
from app.self_improve import library_job as job

SH = ZoneInfo("Asia/Shanghai")
MON = date(2026, 11, 2)
CJK = re.compile(r"[\u3400-\u9fff]")
FORBIDDEN = ("治疗", "治愈", "诊断", "确诊", "处方", "疗效", "根治", "保证")

_PAGE = "<html><head><title>{t}</title></head><body><nav>首页</nav><p>浏览量：{views}</p>{body}</body></html>"


def build_pages(doc, *, changed=(), repealed=(), views=1):
    pages = {}
    for e in doc["entries"]:
        u = e["source"]["url"]
        if u.startswith("http://"):
            u = u.replace("http://", "https://", 1)
        key = u  # 同一个来源页被几条共用：页面内容按来源页算，不按条目
        body = "".join(f"<p>{key[-12:]} 第{i}条 数值 {i * 10} 单位。</p>" for i in range(1, 30))
        sharing = {x["id"] for x in doc["entries"] if x["source"]["url"].replace("http://", "https://", 1) == u}
        if sharing & set(changed):
            body = body.replace("数值 10 单位", "数值 15 单位")
        title = e["source"]["title"] + ("（已废止）" if sharing & set(repealed) else "")
        pages[u] = _PAGE.format(t=title, body=body, views=views).encode("utf-8")
    return pages


def make_http(pages, *, broken=()):
    def http(url, timeout):
        if url in broken:
            raise HTTPError(url, 404, "nf", {}, None)
        return pages[url], "utf-8"
    return http


@pytest.fixture()
def lib(tmp_path, monkeypatch):
    monkeypatch.setenv("SHUNSHI_LIBRARY_DIR", str(tmp_path / "lib"))
    monkeypatch.setenv("SIL_DATA_DIR", str(tmp_path / "sil"))
    monkeypatch.setenv("LIBRARY_FRESHNESS_ENABLED", "1")
    src = job.load_sources()
    src["manual_hosts"] = {"www.nbphsp.org.cn": "只有 http 且返回 500，需人工核对"}  # 其余来源在生产环境可联网，测试里都走抓取
    monkeypatch.setattr(job, "load_sources", lambda: src)
    return tmp_path


def run_check(now, pages, **kw):
    return job.run_check(now, fetch=job.make_fetch(job.policy(), http=make_http(pages, **kw)))


def at(day_offset, hour=2):
    return datetime(MON.year, MON.month, MON.day, hour, tzinfo=SH) + timedelta(days=day_offset)


# ── 任务本身 ─────────────────────────────────────────────

def test_job_is_off_by_default_and_runs_on_existing_sil_slots(monkeypatch):
    monkeypatch.delenv("LIBRARY_FRESHNESS_ENABLED", raising=False)
    assert job.run_check() == {"status": "disabled"} and job.run_discover() == {"status": "disabled"}
    from app.self_improve.scheduler import SCHEDULE_DEFAULTS
    assert job.SLOTS == {"library_check": SCHEDULE_DEFAULTS["daily_scan"], "library_discover": SCHEDULE_DEFAULTS["weekly_cycle"]}
    assert set(job.jobs()) == {"library_check", "library_discover"}


def test_every_source_is_whitelisted_or_declared_manual():
    pol = job.policy()
    src = job.load_sources()
    from urllib.parse import urlparse
    for e in store.load_document()["entries"]:
        u = e["source"]["url"]
        host = urlparse(u).hostname
        assert host in src["manual_hosts"] or pol.domain_ok(host), (e["id"], host)
    for w in src["watch"]:
        assert pol.domain_ok(urlparse(w["listing_url"]).hostname), w["id"]


def test_check_writes_state_report_and_worklist_but_never_touches_entries(lib):
    doc = store.load_document()
    before = json.dumps(doc, sort_keys=True)
    pages = build_pages(doc)
    r = run_check(at(0), pages)
    assert r["status"] == "ok" and r["checked"] == 12 and r["counts"] == {"ok": 11, "manual": 1}
    d = store.data_dir()
    assert (d / "library_state.json").exists() and "已核对 12 条" in (d / "library_report.md").read_text("utf-8")
    assert json.dumps(store.load_document(), sort_keys=True) == before
    # 没人审核 → 条目仍然全部不可见
    assert store.annotated(MON) == []


def test_http_source_is_upgraded_and_blocked_hosts_are_reported_not_faked(lib, monkeypatch):
    doc = store.load_document()
    pages = build_pages(doc)
    src = job.load_sources()
    src["manual_hosts"] = {"www.nhc.gov.cn": "拒绝程序访问", "www.nbphsp.org.cn": "只有 http"}
    monkeypatch.setattr(job, "load_sources", lambda: src)
    r = run_check(at(0), pages)
    st = store.load_state()["entries"]
    assert st["ss-lib-001"]["check"] == "manual" and st["ss-lib-005"]["check"] == "ok"
    assert r["counts"]["manual"] == 5 and st["ss-lib-010"]["check"] == "manual"
    assert st["ss-lib-010"]["source_url"].startswith("http://www.nbphsp")


def test_discover_stages_candidates_with_provenance_and_ledger_rows(lib, monkeypatch):
    listing = '<ul><li><a href="/sps/new1.shtml">关于新增食药物质的公告</a><span>2026-10-30</span></li><li><a href="/sps/x.shtml">无关通知</a><span>2026-10-30</span></li></ul>'
    src = job.load_sources()
    src["manual_hosts"] = {}
    monkeypatch.setattr(job, "load_sources", lambda: src)
    pages = {w["listing_url"]: listing.encode() for w in src["watch"]}
    r = job.run_discover(at(3), fetch=job.make_fetch(job.policy(), http=make_http(pages)))
    assert r["status"] == "ok" and r["candidates"] >= 1
    st = store.load_state()
    c = st["candidates"][0]
    assert c["status"] == "待核实" and c["review_status"] == "待审核" and "正文未读" in c["provenance"]["read_scope"]
    rows = [json.loads(x) for x in (store.data_dir() / "library_candidates.jsonl").read_text("utf-8").splitlines()]
    assert rows and rows[0]["grade"] == "B" and rows[0]["flag"].startswith("待核") and rows[0]["license_class"] == "gov_public"
    assert store.annotated(MON) == []  # 候选永远不会出现在用户端


def test_review_cli_round_trip(lib, monkeypatch, capsys):
    from app.library import review_cli
    doc = store.load_document()
    run_check(at(0), build_pages(doc))
    assert review_cli.main(["approve", "ss-lib-005", "--reviewer", "张三"]) == 0
    assert review_cli.main(["approve", "ss-lib-006", "--reviewer", " "]) == 2  # 没有审核人不行
    assert [e["id"] for e in store.annotated(date.today())] == ["ss-lib-005"]
    e = store.annotated(date.today())[0]
    assert e["reviewer"] == "张三" and e["reviewed_hash"] and e["display"]["badges"][0]["kind"] == "verified"
    log = (store.data_dir() / "library_review_log.jsonl").read_text("utf-8")
    assert '"approve"' in log and "张三" in log
    assert review_cli.main(["repeal", "ss-lib-005", "--reviewer", "张三", "--note", "已被替代"]) == 0
    assert store.annotated(date.today()) == []


# ── 5 个用户 × 7 天 ───────────────────────────────────────

PERSONAS = {
    "sleeper": dict(goals=frozenset({"sleep"})),
    "walker": dict(goals=frozenset({"exercise"})),
    "caregiver": dict(goals=frozenset({"family", "food"})),
    "foodie": dict(goals=frozenset(), followed=frozenset({"food"}), constitution="阳虚"),
    "teen": dict(goals=frozenset({"exercise"}), age_group="minor"),
}
UPDATED_ID, REPEALED_ID = "ss-lib-005", "ss-lib-012"  # 运动类条目来源数字变化；广告识别条目来源页写明已废止


class Sim:
    """和 service.build_feed 一样：把「推荐过什么」「读过什么」带到第二天。"""

    def __init__(self, doc, name):
        self.doc, self.name = doc, name
        self.shown, self.opened, self.last_visit = {}, {}, None
        self.extra = dict(PERSONAS[name])

    def feed(self, day, state, *, enabled=True, record=True, limit=5, muted=frozenset()):
        sig = fd.Signals(lang="zh", season="autumn", term="立冬", days_since_term=(day - date(2026, 11, 7)).days % 15, shown=dict(self.shown), opened=dict(self.opened),
                         last_visit=self.last_visit, enabled=enabled, muted=muted, **self.extra)
        items = store.annotated(day, "zh", document=self.doc, state=state, preview=False)
        out = fd.rank(items, sig, self.name, day, limit=limit)
        if record:
            for i in out["items"]:
                self.shown[i["id"]] = day
        return out


def persist(doc, state=None):
    """和审核命令行一样把审核结果写进数据目录，之后的定时核对读到的才是「已审核」的条目。"""
    d = store.data_dir()
    d.mkdir(parents=True, exist_ok=True)
    (d / "reference_entries.json").write_text(json.dumps(doc, ensure_ascii=False), "utf-8")
    if state is not None:
        (d / "library_state.json").write_text(json.dumps(state, ensure_ascii=False), "utf-8")


def approve_all(doc, state, approve_day):
    for e in doc["entries"]:
        if e["status"] == "现行":  # 「待核实」的那一条不审核通过
            review.approve(doc, state, e["id"], "测试审核人", approve_day)


def test_five_users_seven_days_with_a_mid_week_source_update(lib):
    doc = store.load_document()
    pages = build_pages(doc)
    run_check(at(0), pages)
    state = store.load_state()
    approve_all(doc, state, MON)
    # 上线日：周一审核通过 → 周二新增一条：ss-lib-009（节气）周二才审核
    nine = next(e for e in doc["entries"] if e["id"] == "ss-lib-009")
    nine["review_status"] = "待审核"
    nine.pop("approved_at", None)
    persist(doc, state)
    sims = {n: Sim(doc, n) for n in PERSONAS}
    feeds: dict = {n: [] for n in PERSONAS}
    snapshots: dict = {}
    for i in range(7):
        day = MON + timedelta(days=i)
        if i == 1:
            review.approve(doc, state, "ss-lib-009", "测试审核人", day)
            persist(doc, state)
        if i == 3:  # 周四凌晨的核对：运动条目来源数字变了，广告条目来源页出现「已废止」
            pages = build_pages(doc, changed=(UPDATED_ID,), repealed=(REPEALED_ID,))
        run_check(at(i), pages)
        state = store.load_state()
        snapshots[i] = json.loads(json.dumps(state))
        if i == 4:  # 周五：审核人读过来源，改好条目，写变更说明
            review.update(doc, state, UPDATED_ID, "测试审核人", day, "成年人每周中等强度活动时间的表述更新")
            persist(doc, state)
        for n, s in sims.items():
            out = s.feed(day, state)
            feeds[n].append({"day": day, "ids": [x["id"] for x in out["items"]], "items": {x["id"]: x for x in out["items"]}})
            assert all(x["reason"] for x in out["items"]), (n, day)
            s.last_visit = day  # 访问之后才记录
    names = list(PERSONAS)

    # 1) 每天五个人的推荐两两不同（次序或集合），前三条集合至少一半的组合不同
    for d in range(7):
        lists = [tuple(feeds[n][d]["ids"]) for n in names]
        assert len(set(lists)) == 5, f"day {d}: identical feeds"
        tops = [frozenset(feeds[n][d]["ids"][:3]) for n in names]
        pairs = [(a, b) for a in range(5) for b in range(a + 1, 5)]
        assert sum(1 for a, b in pairs if tops[a] != tops[b]) >= 6, d

    # 2) 每个人每天的推荐在变（轮换），不会一直重复同样的
    for n in names:
        sets = [tuple(f["ids"]) for f in feeds[n]]
        assert len(set(sets)) >= 5, n

    # 3) 周四：来源变了 → 立刻不再推荐，但列表里还看得到，带「来源有更新」提示
    for n in names:
        for d in (3, 4 - 1):
            assert UPDATED_ID not in feeds[n][d]["ids"], (n, d)
    thu_state = snapshots[3]
    # 4) 周五更新之后：相关用户的推荐里带「更新于」和变更说明；无关用户（不关注运动、目标不含运动/家人）不被打扰
    fri = {n: feeds[n][4]["items"].get(UPDATED_ID) for n in names}
    for n in ("walker", "teen", "caregiver"):
        it = fri[n]
        assert it and it["badge"] == "updated" and it["change_note"] == "成年人每周中等强度活动时间的表述更新", n
        assert any(b["kind"] == "updated" for b in it["badges"]) and "最近有更新" in it["reason"]
    # 「更新」只给在意这个主题的人、或之前（周一到周三）看到过旧版本的人；和他无关就不挂徽标、不加分
    def saw_before(n):
        return any(UPDATED_ID in feeds[n][d]["ids"] for d in range(0, 3))

    for n in names:
        it = feeds[n][4]["items"].get(UPDATED_ID)
        topic_match = n in ("walker", "teen", "caregiver")
        if topic_match or saw_before(n):
            assert it is None or it["badge"] == "updated", (n, it)
        else:
            assert it is None or it["badge"] is None, (n, it)  # 无关又没看过：不打扰
    assert any(UPDATED_ID in feeds[n][4]["ids"] for n in ("walker", "teen", "caregiver"))
    # 5) 已废止：周四起任何人的推荐/列表里都没有；详情直接打开只看到横幅
    for n in names:
        for d in range(3, 7):
            assert REPEALED_ID not in feeds[n][d]["ids"]
    visible = {e["id"] for e in store.annotated(MON + timedelta(days=3), "zh", document=doc, state=thu_state, preview=False)}
    assert REPEALED_ID not in visible and UPDATED_ID in visible and "ss-lib-011" not in visible
    held = next(e for e in store.annotated(MON + timedelta(days=3), "zh", document=doc, state=thu_state, preview=False) if e["id"] == UPDATED_ID)
    assert held["display"]["state"] == "source_changed" and "官方原文" in held["display"]["banner"] and not held["display"]["current"]
    direct = store.find(REPEALED_ID, MON + timedelta(days=3), "zh", document=doc, state=thu_state, preview=False)
    assert direct["display"]["state"] == "repeal_hold" and "废止" in direct["display"]["banner"]
    # 6) 周二新增的条目：周一访问过的用户在周二看到「新」；他们周二来过之后，周三起不再标「新」
    new_badges = {n: feeds[n][1]["items"].get("ss-lib-009") for n in names}
    assert any(v and v["badge"] == "new" and "上次来之后新增" in v["reason"] for v in new_badges.values())
    assert all(not (feeds[n][d]["items"].get("ss-lib-009") or {}).get("badge") for n in names for d in range(2, 7))
    # 7) 内容安全：推荐理由（程序生成的句子）里不出现诊断、治疗、疗效之类的词（条目正文是官方资料的改写，可以提醒「不能宣传治病」）；未成年人不收到饮食/体质/消费类
    for n in names:
        for f in feeds[n]:
            for it in f["items"].values():
                assert not [w for w in FORBIDDEN if w in it["reason"].replace("自评，不是诊断", "")], (n, it["id"])
    teen_topics = {it["topic"] for f in feeds["teen"] for it in f["items"].values()}
    assert not (teen_topics & fd.MINOR_BLOCK), teen_topics
    # 体质只作为「自评，不是诊断」的理由出现
    for f in feeds["foodie"]:
        for it in f["items"].values():
            if "constitution" in it["reason_codes"]:
                assert "自评，不是诊断" in it["reason"]

    import os
    if os.environ.get("LIBRARY_DUMP_DIR"):  # 截图用：把周四、周五的真实结果导出成界面预览的数据
        out_dir = os.environ["LIBRARY_DUMP_DIR"]
        os.makedirs(out_dir, exist_ok=True)
        for di, suffix in ((4, ""), (3, "_thu")):
            ents = store.annotated(MON + timedelta(days=di), "zh", document=doc, state=snapshots[di], preview=False)
            for n in names:
                marks = {i: it["badge"] for i, it in feeds[n][di]["items"].items() if it["badge"]}
                mine = [dict(e, badge=marks[e["id"]]) if e["id"] in marks else e for e in ents]
                topics = [{"id": k, "name": v["zh"], "followed": k in PERSONAS[n].get("followed", ()), "muted": False} for k, v in fd.TOPICS.items()]
                feed_json = {"enabled": True, "items": list(feeds[n][di]["items"].values()), "topics": topics, "note": "推荐只用你自己填写的目标、关注的主题和在应用里读过的内容；资料来自官方文件，仅供了解，不是诊断或治疗建议。可随时关闭。"}
                open(f"{out_dir}/{n}{suffix}.json", "w", encoding="utf-8").write(json.dumps({"entries": mine, "feed": feed_json}, ensure_ascii=False))


# ── 单个行为 ─────────────────────────────────────────────

def _guest(client):
    r = client.post("/api/v1/auth/guest-login", json={"device_id": "lib-test"})
    payload = r.json()
    token = payload.get("access_token") or payload["data"]["token"]
    return {"Authorization": f"Bearer {token}"}


def _approved(day=MON, only=None):
    """内存里的一份「全部审核通过」的资料（不碰磁盘）。"""
    doc = store.load_document()
    state = {"entries": {}, "candidates": []}
    for e in doc["entries"]:
        if e["status"] == "现行" and (only is None or e["id"] in only):
            review.approve(doc, state, e["id"], "测试审核人", day)
    return doc, state


def _sig(**kw):
    base = dict(lang="zh", season="autumn", term="立冬", days_since_term=1)
    base.update(kw)
    return fd.Signals(**base)


def test_follow_mute_and_off_switch_change_the_feed():
    day = MON + timedelta(days=1)
    doc, state = _approved()
    items = store.annotated(day, "zh", document=doc, state=state, preview=False)
    plain = fd.rank(items, _sig(), "u", day, limit=20)
    ids = [i["id"] for i in plain["items"]]
    sleep_ids = [e["id"] for e in items if fd.topic_of(e) == "sleep"]
    assert sleep_ids and set(sleep_ids) <= set(ids)
    # 关注睡眠 → 睡眠类排最前，理由写明
    followed = fd.rank(items, _sig(followed=frozenset({"sleep"})), "u", day, limit=20)
    assert followed["items"][0]["id"] in sleep_ids and "你关注了「睡眠与情绪」" in followed["items"][0]["reason"]
    # 静音睡眠 → 一条都不出现
    muted = fd.rank(items, _sig(muted=frozenset({"sleep"})), "u", day, limit=20)
    assert not [i for i in muted["items"] if i["id"] in sleep_ids]
    # 总开关关闭 → 空，并说明是关闭
    off = fd.rank(items, _sig(enabled=False), "u", day, limit=20)
    assert off == {"items": [], "enabled": False}


def test_stale_entry_is_not_current_and_not_recommended():
    doc, state = _approved()
    eid = "ss-lib-005"
    state["entries"][eid] = {"check": "changed", "last_checked_at": "2026-11-05T02:00:00+08:00", "last_ok_at": "2026-11-04T02:00:00+08:00",
                             "content_hash": "x", "change": {"ratio": 0.2, "digits_changed": True}}
    day = date(2026, 11, 5)
    items = {e["id"]: e for e in store.annotated(day, "zh", document=doc, state=state, preview=False)}
    d = items[eid]["display"]
    assert d["state"] == "source_changed" and not d["current"] and not d["feed_eligible"] and "官方原文" in d["banner"]
    got = fd.rank(list(items.values()), _sig(goals=frozenset({"exercise"})), "u", day, limit=20)
    assert eid not in [i["id"] for i in got["items"]]
    # 来源页出现「已废止」：列表里直接消失
    state["entries"][eid]["check"] = "repeal_signal"
    assert eid not in {e["id"] for e in store.annotated(day, "zh", document=doc, state=state, preview=False)}


def test_home_card_only_for_new_or_strong_match_and_never_for_off_users():
    day = MON + timedelta(days=1)
    doc, state = _approved()
    items = store.annotated(day, "zh", document=doc, state=state, preview=False)
    # 来访过、之后没有新增 → 通用参考不够强，不出卡片
    quiet = fd.rank(items, _sig(last_visit=day), "u", day, limit=6)
    assert fd.home_card(quiet) is None
    # 上次来访之前就有人审核通过的不算新；新审核的算
    late_doc, late_state = _approved(day=day)
    late_items = store.annotated(day, "zh", document=late_doc, state=late_state, preview=False)
    card = fd.home_card(fd.rank(late_items, _sig(last_visit=day - timedelta(days=3)), "u", day, limit=6))
    assert card and card["id"] == "library_for_you" and card["href"] == "/reference-library" and card["reason"] and card["title"].startswith("资料库新增")
    # 关注的主题匹配度很高（≥5）也出卡片
    strong = fd.rank(items, _sig(last_visit=day, followed=frozenset({"sleep"})), "u", day, limit=6)
    assert fd.home_card(strong)["title"].startswith("为你选了一篇")
    # 关闭个性化：永远没有卡片
    assert fd.home_card(fd.rank(late_items, _sig(enabled=False), "u", day, limit=6)) is None


def test_everything_user_facing_is_chinese_and_topics_are_complete():
    day = MON + timedelta(days=1)
    doc, state = _approved()
    items = store.annotated(day, "zh", document=doc, state=state, preview=False)
    assert {fd.topic_of(e) for e in items} <= set(fd.TOPICS)  # 每条资料都落在一个可关注的主题里
    out = fd.rank(items, _sig(goals=frozenset({"sleep", "family"}), constitution="气虚", followed=frozenset({"food"})), "u", day, limit=20)
    texts = [fd.TOPICS[k]["zh"] for k in fd.TOPICS] + list(fd.GOAL_NAMES.values())
    for it in out["items"]:
        texts += [it["reason"], it["topic_name"]] + [b["text"] for b in it["badges"]]
    assert all(CJK.search(t) for t in texts if t), [t for t in texts if t and not CJK.search(t)]
    # 英文版文字也齐全（国际版或日后需要时用）
    for k, v in fd.TOPICS.items():
        assert v["en"] and not CJK.search(v["en"])


def test_api_empty_by_default_then_feed_prefs_visit_flow(client, lib, monkeypatch):
    from app.routers import library as lr
    h = _guest(client)
    monkeypatch.setattr(lr, "_today", lambda: MON + timedelta(days=1))
    # 默认：全部待审核 → 列表、推荐都是空，没有首页卡片
    assert client.get("/api/v1/library/entries", headers=h).json()["entries"] == []
    f = client.get("/api/v1/library/feed", headers=h).json()
    assert f["items"] == [] and f["enabled"] is True and len(f["topics"]) == 6
    assert client.get("/api/v1/library/entries/ss-lib-005", headers=h).status_code == 404
    assert client.get("/api/v1/library/feed").status_code == 401  # 必须登录
    # 审核通过两条 → 有内容
    doc = store.load_document()
    state = {"entries": {}, "candidates": []}
    for eid in ("ss-lib-005", "ss-lib-008"):
        review.approve(doc, state, eid, "测试审核人", MON)
    (store.data_dir()).mkdir(parents=True, exist_ok=True)
    (store.data_dir() / "reference_entries.json").write_text(json.dumps(doc, ensure_ascii=False), "utf-8")
    f = client.get("/api/v1/library/feed", headers=h).json()
    assert {i["id"] for i in f["items"]} == {"ss-lib-005", "ss-lib-008"}
    assert all(i["reason"] and i["badges"][0]["kind"] == "verified" for i in f["items"])
    # 关注 / 取消关注 / 静音 / 总开关
    r = client.put("/api/v1/library/preferences", json={"follow": ["sleep"]}, headers=h).json()
    assert r["followed"] == ["sleep"]
    f = client.get("/api/v1/library/feed", headers=h).json()
    assert f["items"][0]["id"] == "ss-lib-008" and any(t["id"] == "sleep" and t["followed"] for t in f["topics"])
    r = client.put("/api/v1/library/preferences", json={"mute": ["sleep"]}, headers=h).json()
    assert r["muted"] == ["sleep"] and r["followed"] == []
    assert {i["id"] for i in client.get("/api/v1/library/feed", headers=h).json()["items"]} == {"ss-lib-005"}
    assert client.put("/api/v1/library/preferences", json={"follow": ["nonsense"]}, headers=h).status_code == 422
    assert client.put("/api/v1/library/preferences", json={"enabled": False}, headers=h).json()["enabled"] is False
    off = client.get("/api/v1/library/feed", headers=h).json()
    assert off["items"] == [] and off["enabled"] is False
    client.put("/api/v1/library/preferences", json={"enabled": True, "unmute": ["sleep"]}, headers=h)
    # 读过之后这一条往后排；访问记录之后，「新」徽标消失
    assert client.post("/api/v1/library/opened/ss-lib-005", headers=h).status_code == 200
    assert client.post("/api/v1/library/opened/ss-lib-999", headers=h).status_code == 404
    assert client.post("/api/v1/library/visit", headers=h).status_code == 200
    f = client.get("/api/v1/library/feed", headers=h).json()
    assert f["since"] == (MON + timedelta(days=1)).isoformat() and all(i["badge"] != "new" for i in f["items"])
    assert f["items"][0]["id"] == "ss-lib-008"


def test_entries_are_public_but_carry_visit_badges_for_logged_in_users(client, lib, monkeypatch):
    from app.routers import library as lr
    h = _guest(client)
    doc = store.load_document()
    state = {"entries": {}, "candidates": []}
    review.approve(doc, state, "ss-lib-005", "测试审核人", MON)
    (store.data_dir()).mkdir(parents=True, exist_ok=True)
    (store.data_dir() / "reference_entries.json").write_text(json.dumps(doc, ensure_ascii=False), "utf-8")
    monkeypatch.setattr(lr, "_today", lambda: MON + timedelta(days=1))
    # 匿名也能看（没有标记）；第一次登录来访：没有来访记录，不标「新」
    anon = client.get("/api/v1/library/entries").json()
    assert [e["id"] for e in anon["entries"]] == ["ss-lib-005"] and anon["personalized"] is False and "badge" not in anon["entries"][0]
    first = client.get("/api/v1/library/entries", headers=h).json()
    assert first["personalized"] is True and "badge" not in first["entries"][0]
    # 来访后，之后审核通过新的一条 → 对这位用户标「新」；已读过的那条不标
    client.post("/api/v1/library/visit", headers=h)
    review.approve(doc, state, "ss-lib-008", "测试审核人", MON + timedelta(days=3))
    (store.data_dir() / "reference_entries.json").write_text(json.dumps(doc, ensure_ascii=False), "utf-8")
    monkeypatch.setattr(lr, "_today", lambda: MON + timedelta(days=4))
    got = {e["id"]: e.get("badge") for e in client.get("/api/v1/library/entries", headers=h).json()["entries"]}
    assert got == {"ss-lib-005": None, "ss-lib-008": "new"}
    # 令牌无效就当匿名，不报错
    assert client.get("/api/v1/library/entries", headers={"Authorization": "Bearer x"}).json()["personalized"] is False


def test_backend_copy_of_the_library_matches_the_app_asset():
    """后端和 App 各带一份同样的资料（后端部署时看不到 App 的 assets）；改一边必须同步改另一边。"""
    import pathlib
    app_copy = pathlib.Path(__file__).resolve().parents[2] / "android-cn" / "assets" / "library" / "reference_entries_v1.json"
    if not app_copy.exists():  # 只在整个仓库里跑时检查（后端镜像单独跑时跳过）
        pytest.skip("android-cn assets not present")
    ios_copy = app_copy.parents[3] / "ios-cn" / "assets" / "library" / "reference_entries_v1.json"
    mine = json.loads((pathlib.Path(store.__file__).parent / "data" / "reference_entries_v1.json").read_text("utf-8"))
    assert json.loads(app_copy.read_text("utf-8")) == mine
    if ios_copy.exists():
        assert json.loads(ios_copy.read_text("utf-8")) == mine
