# 认证 API 路由
# 生产级升级: Token轮换 · 多设备管理 · 游客模式 · 账号安全 · 密码预留
from fastapi import APIRouter, HTTPException, Query, Depends, Header
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, timedelta, timezone
import os
import uuid
import json
import hashlib
import threading
import logging

logger = logging.getLogger(__name__)

try:
    import bcrypt
    _BCRYPT_AVAILABLE = True
except ImportError:
    _BCRYPT_AVAILABLE = False
    logger.warning("[Auth] bcrypt 未安装，回退到 SHA256 (仅开发环境可用)")

try:
    import jwt
    _JWT_AVAILABLE = True
except ImportError:
    _JWT_AVAILABLE = False
    logger.warning("[Auth] PyJWT 未安装，回退到随机 token")

from app.database.db import get_db

router = APIRouter(prefix="/api/v1/auth", tags=["认证"])

# ============ 配置 ============

JWT_SECRET = os.getenv("JWT_SECRET", "shunshi-dev-secret-change-in-production-2026")
JWT_ALGORITHM = "HS256"

# Token 过期时间（生产级缩短）
JWT_ACCESS_EXPIRE_MINUTES = 30       # Access Token 30分钟
JWT_REFRESH_EXPIRE_DAYS = 7          # Refresh Token 7天

# 多设备限制
MAX_DEVICES_PER_USER = 5

# 短信验证码限流
SMS_COOLDOWN_SECONDS = 60            # 同一手机号60秒冷却
SMS_DAILY_LIMIT = 5                  # 同一手机号每天最多5次

# 账号注销宽限期（天）
ACCOUNT_DELETE_GRACE_DAYS = 30

# HTTP Bearer security scheme (for Depends)
_bearer_scheme = HTTPBearer(auto_error=False)

# ============ 内存 Token 黑名单 (生产环境建议迁移到 Redis) ============
_token_blacklock: dict = {}          # token_jti -> 过期时间戳
_token_blacklock_lock = threading.Lock()

# ============ 内存 Token 活跃记录 (用于注销时立即失效) ============
_active_tokens: dict = {}            # user_id -> {device_id: {jti, refresh_jti, expires_at}}
_active_tokens_lock = threading.Lock()

# ============ 短信验证码限流 (内存存储, 生产环境建议迁移到 Redis) ============
_sms_rate_limit: dict = {}           # phone -> {"last_sent": timestamp, "daily_count": int, "date": "YYYY-MM-DD"}

# ============ Models ============

class RegisterRequest(BaseModel):
    email: str
    password: str
    name: Optional[str] = None

class LoginRequest(BaseModel):
    email: str
    password: str

class RefreshRequest(BaseModel):
    refresh_token: str

class GuestLoginRequest(BaseModel):
    """游客登录请求"""
    platform: str = "ios"
    device_id: Optional[str] = None
    device_name: Optional[str] = None

class DeviceKickRequest(BaseModel):
    """踢出设备请求"""
    reason: Optional[str] = None

class CancelDeleteRequest(BaseModel):
    """取消注销请求"""
    pass

class MemoryResetRequest(BaseModel):
    """清空AI记忆请求"""
    confirm: bool = Field(..., description="确认清空，需传 true")

class SmsSendRequest(BaseModel):
    """发送短信验证码"""
    phone: str = Field(..., pattern=r"^1[3-9]\d{9}$", description="中国大陆手机号")

class SmsVerifyRequest(BaseModel):
    """验证短信验证码"""
    phone: str = Field(..., pattern=r"^1[3-9]\d{9}$")
    code: str = Field(..., min_length=4, max_length=6)

class GuestConvertRequest(BaseModel):
    """游客转正式用户"""
    email: Optional[str] = None
    phone: Optional[str] = None
    password: Optional[str] = None
    name: Optional[str] = None

# ============ 密码 Hash (passlib 预留) ============

def hash_password(password: str) -> str:
    """bcrypt 密码哈希，不可用时回退到 SHA256"""
    if _BCRYPT_AVAILABLE:
        salt = bcrypt.gensalt()
        return bcrypt.hashpw(password.encode(), salt).decode()
    else:
        import hashlib
        return f"sha256:{hashlib.sha256(password.encode()).hexdigest()}"

def verify_password(password: str, password_hash: str) -> bool:
    """验证密码"""
    if not password_hash:
        return False
    if _BCRYPT_AVAILABLE and not password_hash.startswith("sha256:"):
        return bcrypt.checkpw(password.encode(), password_hash.encode())
    else:
        import hashlib
        expected = password_hash.replace("sha256:", "")
        return hashlib.sha256(password.encode()).hexdigest() == expected

# ============ JWT Token ============

def generate_token() -> str:
    """生成 legacy 随机 token (向后兼容)"""
    import random
    return ''.join(random.choices('abcdefghijklmnopqrstuvwxyz0123456789', k=32))

