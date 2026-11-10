"""国内首页与资料库的时钟回放。不是墙上连续 7 天，也不是界面或真机验收。

完成动作的因果只在同一时刻、同一画像、同一候选集上比较，并保留一个没有动作的对照。
资料库生产条目保持待审核：HTTP 只证明空库与偏好读写；过滤机制用标明的合成条目，不写审核人。
对话额度只读注册表现值，不改数字。首页排序不因付费档而改变，这不是会员缺陷。
"""
from __future__ import annotations

import asyncio
import json
import os
from datetime import datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

import pytest
from fastapi import HTTPException

from app.entitlements import get_registry, tier_for_product
from app.library import feed as library_feed
from app.library import store as library_store
from app.services import chat_quota
from app.services import personal_home as ph
from app.services import personal_home_service as phs
from app.simple_models import Entitlement, UserSetting

SH = ZoneInfo("Asia/Shanghai")
WEEK_START = datetime(2026, 11, 2, 8, 0, tzinfo=SH)  # 周一 08:00，七天都用这个钟点
CAUSAL_AT = datetime(2026, 11, 4, 21, 0, tzinfo=SH)  # 周三 21:00，对照与动作后仍是这一刻
REINFORCE = "你最近做过同类小行动"
BUNDLED_LIBRARY = library_store.BUNDLED
PIN = []

ONBOARD = {
    "sleeper": {"help_goal": "睡得更好", "support_time": "晚上"},
    "walker": {"help_goal": "白天更有精神", "support_time": "早上"},
    "caregiver": {"help_goal": "照顾家人", "support_time": "晚上"},
    "stressed": {"help_goal": "放松减压", "support_time": "下午"},
    "newcomer": {},
}


def test_clock_header_is_test_env_only():
    from types import SimpleNamespace

    request = SimpleNamespace(headers={"x-shunshi-test-now": "2026-11-04T21:00:00+08:00"})
    assert phs.test_clock(request, SimpleNamespace(env="production")) is None
    assert phs.test_clock(request, SimpleNamespace(env="development")) is None
    pinned = phs.test_clock(request, SimpleNamespace(env="testing"))
    assert pinned is not None and pinned.astimezone(SH).hour == 21


def test_solar_term_uses_the_same_test_clock(client):
    from app.utils.solar_term_calendar import beijing_today, term_on

    pinned = client.get(
        "/api/v1/solar-terms/current",
        headers={"X-Shunshi-Test-Now": "2026-11-04T21:00:00+08:00"},
    )
    assert pinned.status_code == 200, pinned.text
    assert pinned.json()["data"]["name"] == term_on(datetime(2026, 11, 4).date())
    live = client.get("/api/v1/solar-terms/current")
    assert live.json()["data"]["name"] == term_on(beijing_today())


def test_http_dashboard_uses_test_clock_header(client):
    headers, _user_id = _guest(client)
    headers = {**headers, "X-Shunshi-Test-Now": "2026-11-04T21:00:00+08:00"}
    board = _board(client, headers)
    assert board["date"] == "2026-11-04"
    assert board["time_of_day"] == "evening"


def _pin_now(is_global, tz, now_utc=None):
    when = PIN[-1]
    return when.astimezone(SH) if not is_global else when


def _guest(client):
    created = client.post("/api/v1/auth/guest-login", json={}).json()
    token = created.get("access_token") or created["data"]["token"]
    headers = {"Authorization": f"Bearer {token}"}
    me = client.get("/api/v1/auth/me", headers=headers)
    assert me.status_code == 200, me.text
    return headers, me.json()["data"]["id"]


def _board(client, headers):
    response = client.get("/api/v1/seasons/home/dashboard", headers=headers)
    assert response.status_code == 200, response.text
    return response.json()


def _brief(board):
    return [
        {
            "id": card["id"],
            "category": card.get("category"),
            "reason": card.get("reason"),
            "bases": card.get("bases"),
            "score": card.get("score"),
        }
        for card in board["suggestions"]
    ]


def _today_done(board):
    return next(item["done"] for item in board["week"] if item["today"])


# ── 同一时刻的完成动作对照（纯函数，候选集就是产品里的 LIBRARY）──────────────

