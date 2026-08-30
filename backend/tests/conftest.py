import pytest
import uuid
from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app
from app.services.alipay_service import ALIPAY_PRODUCTS, AlipayOrderResult


@pytest.fixture(autouse=True)
def stub_external_alipay_order_creation(monkeypatch):
    """Keep tests deterministic without weakening production payment checks."""

    def _create_order(product_sku: str, user_id: str, return_url=None):
        product = ALIPAY_PRODUCTS[product_sku]
        return AlipayOrderResult(
            order_no=f"APTEST{uuid.uuid4().hex[:16]}",
            pay_url=f"https://openapi.alipay.test/pay/{uuid.uuid4().hex}",
            total_amount=str(product["price"]),
            product_id=product["product_id"],
            mode="sandbox",
        )

    monkeypatch.setattr(
        "app.services.alipay_service.alipay_service.create_order",
        _create_order,
    )


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
    response = client.post("/api/v1/auth/guest-login", json={})
    assert response.status_code == 200
    payload = response.json()
    token = payload.get("access_token") or payload.get("data", {}).get("token")
    assert token, payload
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def test_user(client):
    """Create the email/password user expected by the production auth tests."""
    payload = {
        "email": f"fixture_{uuid.uuid4().hex}@test.com",
        "password": "fixture-pass-123",
        "name": "测试用户",
    }
    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 200, response.text
    return payload


@pytest.fixture()
def test_user_token(client, test_user):
    response = client.post(
        "/api/v1/auth/login",
        json={"email": test_user["email"], "password": test_user["password"]},
    )
    assert response.status_code == 200, response.text
    return response.json()["data"]["token"]
