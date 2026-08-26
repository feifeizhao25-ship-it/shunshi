from app.main import create_app
from app.config import Settings
from fastapi.testclient import TestClient


def _client() -> TestClient:
    return TestClient(create_app(Settings(env="testing")))


def test_cn_acceptance_week_has_five_personas_and_seven_evolving_days():
    response = _client().get("/api/v1/personalization/acceptance-week", headers={"Accept-Language": "zh-CN"})
    assert response.status_code == 200
    payload = response.json()["data"]
    assert payload["locale"] == "zh-CN"
    assert payload["demo_mode"] is True
    assert len(payload["personas"]) == 5
    for persona in payload["personas"]:
        assert len(persona["days"]) == 7
        assert len({day["hero"]["headline"] for day in persona["days"]}) == 7
        assert all(day["evidence_status"] == "demo_disclosed" for day in persona["days"])


def test_global_acceptance_week_is_english_only_and_market_native():
    response = _client().get("/api/v1/personalization/acceptance-week", headers={"Accept-Language": "en-US"})
    assert response.status_code == 200
    payload = response.json()["data"]
    assert payload["locale"] == "en-US"
    assert len(payload["personas"]) == 5
    serialized = str(payload)
    assert not any("\u4e00" <= char <= "\u9fff" for char in serialized)
    assert payload["personas"][0]["days"][-1]["stage"] == "weekly_review"


def test_dashboard_rejects_unknown_persona_and_invalid_day():
    client = _client()
    assert client.get("/api/v1/personalization/dashboard?persona_id=unknown&day=1").status_code == 404
    assert client.get("/api/v1/personalization/dashboard?persona_id=newcomer&day=8").status_code == 422


def test_mobile_personalization_paths_exist():
    client = _client()
    assert client.get("/api/v1/personalization/life-state").status_code == 200
    assert client.get("/api/v1/personalization/anomaly-alert").status_code == 200
    assert client.get("/api/v1/personalization/weekly-insight").status_code == 200
    assert client.post(
        "/api/v1/personalization/action/complete",
        json={"action_type": "breathing", "completed": True, "rating": 4},
    ).status_code == 200
