"""自有网站发布接收口 POST /api/v1/growth/publish/website。

四项都满足才接收：批准单哈希对得上、上海时间 08:00–21:30、有人工智能生成标识、写进只追加的审计。
开关默认关；只认专用令牌 OPENCLAW_SHUNSHI_PUBLISH_TOKEN。每个拒绝原因、时间窗两端、哈希不符、
缺标识、审计只追加、开关关、令牌各种情况都有用例。全部离线，不发任何外部请求。
"""

from __future__ import annotations

import hashlib
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

import pytest

from app.config import Settings
from app.growth import website_receiver as wr
from app.growth.models import GrowthAuditLog, GrowthWebsiteSubmission

SH = ZoneInfo("Asia/Shanghai")
PATH = "/api/v1/growth/publish/website"
TOKEN = "publish-receiver-token-for-tests-0001"
HUB_ADMIN = "ops-hub-admin-token-for-tests-0002"
NOON = datetime(2026, 11, 19, 12, 0, tzinfo=SH)


def hub_content_sha256(payload) -> str:
    """运营中枢 ops/airui_ops/content.py 里 content_sha256 的原样副本，用来证明两边算法一致。"""
    raw = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def make_content(body: str | None = None) -> dict:
    if body is None:
        body = "小雪是二十四节气里的第二十个。\n\n本内容由人工智能生成。\n仅供作息安排参考，不是医疗诊断或治疗建议。"
    return {
        "product": "shunshi",
        "channel": "website_seo",
        "title": "小雪：名字的来历",
        "body": body,
        "url": "https://preview.invalid/website_seo",
    }


def hub_request(content: dict, approval: dict | None | str = "auto") -> dict:
    """运营中枢 Publisher._deliver 的请求体，外加 approval（见文档：运营中枢要补这一段）。"""
    payload = {"content": content, "stub": False, "note": ""}
    if approval == "auto":
        approval = {"id": "ap_test0001", "status": "approved", "content_sha256": hub_content_sha256(content),
                    "channel": "template_card", "detail_checked": False}
    if approval is not None:
        payload["approval"] = approval
    return payload


def auth(token: str = TOKEN) -> dict:
    return {"Authorization": f"Bearer {token}", "X-Airui-Contract": "live"}


@pytest.fixture()
def on(anonymous_client, monkeypatch):
    """开关打开、令牌已配、时间固定在上海中午。"""
    anonymous_client.app.state.settings.growth_publish_receiver_enabled = True
    monkeypatch.setenv(wr.TOKEN_ENV, TOKEN)
    monkeypatch.setenv("OPENCLAW_SHUNSHI_ADMIN_TOKEN", HUB_ADMIN)
    monkeypatch.setattr(wr, "now_utc", lambda: NOON.astimezone(timezone.utc))
    return anonymous_client


def rows(client, model):
    session = client.app.state.session_factory()
    try:
        return session.query(model).all()
    finally:
        session.close()


def audits(client):
    return [r for r in rows(client, GrowthAuditLog) if r.action == "website_receive"]


# ---------- 开关

def test_switch_defaults_off_and_reads_env_name(monkeypatch):
    assert Settings.model_fields["growth_publish_receiver_enabled"].default is False
    monkeypatch.setenv("SHUNSHI_GROWTH_PUBLISH_RECEIVER_ENABLED", "true")
    assert Settings(jwt_secret="x" * 40).growth_publish_receiver_enabled is True


def test_switch_off_means_disabled_even_with_valid_token(anonymous_client, monkeypatch):
    monkeypatch.setenv(wr.TOKEN_ENV, TOKEN)
    res = anonymous_client.post(PATH, json=hub_request(make_content()), headers=auth())
    assert res.status_code == 503
    assert res.json()["reason"] == "disabled"
    assert rows(anonymous_client, GrowthWebsiteSubmission) == []
    assert audits(anonymous_client) == []


# ---------- 令牌

