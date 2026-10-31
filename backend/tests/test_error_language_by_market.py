"""Errors follow the edition: domestic Chinese, international English; never operator details."""
import re

from fastapi.testclient import TestClient

from app.main import create_app

CJK = re.compile(r"[\u3400-\u9fff]")
GLOBAL = {"X-App-Market": "global", "Accept-Language": "en-US"}


def _client(settings):
    return TestClient(create_app(settings), raise_server_exceptions=False)


def test_international_404_405_and_422_are_english(settings):
    with _client(settings) as c:
        r404 = c.get("/api/v1/no-such-thing", headers=GLOBAL)
        assert r404.status_code == 404 and not CJK.search(r404.text)
        assert "couldn't find" in r404.json()["detail"]
        r405 = c.delete("/api/v1/auth/guest-login", headers=GLOBAL)
        assert r405.status_code == 405 and not CJK.search(r405.text)
        r422 = c.post("/api/v1/auth/login", json={}, headers=GLOBAL)
        assert r422.status_code in (400, 401, 404, 422) and not CJK.search(r422.text)


def test_international_error_without_token_is_english(settings):
    with _client(settings) as c:
        r = c.get("/api/v1/chat/history", headers=GLOBAL)
        assert r.status_code in (401, 403, 404) and not CJK.search(r.text)


def test_domestic_errors_stay_chinese(settings):
    with _client(settings) as c:
        r = c.get("/api/v1/no-such-thing")
        assert r.status_code == 404 and CJK.search(r.json()["detail"])


def test_international_operator_text_is_replaced(settings):
    from app import errors

    assert errors._clean_en("Stripe API_KEY missing: SHUNSHI_X_KEY", 500) == errors.SERVER_GENERIC_EN
    assert errors._clean_en("订阅失败", 400) == errors.GENERIC_BY_STATUS_EN[400]
    assert errors._clean_en("Acupoint not found", 404) == "Acupoint not found"