def test_completion_changes_only_the_designed_outputs_at_one_clock():
    """睡前动作按现有计分只影响同类卡片、连续天数和本周记录。

    同类且带目标的卡片：reinforce +1.5，并因为刚做过再 -1，净增 0.5，reason 出现「你最近做过同类小行动」。
    其他类别的分数不变。没有动作的对照必须与动作前完全相同。
    """
    profile = ph.Profile(lang="zh", season=ph.season_of(CAUSAL_AT.date()), goals=frozenset({"sleep"}), support_time="night")
    empty = ph.Activity()
    before = ph.compose(profile, empty, "same-user", CAUSAL_AT, "weekday")
    control = ph.compose(profile, empty, "same-user", CAUSAL_AT, "weekday")
    acted = ph.Activity(completed=[("sleep", CAUSAL_AT)])
    after = ph.compose(profile, acted, "same-user", CAUSAL_AT, "weekday")

    assert control == before
    assert _today_done({"week": before["week"]}) is False
    assert _today_done({"week": after["week"]}) is True
    assert before["streak"]["kind"] == "start"
    assert after["streak"]["kind"] == "steady"
    assert "activity" not in before["personalization"]["used"]
    assert "activity" in after["personalization"]["used"]

    before_by_id = {card["id"]: card for card in before["cards"] if card["id"] in ph.BY_ID}
    after_by_id = {card["id"]: card for card in after["cards"] if card["id"] in ph.BY_ID}
    sleep_after = [card for card in after_by_id.values() if card["category"] == "sleep"]
    assert sleep_after, "这个画像在这一刻应能看到睡眠类建议"
    for card in sleep_after:
        assert "reinforce" in card["bases"]
        assert REINFORCE in card["reason"]
        previous = before_by_id[card["id"]]
        assert card["score"] == round(previous["score"] + 0.5, 2)
    for card_id, card in after_by_id.items():
        if card["category"] == "sleep" or card_id not in before_by_id:
            continue
        assert card["score"] == before_by_id[card_id]["score"]
        assert card["reason"] == before_by_id[card_id]["reason"]
        assert "reinforce" not in card["bases"]


# ── HTTP：五人七天固定 08:00，另加同一 21:00 的动作对照 ─────────────────────

