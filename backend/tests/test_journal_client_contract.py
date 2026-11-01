"""顺时 日记保存：四个 App 发的请求体必须被后端接受（后端是准绳）。

App 端 `journalEntryBody()`（lib/data/network/journal_payload.dart）发出的字段就是下面的 CLIENT_BODY；
以前 App 发 `mood: '平和'`（字符串）+ `note`、没有 energy / sleep_quality，后端 422，日记存不下来。
App 端对应的 Dart 测试：test/diary_save_contract_test.dart。
"""
import pytest


@pytest.fixture()
def me(client, auth_headers, settings):
    from app.security import verify_token
    client.headers.update(auth_headers)
    return verify_token(settings, auth_headers["Authorization"].removeprefix("Bearer "))


def _client_body(user_id):
    # 与 journalEntryBody(moodLabel: '平和', energy: 3, sleepQuality: 4, notes: ..., tags: [...]) 逐字段一致（不带 date）
    return {
        "user_id": user_id,
        "mood": 4,
        "energy": 3,
        "sleep_quality": 4,
        "notes": "今天睡得不错",
        "tags": ["平和", "喝茶"],
    }


def test_app_payload_is_saved_and_read_back(client, me):
    r = client.post("/api/v1/journal/entry", json=_client_body(me))
    assert r.status_code == 200, r.text
    saved = r.json()["data"]
    assert (saved["mood"], saved["energy"], saved["sleep_quality"]) == (4, 3, 4)

    got = client.get(f"/api/v1/journal/entries/{me}").json()["data"]["entries"]
    assert len(got) == 1
    e = got[0]
    # App 列表读取用到的字段：整数心情分、date、notes、tags（心情原词放在 tags 里）
    assert e["mood"] == 4 and e["notes"] == "今天睡得不错" and e["tags"][0] == "平和"
    assert len(e["date"]) == 10


def test_legacy_app_payload_was_rejected(client, me):
    legacy = {"user_id": me, "mood": "平和", "sleep_time": "22:45", "wake_time": "07:00", "note": "x",
              "rituals": {"tea": True, "meditation": False, "exercise": False}}
    r = client.post("/api/v1/journal/entry", json=legacy)
    assert r.status_code == 422
    missing = {tuple(err["loc"])[-1] for err in r.json()["detail"]}
    assert {"mood", "energy", "sleep_quality"} <= missing


@pytest.mark.parametrize("field", ["mood", "energy", "sleep_quality"])
@pytest.mark.parametrize("value", [0, 6])
def test_scores_must_be_1_to_5(client, me, field, value):
    body = _client_body(me)
    body[field] = value
    assert client.post("/api/v1/journal/entry", json=body).status_code == 422
