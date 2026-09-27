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


def test_domestic_acceptance_week_cannot_be_switched_by_client_language():
    client = _client()
    for query in ("", "?locale=en-US", "?locale=fr-FR"):
        response = client.get("/api/v1/personalization/acceptance-week" + query, headers={"Accept-Language": "en-US"})
        assert response.status_code == 200
        payload = response.json()["data"]
        assert payload["locale"] == "zh-CN"
        assert len(payload["personas"]) == 5
        assert payload["personas"][0]["days"][-1]["hero"]["headline"] == "回顾这一周"
    result = client.get("/api/v1/personalization/dashboard?locale=en-US", headers={"Accept-Language": "en-US"})
    assert result.json()["data"]["hero"]["headline"] == "先认识你"


def test_dashboard_rejects_unknown_persona_and_invalid_day():
    client = _client()
    assert client.get("/api/v1/personalization/dashboard?persona_id=unknown&day=1").status_code == 404
    assert client.get("/api/v1/personalization/dashboard?persona_id=newcomer&day=8").status_code == 422


def test_mobile_personalization_paths_exist(client, auth_headers):
    assert client.get("/api/v1/personalization/life-state").status_code == 200
    assert client.get("/api/v1/personalization/anomaly-alert").status_code == 200
    assert client.get("/api/v1/personalization/weekly-insight").status_code == 200
    assert client.post(
        "/api/v1/personalization/action/complete",
        headers=auth_headers,
        json={"action_type": "breathing", "completed": True, "rating": 4},
    ).status_code == 200
