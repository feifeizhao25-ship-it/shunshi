import pytest

from app.config import Settings
from app.growth.models import GrowthEvent, GrowthReferral
from app.security import issue_token

pytestmark = pytest.mark.admin_signed_in


def test_growth_settings_default_closed():
    fields = Settings.model_fields
    assert fields["growth_arpu_yuan"].default == 600
    assert fields["growth_embedding_provider"].default == "local"
    assert fields["growth_reranker"].default == "local"
    assert fields["growth_embedding_url"].default == ""
    assert fields["growth_reranker_url"].default == ""
    assert fields["growth_allow_publish"].default is False
    assert fields["growth_allow_paid_ads"].default is False


def test_funnel_attributes_signup_and_uses_arpu(client):
    session = client.app.state.session_factory()
    session.add(
        GrowthReferral(
            invite_code="abc12345",
            inviter_user_id="inviter-1",
            channel="wechat",
            utm_source="wechat",
            utm_medium="invite",
            utm_campaign="referral",
        )
    )
    session.commit()
    session.close()

    landing = client.post(
        "/api/v1/growth/events",
        json={"event_type": "landing_view", "anonymous_id": "anon-1", "invite_code": "abc12345"},
    )
    assert landing.status_code == 200

    denied = client.post("/api/v1/growth/events", json={"event_type": "signup", "user_id": "payer-1"})
    assert denied.status_code == 401
    stranger = issue_token(client.app.state.settings, "someone-else")["access_token"]
    mismatch = client.post(
        "/api/v1/growth/events",
        headers={"Authorization": f"Bearer {stranger}"},
        json={"event_type": "signup", "user_id": "payer-1"},
    )
    assert mismatch.status_code == 403

    token = issue_token(client.app.state.settings, "payer-1")["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    signup = client.post(
        "/api/v1/growth/events",
        headers=headers,
        json={"event_type": "signup", "user_id": "payer-1", "invite_code": "abc12345"},
    )
    assert signup.status_code == 200
    assert signup.json()["data"]["inviter_user_id"] == "inviter-1"
    paid = client.post(
        "/api/v1/growth/events",
        headers=headers,
        json={"event_type": "subscription_paid", "user_id": "payer-1", "amount_yuan": 1},
    )
    assert paid.status_code == 200

    funnel = client.get("/api/v1/admin/growth/funnel")
    assert funnel.status_code == 200
    body = funnel.json()["data"]
    assert body["counts"]["landing_view"] == 1
    assert body["counts"]["signup"] == 1
    assert body["counts"]["subscription_paid"] == 1
    assert body["attributed_signups"] == 1
    assert body["arpu_yuan"] == 600
    assert body["projected_revenue_yuan"] == 600

    session = client.app.state.session_factory()
    stored = session.query(GrowthEvent).filter(GrowthEvent.event_type == "subscription_paid").one()
    assert stored.amount_yuan == 1
    session.close()


def test_admin_growth_routes_reject_anonymous(anonymous_client):
    for path in (
        "/api/v1/admin/growth/funnel",
        "/api/v1/admin/growth/queue",
        "/api/v1/admin/growth/audit",
        "/api/v1/admin/growth/skills",
        "/api/v1/admin/growth/sources",
    ):
        assert anonymous_client.get(path).status_code == 401, path


def test_admin_can_read_skill_versions_and_sources(client):
    skills = client.get("/api/v1/admin/growth/skills")
    assert skills.status_code == 200
    versions = {row["name"]: row["version"] for row in skills.json()["data"]}
    assert versions["xhs-note"] == "0.1.0"
    assert versions["zhihu-answer"] == "0.1.0"
    sources = client.get("/api/v1/admin/growth/sources")
    assert sources.status_code == 200
    listed = {row["source_id"]: row for row in sources.json()["data"]}
    assert listed["A01"]["license"] == "internal-summary"
    assert listed["A01"]["status"] == "registered"


def test_confirm_endpoint_does_not_publish(client):
    created = client.post(
        "/api/v1/admin/growth/cycle",
        json={"proposals": [{"skill_name": "zhihu-answer", "channel": "知乎", "topic": "立夏", "angle": "早睡"}]},
    )
    assert created.status_code == 200
    payload = created.json()["data"]
    assert payload["decision"] == "queued"
    draft_id = payload["queued_draft_ids"][0]
    client.app.state.settings.growth_allow_publish = True
    confirmed = client.post(f"/api/v1/admin/growth/queue/{draft_id}/confirm")
    assert confirmed.status_code == 200
    body = confirmed.json()["data"]
    assert body["status"] == "human_confirmed"
    assert body["external_posted"] is False
    assert body["published"] is False
    queue = client.get("/api/v1/admin/growth/queue").json()["data"]
    assert queue[0]["external_posted"] is False