def test_token_not_configured(on, monkeypatch):
    monkeypatch.delenv(wr.TOKEN_ENV)
    res = on.post(PATH, json=hub_request(make_content()), headers=auth())
    assert (res.status_code, res.json()["reason"]) == (503, "token_not_configured")


@pytest.mark.parametrize("other", list(wr.FORBIDDEN_REUSE_ENVS))
def test_token_equal_to_another_secret_counts_as_not_configured(on, monkeypatch, other):
    monkeypatch.setenv(other, TOKEN)
    res = on.post(PATH, json=hub_request(make_content()), headers=auth())
    assert (res.status_code, res.json()["reason"]) == (503, "token_not_configured")


@pytest.mark.parametrize(
    "headers",
    [
        {},
        {"Authorization": "Bearer wrong-token"},
        {"Authorization": f"Basic {TOKEN}"},
        {"Authorization": TOKEN},
        {"Authorization": f"Bearer {HUB_ADMIN}"},  # 运营中枢现在发的是后台令牌：这里不认
        {"X-Admin-Token": TOKEN},
    ],
)
def test_bad_or_missing_token_is_401_and_not_audited(on, headers):
    res = on.post(PATH, json=hub_request(make_content()), headers=headers)
    assert (res.status_code, res.json()["reason"]) == (401, "unauthorized")
    assert rows(on, GrowthWebsiteSubmission) == []
    assert audits(on) == []


def test_admin_login_session_does_not_open_receiver(admin_client, monkeypatch):
    admin_client.app.state.settings.growth_publish_receiver_enabled = True
    monkeypatch.setenv(wr.TOKEN_ENV, TOKEN)
    res = admin_client.post(PATH, json=hub_request(make_content()))
    assert res.status_code == 401


def test_publish_token_does_not_open_admin_routes(on):
    res = on.get("/api/v1/admin/growth/audit", headers=auth())
    assert res.status_code == 403


# ---------- 接收成功

def test_accepts_when_all_four_hold_and_only_stores(on):
    content = make_content()
    res = on.post(PATH, json=hub_request(content), headers=auth())
    assert res.status_code == 201, res.text
    data = res.json()
    assert data["accepted"] is True and data["stored"] is True and data["published"] is False
    assert data["content_sha256"] == hub_content_sha256(content) == wr.content_sha256(content)
    saved = rows(on, GrowthWebsiteSubmission)
    assert [(r.id, r.status, r.approval_id, r.title) for r in saved] == [(data["id"], "received", "ap_test0001", content["title"])]
    trail = audits(on)
    assert [(a.decision, a.object_key, a.actor) for a in trail] == [("accept", data["id"], "ops_hub")]
    assert json.loads(trail[0].detail_json)["content_sha256"] == data["content_sha256"]
    assert res.headers["cache-control"] == "no-store"


def test_duplicate_push_is_not_overwritten(on):
    content = make_content()
    first = on.post(PATH, json=hub_request(content), headers=auth()).json()
    again = on.post(PATH, json=hub_request(content), headers=auth())
    assert again.status_code == 200
    assert again.json()["duplicate"] is True and again.json()["id"] == first["id"]
    assert len(rows(on, GrowthWebsiteSubmission)) == 1
    assert [a.decision for a in audits(on)] == ["accept", "duplicate"]


# ---------- 时间窗（上海时间，含两端整分）

@pytest.mark.parametrize(
    ("local", "ok"),
    [
        ((7, 59, 59), False),
        ((8, 0, 0), True),
        ((8, 0, 30), True),
        ((21, 30, 0), True),
        ((21, 30, 59), True),
        ((21, 31, 0), False),
        ((0, 0, 0), False),
        ((23, 59, 0), False),
    ],
)
def test_window_boundaries_shanghai(on, monkeypatch, local, ok):
    h, m, s = local
    moment = datetime(2026, 11, 19, h, m, s, tzinfo=SH)
    monkeypatch.setattr(wr, "now_utc", lambda: moment.astimezone(timezone.utc))
    res = on.post(PATH, json=hub_request(make_content()), headers=auth())
    if ok:
        assert res.status_code == 201, res.text
    else:
        assert (res.status_code, res.json()["reason"]) == (403, "outside_window")
        assert rows(on, GrowthWebsiteSubmission) == []


