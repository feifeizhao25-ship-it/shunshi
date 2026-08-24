"""用户模块：注册 / 登录 / 游客登录 / 短信登录占位，JWT 签发与校验。

路径与方法以 Flutter 客户端实际调用为准（lib/presentation/pages/login/login_page.dart）。
"""

import json
import secrets
import time

import httpx
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from ..config import Settings
from ..deps import current_user, get_session, get_settings
from ..models import (
    AudioProgress,
    Entitlement,
    Feedback,
    Message,
    Reflection,
    SmsCode,
    User,
    UserSetting,
)
from ..security import (
    check_password,
    hash_password,
    hash_sms_code,
    issue_token,
)

router = APIRouter(prefix="/api/v1/auth", tags=["user"])

SMS_CODE_TTL_SECONDS = 300
SMS_MAX_ATTEMPTS = 5


class PhoneBody(BaseModel):
    phone: str = Field(pattern=r"^1\d{10}$")


class SmsVerifyBody(PhoneBody):
    code: str = Field(min_length=4, max_length=8)


class PasswordBody(PhoneBody):
    password: str = Field(min_length=8, max_length=128)
    nickname: str | None = Field(default=None, max_length=64)


@router.post("/guest-login")
def guest_login(
    session: Session = Depends(get_session),
    settings: Settings = Depends(get_settings),
):
    user = User(is_guest=True)
    session.add(user)
    session.flush()
    return issue_token(settings, user.id)


@router.post("/register")
def register(
    body: PasswordBody,
    session: Session = Depends(get_session),
    settings: Settings = Depends(get_settings),
):
    if session.scalar(select(User).where(User.phone == body.phone)):
        raise HTTPException(status_code=409, detail="该手机号已注册")
    user = User(
        phone=body.phone,
        password_hash=hash_password(body.password, body.phone),
        nickname=body.nickname or "顺时用户",
    )
    session.add(user)
    session.flush()
    return issue_token(settings, user.id)


@router.post("/login")
def login(
    body: PasswordBody,
    session: Session = Depends(get_session),
    settings: Settings = Depends(get_settings),
):
    user = session.scalar(select(User).where(User.phone == body.phone))
    if not user or not user.password_hash:
        raise HTTPException(status_code=401, detail="手机号或密码错误")
    if not check_password(body.password, body.phone, user.password_hash):
        raise HTTPException(status_code=401, detail="手机号或密码错误")
    return issue_token(settings, user.id)


@router.post("/sms/send")
async def sms_send(
    body: PhoneBody,
    session: Session = Depends(get_session),
    settings: Settings = Depends(get_settings),
):
    if not settings.sms_provider_url or not settings.sms_provider_token:
        # fail-closed：未配置短信服务商时不静默放行
        raise HTTPException(
            status_code=503,
            detail={"detail": "短信服务尚未配置", "configured": False},
        )
    code = f"{secrets.randbelow(1000000):06d}"
    async with httpx.AsyncClient(timeout=10) as client:
        response = await client.post(
            settings.sms_provider_url,
            json={"phone": body.phone, "code": code},
            headers={"Authorization": f"Bearer {settings.sms_provider_token}"},
        )
        response.raise_for_status()
    digest = hash_sms_code(settings.jwt_secret or "sms-only", body.phone, code)
    session.merge(
        SmsCode(
            phone=body.phone,
            code_hash=digest,
            expires_at=int(time.time()) + SMS_CODE_TTL_SECONDS,
            attempts=0,
        )
    )
    return {"sent": True, "expires_in": SMS_CODE_TTL_SECONDS}