def create_access_token(user_id: str, username: str, email: str,
                        device_id: str = None, jti: str = None) -> str:
    """生成 JWT access token (30分钟过期)"""
    if not _JWT_AVAILABLE:
        return generate_token()
    
    now = datetime.now(timezone.utc)
    payload = {
        "sub": user_id,
        "username": username,
        "email": email,
        "type": "access",
        "jti": jti or str(uuid.uuid4()),
        "device_id": device_id,
        "exp": now + timedelta(minutes=JWT_ACCESS_EXPIRE_MINUTES),
        "iat": now,
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

def create_refresh_token(user_id: str, device_id: str = None, jti: str = None) -> str:
    """生成 JWT refresh token (7天过期)"""
    if not _JWT_AVAILABLE:
        return generate_token()
    
    now = datetime.now(timezone.utc)
    payload = {
        "sub": user_id,
        "type": "refresh",
        "jti": jti or str(uuid.uuid4()),
        "device_id": device_id,
        "exp": now + timedelta(days=JWT_REFRESH_EXPIRE_DAYS),
        "iat": now,
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

def decode_token(token: str) -> Optional[dict]:
    """解码并验证 JWT token"""
    if not _JWT_AVAILABLE:
        return None
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        # 检查是否在黑名单中
        jti = payload.get("jti")
        if jti and _is_token_blacklisted(jti):
            return None
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError as e:
        import logging; logging.getLogger(__name__).warning(f"JWT decode error: {e}")
        return None

def _is_token_blacklisted(jti: str) -> bool:
    """检查 token 是否在黑名单中"""
    with _token_blacklock_lock:
        if jti in _token_blacklock:
            if datetime.now(timezone.utc).timestamp() > _token_blacklock[jti]:
                del _token_blacklock[jti]
                return False
            return True
    return False

def _blacklist_token(jti: str, expires_at: float):
    """将 token 加入黑名单"""
    with _token_blacklock_lock:
        _token_blacklock[jti] = expires_at

def _cleanup_blacklist():
    """清理过期黑名单条目"""
    now = datetime.now(timezone.utc).timestamp()
    with _token_blacklock_lock:
        expired = [jti for jti, exp in _token_blacklock.items() if now > exp]
        for jti in expired:
            del _token_blacklock[jti]

# ============ 活跃 Token 管理 (注销/踢出时立即失效) ============

def _record_active_token(user_id: str, device_id: str, access_jti: str, refresh_jti: str):
    """记录活跃 token"""
    with _active_tokens_lock:
        if user_id not in _active_tokens:
            _active_tokens[user_id] = {}
        _active_tokens[user_id][device_id] = {
            "access_jti": access_jti,
            "refresh_jti": refresh_jti,
            "expires_at": datetime.now(timezone.utc).timestamp() + JWT_REFRESH_EXPIRE_DAYS * 86400,
        }

def _invalidate_user_tokens(user_id: str, device_id: str = None):
    """使指定用户(或设备)的所有 token 立即失效"""
    with _active_tokens_lock:
        if user_id not in _active_tokens:
            return
        devices = _active_tokens[user_id]
        target_devices = {device_id: devices[device_id]} if device_id else devices
        for dev_id, token_info in target_devices.items():
            now_ts = datetime.now(timezone.utc).timestamp()
            _blacklist_token(token_info["access_jti"], token_info["expires_at"])
            _blacklist_token(token_info["refresh_jti"], token_info["expires_at"])
            if device_id:
                del devices[dev_id]
                if not devices:
                    del _active_tokens[user_id]
            else:
                del _active_tokens[user_id]

# ============ 短信验证码管理 ============

_sms_codes: dict = {}  # phone -> {"code": str, "expires_at": timestamp, "verified": bool}

def _generate_sms_code() -> str:
    """生成6位验证码"""
    import random
    return ''.join(random.choices('0123456789', k=6))

def _can_send_sms(phone: str) -> tuple:
    """检查是否可以发送短信 (返回 (can_send, error_message))"""
    now = datetime.now(timezone.utc)
    today_str = now.strftime("%Y-%m-%d")
    
    if phone in _sms_rate_limit:
        info = _sms_rate_limit[phone]
        
        # 检查冷却期
        if now.timestamp() - info["last_sent"] < SMS_COOLDOWN_SECONDS:
            remaining = int(SMS_COOLDOWN_SECONDS - (now.timestamp() - info["last_sent"]))
            return False, f"请{remaining}秒后再试"
        
        # 检查每日限额
        if info["date"] == today_str and info["daily_count"] >= SMS_DAILY_LIMIT:
            return False, "今日验证码已达上限"
    
    return True, ""

def _send_sms_code(phone: str) -> str:
    """发送短信验证码（模拟，生产环境对接短信服务商）"""
    can_send, error = _can_send_sms(phone)
    if not can_send:
        raise HTTPException(status_code=429, detail=error)
    
    now = datetime.now(timezone.utc)
    today_str = now.strftime("%Y-%m-%d")
    code = _generate_sms_code()
    
    # 更新限流记录
    if phone in _sms_rate_limit and _sms_rate_limit[phone]["date"] == today_str:
        _sms_rate_limit[phone]["last_sent"] = now.timestamp()
        _sms_rate_limit[phone]["daily_count"] += 1
    else:
        _sms_rate_limit[phone] = {
            "last_sent": now.timestamp(),
            "daily_count": 1,
            "date": today_str,
        }
    
    # 存储验证码 (5分钟过期)
    _sms_codes[phone] = {
        "code": code,
        "expires_at": now.timestamp() + 300,
        "verified": False,
    }
    
    # 生产环境: 调用短信服务商 API
    # logger.info(f"[SMS] 发送验证码到 {phone}: {code}")
    logger.info(f"[SMS] 验证码已生成: phone={phone}, code={code}")
    
    return code

def _verify_sms_code(phone: str, code: str) -> bool:
    """验证短信验证码"""
    if phone not in _sms_codes:
        return False
    
    info = _sms_codes[phone]
    
    # 检查过期
    if datetime.now(timezone.utc).timestamp() > info["expires_at"]:
        del _sms_codes[phone]
        return False
    
    # 检查是否已验证
    if info["verified"]:
        return False
    
    # 验证码比对
    if info["code"] != code:
        return False
    
    # 标记已验证
    info["verified"] = True
    return True

# ============ 依赖注入 ============

async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(_bearer_scheme)
) -> dict:
    """
    FastAPI 依赖注入：从 Authorization header 解析当前用户
    - 优先解析 JWT token
    - 回退到数据库 token 查找 (向后兼容)
    """
    token = None
    if credentials:
        token = credentials.credentials
    
    import logging; logger.debug(f"[Auth] /me token received: {token[:20] if token else 'None'}...")
    if not token:
        # 返回匿名用户（演示模式）
        return {
            "id": "user-001",
            "email": "demo@shunshi.com",
            "name": "演示用户",
            "life_stage": "exploration",
            "is_premium": 0,
            "subscription_plan": "free",
        }
    
    # 尝试 JWT 解码
    if _JWT_AVAILABLE:
        payload = decode_token(token)
        logger.debug(f"[Auth] JWT payload: {payload.get('sub') if payload else 'None'}, type={payload.get('type') if payload else 'None'}")
        if payload and payload.get("type") == "access":
            # JWT 有效，查找用户补充完整信息
            db = get_db()
            row = db.execute("SELECT * FROM users WHERE id = ?", (payload["sub"],)).fetchone()
            if row:
                user = dict(row)
                # 检查账号是否已注销（软删除中）
                if user.get("status") == "deleted":
                    raise HTTPException(status_code=403, detail="账号已注销")
                return user
            else:
                return {
                    "id": payload["sub"],
                    "username": payload.get("username", ""),
                    "email": payload.get("email", ""),
                }
    
    # 回退: 数据库 token 查找 (向后兼容旧 token)
    db = get_db()
    row = db.execute(
        "SELECT u.* FROM users u JOIN auth_tokens t ON u.id = t.user_id WHERE t.token = ?",
        (token,)
    ).fetchone()
    if row:
        return dict(row)
    
    # 无效 token，返回演示用户
    return {
        "id": "user-001",
        "email": "demo@shunshi.com",
        "name": "演示用户",
        "life_stage": "exploration",
        "is_premium": 0,
        "subscription_plan": "free",
    }

def get_user_from_token(token: str) -> Optional[dict]:
    """通过 token 查找用户 (向后兼容)"""
    # 尝试 JWT
    if _JWT_AVAILABLE:
        payload = decode_token(token)
        if payload and payload.get("type") == "access":
            db = get_db()
            row = db.execute("SELECT u.* FROM users u WHERE u.id = ?", (payload["sub"],)).fetchone()
            if row:
                return dict(row)
    
    # 回退到数据库
    db = get_db()
    row = db.execute(
        "SELECT u.* FROM users u JOIN auth_tokens t ON u.id = t.user_id WHERE t.token = ?",
        (token,)
    ).fetchone()
    if row:
        return dict(row)
    return None

def _get_current_user_from_request(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(_bearer_scheme)
) -> dict:
    """
    FastAPI 依赖注入（严格模式）: 必须提供有效 token，否则返回401
    用于需要登录才能访问的接口
    """
    if not credentials:
        raise HTTPException(status_code=401, detail="未提供认证信息")
    
    token = credentials.credentials
    payload = None
    
    if _JWT_AVAILABLE:
        payload = decode_token(token)
    
    if payload and payload.get("type") == "access":
        db = get_db()
        row = db.execute("SELECT * FROM users WHERE id = ?", (payload["sub"],)).fetchone()
        if row:
            user = dict(row)
            if user.get("status") == "deleted":
                raise HTTPException(status_code=403, detail="账号已注销")
            return user
    
    # 回退
    db = get_db()
    row = db.execute(
        "SELECT u.* FROM users u JOIN auth_tokens t ON u.id = t.user_id WHERE t.token = ?",
        (token,)
    ).fetchone()
    if row:
        return dict(row)
    
    raise HTTPException(status_code=401, detail="Token 无效或已过期")

# ============ 设备管理辅助函数 ============

def _get_or_create_device(db, user_id: str, device_id: str, platform: str = "unknown",
                           device_name: str = None) -> dict:
    """获取或创建设备记录（使用 SQLite auth_tokens 扩展）"""
    if not device_id:
        device_id = f"gen_{uuid.uuid4().hex[:12]}"
    
    # 检查设备是否已存在
    existing = db.execute(
        "SELECT * FROM user_devices WHERE user_id = ? AND device_id = ?",
        (user_id, device_id)
    ).fetchone()
    
    now = datetime.now(timezone.utc).isoformat()
    
    if existing:
        # 更新最后活跃时间
        db.execute(
            "UPDATE user_devices SET last_active_at = ?, is_active = 1 WHERE user_id = ? AND device_id = ?",
            (now, user_id, device_id)
        )
        return dict(existing)
    else:
        # 检查设备数量限制
        devices = db.execute(
            "SELECT COUNT(*) as cnt FROM user_devices WHERE user_id = ? AND is_active = 1",
            (user_id,)
        ).fetchone()
        
        if devices["cnt"] >= MAX_DEVICES_PER_USER:
            # 踢出最久未活跃的设备
            oldest = db.execute(
                "SELECT device_id FROM user_devices WHERE user_id = ? AND is_active = 1 "
                "ORDER BY last_active_at ASC LIMIT 1",
                (user_id,)
            ).fetchone()
            if oldest:
                db.execute(
                    "UPDATE user_devices SET is_active = 0 WHERE device_id = ?",
                    (oldest["device_id"],)
                )
                logger.info(f"[Device] 踢出最久未活跃设备: {oldest['device_id']}")
        
        # 创建设备记录
        db.execute(
            "INSERT INTO user_devices (id, user_id, device_id, platform, device_name, "
            "last_active_at, is_active, created_at, updated_at) "
            "VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?)",
            (f"dev_{uuid.uuid4().hex[:12]}", user_id, device_id, platform,
             device_name or f"{platform} 设备", now, now, now)
        )
        db.commit()
        
        return {
            "user_id": user_id,
            "device_id": device_id,
            "platform": platform,
            "device_name": device_name or f"{platform} 设备",
            "last_active_at": now,
            "is_active": 1,
        }

# ============ API Endpoints (原有，保持签名不变) ============

@router.post("/register", response_model=dict)
async def register(request: RegisterRequest):
    """用户注册"""
    db = get_db()
    
    # 检查邮箱是否已存在
    existing = db.execute("SELECT id FROM users WHERE email = ?", (request.email,)).fetchone()
    if existing:
        raise HTTPException(status_code=400, detail="邮箱已被注册")
    
    # 创建用户
    user_id = f"user_{uuid.uuid4().hex[:12]}"
    now = datetime.now(timezone.utc).isoformat()
    
    db.execute("""
        INSERT INTO users (id, email, name, password_hash, life_stage, created_at, updated_at)
        VALUES (?, ?, ?, ?, 'exploration', ?, ?)
    """, (user_id, request.email, request.name or "用户", hash_password(request.password), now, now))
    
    # 生成 JWT token
    access_token = create_access_token(user_id, request.name or "用户", request.email)
    refresh_token = create_refresh_token(user_id)
    
    # 保存 legacy token 向后兼容
    legacy_token = generate_token()
    db.execute("INSERT INTO auth_tokens (token, user_id) VALUES (?, ?)", (legacy_token, user_id))
    db.commit()
    
    return {
        "success": True,
        "data": {
            "user": {
                "id": user_id,
                "email": request.email,
                "name": request.name or "用户",
                "life_stage": "exploration"
            },
            "token": access_token,
            "refresh_token": refresh_token,
            "token_type": "Bearer",
            "expires_in": JWT_ACCESS_EXPIRE_MINUTES * 60,
        }
    }

@router.post("/login", response_model=dict)
async def login(request: LoginRequest):
    """用户登录"""
    db = get_db()
    
    # 查找用户
    row = db.execute("SELECT * FROM users WHERE email = ?", (request.email,)).fetchone()
    
    if not row:
        # 创建演示用户（保留原始行为）
        user_id = "user-001"
        name = "演示用户"
        life_stage = "exploration"
        is_premium = 0
        subscription_plan = "free"
        pw_hash = ""
    else:
        user_id = row["id"]
        name = row["name"]
        life_stage = row["life_stage"]
        is_premium = row["is_premium"]
        subscription_plan = row["subscription_plan"]
        pw_hash = row["password_hash"]
    
    # 验证密码（如果有的话）
    if pw_hash and not verify_password(request.password, pw_hash):
        raise HTTPException(status_code=401, detail="密码错误")
    
    # 生成 JWT token
    access_token = create_access_token(user_id, name, request.email)
    refresh_token = create_refresh_token(user_id)
    
    # 保存 legacy token 向后兼容
    legacy_token = generate_token()
    db.execute("INSERT OR REPLACE INTO auth_tokens (token, user_id) VALUES (?, ?)", (legacy_token, user_id))
    
    # 更新最后活跃时间
    now = datetime.now(timezone.utc).isoformat()
    db.execute("UPDATE users SET last_active_at = ?, updated_at = ? WHERE id = ?",
               (now, now, user_id))
    db.commit()
    
    return {
        "success": True,
        "data": {
            "user": {
                "id": user_id,
                "email": request.email,
                "name": name,
                "life_stage": life_stage,
                "is_premium": bool(is_premium),
                "subscription_plan": subscription_plan
            },
            "token": access_token,
            "refresh_token": refresh_token,
            "token_type": "Bearer",
            "expires_in": JWT_ACCESS_EXPIRE_MINUTES * 60,
        }
    }

# ============ Token 轮换 ============

@router.post("/refresh", response_model=dict)
async def refresh_token(request: RefreshRequest):
    """
    刷新 access token (Token 轮换)
    - 验证 refresh_token
    - 生成新的 access_token 和 refresh_token
    - 旧 refresh_token 立即失效
    """
    if not _JWT_AVAILABLE:
        raise HTTPException(status_code=501, detail="PyJWT 未安装，不支持 token 刷新")
    
    payload = decode_token(request.refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="refresh token 无效或已过期")
    
    user_id = payload["sub"]
    device_id = payload.get("device_id")
    
    # 查找用户
    db = get_db()
    row = db.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    if not row:
        raise HTTPException(status_code=401, detail="用户不存在")
    
    user = dict(row)
    
    # 使旧 refresh_token 失效
    old_jti = payload.get("jti")
    if old_jti:
        old_exp = payload.get("exp", 0)
        if isinstance(old_exp, datetime):
            old_exp = old_exp.timestamp()
        _blacklist_token(old_jti, old_exp)
    
    # 生成新的 access token 和 refresh token (轮换)
    new_access_jti = str(uuid.uuid4())
    new_refresh_jti = str(uuid.uuid4())
    new_access_token = create_access_token(
        user_id, user["name"], user["email"],
        device_id=device_id, jti=new_access_jti
    )
    new_refresh_token = create_refresh_token(
        user_id, device_id=device_id, jti=new_refresh_jti
    )
    
    # 记录活跃 token（用于注销时立即失效）
    if device_id:
        _record_active_token(user_id, device_id, new_access_jti, new_refresh_jti)
    
    # 更新最后活跃时间
    now = datetime.now(timezone.utc).isoformat()
    db.execute("UPDATE users SET last_active_at = ?, updated_at = ? WHERE id = ?",
               (now, now, user_id))
    db.commit()
    
    return {
        "success": True,
        "data": {
            "token": new_access_token,
            "refresh_token": new_refresh_token,
            "token_type": "Bearer",
            "expires_in": JWT_ACCESS_EXPIRE_MINUTES * 60,
        }
    }

@router.get("/me", response_model=dict)
async def get_me(authorization: str = Header(None)):
    """获取当前用户信息"""
    token = None
    if authorization and authorization.startswith("Bearer "):
        token = authorization.replace("Bearer ", "")
    
    user = get_user_from_token(token) if token else None
    
    if not user:
        # 返回演示用户
        db = get_db()
        row = db.execute("SELECT * FROM users WHERE id = 'user-001'").fetchone()
        if row:
            user = dict(row)
        else:
            user = {"id": "user-001", "email": "demo@shunshi.com", "name": "演示用户",
                    "life_stage": "exploration", "is_premium": 0, "subscription_plan": "free"}
    
    return {
        "success": True,
        "data": {
            "id": user["id"],
            "email": user["email"],
            "name": user["name"],
            "life_stage": user["life_stage"],
            "is_premium": bool(user.get("is_premium", 0)),
            "subscription_plan": user.get("subscription_plan", "free")
        }
    }

@router.post("/logout", response_model=dict)
async def logout(authorization: str = Query(None)):
    """退出登录（使当前 token 立即失效）"""
    if authorization and authorization.startswith("Bearer "):
        token = authorization.replace("Bearer ", "")
        
        # JWT: 加入黑名单
        if _JWT_AVAILABLE:
            payload = decode_token(token)
            if payload:
                jti = payload.get("jti")
                exp = payload.get("exp", 0)
                if isinstance(exp, datetime):
                    exp = exp.timestamp()
                if jti:
                    _blacklist_token(jti, exp)
        
        # Legacy: 删除数据库 token
        db = get_db()
        db.execute("DELETE FROM auth_tokens WHERE token = ?", (token,))
        db.commit()
    
    return {"success": True, "message": "已退出登录"}


# ============ Google OAuth 登录 ============

class GoogleAuthRequest(BaseModel):
    google_id_token: str
    name: Optional[str] = None
    email: Optional[str] = None
    avatar_url: Optional[str] = None
    platform: Optional[str] = "ios"
    device_id: Optional[str] = None


@router.post("/google", response_model=dict)
async def google_auth(request: GoogleAuthRequest):
    """
    Google Sign-In 登录
    验证 google_id_token，创建或关联用户，返回 JWT
    """
    import aiohttp

    # 1. 验证 Google ID Token
    try:
        async with aiohttp.ClientSession() as session:
            verify_url = "https://oauth2.googleapis.com/tokeninfo"
            async with session.get(verify_url, params={"id_token": request.google_id_token}) as resp:
                if resp.status != 200:
                    raise HTTPException(status_code=401, detail="Google token verification failed")
                token_info = await resp.json()
    except aiohttp.ClientError as e:
        raise HTTPException(status_code=502, detail=f"Google verification service unavailable: {e}")

    google_user_id = token_info.get("sub")
    google_email = token_info.get("email", request.email)
    google_name = token_info.get("name", request.name or "User")
    google_picture = token_info.get("picture", request.avatar_url)

    if not google_user_id:
        raise HTTPException(status_code=401, detail="Invalid Google token: missing sub")

    db = get_db()
    now = datetime.now(timezone.utc).isoformat()

    # 2. 查找已有用户 (通过 google_id 或 email)
    row = db.execute("SELECT * FROM users WHERE google_id = ?", (google_user_id,)).fetchone()
    if not row and google_email:
        row = db.execute("SELECT * FROM users WHERE email = ?", (google_email,)).fetchone()

    if row:
        user_id = row["id"]
        name = row["name"]
        if not row.get("google_id"):
            db.execute("UPDATE users SET google_id = ?, updated_at = ? WHERE id = ?",
                       (google_user_id, now, user_id))
            db.commit()
    else:
        user_id = f"google_{datetime.now().strftime('%Y%m%d%H%M%S')}"
        name = google_name
        db.execute("""
            INSERT INTO users (id, name, email, avatar_url, google_id, life_stage, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, 'exploration', ?, ?)
        """, (user_id, name, google_email, google_picture, google_user_id, now, now))

        legacy_token = generate_token()
        db.execute("INSERT INTO auth_tokens (token, user_id) VALUES (?, ?)", (legacy_token, user_id))
        db.commit()

    # 记录设备
    if request.device_id:
        _get_or_create_device(db, user_id, request.device_id, request.platform)

    # 3. 生成 JWT
    email = google_email or row["email"] if row else ""
    device_id = request.device_id
    access_jti = str(uuid.uuid4())
    refresh_jti = str(uuid.uuid4())
    access_token = create_access_token(user_id, name, email, device_id=device_id, jti=access_jti)
    refresh_token = create_refresh_token(user_id, device_id=device_id, jti=refresh_jti)
    
    # 记录活跃 token
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
                "email": email,
                "name": name,
                "avatar_url": google_picture,
                "auth_provider": "google",
            },
            "token": access_token,
            "refresh_token": refresh_token,
            "token_type": "Bearer",
            "expires_in": JWT_ACCESS_EXPIRE_MINUTES * 60,
        }
    }


