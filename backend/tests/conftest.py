import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app


@pytest.fixture()
def settings(tmp_path):
    return Settings(
        env="test",
        database_url=f"sqlite:///{tmp_path}/test.db",
        redis_url="",
        jwt_secret="test-secret-that-is-longer-than-32-characters",
        model_router_url="",
        sms_provider_url="",
        sms_provider_token="",
        payment_callback_secret="",
    )


@pytest.fixture()
def client(settings):
    with TestClient(create_app(settings)) as test_client:
        yield test_client


@pytest.fixture()
def auth_headers(client):
    response = client.post("/api/v1/auth/guest-login")
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}
