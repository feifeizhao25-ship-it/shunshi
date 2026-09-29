"""用户模块：注册 / 登录 / 游客登录 / 短信登录占位，JWT 签发与校验。

路径与方法以 Flutter 客户端实际调用为准（lib/presentation/pages/login/login_page.dart）。
"""

import hashlib
import json
import secrets
import time
from datetime import datetime
from zoneinfo import ZoneInfo

import httpx
from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from sqlalchemy import delete, select, update, func
from sqlalchemy.orm import Session

from ..config import Settings
from ..deps import current_user, get_session, get_settings
from ..simple_models import (
    AudioProgress,
    Entitlement,
    Feedback,
    HealthMeasurement,
    Message,
    Reflection,
    StorePurchase,
    StorePurchaseOwner,
    SmsCode,
    SmsSendLog,
    User,
    UserSetting,
)
from ..security import (
    check_password,
    hash_password,
    hash_sms_code,
    issue_token,
    revoke_token,
)

router = APIRouter(prefix="/api/v1/auth", tags=["user"])

SMS_CODE_TTL_SECONDS = 300
SMS_MAX_ATTEMPTS = 5
# 发送验证码的节流。每条短信都要花钱，且会打扰手机号的主人（短信轰炸）。
SMS_COOLDOWN_SECONDS = 60
SMS_DAILY_PER_PHONE = 5
SMS_DAILY_PER_IP = 20


def _now() -> float:
    return time.time()


def _digest(settings: Settings, value: str) -> str:
    key = (settings.jwt_secret or "sms-only").encode()
    return hashlib.sha256(key + b"|" + value.encode()).hexdigest()


def _client_ip(request: Request) -> str:
    # 后端端口只绑 127.0.0.1，外部请求只能经 nginx 进来；nginx 用 $remote_addr 覆盖 X-Real-IP。
    return (request.headers.get("x-real-ip") or (request.client.host if request.client else "") or "?").strip()


def _start_of_day_cn(now: float) -> int:
    local = datetime.fromtimestamp(now, ZoneInfo("Asia/Shanghai"))
    return int(local.replace(hour=0, minute=0, second=0, microsecond=0).timestamp())


def _enforce_sms_throttle(session: Session, phone_digest: str, ip_digest: str, now: float) -> None:
    from sqlalchemy import func

    last = session.scalar(
        select(func.max(SmsSendLog.sent_at)).where(SmsSendLog.phone_digest == phone_digest)
    )
    if last and now - last < SMS_COOLDOWN_SECONDS:
        wait = int(SMS_COOLDOWN_SECONDS - (now - last)) + 1
        raise HTTPException(
            status_code=429,
            detail=f"发送太频繁，请 {wait} 秒后再试",
            headers={"Retry-After": str(wait)},
        )
    day = _start_of_day_cn(now)
    per_phone = session.scalar(
        select(func.count()).select_from(SmsSendLog).where(
            SmsSendLog.phone_digest == phone_digest, SmsSendLog.sent_at >= day
        )
    )
    if per_phone >= SMS_DAILY_PER_PHONE:
        raise HTTPException(status_code=429, detail="该手机号今日验证码次数已达上限，请明天再试")
    per_ip = session.scalar(
        select(func.count()).select_from(SmsSendLog).where(
            SmsSendLog.ip_digest == ip_digest, SmsSendLog.sent_at >= day
        )
    )
    if per_ip >= SMS_DAILY_PER_IP:
        raise HTTPException(status_code=429, detail="当前网络今日验证码次数已达上限，请明天再试")


