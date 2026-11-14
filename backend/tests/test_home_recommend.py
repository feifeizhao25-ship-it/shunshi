"""首页今日推荐：节气季节、不展示药效、哺乳期排除现有忌口。"""
import re
from datetime import date, datetime
from zoneinfo import ZoneInfo

from app.database import db as dbmod
from app.router.contents import _content_row_to_dict
from app.services import home_recommend as hr
from app.services import personal_home as ph
from app.utils.solar_term_calendar import term_on

SH = ZoneInfo("Asia/Shanghai")
NOVEMBER = date(2026, 11, 13)  # 立冬，冬
EARLY_NOVEMBER = date(2026, 11, 3)  # 霜降，秋


def _guest(client):
    created = client.post("/api/v1/auth/guest-login", json={}).json()
    token = created.get("access_token") or created["data"]["token"]
    return {"Authorization": f"Bearer {token}"}


def test_season_follows_beijing_solar_term_not_the_calendar_month():
    assert term_on(NOVEMBER) == "立冬"
    assert hr.season_on(NOVEMBER) == "winter"
    assert hr.season_on(EARLY_NOVEMBER) == "autumn"
    assert hr.season_on(date(2026, 4, 10)) == "spring"
    assert hr.season_on(date(2026, 7, 1)) == "summer"


def test_november_home_drops_other_seasons_efficacy_and_acupoints():
    items = [
        {"id": "spring-greens", "title": "春菜", "description": "午饭加一盘青菜。", "type": "food_therapy", "season_tag": "spring", "home_safe": True},
        {"id": "lettuce", "title": "莴笋", "description": "《本草纲目》载其通乳汁、利小便。", "type": "food_therapy", "season_tag": "summer", "home_safe": True},
        {"id": "almond", "title": "苦杏仁", "description": "苦杏仁有毒需炮制。", "type": "food_therapy", "season_tag": "autumn", "home_safe": True},
        {"id": "angelica", "title": "当归", "description": "补血活血、调经止痛。", "type": "food_therapy", "season_tag": "winter", "home_safe": True},
        {"id": "jianjing", "title": "肩井穴", "description": "治肩颈疼痛、乳汁不下。孕妇禁用。", "type": "acupressure", "season_tag": "winter", "home_safe": True},
        {"id": "porridge", "title": "热粥", "description": "晚饭喝一碗热粥。", "type": "food_therapy", "season_tag": "winter", "home_safe": True},
        {"id": "unmarked-soup", "title": "晚饭加一碗热汤", "description": "晚饭喝一碗热汤，别吃得太晚。", "type": "food_therapy", "season_tag": "winter"},
    ]
    out = hr.select_home_items(items, NOVEMBER, life_stage=None)
    blob = "".join(item["title"] + item["description"] for item in out)
    ids = [item["id"] for item in out]
    assert "spring-greens" not in ids
    assert "lettuce" not in ids
    assert "almond" not in ids
    assert "angelica" not in ids
    assert "jianjing" not in ids
    assert "unmarked-soup" not in ids
    assert "porridge" in ids
    for term in hr.EFFICACY_TERMS:
        assert term not in blob
    assert all(item["season"] == "winter" for item in out)
    assert all(item["effect"] is None and item["benefits"] == [] for item in out)
    assert out  # 白话日常建议还在


def test_breastfeeding_profile_drops_listed_foods_and_a_general_profile_keeps_plain_text():
    mint = {"id": "mint-tea", "title": "热茶", "description": "下午喝一杯薄荷茶。", "type": "food_therapy", "season_tag": "winter", "home_safe": True}
    crab = {"id": "crab", "title": "清蒸螃蟹", "description": "晚饭吃一点热的螃蟹。", "type": "food_therapy", "season_tag": "winter", "home_safe": True}
    porridge = {"id": "porridge", "title": "热粥", "description": "晚饭喝一碗热粥。", "type": "food_therapy", "season_tag": "winter", "home_safe": True}
    nursing = hr.select_home_items([mint, crab, porridge], NOVEMBER, life_stage="哺乳期")
    nursing_ids = [item["id"] for item in nursing]
    assert "mint-tea" not in nursing_ids
    assert "crab" not in nursing_ids
    assert "porridge" in nursing_ids
    blob = "".join(item["title"] + item["description"] for item in nursing)
    assert "薄荷" not in blob and "螃蟹" not in blob

    general = hr.select_home_items([mint, porridge], NOVEMBER, life_stage="上班")
    assert "mint-tea" in [item["id"] for item in general]

    pregnant = hr.select_home_items(
        [{"id": "dg", "title": "当归蛋汤", "description": "晚饭喝一碗热汤。", "type": "food_therapy", "season_tag": "winter", "home_safe": True}],
        NOVEMBER,
        life_stage="孕期",
    )
    assert "dg" not in [item["id"] for item in pregnant]
    # 名单来自现有表，没有被改写。
    from app.router.maternity import FORBIDDEN_HERBS_DATA

    assert any(row["name"] == "当归" for row in FORBIDDEN_HERBS_DATA)
    assert "当归" in hr.exclusion_names(frozenset({"pregnancy"}))