@router.post("/sms/verify")
def sms_verify(
    body: SmsVerifyBody,
    session: Session = Depends(get_session),
    settings: Settings = Depends(get_settings),
):
    if not settings.sms_provider_url or not settings.sms_provider_token:
        raise HTTPException(
            status_code=503,
            detail={"detail": "短信服务尚未配置", "configured": False},
        )
    row = session.get(SmsCode, body.phone)
    digest = hash_sms_code(settings.jwt_secret or "sms-only", body.phone, body.code)
    if (
        not row
        or row.expires_at < time.time()
        or row.attempts >= SMS_MAX_ATTEMPTS
        or not secrets.compare_digest(row.code_hash, digest)
    ):
        if row:
            row.attempts += 1
        raise HTTPException(status_code=400, detail="验证码错误或已过期")
    user = session.scalar(select(User).where(User.phone == body.phone))
    if not user:
        user = User(phone=body.phone)
        session.add(user)
        session.flush()
    session.delete(row)
    return issue_token(settings, user.id)


def _collect_user_data(session: Session, user_id: str) -> dict:
    """归集该用户在库内的全部数据（真实读库，不抽样不截断到假数据）。"""
    user = session.get(User, user_id)
    settings_rows = session.scalars(
        select(UserSetting).where(UserSetting.user_id == user_id)
    ).all()
    messages = session.scalars(
        select(Message).where(Message.user_id == user_id).order_by(Message.created_at)
    ).all()
    reflections = session.scalars(
        select(Reflection).where(Reflection.user_id == user_id).order_by(Reflection.created_at)
    ).all()
    feedback_rows = session.scalars(
        select(Feedback).where(Feedback.user_id == user_id).order_by(Feedback.created_at)
    ).all()
    progress_rows = session.scalars(
        select(AudioProgress).where(AudioProgress.user_id == user_id)
    ).all()
    entitlement = session.get(Entitlement, user_id)
    return {
        "product": "shunshi",
        "exported_at": int(time.time()),
        "user": (
            {
                "id": user.id,
                "phone": user.phone,
                "nickname": user.nickname,
                "is_guest": user.is_guest,
                "created_at": user.created_at,
            }
            if user
            else None
        ),
        "settings": {row.key: json.loads(row.value) for row in settings_rows},
        "messages": [
            {"id": m.id, "role": m.role, "content": m.content, "created_at": m.created_at}
            for m in messages
        ],
        "reflections": [
            {
                "id": r.id,
                "mood": r.mood,
                "question": r.question,
                "notes": r.notes,
                "recorded_at": r.recorded_at,
                "created_at": r.created_at,
            }
            for r in reflections
        ],
        "feedback": [
            {
                "id": f.id,
                "kind": f.kind,
                "payload": json.loads(f.payload),
                "created_at": f.created_at,
            }
            for f in feedback_rows
        ],
        "audio_progress": [
            {
                "audio_id": p.audio_id,
                "progress_seconds": p.progress_seconds,
                "completed": p.completed,
                "updated_at": p.updated_at,
            }
            for p in progress_rows
        ],
        "entitlement": (
            {
                "product_id": entitlement.product_id,
                "store": entitlement.store,
                "expires_at": entitlement.expires_at,
            }
            if entitlement
            else None
        ),
    }


@router.post("/data/export")
@router.get("/data/export")
def export_data(
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
):
    """数据导出：真实读库返回该用户全部数据的 JSON。客户端实际用 POST，GET 为等价别名。"""
    return _collect_user_data(session, user_id)


@router.post("/account/cancel-delete")
def cancel_delete_account(user_id: str = Depends(current_user)):
    """骨架没有「待删除」软状态，如实告知无可取消项；客户端仅做前置调用，不据此判断成败。"""
    return {"pending_deletion": False, "cancelled": False}


@router.delete("/account")
def delete_account(
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
):
    """账号注销：真实删除该用户全部数据与账号行，返回删除确认与各表删除条数。"""
    counts = {}
    for model, column in (
        (Message, Message.user_id),
        (UserSetting, UserSetting.user_id),
        (Reflection, Reflection.user_id),
        (Feedback, Feedback.user_id),
        (AudioProgress, AudioProgress.user_id),
        (Entitlement, Entitlement.user_id),
    ):
        result = session.execute(delete(model).where(column == user_id))
        counts[model.__tablename__] = result.rowcount
    result = session.execute(delete(User).where(User.id == user_id))
    counts["users"] = result.rowcount
    return {"deleted": True, "user_id": user_id, "deleted_rows": counts}