def test_window_uses_shanghai_not_server_utc():
    # 00:00 UTC 是上海 08:00；13:31 UTC 是上海 21:31
    assert wr.in_window(datetime(2026, 11, 19, 0, 0, tzinfo=timezone.utc)) is True
    assert wr.in_window(datetime(2026, 11, 18, 23, 59, tzinfo=timezone.utc)) is False
    assert wr.in_window(datetime(2026, 11, 19, 13, 30, tzinfo=timezone.utc)) is True
    assert wr.in_window(datetime(2026, 11, 19, 13, 31, tzinfo=timezone.utc)) is False
    # 别的时区传进来也按上海算：纽约 08:30（UTC-5）= 上海 21:30，08:31 = 21:31
    assert wr.in_window(datetime(2026, 11, 19, 8, 30, tzinfo=timezone(timedelta(hours=-5)))) is True
    assert wr.in_window(datetime(2026, 11, 19, 8, 31, tzinfo=timezone(timedelta(hours=-5)))) is False


# ---------- 批准单

def test_current_hub_body_without_approval_is_rejected(on):
    res = on.post(PATH, json=hub_request(make_content(), approval=None), headers=auth())
    assert (res.status_code, res.json()["reason"]) == (409, "approval_missing")


def test_sha_mismatch_when_content_changed_after_approval(on):
    content = make_content()
    payload = hub_request(content)
    payload["content"] = {**content, "title": "改过的标题"}
    res = on.post(PATH, json=payload, headers=auth())
    assert (res.status_code, res.json()["reason"]) == (409, "sha_mismatch")
    assert rows(on, GrowthWebsiteSubmission) == []


def test_sha_mismatch_with_wrong_hash(on):
    approval = {"id": "ap_x", "status": "approved", "content_sha256": "0" * 64}
    res = on.post(PATH, json=hub_request(make_content(), approval), headers=auth())
    assert res.json()["reason"] == "sha_mismatch"


@pytest.mark.parametrize("status", ["pending", "rejected", "timeout", "invalidated", ""])
def test_approval_not_approved(on, status):
    content = make_content()
    approval = {"id": "ap_x", "status": status, "content_sha256": hub_content_sha256(content)}
    res = on.post(PATH, json=hub_request(content, approval), headers=auth())
    assert (res.status_code, res.json()["reason"]) == (409, "approval_not_approved")


def test_oa_approval_needs_detail_checked(on):
    content = make_content()
    approval = {"id": "ap_x", "status": "approved", "content_sha256": hub_content_sha256(content), "channel": "oa", "detail_checked": False}
    res = on.post(PATH, json=hub_request(content, approval), headers=auth())
    assert res.json()["reason"] == "approval_detail_not_checked"
    approval["detail_checked"] = True
    assert on.post(PATH, json=hub_request(content, approval), headers=auth()).status_code == 201


# ---------- 人工智能生成标识

@pytest.mark.parametrize(
    "body",
    [
        "小雪是二十四节气里的第二十个。",
        "小雪是二十四节气里的第二十个。\n仅供作息安排参考，不是医疗诊断或治疗建议。",
        "小雪是二十四节气里的第二十个。\n本内容由人工智能生成。",
        "小雪。本内容由AI生成。仅供作息安排参考，不是医疗诊断或治疗建议。",
    ],
)
def test_missing_aigc_label_or_disclaimer(on, body):
    res = on.post(PATH, json=hub_request(make_content(body)), headers=auth())
    assert (res.status_code, res.json()["reason"]) == (422, "aigc_missing")


# ---------- 其他拒绝原因

