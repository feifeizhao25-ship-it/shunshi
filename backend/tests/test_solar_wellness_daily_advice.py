"""完整时辰养生表：允许名单、不带药效，孕期和哺乳期按现有禁忌名单过滤。"""
import copy

from app.router.maternity import FORBIDDEN_HERBS_DATA
from app.services import shichen_table as table
from app.services.home_recommend import text_blocked_for_stage

NAMES = ("子时", "丑时", "寅时", "卯时", "辰时", "巳时", "午时", "未时", "申时", "酉时", "戌时", "亥时")
MERIDIANS = ("经络", "经活跃", "当令", "胆经", "肝经", "肺经", "大肠经", "胃经", "脾经", "心经", "小肠经", "膀胱经", "肾经", "心包经", "三焦经", "养百脉")


def _guest(client):
    created = client.post("/api/v1/auth/guest-login", json={}).json()
    token = created.get("access_token") or created["data"]["token"]
    return {"Authorization": f"Bearer {token}"}


def _strings(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for item in value.values():
            yield from _strings(item)
    elif isinstance(value, list):
        for item in value:
            yield from _strings(item)


def _advice(client, headers):
    response = client.get("/api/v1/solar-wellness/daily-advice", headers=headers)
    assert response.status_code == 200, response.text
    return response.json()


def _assert_plain(payload):
    data = payload["data"]
    entries = data["entries"]
    assert [row["name"] for row in entries] == list(NAMES)
    blob = "".join(_strings(entries))
    assert "补充水分" in blob
    assert "养心安神" not in blob
    assert "助眠安神" not in blob
    assert "茶" not in blob
    assert table.visible_text_has_efficacy(blob) is False
    assert table.text_has_dosage(blob) is False
    for term in MERIDIANS:
        assert term not in blob
    for stage in ("孕期", "哺乳期"):
        assert text_blocked_for_stage(blob, stage) is False
    for row in entries:
        assert set(row) == {
            "id", "name", "time_range", "period", "headline", "principle",
            "principle_short", "advice", "quote", "actions",
        }
        assert row["headline"] == f"{row['name']} · {row['principle_short']}"
    assert "morning" not in data and "noon" not in data and "evening" not in data


def test_allowlist_keeps_plain_water_and_blocks_efficacy_words():
    assert table.visible_text_has_efficacy("午后记得小口多喝水，补充水分") is False
    assert table.visible_text_has_efficacy("养心安神") is True
    assert table.visible_text_has_efficacy("助眠安神") is True
    assert table.text_has_dosage("歇一会儿") is False
    assert any(row["name"] == "当归" for row in FORBIDDEN_HERBS_DATA)
    plain = table.select_shichen_entries(None)
    assert len(plain) == 12
    for stage in (None, "上班", "孕期", "哺乳期"):
        rows = table.select_shichen_entries(stage)
        assert [row["name"] for row in rows] == list(NAMES)
        blob = "".join(table.entry_blob(row) for row in rows)
        assert table.text_unsafe(blob) is False
        assert text_blocked_for_stage(blob, "孕期") is False
        assert text_blocked_for_stage(blob, "哺乳期") is False


def test_stage_filter_drops_a_forbidden_food_that_replaces_an_allowlisted_line():
    poisoned = copy.deepcopy(table.SHICHEN_ENTRIES)
    poisoned[0]["advice"] = "晚饭喝当归汤"
    poisoned[1]["advice"] = "下午吃一点薄荷"
    source = tuple(poisoned)
    # 名单被换掉之后，才看得出人生阶段会拿掉不同的句子。
    original = table.SHICHEN_ENTRIES
    table.SHICHEN_ENTRIES = source
    try:
        general = {row["id"] for row in table.select_shichen_entries("上班")}
        pregnant = {row["id"] for row in table.select_shichen_entries("孕期")}
        nursing = {row["id"] for row in table.select_shichen_entries("哺乳期")}
    finally:
        table.SHICHEN_ENTRIES = original
    assert "zi" in general and "chou" in general
    assert "zi" not in pregnant and "chou" not in pregnant
    assert "zi" in nursing and "chou" not in nursing
    assert "wei" in pregnant and "wei" in nursing


def test_daily_advice_requires_a_token_and_returns_the_same_twelve_entries(client):
    anonymous = client.get("/api/v1/solar-wellness/daily-advice")
    assert anonymous.status_code == 401

    headers = _guest(client)
    general = _advice(client, headers)
    assert general["data"]["life_stage"] in (None, "")
    _assert_plain(general)

    saved = client.post("/api/v1/seasons/onboarding/complete", json={"life_stage": "孕期"}, headers=headers)
    assert saved.status_code == 200, saved.text
    pregnant = _advice(client, headers)
    assert pregnant["data"]["life_stage"] == "孕期"
    _assert_plain(pregnant)

    saved = client.post("/api/v1/seasons/onboarding/complete", json={"life_stage": "哺乳期"}, headers=headers)
    assert saved.status_code == 200, saved.text
    nursing = _advice(client, headers)
    assert nursing["data"]["life_stage"] == "哺乳期"
    _assert_plain(nursing)
    assert pregnant["data"]["entries"] == nursing["data"]["entries"] == general["data"]["entries"]
    assert pregnant["data"]["life_stage"] != nursing["data"]["life_stage"]


def test_daily_advice_http_drops_forbidden_foods_for_the_signed_in_stage(client, monkeypatch):
    poisoned = copy.deepcopy(table.SHICHEN_ENTRIES)
    poisoned[0]["advice"] = "晚饭喝当归汤"
    poisoned[1]["advice"] = "下午吃一点薄荷"
    monkeypatch.setattr(table, "SHICHEN_ENTRIES", tuple(poisoned))

    def names_for(stage):
        headers = _guest(client)
        if stage:
            saved = client.post("/api/v1/seasons/onboarding/complete", json={"life_stage": stage}, headers=headers)
            assert saved.status_code == 200, saved.text
        payload = _advice(client, headers)
        rows = payload["data"]["entries"]
        blob = "".join(_strings(rows))
        assert "养心安神" not in blob and "助眠安神" not in blob
        assert "茶" not in blob
        return payload["data"]["life_stage"], [row["id"] for row in rows], blob

    general_stage, general_ids, general_blob = names_for("上班")
    pregnant_stage, pregnant_ids, pregnant_blob = names_for("孕期")
    nursing_stage, nursing_ids, nursing_blob = names_for("哺乳期")
    assert general_stage == "上班" and pregnant_stage == "孕期" and nursing_stage == "哺乳期"
    assert "zi" in general_ids and "chou" in general_ids
    assert "当归" in general_blob and "薄荷" in general_blob
    assert "zi" not in pregnant_ids and "当归" not in pregnant_blob
    assert "chou" not in pregnant_ids and "薄荷" not in pregnant_blob
    assert "zi" in nursing_ids and "当归" in nursing_blob
    assert "chou" not in nursing_ids and "薄荷" not in nursing_blob
    assert "wei" in pregnant_ids and "补充水分" in pregnant_blob
