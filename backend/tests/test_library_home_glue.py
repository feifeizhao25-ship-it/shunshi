"""顺时：资料库卡接入个性化首页（国内版）。

5 个用户 × 7 天，走真实的 /seasons/home/dashboard，周四来源变化、周五审核人更新：
  * 资料库里没有已审核条目（默认）时，首页不出现资料库卡，原有首页内容不变；
  * 出现时最多一张、紧跟第一张日历/节气卡之后、带「为什么推荐」和进入资料库的路径；
  * 来源有变化（周四）或已废止的条目，首页卡片里一律不出现；周五审核人更新后，以「资料库有更新」出现，而且只给相关的人；
  * 关掉资料库推荐、或关掉首页个性化，卡片立刻消失；资料库出任何异常都不影响首页；国际版没有这张卡。
"""

import json
import os
import pathlib
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

import pytest

from app.library import store
from app.library_live import review
from app.services import personal_home_service as phs

from .test_library_live import MON, REPEALED_ID, UPDATED_ID, approve_all, at, build_pages, lib, persist, run_check  # noqa: F401

SH = ZoneInfo("Asia/Shanghai")
ONBOARD = {
    "sleeper": {"help_goal": "睡得更好", "support_time": "晚上"},
    "walker": {"help_goal": "白天更有精神", "support_time": "早上"},
    "caregiver": {"help_goal": "照顾家人", "support_time": "晚上"},
    "stressed": {"help_goal": "放松减压", "support_time": "下午"},
    "newcomer": {},
}
VISITORS = ("walker", "caregiver")
FOLLOW = {"walker": ["move"], "caregiver": ["move"]}


def _user(client, name):
    r = client.post("/api/v1/auth/guest-login", json={"device_id": f"glue-{name}"}).json()
    token = r.get("access_token") or r["data"]["token"]
    h = {"Authorization": f"Bearer {token}"}
    if ONBOARD[name]:
        assert client.post("/api/v1/seasons/onboarding/complete", json=ONBOARD[name], headers=h).status_code == 200
    return h


def _pin(monkeypatch, day_offset):
    when = datetime(MON.year, MON.month, MON.day, 9, tzinfo=SH) + timedelta(days=day_offset)
    monkeypatch.setattr(phs, "local_now", lambda is_global, tz, now_utc=None: when if not is_global else when)
    from app.routers import library as lr
    monkeypatch.setattr(lr, "_today", lambda: when.date())


def _dump(edition, name, day, data):
    """截图用：LIB_FIXTURE_DIR 设置时，把每个人每天首页接口的真实返回原样存下来（不是手写的）。"""
    d = os.environ.get("LIB_FIXTURE_DIR")
    if d:
        out = pathlib.Path(d)
        out.mkdir(parents=True, exist_ok=True)
        (out / f"{edition}_{name}_d{day}.json").write_text(json.dumps(data, ensure_ascii=False), "utf-8")


def _home(client, h):
    return client.get("/api/v1/seasons/home/dashboard", headers=h).json()


def _lib_cards(data):
    return [c for c in data["suggestions"] if c.get("kind") == "library"]


def test_five_users_seven_days_library_card_on_home(client, lib, monkeypatch):  # noqa: F811
    users = {n: _user(client, n) for n in ONBOARD}
    for n, topics in FOLLOW.items():
        assert client.put("/api/v1/library/preferences", json={"follow": topics}, headers=users[n]).status_code == 200
    doc = store.load_document()
    pages = build_pages(doc)
    _pin(monkeypatch, 0)
    run_check(at(0), pages)
    state = store.load_state()
    seen: dict = {n: {} for n in users}
    for i in range(7):
        _pin(monkeypatch, i)
        if i == 1:  # 周二：全部审核通过，资料库上线
            approve_all(doc, state, MON + timedelta(days=1))
            persist(doc, state)
        if i == 3:  # 周四凌晨：运动条目来源数字变了，广告识别条目来源页写明已废止
            pages = build_pages(doc, changed=(UPDATED_ID,), repealed=(REPEALED_ID,))
        run_check(at(i), pages)
        state = store.load_state()
        if i == 4:  # 周五：审核人读过来源、改好、写变更说明
            review.update(doc, state, UPDATED_ID, "测试审核人", MON + timedelta(days=4), "成年人每周中等强度活动时间的表述更新")
            persist(doc, state)
        for n, h in users.items():
            data = _home(client, h)
            again = _home(client, h)
            assert [c["id"] for c in data["suggestions"]] == [c["id"] for c in again["suggestions"]], "刷新首页不能重排"
            _dump("cn", n, i, data)
            cards = _lib_cards(data)
            assert len(cards) <= 1 and data["suggestions"] == data["gentle_suggestions"]
            if i < 1:
                assert not cards, "没有已审核条目时首页不能出现资料库卡"
            if cards:
                c = cards[0]
                assert c["href"] == "/reference-library" and c["reason"] and c["id"] == "library_for_you"
                assert data["suggestions"].index(c) == min(1, len(data["suggestions"]) - 1) and data["suggestions"][0] is not c
                assert c["entry_id"] != REPEALED_ID or i < 3, "已废止的条目不能上首页"
                if i == 3:
                    assert c["entry_id"] != UPDATED_ID, "来源有变化、待审核的条目不能上首页"
                seen[n][i] = c
            if n in VISITORS:  # 这两位每天看完首页都会点进资料库逛一下（记一次来访）
                assert client.post("/api/v1/library/visit", headers=h).status_code == 200
    # 周二起至少有人看到资料库卡；不同的人看到不同的条目
    assert any(seen[n] for n in users)
    assert len({c["entry_id"] for n in users for c in seen[n].values()}) >= 2
    assert all(not seen[n].get(0) for n in users)
    # 周四、之后：已废止的从未出现
    assert not [c for n in users for d, c in seen[n].items() if d >= 3 and c["entry_id"] == REPEALED_ID]
    # 周五更新：来访过的、在意运动的人收到「资料库有更新」；没来过资料库的人只是「新增」；睡眠/新人这一条不会带「更新」
    fri = {n: seen[n].get(4) for n in users}
    assert fri["walker"] and fri["walker"]["entry_id"] == UPDATED_ID and fri["walker"]["title"].startswith("资料库有更新：")
    assert "更新" in fri["walker"]["reason"]
    for n, c in fri.items():
        if c and c["entry_id"] == UPDATED_ID and n not in VISITORS:
            assert c["title"].startswith("资料库新增："), n  # 从没来过的人看到的是「新增」，不是「更新」
    # 周五之后，来访过的人不会再看到同一条「更新」（已读过 / 来访已记录）
    for n in VISITORS:
        assert not [d for d in (5, 6) if seen[n].get(d) and seen[n][d]["title"].startswith("资料库有更新：")], n


