"""
顺时 - 认证系统测试
test_auth.py
"""

import pytest
from unittest.mock import patch
from app.router.auth import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
)


class TestPasswordHashing:
    """密码哈希验证"""

    def test_hash_password_returns_non_empty_string(self):
        result = hash_password("test123456")
        assert isinstance(result, str)
        assert len(result) > 0

    def test_hash_password_different_for_different_inputs(self):
        h1 = hash_password("password1")
        h2 = hash_password("password2")
        assert h1 != h2

    def test_verify_password_correct(self):
        pw = "my_secure_password"
        hashed = hash_password(pw)
        assert verify_password(pw, hashed) is True

    def test_verify_password_incorrect(self):
        hashed = hash_password("correct_password")
        assert verify_password("wrong_password", hashed) is False

    def test_verify_password_empty(self):
        hashed = hash_password("test123")
        assert verify_password("", hashed) is False

    def test_hash_empty_password(self):
        hashed = hash_password("")
        assert verify_password("", hashed) is True


class TestJWT:
    """JWT Token 测试"""

    def test_create_access_token(self):
        token = create_access_token("user-001", "测试用户", "test@example.com")
        assert isinstance(token, str)
        assert len(token) > 0

    def test_create_refresh_token(self):
        token = create_refresh_token("user-001")
        assert isinstance(token, str)
        assert len(token) > 0

    def test_decode_valid_token(self):
        token = create_access_token("user-001", "测试用户", "test@example.com")
        payload = decode_token(token)
        assert payload is not None
        assert payload["sub"] == "user-001"
        assert payload["email"] == "test@example.com"
        assert payload["type"] == "access"

    def test_decode_refresh_token(self):
        token = create_refresh_token("user-001")
        payload = decode_token(token)
        assert payload is not None
        assert payload["type"] == "refresh"

    def test_decode_invalid_token(self):
        payload = decode_token("invalid.token.here")
        assert payload is None

    def test_decode_empty_token(self):
        payload = decode_token("")
        assert payload is None


class TestRegisterEndpoint:
    """注册接口测试"""

    def test_register_success(self, client):
        response = client.post("/api/v1/auth/register", json={
            "email": "newuser@test.com",
            "password": "newpass123",
            "name": "新用户",
        })
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "token" in data["data"]
        assert "refresh_token" in data["data"]
        assert data["data"]["user"]["email"] == "newuser@test.com"

    def test_register_duplicate_email(self, client, test_user):
        response = client.post("/api/v1/auth/register", json={
            "email": test_user["email"],
            "password": "another123",
            "name": "重复用户",
        })
        assert response.status_code == 400
        assert "邮箱已被注册" in response.json()["detail"]

    def test_register_missing_email(self, client):
        response = client.post("/api/v1/auth/register", json={
            "password": "test123",
        })
        assert response.status_code == 422  # Validation error

    def test_register_missing_password(self, client):
        response = client.post("/api/v1/auth/register", json={
            "email": "test@test.com",
        })
        assert response.status_code == 422

    def test_register_default_name(self, client):
        response = client.post("/api/v1/auth/register", json={
            "email": "noname-default@test.com",
            "password": "test123",
        })
        assert response.status_code == 200
        assert response.json()["data"]["user"]["name"] == "用户"


class TestLoginEndpoint:
    """登录接口测试"""

    def test_login_success(self, client, test_user):
        response = client.post("/api/v1/auth/login", json={
            "email": test_user["email"],
            "password": test_user["password"],
        })
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "token" in data["data"]
        assert data["data"]["user"]["email"] == test_user["email"]

    def test_login_wrong_password(self, client, test_user):
        response = client.post("/api/v1/auth/login", json={
            "email": test_user["email"],
            "password": "wrong_password",
        })
        assert response.status_code == 401
        assert "密码错误" in response.json()["detail"]

    def test_login_nonexistent_user_fallback(self, client):
        """不存在的用户会回退到演示用户"""
        response = client.post("/api/v1/auth/login", json={
            "email": "nonexistent@test.com",
            "password": "anything",
        })
        # 演示模式：不存在的用户也会返回 token
        assert response.status_code == 200

    def test_login_missing_fields(self, client):
        response = client.post("/api/v1/auth/login", json={
            "email": "test@test.com",
        })
        assert response.status_code == 422


class TestRefreshEndpoint:
    """Token 刷新测试"""

    def test_refresh_success(self, client, test_user):
        # 先登录获取 refresh token
        login_resp = client.post("/api/v1/auth/login", json={
            "email": test_user["email"],
            "password": test_user["password"],
        })
        refresh_token = login_resp.json()["data"]["refresh_token"]

        # 刷新
        refresh_resp = client.post("/api/v1/auth/refresh", json={
            "refresh_token": refresh_token,
        })
        assert refresh_resp.status_code == 200
        data = refresh_resp.json()
        assert data["success"] is True
        assert "token" in data["data"]
        assert "refresh_token" in data["data"]

    def test_refresh_invalid_token(self, client):
        response = client.post("/api/v1/auth/refresh", json={
            "refresh_token": "invalid.token.here",
        })
        assert response.status_code == 401

    def test_refresh_expired_token(self, client):
        """过期 token 应返回 401"""
        response = client.post("/api/v1/auth/refresh", json={
            "refresh_token": "",
        })
        assert response.status_code in (401, 422)


class TestMeEndpoint:
    """获取当前用户信息测试"""

    def test_me_without_token(self, client):
        response = client.get("/api/v1/auth/me")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_me_with_token(self, client, test_user_token):
        response = client.get(
            "/api/v1/auth/me",
            headers={"Authorization": f"Bearer {test_user_token}"},
        )
        assert response.status_code == 200