def test_plain_catalog_itself_has_no_efficacy_terms():
    for season, rows in hr.PLAIN_BY_SEASON.items():
        for row in rows:
            blob = row["title"] + row["description"]
            assert not hr._has_efficacy(blob), blob
            assert hr.text_blocked_for_stage(blob, "哺乳期") is False
            assert hr.text_blocked_for_stage(blob, "孕期") is False
            assert season in hr.PLAIN_BY_SEASON


def test_home_cards_use_life_stage_to_drop_a_forbidden_name():
    poisoned = {
        "id": "food_mint",
        "category": "food",
        "zh": "下午喝一杯薄荷茶",
        "en": "Have a cup of mint tea this afternoon.",
        "goals": ("food",),
        "times": ("afternoon",),
        "seasons": (),
        "day": None,
        "cons": (),
        "minutes": 3,
    }
    library = [poisoned, ph.BY_ID["breath_364"], ph.BY_ID["move_walk"], ph.BY_ID["mood_free"]]
    now = datetime(2026, 11, 9, 15, 0, tzinfo=SH)
    original = ph.LIBRARY
    ph.LIBRARY = library
    try:
        nursing = ph.compose(
            ph.Profile(lang="zh", season="autumn", life_stage="哺乳期", goals=frozenset({"food"})),
            ph.Activity(),
            "u",
            now,
            "weekday",
        )
        general = ph.compose(
            ph.Profile(lang="zh", season="autumn", life_stage="上班", goals=frozenset({"food"})),
            ph.Activity(),
            "u",
            now,
            "weekday",
        )
    finally:
        ph.LIBRARY = original
    assert "food_mint" not in [card["id"] for card in nursing["cards"]]
    assert "life_stage" in nursing["personalization"]["used"]
    assert "food_mint" in [card["id"] for card in general["cards"]]
    assert "life_stage" not in general["personalization"]["used"]
    assert "薄荷" not in "".join(card["title"] for card in nursing["cards"])


def test_pregnancy_and_nursing_drop_tea_wording_and_keep_other_plain_cards():
    tip = {
        "id": "caffeine-tip",
        "title": "下午少喝浓的",
        "description": "下午不再喝咖啡和浓茶，晚上更容易入睡",
        "type": "sleep_tip",
        "season_tag": "winter",
        "home_safe": True,
    }
    caffeine = ph.BY_ID["sleep_caffeine"]["zh"]
    sugar = ph.BY_ID["food_sugar"]["zh"]
    assert "茶" in caffeine and "茶" in sugar
    assert hr.text_blocked_for_stage(caffeine, None) is False
    assert hr.text_blocked_for_stage(caffeine, "上班") is False
    now = datetime(2026, 11, 13, 15, 0, tzinfo=SH)
    for stage in ("孕期", "哺乳期"):
        assert hr.text_blocked_for_stage(caffeine, stage) is True
        assert hr.text_blocked_for_stage(ph.BY_ID["sleep_caffeine"]["en"], stage) is True
        assert hr.text_blocked_for_stage(sugar, stage) is True
        picked = hr.select_home_items([tip], NOVEMBER, life_stage=stage)
        ids = [item["id"] for item in picked]
        blob = "".join(item["title"] + item["description"] for item in picked)
        assert "caffeine-tip" not in ids
        assert "茶" not in blob
        assert any("热粥" in item["title"] + item["description"] for item in picked)
        board = ph.compose(
            ph.Profile(lang="zh", season="winter", life_stage=stage, goals=frozenset({"sleep"})),
            ph.Activity(),
            "stage-user",
            now,
            "weekday",
        )
        titles = "".join(card["title"] for card in board["cards"])
        card_ids = [card["id"] for card in board["cards"]]
        assert "sleep_caffeine" not in card_ids
        assert "food_sugar" not in card_ids
        assert "茶" not in titles
        assert card_ids
        assert all(card_id in ph.BY_ID for card_id in card_ids)
    general_items = hr.select_home_items([tip], NOVEMBER, life_stage="上班")
    assert "caffeine-tip" in [item["id"] for item in general_items]
    general = ph.compose(
        ph.Profile(lang="zh", season="winter", life_stage="上班", goals=frozenset({"sleep"})),
        ph.Activity(),
        "stage-user",
        now,
        "weekday",
    )
    assert "sleep_caffeine" in [card["id"] for card in general["cards"]]