def test_switches_and_failures_never_break_home(client, lib, monkeypatch):  # noqa: F811
    h = _user(client, "walker")
    client.put("/api/v1/library/preferences", json={"follow": ["move"]}, headers=h)
    doc = store.load_document()
    state = {"entries": {}, "candidates": []}
    approve_all(doc, state, MON)
    persist(doc, state)
    _pin(monkeypatch, 2)
    base = _home(client, h)
    assert _lib_cards(base), "已审核 + 关注运动 → 应有一张卡"
    # 关掉资料库推荐
    client.put("/api/v1/library/preferences", json={"enabled": False}, headers=h)
    assert not _lib_cards(_home(client, h))
    client.put("/api/v1/library/preferences", json={"enabled": True}, headers=h)
    assert _lib_cards(_home(client, h))
    # 关掉首页个性化 → 资料库卡也不出现（只剩通用提示）
    client.post("/api/v1/seasons/profile/preferences", json={"personalization_enabled": False}, headers=h)
    off = _home(client, h)
    assert not _lib_cards(off) and off["suggestions"]
    client.post("/api/v1/seasons/profile/preferences", json={"personalization_enabled": True}, headers=h)
    # 资料库抛异常：首页照常返回，只是没有这张卡
    from app.library import service

    def boom(*a, **k):
        raise RuntimeError("library down")

    monkeypatch.setattr(service, "home_card", boom)
    r = client.get("/api/v1/seasons/home/dashboard", headers=h)
    assert r.status_code == 200 and not _lib_cards(r.json()) and r.json()["suggestions"]


def test_international_home_has_no_library_card(client, lib, monkeypatch):  # noqa: F811
    h = _user(client, "walker")
    doc = store.load_document()
    approve_all(doc, {"entries": {}, "candidates": []}, MON)
    persist(doc, {"entries": {}, "candidates": []})
    _pin(monkeypatch, 2)
    en = {**h, "Accept-Language": "en", "X-App-Market": "global"}
    data = client.get("/api/v1/seasons/home/dashboard", headers=en).json()
    assert not _lib_cards(data) and "资料库" not in json.dumps(data, ensure_ascii=False)


def test_with_library_card_is_a_noop_for_empty_library_and_keeps_hero(lib):  # noqa: F811
    board = {"personalization": {"enabled": True}, "date": MON.isoformat(), "hero": {"id": "h"}, "cards": [{"id": "a"}, {"id": "b"}]}

    class S:  # session 不会被用到：资料库没有已审核条目 → 没有卡
        pass

    out = phs.with_library_card(S(), "u1", board)
    assert out["cards"] == board["cards"] and out["hero"] == board["hero"]


def test_international_five_users_seven_days_home_is_english_and_has_no_library_card(client, lib, monkeypatch):  # noqa: F811
    """国际版（SEASONS）5 个用户 × 7 天：首页区块全英文，没有资料库卡（这个资料库只属于国内版）。"""
    users = {n: _user(client, n) for n in ONBOARD}
    doc = store.load_document()
    approve_all(doc, {"entries": {}, "candidates": []}, MON)
    persist(doc, {"entries": {}, "candidates": []})
    cjk = __import__("re").compile(r"[\u3400-\u9fff]")
    for i in range(7):
        _pin(monkeypatch, i)
        for n, h in users.items():
            en = {**h, "Accept-Language": "en", "X-App-Market": "global"}
            data = client.get("/api/v1/seasons/home/dashboard", headers=en).json()
            _dump("global", n, i, data)
            assert not _lib_cards(data), (n, i)
            blob = json.dumps(data, ensure_ascii=False)
            assert not cjk.search(blob), (n, i, cjk.search(blob).group(0))