def test_http_clock_replay_five_users_seven_days_and_same_instant_action(client, monkeypatch, tmp_path):
    monkeypatch.setenv("SHUNSHI_LIBRARY_DIR", str(tmp_path / "library"))
    bundled_before = BUNDLED_LIBRARY.read_bytes()
    monkeypatch.setattr(phs, "local_now", _pin_now)
    users = {}
    for name, body in ONBOARD.items():
        headers, user_id = _guest(client)
        if body:
            response = client.post("/api/v1/seasons/onboarding/complete", json=body, headers=headers)
            assert response.status_code == 200, response.text
        users[name] = {"headers": headers, "user_id": user_id, "onboarding": body}

    days = []
    for offset in range(7):
        when = WEEK_START + timedelta(days=offset)
        assert when.hour == 8
        PIN.append(when)
        row = {"date": when.date().isoformat(), "hour": 8, "users": {}}
        for name, user in users.items():
            first = _board(client, user["headers"])
            second = _board(client, user["headers"])
            assert _brief(first) == _brief(second)
            row["users"][name] = _brief(first)
        days.append(row)

    names = list(users)
    for left in range(5):
        for right in range(left + 1, 5):
            differing = sum(
                1 for day in days
                if [item["id"] for item in day["users"][names[left]]] != [item["id"] for item in day["users"][names[right]]]
            )
            assert differing == 7, (names[left], names[right], differing)
    for name in names:
        sequences = [tuple(item["id"] for item in day["users"][name]) for day in days]
        assert len(set(sequences)) == 7, name

    # 同一周三 21:00：一个人完成睡眠，另一个相同画像的人不做。
    PIN.append(CAUSAL_AT)
    monkeypatch.setattr("time.time", lambda: CAUSAL_AT.timestamp())
    actor_headers, actor_id = _guest(client)
    control_headers, control_id = _guest(client)
    for headers in (actor_headers, control_headers):
        assert client.post("/api/v1/seasons/onboarding/complete", json=ONBOARD["sleeper"], headers=headers).status_code == 200
    actor_before = _board(client, actor_headers)
    control_before = _board(client, control_headers)
    assert _brief(_board(client, actor_headers)) == _brief(actor_before)
    assert _brief(_board(client, control_headers)) == _brief(control_before)
    completed = client.post(
        "/api/v1/personalization/action/complete",
        json={"action_type": "sleep", "completed": True},
        headers=actor_headers,
    )
    assert completed.status_code == 200, completed.text
    actor_after = _board(client, actor_headers)
    control_after = _board(client, control_headers)
    assert _brief(control_after) == _brief(control_before)
    assert _today_done(control_after) is False
    assert _today_done(actor_after) is True
    sleep_cards = [card for card in actor_after["suggestions"] if card.get("category") == "sleep"]
    assert sleep_cards and all(REINFORCE in card["reason"] and "reinforce" in card.get("bases", []) for card in sleep_cards)
    before_scores = {card["id"]: card.get("score") for card in actor_before["suggestions"]}
    for card in actor_after["suggestions"]:
        if card.get("category") == "sleep" or card["id"] not in before_scores:
            continue
        assert card.get("score") == before_scores[card["id"]]
        previous = next(item for item in actor_before["suggestions"] if item["id"] == card["id"])
        assert card.get("reason") == previous.get("reason")

    # 只关闭其中一个账号。
    PIN.append(WEEK_START)
    assert client.post(
        "/api/v1/seasons/profile/preferences",
        json={"personalization_enabled": False},
        headers=users["newcomer"]["headers"],
    ).status_code == 200
    newcomer_off = _board(client, users["newcomer"]["headers"])
    sleeper_still = _board(client, users["sleeper"]["headers"])
    assert newcomer_off["personalization"]["enabled"] is False and newcomer_off["hero"] is None
    assert sleeper_still["personalization"]["enabled"] is True

    # 真实空库：关注、取消、不再推荐都只改这个用户的偏好，推荐列表仍为空。
    library_headers = users["caregiver"]["headers"]
    empty = client.get("/api/v1/library/feed", headers=library_headers)
    assert empty.status_code == 200 and empty.json()["items"] == []
    followed = client.put("/api/v1/library/preferences", json={"follow": ["sleep"]}, headers=library_headers)
    assert followed.status_code == 200 and followed.json()["followed"] == ["sleep"]
    muted = client.put("/api/v1/library/preferences", json={"mute": ["food"]}, headers=library_headers)
    assert muted.status_code == 200
    assert muted.json()["muted"] == ["food"] and muted.json()["followed"] == ["sleep"]
    assert client.get("/api/v1/library/feed", headers=library_headers).json()["items"] == []
    cleared = client.put(
        "/api/v1/library/preferences",
        json={"unfollow": ["sleep"], "unmute": ["food"]},
        headers=library_headers,
    )
    assert cleared.status_code == 200
    assert cleared.json()["followed"] == [] and cleared.json()["muted"] == []
    assert BUNDLED_LIBRARY.read_bytes() == bundled_before

    persisted = {}
    with client.app.state.session_factory() as session:
        for name, user in users.items():
            rows = session.query(UserSetting).filter(UserSetting.user_id == user["user_id"]).all()
            persisted[name] = {row.key: json.loads(row.value) for row in rows}
        actor_log = session.get(UserSetting, {"user_id": actor_id, "key": "behavior:action_completions"})
        control_log = session.get(UserSetting, {"user_id": control_id, "key": "behavior:action_completions"})
    assert actor_log is not None and control_log is None
    assert json.loads(actor_log.value)[-1]["action_type"] == "sleep"
    seen = {name: persisted[name].get("behavior:seen_cards") for name in names}
    assert all(seen.values())
    assert len({json.dumps(value, sort_keys=True) for value in seen.values()}) == 5

    report = {
        "clock": "pinned Asia/Shanghai; seven days all at 08:00 starting 2026-11-02; causal pair at 2026-11-04 21:00",
        "not_wall_clock": True,
        "inputs": ONBOARD,
        "days": days,
        "causal": {
            "action": "sleep",
            "control_unchanged": True,
            "actor_sleep_reasons": [card["reason"] for card in sleep_cards],
        },
        "library_http": {"feed_items": [], "production_review_unchanged": True},
        "persistence_keys": {name: sorted(value) for name, value in persisted.items()},
    }
    destination = os.environ.get("SHUNSHI_5X7_OUT")
    if destination:
        Path(destination).write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def test_synthetic_library_fixture_filters_without_touching_reviews():
    """合成排序夹具。这些条目不是资料库，也没有审核人。"""
    bundled_before = BUNDLED_LIBRARY.read_bytes()
    day = CAUSAL_AT.date()

    def entry(entry_id, category):
        return {
            "id": entry_id,
            "title": f"合成夹具 {entry_id}",
            "summary": "仅用于排序过滤，不是已审核资料",
            "category": category,
            "status": "fixture",
            "fixture": True,
            "source": {"title": "合成", "publisher": "fixture", "url": "", "doc_no": ""},
            "display": {"feed_eligible": True, "badges": [], "change_note": None, "last_verified_at": None},
        }

    items = [
        entry("fixture-sleep", "睡眠与情绪"),
        entry("fixture-move", "运动健身"),
    ]
    signal = library_feed.Signals(lang="zh", season="autumn", term="立冬", days_since_term=1)
    plain = library_feed.rank(items, signal, "fixture-user", day, limit=10)
    muted = library_feed.rank(
        items,
        library_feed.Signals(lang="zh", season="autumn", term="立冬", days_since_term=1, muted=frozenset({"sleep"})),
        "fixture-user",
        day,
        limit=10,
    )
    followed = library_feed.rank(
        items,
        library_feed.Signals(lang="zh", season="autumn", term="立冬", days_since_term=1, followed=frozenset({"sleep"})),
        "fixture-user",
        day,
        limit=10,
    )
    assert {item["id"] for item in plain["items"]} == {"fixture-move", "fixture-sleep"}
    assert [item["id"] for item in muted["items"]] == ["fixture-move"]
    assert followed["items"][0]["id"] == "fixture-sleep"
    assert "你关注了「睡眠与情绪」" in followed["items"][0]["reason"]
    assert BUNDLED_LIBRARY.read_bytes() == bundled_before