def test_streak_and_milestone_use_the_same_day_count():
    from app.services.personal_home import milestone

    for n in (3, 4, 6, 7, 8):
        text = milestone(n, "zh")["text"]
        streak = f"已经连续 {n} 天做小行动，保持这个节奏就好"
        assert str(n) in text
        assert str(n) in streak
        if n != 3:
            assert "连续 3 天了" not in text
        if n > 7:
            assert "连续 7 天，" not in text


def test_http_home_recommend_and_solar_chip_follow_the_injected_day(client):
    headers = _guest(client)
    assert client.post(
        "/api/v1/seasons/onboarding/complete",
        json={"life_stage": "哺乳期"},
        headers=headers,
    ).status_code == 200
    pinned = {**headers, "X-Shunshi-Test-Now": "2026-11-13T08:00:00+08:00"}
    rec = client.get("/api/v1/contents/recommend", params={"limit": 6, "season": "summer"}, headers=pinned)
    assert rec.status_code == 200, rec.text
    data = rec.json()["data"]
    assert data["season"] == "winter"
    blob = "".join(item["title"] + (item.get("description") or "") for item in data["items"])
    for term in ("补血活血", "调经止痛", "通乳", "乳汁", "有毒", "炮制", "孕妇禁用", "穴位", "薄荷", "螃蟹", "当归"):
        assert term not in blob
    assert data["items"]
    assert all(item["season"] == "winter" for item in data["items"])

    early = {**headers, "X-Shunshi-Test-Now": "2026-11-04T21:00:00+08:00"}
    board = client.get("/api/v1/seasons/home/dashboard", headers=early)
    assert board.status_code == 200, board.text
    body = board.json()
    assert body["date"] == "2026-11-04"
    assert body["solar_term"]["name"] == term_on(date(2026, 11, 4))
    titles = " ".join(card["title"] for card in body["suggestions"])
    assert body["solar_term"]["name"] in titles


_SEED_COLS = [
    "id", "title", "description", "type", "category", "tags", "difficulty", "time", "duration",
    "ingredients", "steps", "location", "method", "effect", "benefits", "best_time", "season_tag", "locale",
]
_WINTER_TEA_TITLES = ("姜枣茶", "黑芝麻茶", "枸杞红枣茶", "核桃露")


def _winter_seed_teas() -> list[dict]:
    rows = []
    for raw in dbmod.SEED_CONTENTS:
        item = dict(zip(_SEED_COLS, raw))
        if item["type"] == "tea" and item.get("season_tag") == "winter":
            rows.append(item)
    titles = {row["title"] for row in rows}
    assert set(_WINTER_TEA_TITLES) <= titles
    return rows


class _Rows:
    def __init__(self, rows):
        self._rows = rows

    def fetchall(self):
        return self._rows


class _SeedTeaDb:
    """推荐接口的候选就是这些种子行，不靠 RANDOM() 碰运气。"""

    def __init__(self, rows):
        self.rows = rows

    def execute(self, sql, params=()):
        compact = " ".join(sql.split()).lower()
        if "from follow_ups" in compact:
            return _Rows([])
        if "count(*)" in compact:
            return _Rows([{"type": "tea", "cnt": len(self.rows)}])
        if "from contents" in compact:
            return _Rows(self.rows)
        return _Rows([])


