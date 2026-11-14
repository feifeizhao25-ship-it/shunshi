"""完整时辰养生表：允许名单、不带药效，孕期和哺乳期按现有禁忌名单过滤。"""
import base64
import copy
import json

from fastapi.testclient import TestClient

from app.router.maternity import FORBIDDEN_HERBS_DATA
from app.router.solar_wellness import _hostname_is_cn
from app.services import shichen_table as table
from app.services.home_recommend import text_blocked_for_stage

NAMES = ("子时", "丑时", "寅时", "卯时", "辰时", "巳时", "午时", "未时", "申时", "酉时", "戌时", "亥时")
LEGACY_DAILY_ADVICE = {
    "success": True,
    "data": {
        "morning": "晨起喝一杯温水，舒展筋骨",
        "noon": "午餐后小憩15分钟，养心安神",
        "evening": "晚餐清淡，避免油腻，助眠安神",
        "diet": "宜食当季蔬果，少食生冷",
        "exercise": "推荐八段锦或散步30分钟",
    },
}
MERIDIANS = ("经络", "经活跃", "当令", "胆经", "肝经", "肺经", "大肠经", "胃经", "脾经", "心经", "小肠经", "膀胱经", "肾经", "心包经", "三焦经", "养百脉")


def _guest(client):
    headers, _user_id = _guest_identity(client)
    return headers


def _token_sub(token: str) -> str:
    payload = token.split(".")[1]
    payload += "=" * (-len(payload) % 4)
    return json.loads(base64.urlsafe_b64decode(payload))["sub"]


def _guest_identity(client):
    created = client.post("/api/v1/auth/guest-login", json={}).json()
    token = created.get("access_token") or created["data"]["token"]
    user = (created.get("data") or {}).get("user") or {}
    user_id = user.get("id") or _token_sub(token)
    assert user_id, created
    return {"Authorization": f"Bearer {token}"}, user_id


def _keys(value):
    if isinstance(value, dict):
        for key, item in value.items():
            yield str(key)
            yield from _keys(item)
    elif isinstance(value, list):
        for item in value:
            yield from _keys(item)


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
    assert "life_stage" not in data
    assert data["filtered"] is False


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


def test_daily_advice_anonymous_gets_the_plain_table_and_a_token_does_not_echo_life_stage(client):
    # 测试进程的部署缺省是国内。不带令牌不再下发药效句；locale=en-US 仍是国际版五个字段。
    anonymous = client.get("/api/v1/solar-wellness/daily-advice")
    assert anonymous.status_code == 401, anonymous.text
    assert anonymous.json()["detail"] == "请先登录"
    assert "养心安神" not in anonymous.text and "助眠安神" not in anonymous.text
    localized = client.get("/api/v1/solar-wellness/daily-advice", params={"locale": "en-US"})
    assert localized.status_code == 200, localized.text
    assert localized.json() == LEGACY_DAILY_ADVICE

    headers = _guest(client)
    general = _advice(client, headers)
    _assert_plain(general)

    saved = client.post("/api/v1/seasons/onboarding/complete", json={"life_stage": "孕期"}, headers=headers)
    assert saved.status_code == 200, saved.text
    pregnant = _advice(client, headers)
    _assert_plain(pregnant)
    assert pregnant["data"]["filtered"] is False
    assert "孕期" not in client.get("/api/v1/solar-wellness/daily-advice", headers=headers).text

    saved = client.post("/api/v1/seasons/onboarding/complete", json={"life_stage": "哺乳期"}, headers=headers)
    assert saved.status_code == 200, saved.text
    nursing = _advice(client, headers)
    _assert_plain(nursing)
    assert pregnant["data"]["entries"] == nursing["data"]["entries"] == general["data"]["entries"]
    assert "life_stage" not in pregnant["data"] and "life_stage" not in nursing["data"]


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
        assert "life_stage" not in payload["data"]
        return payload["data"]["filtered"], [row["id"] for row in rows], blob

    general_filtered, general_ids, general_blob = names_for("上班")
    pregnant_filtered, pregnant_ids, pregnant_blob = names_for("孕期")
    nursing_filtered, nursing_ids, nursing_blob = names_for("哺乳期")
    assert general_filtered is False and pregnant_filtered is True and nursing_filtered is True
    assert "zi" in general_ids and "chou" in general_ids
    assert "当归" in general_blob and "薄荷" in general_blob
    assert "zi" not in pregnant_ids and "当归" not in pregnant_blob
    assert "chou" not in pregnant_ids and "薄荷" not in pregnant_blob
    assert "zi" in nursing_ids and "当归" in nursing_blob
    assert "chou" not in nursing_ids and "薄荷" not in nursing_blob
    assert "wei" in pregnant_ids and "补充水分" in pregnant_blob