# ── 对话额度：注册表现值，上海日切，用户之间不共用 ──────────────────────────

def test_chat_quota_uses_configured_tiers_and_isolates_users(chat_redis_url, monkeypatch):
    registry = get_registry()
    limits = {tier: registry["tiers"][tier]["quotas"]["ai_daily_messages"] for tier in ("free", "plus", "pro")}
    assert limits == {"free": 20, "plus": 100, "pro": 200}
    assert tier_for_product("content_yearly") == "plus"
    assert tier_for_product("member_yearly") == "pro"
    assert tier_for_product("does-not-exist") == "free"

    class Clock(datetime):
        # 过期时间必须晚于 Redis 的真实时钟，否则 EXPIREAT 会立刻删掉计数。
        fixed = (datetime.now(SH) + timedelta(days=1)).replace(hour=23, minute=30, second=0, microsecond=0)

        @classmethod
        def now(cls, tz=None):
            return cls.fixed.astimezone(tz) if tz else cls.fixed

    monkeypatch.setattr(chat_quota, "datetime", Clock)

    async def accept_count(user_id, tier):
        accepted = 0
        limit = limits[tier]
        for _ in range(limit + 1):
            try:
                await chat_quota.reserve(chat_redis_url, user_id, tier)
                accepted += 1
            except HTTPException as exc:
                assert exc.status_code == 429
                break
        return accepted

    async def run():
        assert await accept_count("quota-free-a", "free") == limits["free"]
        assert await accept_count("quota-plus", "plus") == limits["plus"]
        await chat_quota.reserve(chat_redis_url, "quota-free-b", "free")
        await chat_quota.reserve(chat_redis_url, "quota-free-b", "free")
        with pytest.raises(HTTPException) as denied:
            await chat_quota.reserve(chat_redis_url, "quota-free-a", "free")
        assert denied.value.status_code == 429
        assert await chat_quota.used_today(chat_redis_url, "quota-free-b") == 2
        Clock.fixed = (Clock.fixed + timedelta(hours=1)).replace(minute=30)
        await chat_quota.reserve(chat_redis_url, "quota-free-a", "free")
        assert await chat_quota.used_today(chat_redis_url, "quota-free-a") == 1

    asyncio.run(run())
