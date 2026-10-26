import pytest

from app.growth.models import GrowthReferral, GrowthShare

pytestmark = pytest.mark.signed_in


def test_share_card_survives_in_the_database(client):
    created = client.post(
        "/api/v1/share/card",
        json={"user_id": "test_user", "type": "wellness_plan", "content": "气虚质"},
    )
    assert created.status_code == 200
    share_id = created.json()["data"]["card"]["share_id"]
    session = client.app.state.session_factory()
    row = session.get(GrowthShare, share_id)
    assert row is not None
    assert row.user_id == "test_user"
    session.close()

    fetched = client.get(f"/api/v1/share/card/{share_id}")
    assert fetched.status_code == 200
    session = client.app.state.session_factory()
    assert session.get(GrowthShare, share_id).clicks == 1
    session.close()


def test_invite_is_stored_and_does_not_promise_a_free_membership(client):
    first = client.post("/api/v1/share/invite", json={"user_id": "test_user", "channel": "wechat"})
    assert first.status_code == 200
    data = first.json()["data"]
    assert data["invite_url"].endswith(data["invite_code"])
    assert "7天" not in data["reward_message"]
    assert "记到你的名下" in data["reward_message"]
    again = client.post("/api/v1/share/invite", json={"user_id": "test_user", "channel": "wechat"})
    assert again.json()["data"]["invite_code"] == data["invite_code"]

    session = client.app.state.session_factory()
    row = session.get(GrowthReferral, data["invite_code"])
    assert row.inviter_user_id == "test_user"
    assert row.utm_medium == "invite"
    assert session.query(GrowthReferral).count() == 1
    session.close()
