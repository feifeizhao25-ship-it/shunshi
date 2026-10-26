"""运营中枢调用的发布动作。

开关默认全关。全局急停打开时不写卡片、不记推送。
发布前重新计算 content_sha256，必须和一条已记录的审批一致。
只投给自己打开对应开关的用户。
"""

from __future__ import annotations

import hashlib
import json
import os

from sqlalchemy.orm import Session

from app.growth.audit import append_audit
from app.growth.compliance.gate import violation_codes
from app.growth.config import GrowthConfig
from app.growth.models import GrowthApproval, GrowthInAppCard, GrowthPushDelivery
from app.simple_models import UserSetting

OPT_IN_KEY = "growth:channel_opt_in"
CHANNELS = {"in_app_card": "in_app_cards", "app_push": "app_push"}


class OpsRefused(Exception):
    def __init__(self, status_code: int, detail: str):
        self.status_code = status_code
        self.detail = detail
        super().__init__(detail)


def content_sha256(channel: str, title: str, body: str) -> str:
    raw = f"{channel}\n{title}\n{body}".encode("utf-8")
    return hashlib.sha256(raw).hexdigest()


def kill_switch_on(config: GrowthConfig) -> bool:
    if config.kill_switch:
        return True
    return os.getenv("SHUNSHI_KILL_SWITCH", "").strip().lower() in {"1", "true", "yes", "on"}


def read_opt_in(session: Session, user_id: str) -> dict[str, bool]:
    row = session.get(UserSetting, {"user_id": user_id, "key": OPT_IN_KEY})
    if row is None:
        return {"in_app_cards": False, "app_push": False}
    try:
        data = json.loads(row.value)
    except json.JSONDecodeError:
        return {"in_app_cards": False, "app_push": False}
    if not isinstance(data, dict):
        return {"in_app_cards": False, "app_push": False}
    return {
        "in_app_cards": bool(data.get("in_app_cards")),
        "app_push": bool(data.get("app_push")),
    }


def write_opt_in(session: Session, user_id: str, *, in_app_cards: bool, app_push: bool) -> dict[str, bool]:
    value = {"in_app_cards": bool(in_app_cards), "app_push": bool(app_push)}
    session.merge(
        UserSetting(user_id=user_id, key=OPT_IN_KEY, value=json.dumps(value, ensure_ascii=False))
    )
    return value


def _opted_user_ids(session: Session, channel: str, requested: list[str] | None) -> list[str]:
    flag = CHANNELS[channel]
    if requested:
        return [user_id for user_id in requested if read_opt_in(session, user_id).get(flag)]
    matched: list[str] = []
    rows = session.query(UserSetting).filter(UserSetting.key == OPT_IN_KEY).all()
    for row in rows:
        prefs = read_opt_in(session, row.user_id)
        if prefs.get(flag):
            matched.append(row.user_id)
    return matched


def record_approval(
    session: Session,
    *,
    channel: str,
    title: str,
    body: str,
    content_sha256_hex: str,
) -> GrowthApproval:
    if channel not in CHANNELS:
        raise OpsRefused(422, "不支持的渠道")
    digest = content_sha256(channel, title, body)
    if not content_sha256_hex or content_sha256_hex.lower() != digest:
        raise OpsRefused(409, "content_sha256 与正文不一致")
    if violation_codes(f"{title}\n{body}"):
        raise OpsRefused(422, "内容未过合规门")
    row = GrowthApproval(
        channel=channel,
        title=title,
        body=body,
        content_sha256=digest,
        status="approved",
    )
    session.add(row)
    session.flush()
    append_audit(
        session,
        action="record_approval",
        decision="no_change",
        object_key=row.id,
        detail={"channel": channel, "content_sha256": digest},
    )
    return row


def _switch_open(config: GrowthConfig, channel: str) -> bool:
    if not config.allow_publish:
        return False
    if channel == "in_app_card":
        return config.allow_in_app_cards
    if channel == "app_push":
        return config.allow_app_push
    return False


def publish(
    session: Session,
    config: GrowthConfig,
    *,
    channel: str,
    title: str,
    body: str,
    content_sha256_hex: str,
    user_ids: list[str] | None = None,
) -> dict:
    if kill_switch_on(config):
        raise OpsRefused(423, "全局急停已打开，不发布")
    if channel not in CHANNELS:
        raise OpsRefused(422, "不支持的渠道")
    if not _switch_open(config, channel):
        raise OpsRefused(403, "发布开关未打开")
    digest = content_sha256(channel, title, body)
    if content_sha256_hex.lower() != digest:
        raise OpsRefused(409, "content_sha256 与正文不一致")
    approval = (
        session.query(GrowthApproval)
        .filter(
            GrowthApproval.content_sha256 == digest,
            GrowthApproval.channel == channel,
            GrowthApproval.status == "approved",
        )
        .one_or_none()
    )
    if approval is None:
        raise OpsRefused(409, "没有匹配的审批记录")
    if violation_codes(f"{title}\n{body}"):
        raise OpsRefused(422, "内容未过合规门")
    delivered: list[str] = []
    for user_id in _opted_user_ids(session, channel, user_ids):
        if channel == "in_app_card":
            session.add(
                GrowthInAppCard(user_id=user_id, title=title, body=body, content_sha256=digest)
            )
        else:
            session.add(
                GrowthPushDelivery(
                    user_id=user_id, title=title, body=body, content_sha256=digest, status="recorded"
                )
            )
        delivered.append(user_id)
    session.flush()
    append_audit(
        session,
        action="publish",
        decision="ship",
        object_key=approval.id,
        detail={"channel": channel, "content_sha256": digest, "delivered": len(delivered)},
    )
    return {"channel": channel, "content_sha256": digest, "delivered_user_ids": delivered, "published": True}