def test_daily_advice_does_not_reveal_another_users_life_stage(client, monkeypatch):
    poisoned = copy.deepcopy(table.SHICHEN_ENTRIES)
    poisoned[0]["advice"] = "晚饭喝当归汤"
    monkeypatch.setattr(table, "SHICHEN_ENTRIES", tuple(poisoned))

    owner_headers, owner_id = _guest_identity(client)
    saved = client.post("/api/v1/seasons/onboarding/complete", json={"life_stage": "孕期"}, headers=owner_headers)
    assert saved.status_code == 200, saved.text

    stranger_headers, _stranger_id = _guest_identity(client)
    stolen = client.get("/api/v1/solar-wellness/daily-advice", params={"user_id": owner_id}, headers=stranger_headers)
    assert stolen.status_code == 403, stolen.text
    assert "孕期" not in stolen.text
    assert "当归" not in stolen.text
    assert "life_stage" not in stolen.text

    camel = client.get("/api/v1/solar-wellness/daily-advice", params={"userId": owner_id}, headers=stranger_headers)
    assert camel.status_code == 403, camel.text

    anonymous_named = client.get("/api/v1/solar-wellness/daily-advice", params={"user_id": owner_id})
    assert anonymous_named.status_code == 401, anonymous_named.text
    assert "孕期" not in anonymous_named.text
    assert "当归" not in anonymous_named.text

    anonymous = client.get("/api/v1/solar-wellness/daily-advice")
    assert anonymous.status_code == 401, anonymous.text
    assert "孕期" not in anonymous.text
    assert "当归" not in anonymous.text
    assert "养心安神" not in anonymous.text and "助眠安神" not in anonymous.text
    assert "entries" not in anonymous.text

    own = client.get("/api/v1/solar-wellness/daily-advice", params={"user_id": owner_id}, headers=owner_headers)
    assert own.status_code == 200, own.text
    body = own.json()["data"]
    assert body["filtered"] is True
    assert "zi" not in [row["id"] for row in body["entries"]]
    assert "当归" not in own.text
    assert "life_stage" not in body
    assert "孕期" not in own.text

    invalid = client.get("/api/v1/solar-wellness/daily-advice", headers={"Authorization": "Bearer not-a-token"})
    assert invalid.status_code == 401


def _assert_no_efficacy(response):
    assert "养心安神" not in response.text
    assert "助眠安神" not in response.text
    body = response.json()
    data = body.get("data") if isinstance(body, dict) else None
    if isinstance(data, dict):
        assert "morning" not in data and "noon" not in data and "evening" not in data
        assert "diet" not in data and "exercise" not in data


def test_daily_advice_cn_no_token_never_returns_efficacy_wording(client):
    """国内市场、中文请求、国内部署缺省、国内域名：没令牌只返回已有的登录提示。"""
    cases = (
        {"X-App-Market": "cn"},
        {"X-App-Market": "cn", "Accept-Language": "en-US"},
        {"Accept-Language": "zh-CN,zh;q=0.9"},
        {},
    )
    for headers in cases:
        response = client.get("/api/v1/solar-wellness/daily-advice", headers=headers)
        assert response.status_code == 401, response.text
        assert response.json()["detail"] == "请先登录"
        _assert_no_efficacy(response)

    hosted = TestClient(client.app, base_url="http://api.shunshi.example.cn")
    on_cn_host = hosted.get(
        "/api/v1/solar-wellness/daily-advice",
        headers={"X-App-Market": "global", "Accept-Language": "en-US"},
    )
    assert on_cn_host.status_code == 401, on_cn_host.text
    _assert_no_efficacy(on_cn_host)
    forwarded = client.get(
        "/api/v1/solar-wellness/daily-advice",
        headers={"X-Forwarded-Host": "api.shunshi.example.cn", "X-App-Market": "global"},
    )
    assert forwarded.status_code == 401, forwarded.text
    _assert_no_efficacy(forwarded)
    assert _hostname_is_cn("api.shunshi.example.cn") is True
    assert _hostname_is_cn("api.seasonsapp.com") is False
    assert _hostname_is_cn("testserver") is False


def test_daily_advice_cn_with_token_returns_the_plain_table(client):
    headers = {**_guest(client), "X-App-Market": "cn", "Accept-Language": "zh-CN"}
    response = client.get("/api/v1/solar-wellness/daily-advice", headers=headers)
    assert response.status_code == 200, response.text
    _assert_plain(response.json())
    _assert_no_efficacy(response)
    saved = client.post("/api/v1/seasons/onboarding/complete", json={"life_stage": "孕期"}, headers=headers)
    assert saved.status_code == 200, saved.text
    again = client.get("/api/v1/solar-wellness/daily-advice", headers=headers)
    assert again.status_code == 200, again.text
    _assert_plain(again.json())
    assert "孕期" not in again.text
    assert "养心安神" not in again.text and "助眠安神" not in again.text


def test_daily_advice_intl_no_token_keeps_the_legacy_five_fields(client, monkeypatch):
    intl = client.get(
        "/api/v1/solar-wellness/daily-advice",
        headers={"X-App-Market": "global", "Accept-Language": "en-US"},
    )
    assert intl.status_code == 200, intl.text
    assert intl.json() == LEGACY_DAILY_ADVICE

    english = client.get("/api/v1/solar-wellness/daily-advice", headers={"Accept-Language": "en-GB"})
    assert english.status_code == 200, english.text
    assert english.json() == LEGACY_DAILY_ADVICE

    # 市场头优先于中文语言：国际版客户端即使用中文系统语言，也仍是原来的五个字段。
    global_in_chinese = client.get(
        "/api/v1/solar-wellness/daily-advice",
        headers={"X-App-Market": "global", "Accept-Language": "zh-CN"},
    )
    assert global_in_chinese.status_code == 200, global_in_chinese.text
    assert global_in_chinese.json() == LEGACY_DAILY_ADVICE

    monkeypatch.setenv("SHUNSHI_DEFAULT_MARKET", "global")
    deployed = client.get("/api/v1/solar-wellness/daily-advice")
    assert deployed.status_code == 200, deployed.text
    assert deployed.json() == LEGACY_DAILY_ADVICE
    # 国内部署头仍盖过国际部署缺省。
    domestic = client.get("/api/v1/solar-wellness/daily-advice", headers={"X-App-Market": "cn"})
    assert domestic.status_code == 401, domestic.text
    _assert_no_efficacy(domestic)