def test_all_failed_checks_are_listed(on, monkeypatch):
    monkeypatch.setattr(wr, "now_utc", lambda: datetime(2026, 11, 19, 23, 0, tzinfo=SH).astimezone(timezone.utc))
    res = on.post(PATH, json=hub_request(make_content("没有标识的正文"), approval=None), headers=auth())
    body = res.json()
    assert body["reason"] == "outside_window"
    assert body["failed"] == ["outside_window", "aigc_missing", "approval_missing"]
    assert body["message"]


def test_kill_switch(on):
    on.app.state.settings.kill_switch = True
    res = on.post(PATH, json=hub_request(make_content()), headers=auth())
    assert (res.status_code, res.json()["reason"]) == (423, "kill_switch")


def test_compliance_gate(on):
    body = "这个节气可长期服用某某汤。\n本内容由人工智能生成。\n仅供作息安排参考，不是医疗诊断或治疗建议。"
    res = on.post(PATH, json=hub_request(make_content(body)), headers=auth())
    assert res.json()["reason"] == "compliance_failed"


@pytest.mark.parametrize(
    "payload",
    [
        None,
        [],
        {"content": "text"},
        {"content": {"title": "无正文"}},
        {**hub_request(make_content()), "stub": True},
        hub_request({**make_content(), "channel": "in_app_cards"}),
        hub_request({**make_content(), "product": "fenfaxia"}),
    ],
)
def test_bad_request(on, payload):
    res = on.post(PATH, json=payload, headers=auth())
    assert (res.status_code, res.json()["reason"]) == (422, "bad_request")


# ---------- 审计只追加

def test_every_authenticated_rejection_is_audited_and_history_is_kept(on, monkeypatch):
    on.post(PATH, json=hub_request(make_content(), approval=None), headers=auth())
    first = [(a.id, a.decision, a.detail_json) for a in audits(on)]
    assert first[0][1] == "reject" and json.loads(first[0][2])["reason"] == "approval_missing"
    on.post(PATH, json=hub_request(make_content()), headers=auth())
    after = [(a.id, a.decision, a.detail_json) for a in audits(on)]
    assert after[: len(first)] == first  # 旧记录原样保留
    assert [d for _, d, _ in after] == ["reject", "accept"]


def test_audit_rows_cannot_be_updated_or_deleted(on):
    on.post(PATH, json=hub_request(make_content()), headers=auth())
    session = on.app.state.session_factory()
    try:
        row = session.query(GrowthAuditLog).filter_by(action="website_receive").one()
        row.decision = "edited"
        with pytest.raises(RuntimeError, match="append-only"):
            session.flush()
        session.rollback()
        row = session.query(GrowthAuditLog).filter_by(action="website_receive").one()
        session.delete(row)
        with pytest.raises(RuntimeError, match="append-only"):
            session.flush()
        session.rollback()
        sub = session.query(GrowthWebsiteSubmission).one()
        session.delete(sub)
        with pytest.raises(RuntimeError, match="append-only"):
            session.flush()
    finally:
        session.rollback()
        session.close()


def test_audit_failure_means_not_accepted_and_nothing_stored(on, monkeypatch):
    real = wr._audit

    def broken(session, *, decision, **kwargs):
        if decision == "accept":
            raise RuntimeError("audit store down")
        return real(session, decision=decision, **kwargs)

    monkeypatch.setattr(wr, "_audit", broken)
    res = on.post(PATH, json=hub_request(make_content()), headers=auth())
    assert (res.status_code, res.json()["reason"]) == (503, "audit_unavailable")
    assert rows(on, GrowthWebsiteSubmission) == []
    assert [a.decision for a in audits(on)] == ["reject"]


# ---------- 不碰外部

def test_receiver_has_no_outbound_calls():
    source = Path(wr.__file__).read_text(encoding="utf-8")
    for word in ("requests", "httpx", "urllib", "aiohttp", "socket", "subprocess"):
        assert f"import {word}" not in source and f"from {word}" not in source
