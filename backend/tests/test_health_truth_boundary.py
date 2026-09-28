import pytest


@pytest.mark.parametrize("payload", [{"steps": 1}, {"sleep_hours": 4}, {"hrv": 10}, {"resting_hr": 100}])
def test_measurements_do_not_generate_diagnoses_or_medicines(client, auth_headers, payload):
    response = client.post("/api/v1/health-data/analyze", headers=auth_headers, json=payload)
    assert response.status_code == 200
    data = response.json()["data"]
    assert data["overall_score"] is None
    assert data["diagnostic"] is False
    assert all(item["score"] is None and item["evidence_status"] == "insufficient_for_diagnosis" for item in data["analyses"])
    assert all(term not in response.text for term in ["重度气虚", "肝气郁结", "阴虚火旺", "柴胡", "酸枣仁", "麦冬"])


@pytest.mark.parametrize("invalid", [{"unit": "kg"}, {"recorded_at": "tomorrow"}, {"value": 1.5}])
def test_invalid_steps_are_not_misinterpreted(client, auth_headers, invalid):
    body = {"data_type": "steps", "value": 5000, "unit": "steps", "recorded_at": "2026-09-28T08:00:00+08:00", "source": "manual", **invalid}
    assert client.post("/api/v1/health-data/sync", headers=auth_headers, json=body).status_code == 422


def test_health_records_are_not_exposed_to_anonymous_or_other_users(client, auth_headers):
    assert client.get("/api/v1/health-data/summary/private-user").status_code == 401
    assert client.get("/api/v1/health-data/summary/private-user", headers=auth_headers).status_code == 403
