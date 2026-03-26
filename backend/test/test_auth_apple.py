"""
Apple Sign-In 验证测试
用 mock 数据测试 apple_verify.py 的验证逻辑
"""

import base64
import json
import pytest
from unittest.mock import AsyncMock, patch, MagicMock

# Mock Apple 公钥 (测试用)
MOCK_APPLE_PRIVATE_KEY_PEM = """-----BEGIN PRIVATE KEY-----
MIGHAgEA淇?... (mock key, not real)
-----END PRIVATE KEY-----"""


def _make_mock_jwt(payload: dict, kid: str = "mock-kid-1") -> str:
    """
    构造 mock JWT (不签名，仅用于测试解码逻辑)
    """
    header = {"alg": "RS256", "kid": kid, "typ": "JWT"}
    header_b64 = base64.urlsafe_b64encode(json.dumps(header).encode()).decode().rstrip("=")
    payload_b64 = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip("=")
    # mock signature (just some bytes)
    sig_b64 = base64.urlsafe_b64encode(b"mock-signature").decode().rstrip("=")
    return f"{header_b64}.{payload_b64}.{sig_b64}"


def _make_valid_apple_token() -> str:
    """构造一个模拟的有效 Apple identity token"""
    payload = {
        "iss": "https://appleid.apple.com",
        "aud": "com.shunshi.app",
        "exp": 9999999999,  # far future
        "iat": 1700000000,
        "sub": "001234.abcd1234efgh5678.0901",
        "email": "test@privaterelay.appleid.com",
        "email_verified": True,
        "is_private_email": True,
        "auth_time": 1700000000,
    }
    return _make_mock_jwt(payload)


def _make_expired_apple_token() -> str:
    """构造一个过期的 Apple token"""
    payload = {
        "iss": "https://appleid.apple.com",
        "aud": "com.shunshi.app",
        "exp": 1000000000,  # expired
        "iat": 999999000,
        "sub": "001234.abcd1234efgh5678.0901",
        "email": "test@example.com",
        "email_verified": True,
    }
    return _make_mock_jwt(payload)


def _make_bad_audience_token() -> str:
    """构造一个 audience 不匹配的 token"""
    payload = {
        "iss": "https://appleid.apple.com",
        "aud": "com.other.app",
        "exp": 9999999999,
        "iat": 1700000000,
        "sub": "001234.abcd1234efgh5678.0901",
        "email": "test@example.com",
        "email_verified": True,
    }
    return _make_mock_jwt(payload)


def _make_missing_sub_token() -> str:
    """构造一个缺少 sub 的 token"""
    payload = {
        "iss": "https://appleid.apple.com",
        "aud": "com.shunshi.app",
        "exp": 9999999999,
        "iat": 1700000000,
        "email": "test@example.com",
    }
    return _make_mock_jwt(payload)


class TestAppleJWTDecode:
    """测试 JWT 解码 (不依赖网络)"""

    def test_decode_header(self):
        """测试解码 JWT header"""
        from app.auth.apple_verify import _decode_jwt_header

        token = _make_valid_apple_token()
        header = _decode_jwt_header(token)

        assert header["alg"] == "RS256"
        assert header["kid"] == "mock-kid-1"
        assert header["typ"] == "JWT"

    def test_decode_payload(self):
        """测试解码 JWT payload"""
        from app.auth.apple_verify import _decode_jwt_payload

        token = _make_valid_apple_token()
        payload = _decode_jwt_payload(token)

        assert payload["sub"] == "001234.abcd1234efgh5678.0901"
        assert payload["email"] == "test@privaterelay.appleid.com"
        assert payload["iss"] == "https://appleid.apple.com"
        assert payload["aud"] == "com.shunshi.app"

    def test_invalid_token_format(self):
        """测试无效 token 格式"""
        from app.auth.apple_verify import _decode_jwt_header, _decode_jwt_payload

        with pytest.raises(ValueError):
            _decode_jwt_header("not-a-jwt")

        with pytest.raises(ValueError):
            _decode_jwt_payload("not-a-jwt")


class TestAppleDevVerification:
    """测试开发环境验证 (降级模式)"""

    @pytest.mark.asyncio
    async def test_dev_verify_valid_token(self):
        """开发环境: 有效 token 应该成功"""
        from app.auth.apple_verify import verify_apple_identity_token_dev

        token = _make_valid_apple_token()
        result = await verify_apple_identity_token_dev(token, "com.shunshi.app")

        assert result["sub"] == "001234.abcd1234efgh5678.0901"
        assert result["email"] == "test@privaterelay.appleid.com"
        assert result["email_verified"] is True
        assert result["is_private_email"] is True

    @pytest.mark.asyncio
    async def test_dev_verify_missing_sub(self):
        """开发环境: 缺少 sub 应该失败"""
        from app.auth.apple_verify import verify_apple_identity_token_dev

        token = _make_missing_sub_token()

        with pytest.raises(ValueError, match="sub"):
            await verify_apple_identity_token_dev(token)

    @pytest.mark.asyncio
    async def test_dev_verify_empty_token(self):
        """开发环境: 空 token 应该失败"""
        from app.auth.apple_verify import verify_apple_identity_token_dev

        with pytest.raises(ValueError):
            await verify_apple_identity_token_dev("", "com.shunshi.app")

        with pytest.raises(ValueError):
            await verify_apple_identity_token_dev("abc", "com.shunshi.app")


class TestAppleGetKeys:
    """测试 Apple 公钥获取 (mock 网络)"""

    @pytest.mark.asyncio
    async def test_get_keys_success(self):
        """测试成功获取公钥"""
        from app.auth import apple_verify

        mock_keys = [
            {"kid": "key-1", "kty": "RSA", "n": "...", "e": "...", "alg": "RS256"},
            {"kid": "key-2", "kty": "RSA", "n": "...", "e": "...", "alg": "RS256"},
        ]

        mock_response = MagicMock()
        mock_response.json.return_value = {"keys": mock_keys}
        mock_response.raise_for_status = MagicMock()

        mock_client = AsyncMock()
        mock_client.__aenter__ = AsyncMock(return_value=mock_client)
        mock_client.__aexit__ = AsyncMock(return_value=False)
        mock_client.get = AsyncMock(return_value=mock_response)

        # 清除缓存，确保 mock 生效
        apple_verify._cached_keys = None

        with patch("app.auth.apple_verify.httpx.AsyncClient", return_value=mock_client):
            keys = await apple_verify.get_apple_public_keys()
            assert len(keys) == 2
            assert keys[0]["kid"] == "key-1"


class TestAppleLoginEndpoint:
    """测试 /auth/apple/login 端点"""

    @pytest.mark.asyncio
    async def test_apple_login_success(self):
        """测试 Apple 登录成功"""
        from app.auth.apple_verify import verify_apple_identity_token_dev

        # Mock 验证函数
        mock_token_data = {
            "sub": "001234.test1234",
            "email": "user@icloud.com",
            "email_verified": True,
            "is_private_email": False,
        }

        with patch("app.auth.apple_verify.verify_apple_identity_token_dev",
                    new_callable=AsyncMock, return_value=mock_token_data):
            # 这里需要 FastAPI test client，暂用简单测试
            # 实际测试会在集成测试中覆盖
            pass


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