# ============ Apple Sign-In 登录 ============

APPLE_BUNDLE_ID = os.getenv("APPLE_BUNDLE_ID", "com.shunshi.app")
APPLE_TEAM_ID = os.getenv("APPLE_TEAM_ID", "")
APPLE_SERVICE_ID = os.getenv("APPLE_SERVICE_ID", "")
APPLE_KEY_ID = os.getenv("APPLE_KEY_ID", "")
APPLE_PRIVATE_KEY_PATH = os.getenv("APPLE_PRIVATE_KEY_PATH", "")


class AppleLoginRequest(BaseModel):
    identity_token: str
    authorization_code: Optional[str] = None
    name: Optional[str] = None
    email: Optional[str] = None
    platform: Optional[str] = "ios"
    device_id: Optional[str] = None


class AppleRefreshRequest(BaseModel):
    authorization_code: str


@router.post("/apple/login", response_model=dict)
async def apple_login(request: AppleLoginRequest):
    """
    Sign in with Apple 登录
    1. 验证 identity_token (JWT + Apple 公钥签名验证)
    2. 提取 user_id (sub), email
    3. 查找或创建用户
    4. 返回 access_token + refresh_token
    """
    from app.auth.apple_verify import (
        verify_apple_identity_token_dev,
        verify_apple_identity_token,
    )

    # 1. 验证 Apple identity token
    env = os.getenv("ENV", "dev")
    verify_fn = verify_apple_identity_token_dev if env == "dev" else verify_apple_identity_token

    try:
        token_data = await verify_fn(request.identity_token, APPLE_BUNDLE_ID)
    except ValueError as e:
        raise HTTPException(status_code=401, detail=f"Apple token 验证失败: {e}")

    apple_user_id = token_data["sub"]
    apple_email = token_data.get("email") or request.email
    is_private_email = token_data.get("is_private_email", False)

    if not apple_user_id:
        raise HTTPException(status_code=401, detail="Apple token 缺少 sub")

    # 2. authorization_code 处理 (生产环境可用来刷新获取用户信息)
    if request.authorization_code:
        logger.info(f"[Apple] 收到 authorization_code, apple_user_id={apple_user_id}")
        # 生产环境: 可调用 Apple 的 /auth/token 接口刷新用户信息
        # 但 Apple 只在首次登录返回 email 和 name

    db = get_db()
    now = datetime.now(timezone.utc).isoformat()

    # 3. 查找已有用户 (通过 apple_id 或 email)
    row = db.execute("SELECT * FROM users WHERE apple_id = ?", (apple_user_id,)).fetchone()
    if not row and apple_email and not is_private_email:
        row = db.execute("SELECT * FROM users WHERE email = ?", (apple_email,)).fetchone()

    if row:
        user_id = row["id"]
        name = row["name"]
        # 首次用 Apple 登录时关联已有账号
        if not row.get("apple_id"):
            db.execute("UPDATE users SET apple_id = ?, updated_at = ? WHERE id = ?",
                       (apple_user_id, now, user_id))
            db.commit()
            logger.info(f"[Apple] 关联已有用户: {user_id} -> apple_id={apple_user_id}")
    else:
        # 4. 创建新用户
        user_id = f"apple_{datetime.now().strftime('%Y%m%d%H%M%S')}"
        name = request.name or "Apple 用户"
        db.execute("""
            INSERT INTO users (id, name, email, apple_id, life_stage, created_at, updated_at)
            VALUES (?, ?, ?, ?, 'exploration', ?, ?)
        """, (user_id, name, apple_email, apple_user_id, now, now))

        legacy_token = generate_token()
        db.execute("INSERT INTO auth_tokens (token, user_id) VALUES (?, ?)", (legacy_token, user_id))
        db.commit()
        logger.info(f"[Apple] 新用户创建: {user_id}, email={apple_email}")

    # 记录设备
    if request.device_id:
        _get_or_create_device(db, user_id, request.device_id, request.platform)

    # 5. 生成 JWT
    email = apple_email or (row["email"] if row else "")
    device_id = request.device_id
    access_jti = str(uuid.uuid4())
    refresh_jti = str(uuid.uuid4())
    access_token = create_access_token(user_id, name, email, device_id=device_id, jti=access_jti)
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
                "email": email,
                "name": name,
                "auth_provider": "apple",
                "is_private_email": is_private_email,
            },
            "token": access_token,
            "refresh_token": refresh_token,
            "token_type": "Bearer",
            "expires_in": JWT_ACCESS_EXPIRE_MINUTES * 60,
        }
    }


