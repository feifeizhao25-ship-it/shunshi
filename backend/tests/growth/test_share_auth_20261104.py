"""/share/card, /share/invite, /share/stats: identity comes from the login token only."""
import pytest

from app.growth.models import GrowthReferral, GrowthShare
from app.security import verify_token


def _login(client):
    """A real (guest) account: returns (user_id, headers)."""
    r = client.post("/api/v1/auth/guest-login", json={})
    assert r.status_code == 200
    body = r.json()
    token = body.get("access_token") or body.get("data", {}).get("token")
    return verify_token(client.app.state.settings, token), {"Authorization": f"Bearer {token}"}


CARD = {"type": "insight", "content": "c1"}


@pytest.fixture()
def anon(client):
    return client


def test_unauthenticated_requests_are_401(anon):
    assert anon.post("/api/v1/share/card", json={**CARD, "user_id": "victim"}).status_code == 401
    assert anon.post("/api/v1/share/card", json=CARD).status_code == 401
    assert anon.post("/api/v1/share/invite", json={"user_id": "victim", "channel": "wechat"}).status_code == 401
    assert anon.post("/api/v1/share/invite", json={"channel": "wechat"}).status_code == 401
    assert anon.get("/api/v1/share/stats/victim").status_code == 401


def test_body_user_id_of_someone_else_is_403_and_creates_nothing(anon):
    _, h = _login(anon)
    assert anon.post("/api/v1/share/card", json={**CARD, "user_id": "victim"}, headers=h).status_code == 403
    assert anon.post("/api/v1/share/invite", json={"user_id": "victim", "channel": "wechat"}, headers=h).status_code == 403
    assert anon.get("/api/v1/share/stats/victim", headers=h).status_code == 403
    session = anon.app.state.session_factory()
    try:
        assert session.query(GrowthShare).filter(GrowthShare.user_id == "victim").count() == 0
        assert session.query(GrowthReferral).filter(GrowthReferral.inviter_user_id == "victim").count() == 0
    finally:
        session.close()


def test_normal_path_and_legacy_body_still_work(anon):
    alice, h = _login(anon)
    # new clients send no user_id
    r = anon.post("/api/v1/share/invite", json={"channel": "wechat"}, headers=h)
    assert r.status_code == 200
    code = r.json()["data"]["invite_code"]
    # legacy clients send their own user_id: same result
    legacy = anon.post("/api/v1/share/invite", json={"user_id": alice, "channel": "wechat"}, headers=h)
    assert legacy.status_code == 200 and legacy.json()["data"]["invite_code"] == code
    session = anon.app.state.session_factory()
    try:
        assert session.get(GrowthReferral, code).inviter_user_id == alice
    finally:
        session.close()
    card = anon.post("/api/v1/share/card", json={**CARD, "user_id": alice}, headers=h)
    assert card.status_code == 200
    assert anon.post("/api/v1/share/card", json=CARD, headers=h).json()["data"]["card"]["share_id"] == card.json()["data"]["card"]["share_id"]
    stats = anon.get(f"/api/v1/share/stats/{alice}", headers=h)
    assert stats.status_code == 200 and stats.json()["data"]["total_shares"] == 1


def test_public_card_page_hides_owner_and_clicks_from_strangers(anon):
    alice, owner = _login(anon)
    sid = anon.post("/api/v1/share/card", json=CARD, headers=owner).json()["data"]["card"]["share_id"]
    stranger = anon.get(f"/api/v1/share/card/{sid}")
    assert stranger.status_code == 200
    assert "user_id" not in stranger.json()["data"] and "clicks" not in stranger.json()["data"]
    other = anon.get(f"/api/v1/share/card/{sid}", headers=_login(anon)[1])
    assert "user_id" not in other.json()["data"]
    bad = anon.get(f"/api/v1/share/card/{sid}", headers={"Authorization": "Bearer not-a-token"})
    assert bad.status_code == 200 and "user_id" not in bad.json()["data"]
    mine = anon.get(f"/api/v1/share/card/{sid}", headers=owner).json()["data"]
    assert mine["user_id"] == alice and mine["clicks"] == 4


@pytest.mark.parametrize(
    "card_type,content,message",
    [
        ("solar_term", "立冬", "立冬进补，早睡晚起，注意保暖。"),
        ("constitution", "气虚质", "气虚质，主要倾向：气虚 72、阳虚 55"),
    ],
)
def test_solar_term_and_constitution_cards_use_the_same_authenticated_endpoint(anon, card_type, content, message):
    assert anon.post("/api/v1/share/card", json={"type": card_type, "content": content}).status_code == 401
    uid, h = _login(anon)
    r = anon.post("/api/v1/share/card", json={"type": card_type, "content": content, "custom_message": message, "platform": "wechat"}, headers=h)
    assert r.status_code == 200
    card = r.json()["data"]["card"]
    assert message in card["text"] and "顺时" in card["text"]
    assert "%" in card["image_url"] and content not in card["image_url"]  # non-ASCII id is URL-quoted
    session = anon.app.state.session_factory()
    try:
        row = session.get(GrowthShare, card["share_id"])
        assert row.user_id == uid and row.content_type == card_type
    finally:
        session.close()
    assert anon.post("/api/v1/share/card", json={"type": card_type, "content": content, "user_id": "someone-else"}, headers=h).status_code == 403


def test_new_card_types_keep_the_claims_scan(anon, monkeypatch):
    monkeypatch.setenv("SHARECARD_ENABLED", "1")
    _, h = _login(anon)
    bad = anon.post("/api/v1/share/card", json={"type": "solar_term", "content": "立冬", "custom_message": "喝这个汤可以根治失眠"}, headers=h)
    assert bad.status_code == 422
    ok = anon.post("/api/v1/share/card", json={"type": "solar_term", "content": "立冬", "custom_message": "立冬早睡晚起"}, headers=h)
    assert ok.status_code == 200
