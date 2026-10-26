"""邀请和分享卡片的持久化。邀请码算法与原来的内存实现一致。"""

from __future__ import annotations

import hashlib
import json
from datetime import datetime

from sqlalchemy.orm import Session

from app.growth.models import GrowthReferral, GrowthShare
from app.simple_models import now_ts


def share_id_for(user_id: str, content_type: str, content_id: str, day=None) -> str:
    day = day or datetime.now().date()
    raw = f"{user_id}:{content_type}:{content_id}:{day}"
    return hashlib.md5(raw.encode()).hexdigest()[:12]


def invite_code_for(user_id: str, channel: str) -> str:
    return hashlib.md5(f"invite:{user_id}:{channel}".encode()).hexdigest()[:8]


def save_share(session: Session, payload: dict) -> GrowthShare:
    row = session.get(GrowthShare, payload["share_id"])
    if row is None:
        row = GrowthShare(share_id=payload["share_id"], clicks=0)
        session.add(row)
    row.user_id = payload["user_id"]
    row.content_type = payload.get("content_type", "")
    row.content_id = payload.get("content_id", "")
    row.platform = payload.get("platform", "")
    row.title = payload.get("title", "")
    row.text = payload.get("text", "")
    row.hashtags_json = json.dumps(payload.get("hashtags", []), ensure_ascii=False)
    row.share_url = payload.get("share_url", "")
    row.image_url = payload.get("image_url", "")
    row.created_at = payload.get("created_at") or row.created_at or datetime.now().isoformat()
    session.flush()
    return row


def get_share(session: Session, share_id: str) -> GrowthShare | None:
    return session.get(GrowthShare, share_id)


def list_shares(session: Session, user_id: str) -> list[GrowthShare]:
    return (
        session.query(GrowthShare)
        .filter(GrowthShare.user_id == user_id)
        .order_by(GrowthShare.created_at.desc())
        .all()
    )


def share_payload(row: GrowthShare, *, include_private: bool) -> dict:
    payload = {
        "share_id": row.share_id,
        "title": row.title,
        "text": row.text,
        "hashtags": json.loads(row.hashtags_json or "[]"),
        "platform": row.platform,
        "share_url": row.share_url,
        "image_url": row.image_url,
        "created_at": row.created_at,
    }
    if include_private:
        payload["user_id"] = row.user_id
        payload["clicks"] = row.clicks
    return payload


def save_invite(
    session: Session,
    *,
    user_id: str,
    channel: str,
    content_id: str = "",
) -> GrowthReferral:
    code = invite_code_for(user_id, channel)
    row = session.get(GrowthReferral, code)
    if row is None:
        row = GrowthReferral(
            invite_code=code,
            inviter_user_id=user_id,
            channel=channel,
            utm_source=channel,
            utm_medium="invite",
            utm_campaign="referral",
            content_id=content_id,
            created_at=now_ts(),
        )
        session.add(row)
        session.flush()
    return row
