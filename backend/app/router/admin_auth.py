"""Administrator authentication backed by the shared product database."""
import os
import re
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel, Field

from app.services import admin_identity

router = APIRouter(prefix="/api/v1/admin/auth", tags=["Admin 认证"])
ADMIN_PASSWORD_HASH = os.getenv("ADMIN_PASSWORD_HASH")
ADMIN_JWT_SECRET = os.getenv("ADMIN_JWT_SECRET")
ADMIN_USERNAME = os.getenv("ADMIN_USERNAME", "admin")
ADMIN_TOKEN_EXPIRY_HOURS = int(os.getenv("ADMIN_TOKEN_EXPIRY_HOURS", "24"))
if not ADMIN_PASSWORD_HASH or not ADMIN_JWT_SECRET:
    raise RuntimeError("管理员初始密码和会话密钥必须配置")
if not re.fullmatch(r"[0-9a-fA-F]{64}", ADMIN_PASSWORD_HASH) or len(ADMIN_JWT_SECRET) < 32:
    raise RuntimeError("管理员初始密码须为 SHA256 摘要，会话密钥至少 32 字符")
ADMIN_PASSWORD_HASH = ADMIN_PASSWORD_HASH.lower()
if not 1 <= ADMIN_TOKEN_EXPIRY_HOURS <= 168:
    raise RuntimeError("管理员会话有效期必须为 1–168 小时")


class AdminLoginRequest(BaseModel):
    username: str = Field(default="admin", min_length=1, max_length=100)
    password: str = Field(min_length=1, max_length=1024)


class AdminLoginResponse(BaseModel):
    success: bool
    token: str
    expires_at: str
    message: str


class AdminVerifyResponse(BaseModel):
    valid: bool
    username: str


class AdminChangePasswordRequest(BaseModel):
    old_password: str = Field(min_length=1, max_length=1024)
    new_password: str = Field(min_length=12, max_length=1024)


def _token(header: Optional[str], authorization: Optional[str]) -> str:
    """Accept one consistent token; conflicting headers fail closed."""
    def normalize(value):
        value = (value or "").strip()
        if value.lower().startswith("bearer "):
            return value[7:].strip()
        return value
    primary = normalize(header)
    bearer = normalize(authorization) if (authorization or "").lower().startswith("bearer ") else ""
    if primary and bearer and primary != bearer:
        raise HTTPException(status_code=401, detail="登录凭证不一致")
    return primary or bearer


def _verify_token(token: str) -> bool:
    return bool(admin_identity.verify(token, ADMIN_JWT_SECRET))


def get_current_admin(
    token: Optional[str] = Header(None, alias="X-Admin-Token"),
    authorization: Optional[str] = Header(None),
) -> str:
    username = admin_identity.verify(_token(token, authorization), ADMIN_JWT_SECRET)
    if not username:
        raise HTTPException(status_code=401, detail="管理员登录已失效，请重新登录")
    return username


@router.post("/login", response_model=AdminLoginResponse)
async def admin_login(request: AdminLoginRequest):
    if request.username != ADMIN_USERNAME:
        raise HTTPException(status_code=401, detail="用户名或密码错误")
    result = admin_identity.login(
        request.username, request.password, ADMIN_PASSWORD_HASH,
        ADMIN_JWT_SECRET, ADMIN_TOKEN_EXPIRY_HOURS,
    )
    if not result:
        raise HTTPException(status_code=401, detail="用户名或密码错误")
    token, expires = result
    return AdminLoginResponse(
        success=True, token=token,
        expires_at=datetime.fromtimestamp(expires, timezone.utc).isoformat(),
        message="登录成功",
    )


@router.post("/logout")
async def admin_logout(
    token: Optional[str] = Header(None, alias="X-Admin-Token"),
    authorization: Optional[str] = Header(None),
):
    value = _token(token, authorization)
    if value:
        admin_identity.logout(value, ADMIN_JWT_SECRET)
    return {"success": True, "message": "已登出"}


@router.get("/verify", response_model=AdminVerifyResponse)
async def admin_verify(
    token: Optional[str] = Header(None, alias="X-Admin-Token"),
    authorization: Optional[str] = Header(None),
):
    username = admin_identity.verify(_token(token, authorization), ADMIN_JWT_SECRET)
    return AdminVerifyResponse(valid=bool(username), username=username or "")


@router.post("/change-password")
async def admin_change_password(
    request: AdminChangePasswordRequest,
    token: Optional[str] = Header(None, alias="X-Admin-Token"),
    authorization: Optional[str] = Header(None),
):
    value = _token(token, authorization)
    username = admin_identity.verify(value, ADMIN_JWT_SECRET)
    if not username:
        raise HTTPException(status_code=401, detail="管理员登录已失效，请重新登录")
    if request.old_password == request.new_password:
        raise HTTPException(status_code=422, detail="新密码不能与旧密码相同")
    result = admin_identity.change_password(
        username, value, request.old_password, request.new_password,
        ADMIN_PASSWORD_HASH, ADMIN_JWT_SECRET,
    )
    if result != "changed":
        raise HTTPException(status_code=401, detail="登录已失效或旧密码错误")
    return {"success": True, "message": "密码已修改，所有管理员会话已退出，请重新登录"}