@router.post("/apple/refresh", response_model=dict)
async def apple_refresh_token(request: AppleRefreshRequest):
    """
    用 Apple 的 authorization_code 刷新用户信息

    Apple 只在首次登录时返回 email 和 name，
    后续登录如需获取用户信息，需要通过 authorization_code 向 Apple 换取 refresh_token。
    """
    if not APPLE_TEAM_ID or not APPLE_SERVICE_ID or not APPLE_KEY_ID:
        raise HTTPException(
            status_code=501,
            detail="Apple Server-to-Server 未配置 (需要 APPLE_TEAM_ID, APPLE_SERVICE_ID, APPLE_KEY_ID)",
        )

    import httpx

    # 读取 Apple 私钥
    try:
        with open(APPLE_PRIVATE_KEY_PATH, "r") as f:
            private_key = f.read()
    except FileNotFoundError:
        raise HTTPException(status_code=500, detail=f"Apple 私钥文件不存在: {APPLE_PRIVATE_KEY_PATH}")

    # 构造 client_secret (JWT)
    now = datetime.now(timezone.utc)
    client_secret_payload = {
        "iss": APPLE_TEAM_ID,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(hours=1)).timestamp()),
        "aud": "https://appleid.apple.com",
        "sub": APPLE_SERVICE_ID,
    }
    if not _JWT_AVAILABLE:
        raise HTTPException(status_code=501, detail="PyJWT 未安装")

    client_secret = jwt.encode(
        client_secret_payload,
        private_key,
        algorithm="ES256",
        headers={"kid": APPLE_KEY_ID},
    )

    # 用 authorization_code 换取 Apple refresh_token
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(
                "https://appleid.apple.com/auth/token",
                data={
                    "client_id": APPLE_SERVICE_ID,
                    "client_secret": client_secret,
                    "code": request.authorization_code,
                    "grant_type": "authorization_code",
                },
            )
            resp.raise_for_status()
            token_response = resp.json()
    except Exception as e:
        logger.error(f"[Apple] 刷新 token 失败: {e}")
        raise HTTPException(status_code=502, detail=f"Apple token 刷新失败: {e}")

    # 返回 Apple 的 refresh_token (不存储，由客户端保存)
    # Apple 的 access_token 有效期仅 1 小时
    return {
        "success": True,
        "data": {
            "apple_access_token": token_response.get("access_token"),
            "expires_in": token_response.get("expires_in", 3600),
            "token_type": token_response.get("token_type", "Bearer"),
        },
    }


