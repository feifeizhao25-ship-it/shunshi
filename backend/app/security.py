"""JWT 签发/校验与密码散列。密钥只走环境变量，未配置时 fail-closed。"""

import hashlib
import hmac
import threading
import uuid
from collections.abc import Iterable
from datetime import datetime, timedelta, timezone

import jwt
from fastapi import HTTPException

from .config import Settings

_revoked_jtis: dict[str, float] = {}
_revoked_lock = threading.Lock()


def token_now() -> float:
    """签发、校验、注销黑名单共用的 Unix 时间。

    PyJWT 用 ``datetime.now()`` 检查 iat/nbf/exp，签发以前用 ``time.time()``。
    时钟回放把 ``time.time`` 钉在过去时，新令牌的 exp 会早于校验时钟，立刻被拒绝；
    钉在未来时，注销记录又会按另一只钟被清掉。两边都走这里。
    生产环境就是当前 UTC：exp、nbf、iat 照常检查，不加 leeway。
    """
    return datetime.now(timezone.utc).timestamp()


class _SameClockJWT(jwt.PyJWT):
    """与 PyJWT 相同的声明校验，只把 iat/nbf/exp 的时钟换成 ``token_now``。"""

    def _validate_claims(
        self,
        payload,
        options,
        audience=None,
        issuer=None,
        subject=None,
        leeway=0,
    ):
        if isinstance(leeway, timedelta):
            leeway = leeway.total_seconds()
        if audience is not None and not isinstance(audience, (str, Iterable)):
            raise TypeError("audience must be a string, iterable or None")

        self._validate_required_claims(payload, options["require"])
        now = float(token_now())
        if "iat" in payload and options["verify_iat"]:
            self._validate_iat(payload, now, leeway)
        if "nbf" in payload and options["verify_nbf"]:
            self._validate_nbf(payload, now, leeway)
        if "exp" in payload and options["verify_exp"]:
            self._validate_exp(payload, now, leeway)
        if options["verify_iss"]:
            self._validate_iss(payload, issuer)
        if options["verify_aud"]:
            self._validate_aud(payload, audience, strict=options.get("strict_aud", False))
        if options["verify_sub"]:
            self._validate_sub(payload, subject)
        if options["verify_jti"]:
            self._validate_jti(payload)


_decoder = _SameClockJWT()


def _decode(token: str, secret: str) -> dict:
    return _decoder.decode(token, secret, algorithms=["HS256"])


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
    now = int(token_now())
    payload = {
        "sub": user_id,
        "jti": uuid.uuid4().hex,
        "iat": now,
        "exp": now + settings.jwt_ttl_seconds,
    }
    return {
        "access_token": jwt.encode(payload, secret, algorithm="HS256"),
        "token_type": "bearer",
        "expires_in": settings.jwt_ttl_seconds,
    }


def verify_token(settings: Settings, token: str) -> str:
    secret = _require_secret(settings)
    try:
        payload = _decode(token, secret)
        if payload.get("type") == "refresh":
            # 登录接口签发的 refresh token（30 天）与 access token 同一把密钥；
            # 不拦的话 refresh token 就能当 access token 用，过期时间从 1 小时变成 30 天。
            raise HTTPException(status_code=401, detail="登录状态已失效")
        jti = payload.get("jti")
        now = token_now()
        with _revoked_lock:
            expired = [key for key, exp in _revoked_jtis.items() if exp <= now]
            for key in expired:
                _revoked_jtis.pop(key, None)
            if jti and jti in _revoked_jtis:
                raise HTTPException(status_code=401, detail="登录状态已失效")
        return str(payload["sub"])
    except HTTPException:
        raise
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="登录状态已失效") from None


def revoke_token(settings: Settings, token: str) -> None:
    secret = _require_secret(settings)
    try:
        payload = _decode(token, secret)
    except jwt.PyJWTError:
        return
    jti = payload.get("jti")
    exp = float(payload.get("exp", token_now()))
    if jti:
        with _revoked_lock:
            _revoked_jtis[str(jti)] = exp


def hash_password(password: str, salt: str) -> str:
    return hashlib.scrypt(password.encode(), salt=salt.encode(), n=16384, r=8, p=1).hex()


def check_password(password: str, salt: str, expected: str) -> bool:
    return hmac.compare_digest(hash_password(password, salt), expected)


def hash_sms_code(secret: str, phone: str, code: str) -> str:
    return hmac.new(secret.encode(), f"{phone}:{code}".encode(), hashlib.sha256).hexdigest()
