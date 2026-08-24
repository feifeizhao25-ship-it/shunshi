"""季节/首页模块：dashboard 空态不编造；onboarding/音频进度真实落库；内容 fail-closed。"""


def test_dashboard_requires_auth(client):
    assert client.get("/api/v1/seasons/home/dashboard").status_code == 401


def test_dashboard_empty_state(client, auth_headers):
    response = client.get(
        "/api/v1/seasons/home/dashboard",
        params={"hemisphere": "north"},
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data["greeting"], str) and data["greeting"]
    # 无内容数据源：空态结构，不编造
    assert data["daily_insight"] is None
    assert data["suggestions"] == []
    assert data["hemisphere"] == "north"


def test_onboarding_complete_requires_auth(client):
    assert client.post("/api/v1/seasons/onboarding/complete", json={}).status_code == 401


def test_onboarding_complete_saved(client, auth_headers):
    body = {
        "feeling": "tired",
        "help_goal": "sleep",
        "life_stage": "working",
        "support_time": "evening",
        "style_preference": "gentle",
    }
    response = client.post("/api/v1/seasons/onboarding/complete", json=body, headers=auth_headers)
    assert response.status_code == 200
    assert response.json() == {"saved": True, "profile": body}
    # 真实落库：通过导出可读到同一份档案
    exported = client.post("/api/v1/auth/data/export", headers=auth_headers).json()
    assert exported["settings"]["profile:onboarding"] == body


def test_audio_progress_requires_auth(client):
    body = {"audio_id": "a1", "progress_seconds": 10, "completed": False}
    assert client.post("/api/v1/seasons/audio/progress", json=body).status_code == 401


def test_audio_progress_saved(client, auth_headers):
    body = {"audio_id": "a1", "progress_seconds": 120, "completed": True}
    response = client.post("/api/v1/seasons/audio/progress", json=body, headers=auth_headers)
    assert response.status_code == 200
    assert response.json() == {"saved": True}
    exported = client.post("/api/v1/auth/data/export", headers=auth_headers).json()
    assert exported["audio_progress"] == [
        {"audio_id": "a1", "progress_seconds": 120, "completed": True, "updated_at": exported["audio_progress"][0]["updated_at"]}
    ]


def test_content_endpoints_fail_closed(client, auth_headers):
    """无内容源配置：contents/cms/audio 详情一律 503 configured:false，不编造内容。"""
    for method, path in (
        ("GET", "/api/v1/contents"),
        ("GET", "/api/v1/contents/c1"),
        ("POST", "/api/v1/contents/c1/like"),
        ("GET", "/api/v1/cms/content/c1"),
        ("GET", "/api/v1/seasons/audio/a1"),
    ):
        response = client.request(method, path, headers=auth_headers)
        assert response.status_code == 503, path
        assert response.json()["detail"]["configured"] is False


def test_content_endpoints_require_auth(client):
    assert client.get("/api/v1/contents").status_code == 401
    assert client.get("/api/v1/seasons/audio/a1").status_code == 401