def _mirror_to_record_store(user_id: str, *, phone: str | None = None, nickname: str | None = None) -> None:
    """在记录库（app/database/db.py 的 users 表）里补一行同 id 的账号。

    游客登录、短信登录、手机号注册的账号只写在核心库里；而 ``/api/v1/auth/me`` 与大量产品
    接口按记录库查人——查不到就 401，客户端登录后第一步取「我的资料」就被踢回登录页。
    """
    try:
        from ..database.db import get_db

        db = get_db()
        name = nickname or "顺时用户"
        cursor = db.execute(
            "INSERT OR IGNORE INTO users (id, name, phone) VALUES (?, ?, ?)", (user_id, name, phone)
        )
        if not cursor.rowcount and phone:
            # 该手机号已被记录库里另一个账号占用：至少保证本账号能被识别。
            db.execute("INSERT OR IGNORE INTO users (id, name) VALUES (?, ?)", (user_id, name))
        db.commit()
    except Exception:  # 记录库不可用时不影响登录本身
        pass


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
    _mirror_to_record_store(user.id, nickname="游客")
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
    _mirror_to_record_store(user.id, phone=body.phone, nickname=user.nickname)
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
    request: Request,
    session: Session = Depends(get_session),
    settings: Settings = Depends(get_settings),
):
    if not settings.sms_provider_url or not settings.sms_provider_token:
        # fail-closed：未配置短信服务商时不静默放行
        raise HTTPException(
            status_code=503,
            detail={"detail": "短信服务尚未配置", "configured": False},
        )
    now = _now()
    phone_digest = _digest(settings, "phone:" + body.phone)
    ip_digest = _digest(settings, "ip:" + _client_ip(request))
    _enforce_sms_throttle(session, phone_digest, ip_digest, now)
    code = f"{secrets.randbelow(1000000):06d}"
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.post(
                settings.sms_provider_url,
                json={"phone": body.phone, "code": code},
                headers={"Authorization": f"Bearer {settings.sms_provider_token}"},
            )
            response.raise_for_status()
    except httpx.HTTPError:
        raise HTTPException(status_code=502, detail="短信发送失败，请稍后重试") from None
    digest = hash_sms_code(settings.jwt_secret or "sms-only", body.phone, code)
    session.merge(
        SmsCode(
            phone=body.phone,
            code_hash=digest,
            expires_at=int(now) + SMS_CODE_TTL_SECONDS,
            attempts=0,
        )
    )
    session.add(SmsSendLog(phone_digest=phone_digest, ip_digest=ip_digest, sent_at=int(now)))
    return {"sent": True, "expires_in": SMS_CODE_TTL_SECONDS, "cooldown": SMS_COOLDOWN_SECONDS}


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
    if not row:
        raise HTTPException(status_code=400, detail="验证码错误或已过期")
    # Conditional update both reserves an attempt and locks the current issuance.
    # Concurrent guesses cannot overwrite counters, and a replacement code cannot
    # be consumed using an earlier read. Use the same clock as issuance.
    claimed = session.execute(
        update(SmsCode).where(
            SmsCode.phone == body.phone,
            SmsCode.code_hash == row.code_hash,
            SmsCode.expires_at > _now(),
            SmsCode.attempts < SMS_MAX_ATTEMPTS,
        ).values(attempts=SmsCode.attempts + 1)
    ).rowcount
    if claimed != 1 or not secrets.compare_digest(row.code_hash, digest):
        session.commit()  # Do not roll back failed-attempt accounting.
        raise HTTPException(status_code=400, detail="验证码错误或已过期")
    user = session.scalar(select(User).where(User.phone == body.phone))
    if not user:
        user = User(phone=body.phone)
        session.add(user)
        session.flush()
    session.delete(row)
    _mirror_to_record_store(user.id, phone=body.phone, nickname=user.nickname)
    return issue_token(settings, user.id)


