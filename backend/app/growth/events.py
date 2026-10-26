"""流量到注册再到付费的事件。落地页可以匿名，其后的事件必须对上登录凭证。"""

from __future__ import annotations

from fastapi import HTTPException, Request
from sqlalchemy.orm import Session

from app.growth.constants import AUTHENTICATED_EVENTS, FUNNEL_EVENTS
from app.growth.models import GrowthEvent, GrowthReferral
from app.security import verify_token


def record_event(
    session: Session,
    request: Request,
    payload: dict,
) -> GrowthEvent:
    event_type = payload.get("event_type") or ""
    if event_type not in FUNNEL_EVENTS:
        raise HTTPException(status_code=422, detail="不认识的事件类型")
    claimed = str(payload.get("user_id") or "")
    if event_type in AUTHENTICATED_EVENTS:
        user_id = _require_self(request, claimed)
    else:
        user_id = _optional_self(request, claimed)
    invite_code = str(payload.get("invite_code") or "")
    inviter = ""
    if invite_code:
        referral = session.get(GrowthReferral, invite_code)
        if referral is not None:
            inviter = referral.inviter_user_id
    row = GrowthEvent(
        event_type=event_type,
        user_id=user_id,
        anonymous_id=str(payload.get("anonymous_id") or ""),
        invite_code=invite_code,
        inviter_user_id=inviter,
        utm_source=str(payload.get("utm_source") or ""),
        utm_medium=str(payload.get("utm_medium") or ""),
        utm_campaign=str(payload.get("utm_campaign") or ""),
        content_id=str(payload.get("content_id") or ""),
        amount_yuan=float(payload.get("amount_yuan") or 0),
    )
    session.add(row)
    session.flush()
    return row


def _bearer(request: Request) -> str:
    header = request.headers.get("authorization") or ""
    scheme, _, token = header.partition(" ")
    return token.strip() if scheme.lower() == "bearer" else ""


def _require_self(request: Request, claimed: str) -> str:
    token = _bearer(request)
    if not token:
        raise HTTPException(status_code=401, detail="请先登录")
    user_id = verify_token(request.app.state.settings, token)
    if not claimed or claimed != user_id:
        raise HTTPException(status_code=403, detail="只能记录自己的行为")
    return user_id


def _optional_self(request: Request, claimed: str) -> str:
    token = _bearer(request)
    if not token or not claimed:
        return ""
    try:
        user_id = verify_token(request.app.state.settings, token)
    except HTTPException:
        return ""
    return user_id if user_id == claimed else ""
