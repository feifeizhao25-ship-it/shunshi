"""Growth kit wired in behind OFF flags: HMAC invite codes (REFERRAL_ENABLED) and the claims scan on share-card copy (SHARECARD_ENABLED)."""
import re

import pytest

from app.growth.referral_store import invite_code_for

pytestmark = pytest.mark.signed_in

LEGACY = re.compile(r"^[0-9a-f]{8}$")


def test_flags_off_keeps_the_legacy_invite_code(monkeypatch):
    monkeypatch.delenv("REFERRAL_ENABLED", raising=False)
    monkeypatch.setenv("REFERRAL_HMAC_SECRET", "unit-test-only")
    assert LEGACY.match(invite_code_for("u1", "wechat"))


def test_flag_on_without_secret_keeps_the_legacy_code(monkeypatch):
    monkeypatch.setenv("REFERRAL_ENABLED", "1")
    monkeypatch.delenv("REFERRAL_HMAC_SECRET", raising=False)
    assert LEGACY.match(invite_code_for("u1", "wechat"))


def test_flag_and_secret_give_an_hmac_code_that_is_stable_and_not_derivable(monkeypatch):
    monkeypatch.setenv("REFERRAL_ENABLED", "1")
    monkeypatch.setenv("REFERRAL_HMAC_SECRET", "unit-test-only")
    a = invite_code_for("u1", "wechat")
    assert a == invite_code_for("u1", "wechat") and len(a) == 8 and not LEGACY.match(a)
    assert a != invite_code_for("u1", "weibo") and a != invite_code_for("u2", "wechat")
    monkeypatch.setenv("REFERRAL_HMAC_SECRET", "another-secret")
    assert invite_code_for("u1", "wechat") != a  # depends on the server secret


def test_invite_endpoint_uses_the_hmac_code_when_enabled(client, monkeypatch):
    monkeypatch.setenv("REFERRAL_ENABLED", "1")
    monkeypatch.setenv("REFERRAL_HMAC_SECRET", "unit-test-only")
    r = client.post("/api/v1/share/invite", json={"user_id": "test_user", "channel": "wechat"})
    assert r.status_code == 200
    code = r.json()["data"]["invite_code"]
    assert not LEGACY.match(code) and r.json()["data"]["invite_url"].endswith(code)


def _card(client, text):
    return client.post("/api/v1/share/card", json={"user_id": "test_user", "type": "insight", "content": "x1", "custom_message": text})


def test_sharecard_flag_off_does_not_scan(client, monkeypatch):
    monkeypatch.delenv("SHARECARD_ENABLED", raising=False)
    assert _card(client, "这个方法可以根治失眠").status_code == 200


@pytest.mark.parametrize("text", ["这个方法可以根治失眠", "保证收益，稳赚", "全网第一的养生工具", "好评返现"])
def test_sharecard_flag_on_holds_forbidden_claims(client, monkeypatch, text):
    monkeypatch.setenv("SHARECARD_ENABLED", "1")
    r = _card(client, text)
    assert r.status_code == 422 and "修改" in r.json()["detail"]


def test_sharecard_flag_on_allows_normal_copy(client, monkeypatch):
    monkeypatch.setenv("SHARECARD_ENABLED", "1")
    assert _card(client, "今天按节气吃了一碗热粥，感觉不错").status_code == 200
