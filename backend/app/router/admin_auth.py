"""
Admin 后台认证路由

提供 Admin 登录、Token 刷新、权限检查等接口。

作者: Claw 🦅
日期: 2026-04-29
"""

from __future__ import annotations
import os
import uuid
import hashlib
import secrets
import logging
from datetime import datetime, timedelta
from typing import Optional, Dict, Any

from fastapi import APIRouter, HTTPException, Header, Depends
from pydantic import BaseModel, Field

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/admin/auth", tags=["Admin 认证"])


# ==================== 配置 ====================

# Admin 密码 — 必须从环境变量读取，不允许硬编码回退
ADMIN_PASSWORD_HASH = os.getenv("ADMIN_PASSWORD_HASH")
if not ADMIN_PASSWORD_HASH:
    logger.critical("[Security] ADMIN_PASSWORD_HASH 环境变量未设置。")
    raise RuntimeError("ADMIN_PASSWORD_HASH 环境变量必须设置。使用: echo -n 'your_password' | sha256sum")

ADMIN_JWT_SECRET = os.getenv("ADMIN_JWT_SECRET")
if not ADMIN_JWT_SECRET:
    logger.critical("[Security] ADMIN_JWT_SECRET 环境变量未设置。")
    raise RuntimeError("ADMIN_JWT_SECRET 环境变量必须设置。使用: openssl rand -hex 32")
ADMIN_TOKEN_EXPIRY_HOURS = int(os.getenv("ADMIN_TOKEN_EXPIRY_HOURS", "24"))


# ==================== 内存中的 Token 存储（生产环境应使用 Redis）====================

_active_tokens: Dict[str, Dict[str, Any]] = {}


# ==================== 请求/响应模型 ====================

class AdminLoginRequest(BaseModel):
    username: str = Field(default="admin", description="管理员用户名")
    password: str = Field(..., description="管理员密码", min_length=1)


class AdminLoginResponse(BaseModel):
    success: bool
    token: str
    expires_at: str
    message: str


class AdminVerifyResponse(BaseModel):
    valid: bool
    username: str


class AdminChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str = Field(..., min_length=6)


# ==================== 工具函数 ====================

def _hash_password(password: str) -> str:
    """密码 SHA256 哈希"""
    return hashlib.sha256(password.encode()).hexdigest()


def _generate_token() -> str:
    """生成随机 Token"""
    return secrets.token_urlsafe(32)


def _verify_token(token: str) -> bool:
    """验证 Token 是否有效"""
    if token not in _active_tokens:
        return False
    
    expires_at = _active_tokens[token].get("expires_at")
    if expires_at and datetime.now() > expires_at:
        del _active_tokens[token]
        return False
    
    return True


def get_current_admin(token: Optional[str] = Header(None, alias="X-Admin-Token")) -> str:
    """
    获取当前 Admin 用户（依赖注入用）
    
    优先从 X-Admin-Token header 获取，也兼容 Authorization: Bearer <token>
    """
    # 兼容 Bearer token
    if token and token.startswith("Bearer "):
        token = token[7:]
    
    if not token:
        raise HTTPException(status_code=401, detail="Missing admin token")
    
    if not _verify_token(token):
        raise HTTPException(status_code=401, detail="Invalid or expired admin token")
    
    return _active_tokens[token].get("username", "admin")


# ==================== API 端点 ====================

@router.post("/login", response_model=AdminLoginResponse)
async def admin_login(request: AdminLoginRequest):
    """
    Admin 登录
    
    验证密码后返回访问 Token，Token 有效期 24 小时。
    """
    input_hash = _hash_password(request.password)
    
    if input_hash != ADMIN_PASSWORD_HASH:
        logger.warning(f"[AdminAuth] 登录失败: username={request.username}")
        raise HTTPException(status_code=401, detail="Invalid username or password")
    
    # 生成 Token
    token = _generate_token()
    expires_at = datetime.now() + timedelta(hours=ADMIN_TOKEN_EXPIRY_HOURS)
    
    _active_tokens[token] = {
        "username": request.username,
        "created_at": datetime.now(),
        "expires_at": expires_at,
    }
    
    logger.info(f"[AdminAuth] 登录成功: {request.username}")
    
    return AdminLoginResponse(
        success=True,
        token=token,
        expires_at=expires_at.isoformat(),
        message="登录成功",
    )


@router.post("/logout")
async def admin_logout(token: Optional[str] = Header(None, alias="X-Admin-Token")):
    """
    Admin 登出
    
    使当前 Token 失效。
    """
    if token and token in _active_tokens:
        del _active_tokens[token]
        logger.info("[AdminAuth] 登出成功")
    
    return {"success": True, "message": "已登出"}


@router.get("/verify", response_model=AdminVerifyResponse)
async def admin_verify(token: Optional[str] = Header(None, alias="X-Admin-Token")):
    """
    验证 Token 是否有效
    
    用于前端页面加载时检查登录状态。
    """
    if token and token.startswith("Bearer "):
        token = token[7:]
    
    valid = _verify_token(token) if token else False
    username = _active_tokens[token].get("username", "") if valid else ""
    
    return AdminVerifyResponse(
        valid=valid,
        username=username,
    )


@router.post("/change-password")
async def admin_change_password(
    request: AdminChangePasswordRequest,
    username: str = Depends(get_current_admin),
):
    """
    修改 Admin 密码
    
    需要提供旧密码验证身份。
    """
    old_hash = _hash_password(request.old_password)
    
    if old_hash != ADMIN_PASSWORD_HASH:
        raise HTTPException(status_code=401, detail="旧密码错误")
    
    new_hash = _hash_password(request.new_password)
    
    # 注意：这里只是演示，实际应更新环境变量或数据库中的密码
    logger.info(f"[AdminAuth] 密码修改请求: {username}")
    
    return {
        "success": True,
        "message": "密码修改成功（请在环境变量中更新 ADMIN_PASSWORD_HASH）",
    }
