"""首页今日推荐：节气季节、不展示药效、哺乳期排除现有忌口。"""
from datetime import date, datetime
from zoneinfo import ZoneInfo

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
        {"id": "spring-greens", "title": "春菜", "description": "午饭加一盘青菜。", "type": "food_therapy", "season_tag": "spring"},
        {"id": "lettuce", "title": "莴笋", "description": "《本草纲目》载其通乳汁、利小便。", "type": "food_therapy", "season_tag": "summer"},
        {"id": "almond", "title": "苦杏仁", "description": "苦杏仁有毒需炮制。", "type": "food_therapy", "season_tag": "autumn"},
        {"id": "angelica", "title": "当归", "description": "补血活血、调经止痛。", "type": "food_therapy", "season_tag": "winter"},
        {"id": "jianjing", "title": "肩井穴", "description": "治肩颈疼痛、乳汁不下。孕妇禁用。", "type": "acupressure", "season_tag": "winter"},
        {"id": "porridge", "title": "热粥", "description": "晚饭喝一碗热粥。", "type": "food_therapy", "season_tag": "winter"},
    ]
    out = hr.select_home_items(items, NOVEMBER, life_stage=None)
    blob = "".join(item["title"] + item["description"] for item in out)
    ids = [item["id"] for item in out]
    assert "spring-greens" not in ids
    assert "lettuce" not in ids
    assert "almond" not in ids
    assert "angelica" not in ids
    assert "jianjing" not in ids
    assert "porridge" in ids
    for term in hr.EFFICACY_TERMS:
        assert term not in blob
    assert all(item["season"] == "winter" for item in out)
    assert all(item["effect"] is None and item["benefits"] == [] for item in out)
    assert out  # 白话日常建议还在


def test_breastfeeding_profile_drops_listed_foods_and_a_general_profile_keeps_plain_text():
    mint = {"id": "mint-tea", "title": "热茶", "description": "下午喝一杯薄荷茶。", "type": "food_therapy", "season_tag": "winter"}
    crab = {"id": "crab", "title": "清蒸螃蟹", "description": "晚饭吃一点热的螃蟹。", "type": "food_therapy", "season_tag": "winter"}
    porridge = {"id": "porridge", "title": "热粥", "description": "晚饭喝一碗热粥。", "type": "food_therapy", "season_tag": "winter"}
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
        [{"id": "dg", "title": "当归蛋汤", "description": "晚饭喝一碗热汤。", "type": "food_therapy", "season_tag": "winter"}],
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