# 保留旧路由兼容 (不带 /login 后缀)
@router.post("/apple", response_model=dict)
async def apple_auth(request: AppleLoginRequest):
    """向后兼容: /apple -> /apple/login"""
    return await apple_login(request)


# ============ 短信验证码 ============

@router.post("/sms/send", response_model=dict)
async def send_sms_code(request: SmsSendRequest):
    """
    发送短信验证码
    - 同一手机号60秒冷却
    - 同一手机号每天最多5次
    """
    code = _send_sms_code(request.phone)
    
    return {
        "success": True,
        "message": "验证码已发送",
        # 开发环境返回验证码，生产环境应移除
        "_debug_code": code if os.getenv("ENV", "dev") != "production" else None,
    }

@router.post("/sms/verify", response_model=dict)
async def verify_sms_code(request: SmsVerifyRequest):
    """
    验证短信验证码
    """
    if _verify_sms_code(request.phone, request.code):
        return {"success": True, "message": "验证码正确"}
    else:
        raise HTTPException(status_code=400, detail="验证码错误或已过期")


# ============ 游客模式 ============

@router.post("/guest-login", response_model=dict)
async def guest_login(request: GuestLoginRequest):
    """
    游客登录 — 自动生成临时账号
    - 创建 guest_xxx 格式用户
    - 游客可正常使用免费功能
    - 游客转正式用户时保留数据
    """
    db = get_db()
    now = datetime.now(timezone.utc).isoformat()
    
    # 生成游客用户
    user_id = f"guest_{uuid.uuid4().hex[:12]}"
    device_id = request.device_id or f"guest_dev_{uuid.uuid4().hex[:8]}"
    
    db.execute("""
        INSERT INTO users (id, name, life_stage, created_at, updated_at)
        VALUES (?, '游客用户', 'exploration', ?, ?)
    """, (user_id, now, now))
    
    # 创建设备记录
    _get_or_create_device(db, user_id, device_id, request.platform, request.device_name)
    
    # 生成 JWT
    access_jti = str(uuid.uuid4())
    refresh_jti = str(uuid.uuid4())
    access_token = create_access_token(user_id, "游客用户", "", device_id=device_id, jti=access_jti)
    refresh_token = create_refresh_token(user_id, device_id=device_id, jti=refresh_jti)
    
    # 记录活跃 token
    _record_active_token(user_id, device_id, access_jti, refresh_jti)
    
    db.commit()
    
    return {
        "success": True,
        "data": {
            "user": {
                "id": user_id,
                "name": "游客用户",
                "is_guest": True,
                "auth_provider": "guest",
            },
            "token": access_token,
            "refresh_token": refresh_token,
            "token_type": "Bearer",
            "expires_in": JWT_ACCESS_EXPIRE_MINUTES * 60,
        }
    }

