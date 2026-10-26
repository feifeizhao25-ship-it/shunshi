"""JWT 签发/校验与密码散列。密钥只走环境变量，未配置时 fail-closed。"""

import hashlib
import hmac
import time

import jwt
from fastapi import HTTPException

from .config import Settings


def _require_secret(settings: Settings) -> str:
    if not settings.jwt_secret:
        # fail-closed：不假发 token、不假校验通过
        raise HTTPException(
            status_code=503,
            detail={"detail": "认证服务未配置（缺少 SHUNSHI_JWT_SECRET）", "configured": False},
        )
    return settings.jwt_secret


def issue_token(settings: Settings, user_id: str) -> dict:
    secret = _require_secret(settings)
    now = int(time.time())
    payload = {"sub": user_id, "iat": now, "exp": now + settings.jwt_ttl_seconds}
    return {
        "access_token": jwt.encode(payload, secret, algorithm="HS256"),
        "token_type": "bearer",
        "expires_in": settings.jwt_ttl_seconds,
    }


def verify_token(settings: Settings, token: str) -> str:
    secret = _require_secret(settings)
    try:
        payload = jwt.decode(token, secret, algorithms=["HS256"])
        return str(payload["sub"])
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="登录状态已失效") from None


def hash_password(password: str, salt: str) -> str:
    return hashlib.scrypt(password.encode(), salt=salt.encode(), n=16384, r=8, p=1).hex()


def check_password(password: str, salt: str, expected: str) -> bool:
    return hmac.compare_digest(hash_password(password, salt), expected)


def hash_sms_code(secret: str, phone: str, code: str) -> str:
    return hmac.new(secret.encode(), f"{phone}:{code}".encode(), hashlib.sha256).hexdigest()
