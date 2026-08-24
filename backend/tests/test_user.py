"""用户模块：JWT 签发/校验流程，密钥未配置时 fail-closed。"""

from fastapi.testclient import TestClient

from app.main import create_app


def test_jwt_fail_closed_when_secret_missing(settings):
    settings.jwt_secret = ""
    with TestClient(create_app(settings)) as client:
        response = client.post("/api/v1/auth/guest-login")
    assert response.status_code == 503
    assert response.json()["detail"]["configured"] is False


def test_guest_login_and_authenticated_access(client, auth_headers):
    response = client.get("/api/v1/settings/memory", headers=auth_headers)
    assert response.status_code == 200


def test_protected_endpoint_rejects_anonymous(client):
    assert client.get("/api/v1/settings/memory").status_code == 401
    assert client.get("/api/v1/settings/memory", headers={"Authorization": "Bearer bad"}).status_code == 401


def test_register_login_password_flow(client):
    body = {"phone": "13800138000", "password": "passw0rd-strong"}
    register = client.post("/api/v1/auth/register", json=body)
    assert register.status_code == 200
    assert register.json()["access_token"]
    assert client.post("/api/v1/auth/register", json=body).status_code == 409

    login = client.post("/api/v1/auth/login", json=body)
    assert login.status_code == 200
    token = login.json()["access_token"]
    assert client.get(
        "/api/v1/settings/memory", headers={"Authorization": f"Bearer {token}"}
    ).status_code == 200

    wrong = client.post("/api/v1/auth/login", json={**body, "password": "wrong-password"})
    assert wrong.status_code == 401


def test_sms_endpoints_fail_closed_when_provider_unconfigured(client):
    send = client.post("/api/v1/auth/sms/send", json={"phone": "13800138000"})
    assert send.status_code == 503
    assert send.json()["detail"]["configured"] is False
    verify = client.post("/api/v1/auth/sms/verify", json={"phone": "13800138000", "code": "123456"})
    assert verify.status_code == 503