def _collect_user_data(session: Session, user_id: str) -> dict:
    """归集核心账号数据及国内付款、退款申请记录。"""
    user = session.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=401, detail="账号已不存在，请重新登录")
    from ..services.billing_data import collect_domestic_billing_data
    billing = collect_domestic_billing_data(user_id)
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
        "domestic_billing": billing,
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
        "store_purchases": [
            {"transaction_key": row.transaction_key, "store": row.store,
             "product_id": row.product_id, "expires_at": row.expires_at,
             "verified_at": row.verified_at}
            for row in session.scalars(select(StorePurchase).where(StorePurchase.user_id == user_id))
        ],
        "health_measurements": [
            {"id": row.id, "data_type": row.data_type, "value": row.value,
             "unit": row.unit, "source": row.source,
             "recorded_at": row.recorded_at, "synced_at": row.synced_at}
            for row in session.scalars(select(HealthMeasurement).where(
                HealthMeasurement.user_id == user_id).order_by(HealthMeasurement.recorded_at))
        ],
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
    data = _collect_user_data(session, user_id)
    # 产品模块的数据（家庭成员、饮水、日记……）原来不在导出里；范围与注销时删除的一致。
    from ..database.db import close_test_connection, get_db
    from ..services.account_erasure import export_product_store, export_record_store

    db = get_db()
    try:
        data["record_store"] = export_record_store(db, user_id)
    finally:
        close_test_connection(db)
    data["product_store"] = export_product_store(user_id)
    return data


@router.post("/account/cancel-delete")
def cancel_delete_account(user_id: str = Depends(current_user)):
    """骨架没有「待删除」软状态，如实告知无可取消项；客户端仅做前置调用，不据此判断成败。"""
    return {"pending_deletion": False, "cancelled": False}


@router.delete("/account")
def delete_account(
    request: Request,
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
    settings: Settings = Depends(get_settings),
):
    """删除核心账号数据，并报告尚保留的国内付款、退款申请记录。"""
    from ..database.db import get_db, close_test_connection
    from ..services.payment_recovery import ensure_recovery_jobs

    db = get_db()
    try:
        ensure_recovery_jobs(db)
        # Coordinate deletion with domestic recovery before taking SQLAlchemy
        # write locks, using the same lock order as the recovery worker.
        db.execute("BEGIN IMMEDIATE")
        # Financial evidence is not silently destroyed by account deletion.
        # Report it explicitly; retention policy and refund settlement remain
        # separate deployment requirements.
        tables = {row[0] for row in db.execute(
            "SELECT name FROM sqlite_master WHERE type='table'").fetchall()}
        retained = {
            model.__tablename__: session.scalar(select(func.count()).select_from(model).where(model.user_id == user_id))
            for model in (StorePurchase, StorePurchaseOwner)
        }
        for table in ('payment_orders', 'domestic_refund_requests'):
            retained[table] = (db.execute(f'SELECT count(*) FROM {table} WHERE user_id=?',
                (user_id,)).fetchone()[0] if table in tables else 0)
        counts = {}
        for model, column in (
            (Message, Message.user_id),
            (HealthMeasurement, HealthMeasurement.user_id),
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
        session.commit()
        db.execute("DELETE FROM domestic_payment_recovery WHERE user_id=?", (user_id,))
        # 记录库与产品库里的个人数据（家庭成员、饮水、日记、情绪……）原来注销后原样留着。
        from ..services.account_erasure import erase_product_store, erase_record_store

        record_deleted, record_retained = erase_record_store(db, user_id)
        db.commit()
        product_deleted, product_retained, leftovers = erase_product_store(user_id)
        for table, count in {**record_retained, **product_retained}.items():
            retained.setdefault(table, count)
        # 这把 token 立即作废（否则 1 小时内还能写入新数据）。
        header = request.headers.get("authorization") or ""
        if header.lower().startswith("bearer "):
            revoke_token(settings, header[7:].strip())
        return {"deleted": True, "user_id": user_id, "deleted_rows": counts,
            "deleted_record_rows": record_deleted,
            "deleted_product_rows": product_deleted,
            "erasure_incomplete_tables": leftovers,
            "retained_billing_records": retained,
            "billing_notice": "支付与退款申请记录仍保留，注销不表示退款已完成"}
    except Exception:
        session.rollback()
        db.rollback()
        raise
    finally:
        close_test_connection(db)