@router.post("/guest/convert", response_model=dict)
async def guest_convert(
    request: GuestConvertRequest,
    user: dict = Depends(_get_current_user_from_request),
):
    """
    游客转正式用户 — 保留所有数据
    """
    db = get_db()
    user_id = user["id"]
    
    # 验证是游客用户
    if not user_id.startswith("guest_") and user.get("auth_provider") != "guest":
        raise HTTPException(status_code=400, detail="当前账号不是游客账号")
    
    now = datetime.now(timezone.utc).isoformat()
    
    # 检查邮箱/手机号唯一性
    if request.email:
        existing = db.execute("SELECT id FROM users WHERE email = ? AND id != ?",
                             (request.email, user_id)).fetchone()
        if existing:
            raise HTTPException(status_code=400, detail="邮箱已被注册")
    
    if request.phone:
        existing = db.execute("SELECT id FROM users WHERE phone = ? AND id != ?",
                             (request.phone, user_id)).fetchone()
        if existing:
            raise HTTPException(status_code=400, detail="手机号已被注册")
    
    # 更新用户信息（保留 ID，数据不丢失）
    updates = []
    params = []
    
    if request.email:
        updates.append("email = ?")
        params.append(request.email)
    if request.phone:
        updates.append("phone = ?")
        params.append(request.phone)
    if request.password:
        updates.append("password_hash = ?")
        params.append(hash_password(request.password))
    if request.name:
        updates.append("name = ?")
        params.append(request.name)
    
    updates.extend(["auth_provider = ?", "updated_at = ?"])
    params.extend(["phone" if request.phone else ("email" if request.email else "manual"), now])
    
    if updates:
        params.append(user_id)
        db.execute(f"UPDATE users SET {', '.join(updates)} WHERE id = ?", params)
    
    db.commit()
    
    # 返回新的 token
    name = request.name or user["name"]
    email = request.email or user.get("email", "")
    access_token = create_access_token(user_id, name, email)
    refresh_token = create_refresh_token(user_id)
    
    return {
        "success": True,
        "message": "已转为正式用户，所有数据已保留",
        "data": {
            "user": {
                "id": user_id,
                "email": request.email,
                "name": name,
                "is_guest": False,
            },
            "token": access_token,
            "refresh_token": refresh_token,
        }
    }


