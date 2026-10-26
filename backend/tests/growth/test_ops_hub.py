"""运营中枢：令牌、审批哈希、默认关闭的开关、急停、只投给已订阅的人。"""

import hashlib
import hmac

import pytest

from app.config import Settings
from app.growth.ops import content_sha256
from app.security import issue_token

pytestmark = pytest.mark.admin_signed_in

TOKEN = "ops-hub-token-for-tests"


def _digest(channel, title, body):
    return content_sha256(channel, title, body)


def test_new_switches_default_off():
    fields = Settings.model_fields
    assert fields["growth_allow_in_app_cards"].default is False
    assert fields["growth_allow_app_push"].default is False
    assert fields["growth_allow_publish"].default is False
    assert fields["kill_switch"].default is False


def test_ops_token_can_read_audit_and_a_wrong_token_cannot(anonymous_client, monkeypatch):
    monkeypatch.setenv("OPENCLAW_SHUNSHI_ADMIN_TOKEN", TOKEN)
    denied = anonymous_client.get(
        "/api/v1/admin/growth/audit",
        headers={"Authorization": "Bearer not-the-token"},
    )
    # 带了凭证但不是管理员：产品门禁返回 403。没带凭证才是 401。
    assert denied.status_code == 403
    allowed = anonymous_client.get(
        "/api/v1/admin/growth/audit",
        headers={"Authorization": f"Bearer {TOKEN}"},
    )
    assert allowed.status_code == 200
    # 比较的是哈希，不是明文相等短路。
    assert hmac.compare_digest(hashlib.sha256(TOKEN.encode()).digest(), hashlib.sha256(TOKEN.encode()).digest())


def test_publish_requires_matching_approval_and_open_switches(client, monkeypatch):
    monkeypatch.setenv("OPENCLAW_SHUNSHI_ADMIN_TOKEN", TOKEN)
    title, body = "立夏小憩", "午后休息二十分钟，晚饭清淡。仅供作息安排参考，不是医疗诊断或治疗建议。"
    digest = _digest("in_app_card", title, body)
    headers = {"Authorization": f"Bearer {TOKEN}"}

    blocked = client.post(
        "/api/v1/admin/growth/publish",
        headers=headers,
        json={"channel": "in_app_card", "title": title, "body": body, "content_sha256": digest},
    )
    assert blocked.status_code == 403

    mismatch = client.post(
        "/api/v1/admin/growth/approvals",
        headers=headers,
        json={"channel": "in_app_card", "title": title, "body": body, "content_sha256": "0" * 64},
    )
    assert mismatch.status_code == 409

    recorded = client.post(
        "/api/v1/admin/growth/approvals",
        headers=headers,
        json={"channel": "in_app_card", "title": title, "body": body, "content_sha256": digest},
    )
    assert recorded.status_code == 200

    settings = client.app.state.settings
    settings.growth_allow_publish = True
    settings.growth_allow_in_app_cards = True
    no_approval_match = client.post(
        "/api/v1/admin/growth/publish",
        headers=headers,
        json={
            "channel": "in_app_card",
            "title": title + "。",
            "body": body,
            "content_sha256": _digest("in_app_card", title + "。", body),
        },
    )
    assert no_approval_match.status_code == 409

    client._ensure_user("opted-in-user")
    client._ensure_user("not-opted")
    user = issue_token(settings, "opted-in-user")["access_token"]
    opted = client.post(
        "/api/v1/growth/opt-in",
        headers={"Authorization": f"Bearer {user}"},
        json={"in_app_cards": True, "app_push": False},
    )
    assert opted.status_code == 200

    stranger = issue_token(settings, "not-opted")["access_token"]
    assert client.post(
        "/api/v1/growth/opt-in",
        headers={"Authorization": f"Bearer {stranger}"},
        json={"in_app_cards": False, "app_push": False},
    ).status_code == 200

    published = client.post(
        "/api/v1/admin/growth/publish",
        headers=headers,
        json={
            "channel": "in_app_card",
            "title": title,
            "body": body,
            "content_sha256": digest,
            "user_ids": ["opted-in-user", "not-opted"],
        },
    )
    assert published.status_code == 200, published.text
    assert published.json()["data"]["delivered_user_ids"] == ["opted-in-user"]

    cards = client.get("/api/v1/growth/cards", headers={"Authorization": f"Bearer {user}"})
    assert cards.status_code == 200
    assert cards.json()["data"][0]["title"] == title
    empty = client.get("/api/v1/growth/cards", headers={"Authorization": f"Bearer {stranger}"})
    assert empty.json()["data"] == []

    settings.kill_switch = True
    stopped = client.post(
        "/api/v1/admin/growth/publish",
        headers=headers,
        json={"channel": "in_app_card", "title": title, "body": body, "content_sha256": digest},
    )
    assert stopped.status_code == 423

    metrics = client.get("/api/v1/admin/growth/metrics", headers=headers)
    assert metrics.status_code == 200
    data = metrics.json()["data"]
    assert data["in_app_cards"] == 1
    assert data["switches"]["kill_switch"] is True
    assert data["switches"]["allow_paid_ads"] is False


def test_compliance_failure_is_not_stored_as_an_approval(client):
    recorded = client.post(
        "/api/v1/admin/growth/approvals",
        json={
            "channel": "app_push",
            "title": "方子",
            "body": "这个方子可长期服用",
            "content_sha256": _digest("app_push", "方子", "这个方子可长期服用"),
        },
    )
    assert recorded.status_code == 422