def _recommend(client, headers, monkeypatch, rows):
    monkeypatch.setattr("app.router.contents.get_db", lambda: _SeedTeaDb(rows))
    pinned = {**headers, "X-Shunshi-Test-Now": "2026-11-13T08:00:00+08:00"}
    response = client.get("/api/v1/contents/recommend", params={"limit": 6, "season": "summer"}, headers=pinned)
    assert response.status_code == 200, response.text
    return response.json()["data"]


def test_recommend_endpoint_drops_seed_teas_and_keeps_plain_porridge_for_each_stage(client, monkeypatch):
    teas = _winter_seed_teas()
    raw = "".join(row["title"] + (row["description"] or "") + str(row.get("ingredients") or "") for row in teas)
    for term in ("补中益气", "滋补肝肾", "补肾固精", "润肠通便", "风寒感冒初期尤宜"):
        assert term in raw
    assert re.search(r"\d+\s*g", raw, re.IGNORECASE)

    rows = list(teas)
    rows.append({
        "id": "unmarked-soup",
        "title": "晚饭加一碗热汤",
        "description": "晚饭喝一碗热汤，别吃得太晚。",
        "type": "food_therapy",
        "category": "饮食",
        "tags": "[]",
        "season_tag": "winter",
        "locale": "zh-CN",
        "ingredients": "[]",
        "benefits": "[]",
        "steps": "[]",
    })
    rows.append({
        "id": "marked-soup",
        "title": "午饭喝一碗热汤",
        "description": "午饭喝一碗热汤，配一点青菜。",
        "type": "food_therapy",
        "category": "饮食",
        "tags": '["home_safe"]',
        "season_tag": "winter",
        "locale": "zh-CN",
        "ingredients": "[]",
        "benefits": "[]",
        "steps": "[]",
    })
    rows.append({
        "id": "dg-soup",
        "title": "当归蛋汤",
        "description": "晚饭喝一碗热汤。",
        "type": "food_therapy",
        "category": "饮食",
        "tags": '["home_safe"]',
        "season_tag": "winter",
        "locale": "zh-CN",
        "ingredients": "[]",
        "benefits": "[]",
        "steps": "[]",
    })
    rows.append({
        "id": "mint-soup",
        "title": "热茶",
        "description": "下午喝一杯薄荷茶。",
        "type": "food_therapy",
        "category": "饮食",
        "tags": '["home_safe"]',
        "season_tag": "winter",
        "locale": "zh-CN",
        "ingredients": "[]",
        "benefits": "[]",
        "steps": "[]",
    })

    parsed = [_content_row_to_dict(row) for row in rows]
    direct = hr.select_home_items(parsed, NOVEMBER, life_stage=None)
    direct_blob = "".join(item["title"] + item["description"] for item in direct)
    direct_ids = [item["id"] for item in direct]
    for title in _WINTER_TEA_TITLES:
        assert title not in direct_blob
    assert "unmarked-soup" not in direct_ids
    assert "marked-soup" in direct_ids
    assert any("热粥" in item["title"] + item["description"] for item in direct)

    stages = {None: None, "上班": "上班", "孕期": "孕期", "哺乳期": "哺乳期"}
    for label, life_stage in stages.items():
        headers = _guest(client)
        if life_stage:
            saved = client.post("/api/v1/seasons/onboarding/complete", json={"life_stage": life_stage}, headers=headers)
            assert saved.status_code == 200, saved.text
        data = _recommend(client, headers, monkeypatch, rows)
        blob = "".join(item["title"] + (item.get("description") or "") for item in data["items"])
        ids = [item["id"] for item in data["items"]]
        assert data["season"] == "winter"
        for title in _WINTER_TEA_TITLES:
            assert title not in blob
        for term in ("补中益气", "滋补肝肾", "补肾固精", "润肠通便", "感冒", "尤宜", "引火归元", "滋养气血", "运化", "清心导浊"):
            assert term not in blob
        assert re.search(r"\d+\s*(?:g|mg|ml|克|片|颗)", blob, re.IGNORECASE) is None
        assert "unmarked-soup" not in ids
        assert any("热粥" in item["title"] + item["description"] for item in data["items"])
        if life_stage == "孕期":
            assert "dg-soup" not in ids
            assert "当归" not in blob
            assert "marked-soup" in ids
        if life_stage == "哺乳期":
            assert "mint-soup" not in ids
            assert "薄荷" not in blob
            assert "marked-soup" in ids
        if label in (None, "上班"):
            assert "mint-soup" in ids
            assert "marked-soup" in ids