# ============ 多设备登录管理 ============

@router.get("/devices", response_model=dict)
async def list_devices(
    user: dict = Depends(_get_current_user_from_request),
):
    """获取已登录设备列表"""
    db = get_db()
    user_id = user["id"]
    
    # 确保设备表存在
    _ensure_user_devices_table(db)
    
    devices = db.execute(
        "SELECT * FROM user_devices WHERE user_id = ? ORDER BY last_active_at DESC",
        (user_id,)
    ).fetchall()
    
    device_list = []
    for d in devices:
        device_list.append({
            "device_id": d["device_id"],
            "platform": d["platform"],
            "device_name": d.get("device_name", ""),
            "last_active_at": d["last_active_at"],
            "is_active": bool(d["is_active"]),
        })
    
    return {
        "success": True,
        "data": {
            "devices": device_list,
            "active_count": len([d for d in device_list if d["is_active"]]),
            "max_devices": MAX_DEVICES_PER_USER,
        }
    }

@router.delete("/devices/{device_id}", response_model=dict)
async def kick_device(
    device_id: str,
    user: dict = Depends(_get_current_user_from_request),
):
    """
    踢出指定设备 — 该设备的所有 token 立即失效
    """
    db = get_db()
    user_id = user["id"]
    
    # 验证设备属于当前用户
    device = db.execute(
        "SELECT * FROM user_devices WHERE user_id = ? AND device_id = ?",
        (user_id, device_id)
    ).fetchone()
    
    if not device:
        raise HTTPException(status_code=404, detail="设备不存在或不属于当前用户")
    
    # 使该设备的所有 token 失效
    _invalidate_user_tokens(user_id, device_id)
    
    # 标记设备为不活跃
    now = datetime.now(timezone.utc).isoformat()
    db.execute(
        "UPDATE user_devices SET is_active = 0, updated_at = ? WHERE device_id = ?",
        (now, device_id)
    )
    db.commit()
    
    logger.info(f"[Device] 设备已踢出: user={user_id}, device={device_id}")
    
    return {
        "success": True,
        "message": f"设备 {device_id} 已踢出",
    }


# ============ 账号安全 ============

@router.delete("/account", response_model=dict)
async def delete_account(
    user: dict = Depends(_get_current_user_from_request),
):
    """
    注销账号（软删除）
    - 30天后硬删除
    - 期间可取消注销
    - 注销后所有 token 立即失效
    """
    db = get_db()
    user_id = user["id"]
    now = datetime.now(timezone.utc)
    now_iso = now.isoformat()
    
    # 游客账号直接删除
    if user_id.startswith("guest_"):
        _invalidate_user_tokens(user_id)
        db.execute("DELETE FROM users WHERE id = ?", (user_id,))
        db.commit()
        return {"success": True, "message": "游客账号已删除"}
    
    # 计算硬删除日期
    hard_delete_at = (now + timedelta(days=ACCOUNT_DELETE_GRACE_DAYS)).isoformat()
    
    # 软删除
    db.execute(
        "UPDATE users SET status = 'deleted', updated_at = ? WHERE id = ?",
        (now_iso, user_id)
    )
    
    # 记录注销计划（利用 user_memory 表或单独字段）
    # 暂时用 user_settings 记录
    db.execute("""
        INSERT OR REPLACE INTO user_settings (user_id, scheduled_delete_at, updated_at)
        VALUES (?, ?, ?)
    """, (user_id, hard_delete_at, now_iso))
    
    # 使所有 token 立即失效
    _invalidate_user_tokens(user_id)
    
    db.commit()
    
    logger.info(f"[Account] 账号已软删除: user={user_id}, hard_delete_at={hard_delete_at}")
    
    return {
        "success": True,
        "message": f"账号已注销，{ACCOUNT_DELETE_GRACE_DAYS}天后将永久删除",
        "data": {
            "hard_delete_at": hard_delete_at,
            "grace_days": ACCOUNT_DELETE_GRACE_DAYS,
        }
    }

