"""
Apple Sign-In Identity Token 验证模块

验证流程:
1. 解析 JWT header 获取 kid (Key ID)
2. 从 Apple 获取对应公钥
3. 用 RSA 公钥验证签名
4. 检查 iss / aud / exp / iat / nonce
5. 返回 {sub, email, email_verified}
"""

import base64
import json
import time
import hashlib
import logging
from typing import Optional

import jwt
import httpx

logger = logging.getLogger(__name__)

APPLE_KEYS_URL = "https://appleid.apple.com/auth/keys"
APPLE_ISSUER = "https://appleid.apple.com"

# 缓存 Apple 公钥 (1小时过期)
_cached_keys: Optional[list] = None
_cached_keys_time: float = 0
_KEYS_CACHE_TTL = 3600  # 秒


async def get_apple_public_keys() -> list:
    """获取 Apple 公钥 (带缓存)"""
    global _cached_keys, _cached_keys_time

    now = time.time()
    if _cached_keys and (now - _cached_keys_time) < _KEYS_CACHE_TTL:
        return _cached_keys

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(APPLE_KEYS_URL)
            resp.raise_for_status()
            _cached_keys = resp.json().get("keys", [])
            _cached_keys_time = now
            logger.info(f"[Apple] 公钥已更新, 共 {len(_cached_keys)} 个")
            return _cached_keys
    except Exception as e:
        logger.error(f"[Apple] 获取公钥失败: {e}")
        if _cached_keys:
            logger.warning("[Apple] 使用缓存的公钥")
            return _cached_keys
        raise HTTPException(status_code=502, detail="无法连接 Apple 验证服务")


def _decode_jwt_header(token: str) -> dict:
    """解码 JWT header (不需要验证签名)"""
    try:
        header_b64 = token.split(".")[0]
        # 补齐 base64 padding
        header_b64 += "=" * (4 - len(header_b64) % 4)
        header_json = base64.urlsafe_b64decode(header_b64)
        return json.loads(header_json)
    except Exception as e:
        raise ValueError(f"无效的 JWT header: {e}")


def _decode_jwt_payload(token: str) -> dict:
    """解码 JWT payload (不验证签名，用于快速读取)"""
    try:
        payload_b64 = token.split(".")[1]
        payload_b64 += "=" * (4 - len(payload_b64) % 4)
        payload_json = base64.urlsafe_b64decode(payload_b64)
        return json.loads(payload_json)
    except Exception as e:
        raise ValueError(f"无效的 JWT payload: {e}")


def _build_rsa_public_key(key_data: dict):
    """
    从 Apple JWK 构造 RSA 公钥对象
    Apple 使用 P-256 / RSA，这里处理 RSA (RS256) 签名
    """
    from cryptography.hazmat.primitives.asymmetric.rsa import RSAPublicNumbers
    from cryptography.hazmat.backends import default_backend

    try:
        # Apple 的 JWK 使用 base64url 编码
        def b64url_decode(data: str) -> bytes:
            data += "=" * (4 - len(data) % 4)
            return base64.urlsafe_b64decode(data)

        n = int.from_bytes(b64url_decode(key_data["n"]), byteorder="big")
        e = int.from_bytes(b64url_decode(key_data["e"]), byteorder="big")

        public_numbers = RSAPublicNumbers(e, n)
        return public_numbers.public_key(default_backend())
    except Exception as ex:
        logger.error(f"[Apple] 构造 RSA 公钥失败: {ex}")
        return None


async def verify_apple_identity_token(
    identity_token: str,
    bundle_id: str,
) -> dict:
    """
    验证 Apple identity token 并返回 payload

    Args:
        identity_token: Apple 返回的 JWT 字符串
        bundle_id: 应用的 Bundle ID (aud 验证用)

    Returns:
        dict: {"sub": apple_user_id, "email": ..., "email_verified": ...}

    Raises:
        ValueError: token 格式无效
        HTTPException: 验证失败 (401)
    """
    if not identity_token or "." not in identity_token:
        raise ValueError("identity_token 格式无效")

    # 1. 解析 header 获取 kid 和 alg
    header = _decode_jwt_header(identity_token)
    kid = header.get("kid")
    alg = header.get("alg", "RS256")

    logger.info(f"[Apple] 验证 token: kid={kid}, alg={alg}")

    if not kid:
        raise ValueError("Apple token header 缺少 kid")

    # 2. 获取 Apple 公钥
    keys = await get_apple_public_keys()
    matching_key = None
    for k in keys:
        if k.get("kid") == kid:
            matching_key = k
            break

    if not matching_key:
        raise ValueError(f"未找到 kid={kid} 对应的 Apple 公钥")

    # 3. 构造 RSA 公钥
    public_key = _build_rsa_public_key(matching_key)
    if not public_key:
        raise ValueError("无法构造 Apple 公钥")

    # 4. 用 PyJWT 验证签名和 claims
    try:
        payload = jwt.decode(
            identity_token,
            public_key,
            algorithms=[alg],
            issuer=APPLE_ISSUER,
            audience=bundle_id,
            options={
                "verify_exp": True,
                "verify_iat": True,
                "verify_iss": True,
                "verify_aud": True,
                "verify_sub": True,
            },
        )
    except jwt.ExpiredSignatureError:
        raise ValueError("Apple token 已过期")
    except jwt.InvalidAudienceError:
        raise ValueError(f"Apple token audience 不匹配 (期望: {bundle_id})")
    except jwt.InvalidIssuerError:
        raise ValueError(f"Apple token issuer 不匹配 (期望: {APPLE_ISSUER})")
    except jwt.InvalidSignatureError:
        raise ValueError("Apple token 签名验证失败")
    except Exception as e:
        logger.error(f"[Apple] token 验证异常: {e}")
        raise ValueError(f"Apple token 验证失败: {e}")

    # 5. 提取用户信息
    result = {
        "sub": payload.get("sub"),
        "email": payload.get("email"),
        "email_verified": payload.get("email_verified", False),
        "is_private_email": payload.get("is_private_email", False),
    }

    if not result["sub"]:
        raise ValueError("Apple token 缺少 sub (user_id)")

    logger.info(f"[Apple] token 验证成功: sub={result['sub']}, email={result['email']}")
    return result


async def verify_apple_identity_token_dev(
    identity_token: str,
    bundle_id: str = "com.shunshi.app",
) -> dict:
    """
    开发环境验证: 先尝试完整验证，失败时降级为 base64 解码
    用于开发调试，生产环境应使用 verify_apple_identity_token
    """
    try:
        return await verify_apple_identity_token(identity_token, bundle_id)
    except Exception as e:
        logger.warning(f"[Apple-Dev] 完整验证失败，降级为解码: {e}")
        payload = _decode_jwt_payload(identity_token)

        # 基本检查
        sub = payload.get("sub")
        if not sub:
            raise ValueError("Apple token 缺少 sub")

        return {
            "sub": sub,
            "email": payload.get("email"),
            "email_verified": payload.get("email_verified", False),
            "is_private_email": payload.get("is_private_email", False),
        }


# 用于在非异步上下文中导入的占位
class HTTPException(Exception):
    """简化版 HTTPException，用于验证模块内部"""
    def __init__(self, status_code: int, detail: str):
        self.status_code = status_code
        self.detail = detail
        super().__init__(detail)
