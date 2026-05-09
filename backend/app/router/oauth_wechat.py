"""
顺时 — 微信 OAuth 登录 API
/api/v1/auth/wechat
"""
import logging
import os
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.database.db import get_db
from app.router.auth import (
    create_access_token,
    create_refresh_token,
    generate_token,
    _get_or_create_device,
    _record_active_token,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/auth/wechat", tags=["微信登录"])

# ============ 配置 ============

WECHAT_APP_ID = os.getenv("WECHAT_APP_ID", "")
WECHAT_APP_SECRET = os.getenv("WECHAT_APP_SECRET", "")


# ============ 模型 ============

class WechatLoginRequest(BaseModel):
    code: str = Field(..., description="微信授权临时票据 (auth_code)")
    device_info: Optional[dict] = Field(default=None, description="设备信息")


class WechatMiniProgramLoginRequest(BaseModel):
    js_code: str = Field(..., description="小程序登录临时 code")
    user_info: Optional[dict] = Field(default=None, description="用户信息 (encryptedData + iv)")
    device_info: Optional[dict] = Field(default=None, description="设备信息")


# ============ API 端点 ============

@router.post("/login", response_model=dict)
async def wechat_login(request: WechatLoginRequest):
    """
    微信 OAuth 登录
    
    流程:
    1. 用 code 向微信服务器换取 access_token + openid + unionid
    2. 查找或创建用户
    3. 返回 JWT token
    
    TODO: 生产环境接入真实微信开放平台 API
    """
    # 检查微信配置
    if not WECHAT_APP_ID or not WECHAT_APP_SECRET:
        logger.warning("Wechat APP_ID/SECRET not configured, login disabled")
        raise HTTPException(
            status_code=503,
            detail="微信登录未开通",
        )

    # 真实微信登录流程
    import httpx
    async with httpx.AsyncClient() as client:
        # 1. 获取 access_token
        token_url = "https://api.weixin.qq.com/sns/oauth2/access_token"
        resp = await client.get(token_url, params={
            "appid": WECHAT_APP_ID,
            "secret": WECHAT_APP_SECRET,
            "code": request.code,
            "grant_type": "authorization_code",
        })
        token_data = resp.json()
        openid = token_data.get("openid")
        unionid = token_data.get("unionid")
        access_token_wechat = token_data.get("access_token")

        if not openid:
            raise HTTPException(status_code=400, detail=f"微信授权失败: {token_data}")

        # 2. 获取用户信息
        nickname = "微信用户"
        avatar = ""
        if access_token_wechat:
            user_url = "https://api.weixin.qq.com/sns/userinfo"
            resp = await client.get(user_url, params={
                "access_token": access_token_wechat,
                "openid": openid,
            })
            user_info = resp.json()
            nickname = user_info.get("nickname", "微信用户")
            avatar = user_info.get("headimgurl", "")
    
    db = get_db()
    now = datetime.now(timezone.utc).isoformat()
    
    # 查找已有用户 (通过 unionid 或 openid)
    row = db.execute("SELECT * FROM users WHERE wechat_unionid = ?", (unionid,)).fetchone()
    if not row:
        row = db.execute("SELECT * FROM users WHERE wechat_openid = ?", (openid,)).fetchone()
    
    if row:
        user_id = row["id"]
        name = row["name"]
        # 关联
        if not dict(row).get("wechat_unionid"):
            db.execute("UPDATE users SET wechat_unionid = ?, updated_at = ? WHERE id = ?",
                       (unionid, now, user_id))
            db.commit()
    else:
        user_id = f"wechat_{datetime.now().strftime('%Y%m%d%H%M%S')}"
        name = nickname
        db.execute("""
            INSERT INTO users (id, name, wechat_openid, wechat_unionid, life_stage, created_at, updated_at)
            VALUES (?, ?, ?, ?, 'exploration', ?, ?)
        """, (user_id, name, openid, unionid, now, now))
        
        legacy_token = generate_token()
        db.execute("INSERT INTO auth_tokens (token, user_id) VALUES (?, ?)", (legacy_token, user_id))
        db.commit()
        logger.info(f"[Wechat] 新用户创建: {user_id}")
    
    # 记录设备
    device_id = request.device_info.get("device_id") if request.device_info else None
    platform = request.device_info.get("platform", "android") if request.device_info else "android"
    if device_id:
        _get_or_create_device(db, user_id, device_id, platform)
    
    # 生成 JWT
    access_jti = __import__('uuid').uuid4().hex
    refresh_jti = __import__('uuid').uuid4().hex
    access_token = create_access_token(user_id, name, "", device_id=device_id, jti=access_jti)
    refresh_token = create_refresh_token(user_id, device_id=device_id, jti=refresh_jti)
    
    if device_id:
        _record_active_token(user_id, device_id, access_jti, refresh_jti)
    
    db.execute("UPDATE users SET last_active_at = ?, updated_at = ? WHERE id = ?",
               (now, now, user_id))
    db.commit()
    
    return {
        "success": True,
        "data": {
            "user": {
                "id": user_id,
                "name": name,
                "avatar_url": avatar,
                "auth_provider": "wechat",
            },
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "Bearer",
            "expires_in": 1800,
        }
    }


@router.post("/miniprogram/login", response_model=dict)
async def wechat_miniprogram_login(request: WechatMiniProgramLoginRequest):
    """
    微信小程序登录
    
    流程:
    1. 用 js_code 向微信服务器换取 session_key + openid
    2. 解密用户信息 (encryptedData + iv)
    3. 查找或创建用户
    4. 返回 JWT token
    
    TODO: 生产环境接入真实微信小程序 API
    """
    # 检查微信配置
    if not WECHAT_APP_ID or not WECHAT_APP_SECRET:
        logger.warning("Wechat APP_ID/SECRET not configured, miniprogram login disabled")
        raise HTTPException(
            status_code=503,
            detail="微信登录未开通",
        )

    # 真实小程序登录流程
    import httpx
    async with httpx.AsyncClient() as client:
        token_url = "https://api.weixin.qq.com/sns/jscode2session"
        resp = await client.get(token_url, params={
            "appid": WECHAT_APP_ID,
            "secret": WECHAT_APP_SECRET,
            "js_code": request.js_code,
            "grant_type": "authorization_code",
        })
        session_data = resp.json()
        openid = session_data.get("openid")

        if not openid:
            raise HTTPException(status_code=400, detail=f"小程序登录失败: {session_data}")

    db = get_db()
    now = datetime.now(timezone.utc).isoformat()

    row = db.execute("SELECT * FROM users WHERE wechat_openid = ?", (openid,)).fetchone()

    if row:
        user_id = row["id"]
        name = row["name"]
    else:
        user_id = f"mp_{datetime.now().strftime('%Y%m%d%H%M%S')}"
        name = "小程序用户"
        db.execute("""
            INSERT INTO users (id, name, wechat_openid, life_stage, created_at, updated_at)
            VALUES (?, ?, ?, 'exploration', ?, ?)
        """, (user_id, name, openid, now, now))
        
        legacy_token = generate_token()
        db.execute("INSERT INTO auth_tokens (token, user_id) VALUES (?, ?)", (legacy_token, user_id))
        db.commit()
    
    access_jti = __import__('uuid').uuid4().hex
    refresh_jti = __import__('uuid').uuid4().hex
    access_token = create_access_token(user_id, name, "", jti=access_jti)
    refresh_token = create_refresh_token(user_id, jti=refresh_jti)
    
    db.execute("UPDATE users SET last_active_at = ?, updated_at = ? WHERE id = ?",
               (now, now, user_id))
    db.commit()
    
    return {
        "success": True,
        "data": {
            "user": {
                "id": user_id,
                "name": name,
                "auth_provider": "wechat_miniprogram",
            },
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "Bearer",
            "expires_in": 1800,
        }
    }