@router.post("/account/cancel-delete", response_model=dict)
async def cancel_delete_account(
    request: CancelDeleteRequest,
    user: dict = Depends(_get_current_user_from_request),
):
    """取消账号注销 — 恢复为正常状态"""
    db = get_db()
    user_id = user["id"]
    now = datetime.now(timezone.utc).isoformat()
    
    # 检查当前是否处于删除状态
    if user.get("status") != "deleted":
        raise HTTPException(status_code=400, detail="账号不在注销状态")
    
    # 恢复账号
    db.execute(
        "UPDATE users SET status = 'active', updated_at = ? WHERE id = ?",
        (now, user_id)
    )
    
    # 清除注销计划
    db.execute("""
        UPDATE user_settings SET scheduled_delete_at = NULL, updated_at = ? WHERE user_id = ?
    """, (now, user_id))
    
    db.commit()
    
    logger.info(f"[Account] 账号注销已取消: user={user_id}")
    
    return {
        "success": True,
        "message": "账号已恢复正常",
    }

@router.post("/data/export", response_model=dict)
async def export_user_data(
    user: dict = Depends(_get_current_user_from_request),
):
    """
    导出用户数据（JSON格式）
    - 包含用户基本信息、对话、记忆、订阅等
    - 符合数据隐私法规要求
    """
    db = get_db()
    user_id = user["id"]
    
    export_data = {
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "user_id": user_id,
        "user": {
            "id": user["id"],
            "email": user.get("email"),
            "name": user.get("name"),
            "phone": user.get("phone"),
            "life_stage": user.get("life_stage"),
            "created_at": user.get("created_at"),
        },
        "conversations": [],
        "memories": [],
        "settings": {},
        "subscriptions": [],
        "purchase_history": [],
    }
    
    # 导出对话
    try:
        convs = db.execute(
            "SELECT id, title, created_at, updated_at FROM conversations WHERE user_id = ?",
            (user_id,)
        ).fetchall()
        for c in convs:
            conv_data = {
                "id": c["id"],
                "title": c["title"],
                "created_at": c["created_at"],
                "messages": [],
            }
            msgs = db.execute(
                "SELECT role, content, created_at FROM messages WHERE conversation_id = ? ORDER BY created_at",
                (c["id"],)
            ).fetchall()
            for m in msgs:
                conv_data["messages"].append({
                    "role": m["role"],
                    "content": m["content"],
                    "created_at": m["created_at"],
                })
            export_data["conversations"].append(conv_data)
    except Exception as e:
        logger.warning(f"[Export] 导出对话失败: {e}")
    
    # 导出记忆
    try:
        memories = db.execute(
            "SELECT type, content, confidence, source, created_at FROM user_memory WHERE user_id = ?",
            (user_id,)
        ).fetchall()
        for m in memories:
            export_data["memories"].append({
                "type": m["type"],
                "content": m["content"],
                "confidence": m["confidence"],
                "source": m["source"],
                "created_at": m["created_at"],
            })
    except Exception as e:
        logger.warning(f"[Export] 导出记忆失败: {e}")
    
    # 导出设置
    try:
        settings = db.execute(
            "SELECT * FROM user_settings WHERE user_id = ?",
            (user_id,)
        ).fetchone()
        if settings:
            export_data["settings"] = dict(settings)
    except Exception as e:
        logger.warning(f"[Export] 导出设置失败: {e}")
    
    # 导出订阅历史
    try:
        subs = db.execute(
            "SELECT plan, price, platform, subscribed_at FROM purchase_history WHERE user_id = ? ORDER BY subscribed_at DESC",
            (user_id,)
        ).fetchall()
        for s in subs:
            export_data["purchase_history"].append(dict(s))
    except Exception as e:
        logger.warning(f"[Export] 导出订阅失败: {e}")
    
    return {
        "success": True,
        "data": export_data,
    }

@router.post("/memory/reset", response_model=dict)
async def reset_ai_memory(
    request: MemoryResetRequest,
    user: dict = Depends(_get_current_user_from_request),
):
    """清空AI记忆 — 不可恢复"""
    if not request.confirm:
        raise HTTPException(status_code=400, detail="请确认清空操作")
    
    db = get_db()
    user_id = user["id"]
    
    # 清空 user_memory 表
    deleted = db.execute(
        "DELETE FROM user_memory WHERE user_id = ?",
        (user_id,)
    ).rowcount
    
    db.commit()
    
    logger.info(f"[Memory] AI记忆已清空: user={user_id}, deleted={deleted}")
    
    return {
        "success": True,
        "message": f"AI记忆已清空（共{deleted}条）",
        "data": {"deleted_count": deleted}
    }


# ============ 辅助函数: 确保设备表存在 ============

def _ensure_user_devices_table(db):
    """确保 user_devices 表存在（兼容旧数据库）"""
    try:
        db.execute("SELECT 1 FROM user_devices LIMIT 1")
    except Exception:
        db.execute("""
            CREATE TABLE IF NOT EXISTS user_devices (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                device_id TEXT NOT NULL,
                platform TEXT DEFAULT 'unknown',
                device_name TEXT DEFAULT '',
                push_token TEXT,
                app_version TEXT,
                os_version TEXT,
                last_active_at TEXT,
                is_active INTEGER DEFAULT 1,
                created_at TEXT DEFAULT (datetime('now')),
                updated_at TEXT DEFAULT (datetime('now'))
            )
        """)
        db.execute("CREATE INDEX IF NOT EXISTS idx_user_devices_user ON user_devices(user_id)")
        db.execute("CREATE INDEX IF NOT EXISTS idx_user_devices_device ON user_devices(device_id)")
        db.commit()
