"""
顺时 - 恢复购买测试

覆盖:
- iOS 有效收据 → 恢复权益
- iOS 无效收据 → 拒绝
- iOS 过期收据 → 告知用户
- Android 有效令牌 → 恢复权益
- Android 无效令牌 → 拒绝
- 无 receipt / 无历史 → 失败
- 幂等操作：重复调用不影响
- 收据 hash 不存储明文
- Mock 模式

作者: Claw 🦅
"""

import pytest
import asyncio
from unittest.mock import AsyncMock, patch, MagicMock
from datetime import datetime, timedelta
import hashlib
import time


# ==================== iOS 恢复购买 ====================

class TestIOSRestorePurchase:
    """iOS 恢复购买"""

    def test_restore_ios_valid_receipt(self, client):
        """iOS 有效收据 → 恢复权益"""
        # 先创建购买历史
        client.post(
            "/api/v1/subscription/subscribe",
            params={"user_id": "restore-ios-user"},
            json={"plan": "yiyang", "platform": "ios"},
        )

        # Mock Apple 验证返回有效
        mock_result = {
            "valid": True,
            "status": 0,
            "expires_at_ms": None,
            "product_id": "com.shunshi.yiyang.yearly",
            "transaction_id": "IOS_TXN_RESTORE_001",
            "bundle_id": "com.shunshi.app",
            "environment": "Production",
            "is_trial": False,
            "auto_renew": True,
            "error": None,
        }

        with patch("app.services.apple_receipt.verify_apple_receipt", new_callable=AsyncMock, return_value=mock_result):
            response = client.post(
                "/api/v1/subscription/restore",
                params={"user_id": "restore-ios-user"},
                json={
                    "platform": "ios",
                    "receipt": "MOCK_IOS_RECEIPT_VALID_DATA_1234567890",
                    "transaction_id": "IOS_TXN_RESTORE_001",
                },
            )

        assert response.status_code == 200
        data = response.json()
        assert data.get("success") is True, f"恢复购买应成功: {data}"
        assert data.get("code") in ("restored", "already_restored")

        # 验证订阅已恢复
        sub_resp = client.get("/api/v1/subscription?user_id=restore-ios-user")
        sub_data = sub_resp.json().get("data", {})
        assert sub_data.get("plan") == "yiyang"
        assert sub_data.get("status") == "active"

    def test_restore_ios_invalid_receipt(self, client):
        """iOS 无效收据 → 拒绝"""
        mock_result = {
            "valid": False,
            "status": 21002,
            "error": "收据数据格式错误",
        }

        with patch("app.services.apple_receipt.verify_apple_receipt", new_callable=AsyncMock, return_value=mock_result):
            response = client.post(
                "/api/v1/subscription/restore",
                params={"user_id": "restore-ios-invalid-user"},
                json={
                    "platform": "ios",
                    "receipt": "INVALID_RECEIPT",
                    "transaction_id": "INVALID_TXN",
                },
            )

        assert response.status_code == 200
        data = response.json()
        assert data.get("success") is False
        assert data.get("code") == "verify_failed"

    def test_restore_ios_expired_receipt(self, client):
        """iOS 过期收据 → 告知用户"""
        mock_result = {
            "valid": False,
            "status": 21006,
            "error": "订阅已过期",
        }

        with patch("app.services.apple_receipt.verify_apple_receipt", new_callable=AsyncMock, return_value=mock_result):
            response = client.post(
                "/api/v1/subscription/restore",
                params={"user_id": "restore-ios-expired-user"},
                json={
                    "platform": "ios",
                    "receipt": "EXPIRED_RECEIPT_DATA",
                },
            )

        assert response.status_code == 200
        data = response.json()
        assert data.get("success") is False
        assert data.get("code") == "expired"

    def test_restore_ios_no_receipt_fallback(self, client):
        """iOS 无 receipt 时回退到本地历史"""
        # 先创建购买历史
        client.post(
            "/api/v1/subscription/subscribe",
            params={"user_id": "restore-ios-fallback-user"},
            json={"plan": "yangxin", "platform": "ios"},
        )

        response = client.post(
            "/api/v1/subscription/restore",
            params={"user_id": "restore-ios-fallback-user"},
            json={
                "platform": "ios",
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert data.get("success") is True


# ==================== Android 恢复购买 ====================

class TestAndroidRestorePurchase:
    """Android 恢复购买"""

    def test_restore_android_valid_token(self, client):
        """Android 有效令牌 → 恢复权益"""
        # 先创建购买历史
        client.post(
            "/api/v1/subscription/subscribe",
            params={"user_id": "restore-android-user"},
            json={"plan": "jiahe", "platform": "android"},
        )

        mock_result = {
            "valid": True,
            "expiry_time_ms": None,
            "auto_renewing": True,
            "product_id": "com.shunshi.jiahe.yearly",
            "purchase_token": "MOCK_ANDROID_TOKEN",
            "order_id": "GPA.MOCK-ORDER-001",
            "error": None,
        }

        with patch("app.services.google_purchase.verify_google_purchase", new_callable=AsyncMock, return_value=mock_result):
            response = client.post(
                "/api/v1/subscription/restore",
                params={"user_id": "restore-android-user"},
                json={
                    "platform": "android",
                    "purchase_token": "MOCK_ANDROID_TOKEN_1234567890",
                    "product_id": "com.shunshi.jiahe.yearly",
                },
            )

        assert response.status_code == 200
        data = response.json()
        assert data.get("success") is True, f"恢复购买应成功: {data}"

        # 验证订阅已恢复
        sub_resp = client.get("/api/v1/subscription?user_id=restore-android-user")
        sub_data = sub_resp.json().get("data", {})
        assert sub_data.get("plan") == "jiahe"
        assert sub_data.get("status") == "active"

    def test_restore_android_invalid_token(self, client):
        """Android 无效令牌 → 拒绝"""
        mock_result = {
            "valid": False,
            "product_id": "com.shunshi.yiyang.yearly",
            "purchase_token": "INVALID_TOKEN",
            "error": "Google API 错误: 400",
        }

        with patch("app.services.google_purchase.verify_google_purchase", new_callable=AsyncMock, return_value=mock_result):
            response = client.post(
                "/api/v1/subscription/restore",
                params={"user_id": "restore-android-invalid-user"},
                json={
                    "platform": "android",
                    "purchase_token": "SHORT",
                    "product_id": "com.shunshi.yiyang.yearly",
                },
            )

        assert response.status_code == 200
        data = response.json()
        assert data.get("success") is False
        assert data.get("code") == "verify_failed"

    def test_restore_android_no_token_fallback(self, client):
        """Android 无 token 时回退到本地历史"""
        client.post(
            "/api/v1/subscription/subscribe",
            params={"user_id": "restore-android-fallback-user"},
            json={"plan": "yiyang", "platform": "android"},
        )

        response = client.post(
            "/api/v1/subscription/restore",
            params={"user_id": "restore-android-fallback-user"},
            json={
                "platform": "android",
            },
        )

        assert response.status_code == 200
        data = response.json()
        assert data.get("success") is True


# ==================== 边界情况 ====================

class TestRestoreEdgeCases:
    """恢复购买边界情况"""

    def test_restore_no_purchase_history(self, client):
        """无购买历史 + 验证失败 → 应失败"""
        mock_result = {
            "valid": True,
            "product_id": "unknown.product.id",
            "transaction_id": "TXN_UNKNOWN",
            "expires_at_ms": None,
            "auto_renew": True,
            "error": None,
        }

        with patch("app.services.apple_receipt.verify_apple_receipt", new_callable=AsyncMock, return_value=mock_result):
            response = client.post(
                "/api/v1/subscription/restore",
                params={"user_id": "restore-no-history-user-2"},
                json={
                    "platform": "ios",
                    "receipt": "SOME_RECEIPT",
                },
            )

        assert response.status_code == 200
        data = response.json()
        assert data.get("success") is False

    def test_restore_idempotent(self, client):
        """幂等操作：重复调用不影响"""
        client.post(
            "/api/v1/subscription/subscribe",
            params={"user_id": "restore-idempotent-user"},
            json={"plan": "yiyang", "platform": "ios"},
        )

        mock_result = {
            "valid": True,
            "product_id": "com.shunshi.yiyang.yearly",
            "transaction_id": "TXN_IDEMPOTENT",
            "expires_at_ms": None,
            "auto_renew": True,
            "error": None,
        }

        with patch("app.services.apple_receipt.verify_apple_receipt", new_callable=AsyncMock, return_value=mock_result):
            # 第一次恢复
            r1 = client.post(
                "/api/v1/subscription/restore",
                params={"user_id": "restore-idempotent-user"},
                json={
                    "platform": "ios",
                    "receipt": "RECEIPT_IDEMPOTENT",
                    "transaction_id": "TXN_IDEMPOTENT",
                },
            )
            assert r1.json().get("success") is True

            # 第二次恢复（幂等）
            r2 = client.post(
                "/api/v1/subscription/restore",
                params={"user_id": "restore-idempotent-user"},
                json={
                    "platform": "ios",
                    "receipt": "RECEIPT_IDEMPOTENT",
                    "transaction_id": "TXN_IDEMPOTENT",
                },
            )
            assert r2.json().get("success") is True
            assert r2.json().get("code") == "already_restored"

            # 状态一致
            sub = client.get("/api/v1/subscription?user_id=restore-idempotent-user")
            sub_data = sub.json().get("data", {})
            assert sub_data.get("plan") == "yiyang"

    def test_restore_receipt_hashed_not_plaintext(self, client):
        """收据不存储明文，使用 hash"""
        receipt_data = "SENSITIVE_RECEIPT_DATA_SHOULD_NOT_BE_STORED"
        expected_hash = hashlib.sha256(receipt_data.encode()).hexdigest()[:32]

        client.post(
            "/api/v1/subscription/subscribe",
            params={"user_id": "restore-hash-user"},
            json={"plan": "yiyang", "platform": "ios"},
        )

        mock_result = {
            "valid": True,
            "product_id": "com.shunshi.yiyang.yearly",
            "transaction_id": "TXN_HASH_TEST",
            "expires_at_ms": None,
            "auto_renew": True,
            "error": None,
        }

        with patch("app.services.apple_receipt.verify_apple_receipt", new_callable=AsyncMock, return_value=mock_result):
            client.post(
                "/api/v1/subscription/restore",
                params={"user_id": "restore-hash-user"},
                json={
                    "platform": "ios",
                    "receipt": receipt_data,
                    "transaction_id": "TXN_HASH_TEST",
                },
            )

        # 检查购买历史中不包含明文收据
        from app.router.subscription import purchase_history
        history = purchase_history.get("restore-hash-user", [])
        for record in history:
            if record.get("source") == "restore":
                assert receipt_data not in record.get("receipt_hash", ""), \
                    "购买历史中不应包含明文收据"
                assert record.get("receipt_hash") == expected_hash, \
                    "应存储收据 hash"
                break

    def test_restore_unsupported_platform(self, client):
        """不支持的平台应返回 400"""
        response = client.post(
            "/api/v1/subscription/restore",
            params={"user_id": "restore-bad-platform-user"},
            json={
                "platform": "windows",
            },
        )
        assert response.status_code == 400

    def test_restore_product_id_mapping(self):
        """产品 ID 正确映射到订阅计划（纯函数，无需 client）"""
        from app.router.subscription import _product_id_to_plan

        assert _product_id_to_plan("com.shunshi.yangxin.monthly") == "yangxin"
        assert _product_id_to_plan("com.shunshi.yiyang.yearly") == "yiyang"
        assert _product_id_to_plan("com.shunshi.jiahe.monthly") == "jiahe"
        assert _product_id_to_plan("com.shunshi.family.yearly") == "jiahe"
        assert _product_id_to_plan("yangxin_apple_monthly") == "yangxin"
        assert _product_id_to_plan("unknown_product") is None
        assert _product_id_to_plan("") is None
        assert _product_id_to_plan(None) is None


# ==================== Mock 模式 ====================

class TestRestoreMockMode:
    """Mock 模式（无 APPLE_SHARED_SECRET 时自动启用）"""

    def test_ios_mock_mode_returns_valid(self):
        """iOS Mock 模式返回有效订阅"""
        from app.services.apple_receipt import verify_apple_receipt

        result = asyncio.run(
            verify_apple_receipt(
                receipt_data="MOCK_RECEIPT_DATA_FOR_TESTING",
                transaction_id="MOCK_TXN_001",
            )
        )
        assert result.get("valid") is True
        assert result.get("environment") == "mock"
        assert result.get("auto_renew") is True

    def test_android_mock_mode_returns_valid(self):
        """Android Mock 模式返回有效订阅"""
        from app.services.google_purchase import verify_google_purchase

        result = asyncio.run(
            verify_google_purchase(
                package_name="com.shunshi.app",
                product_id="com.shunshi.yiyang.yearly",
                purchase_token="MOCK_ANDROID_TOKEN_FOR_TESTING",
                is_subscription=True,
            )
        )
        assert result.get("valid") is True
        assert result.get("environment") == "mock"
        assert result.get("auto_renewing") is True

    def test_mock_receipt_hash_consistency(self):
        """Mock 模式收据 hash 一致性"""
        from app.services.apple_receipt import verify_apple_receipt

        receipt = "CONSISTENT_RECEIPT_DATA"
        expected_hash = hashlib.sha256(receipt.encode()).hexdigest()[:16]

        result = asyncio.run(verify_apple_receipt(receipt_data=receipt))
        assert expected_hash in result.get("transaction_id", "")

    def test_android_empty_token_rejected(self):
        """空 token 应被拒绝"""
        from app.services.google_purchase import verify_google_purchase

        result = asyncio.run(
            verify_google_purchase(
                package_name="com.shunshi.app",
                product_id="test",
                purchase_token="",
                is_subscription=True,
            )
        )
        assert result.get("valid") is False

    def test_ios_empty_receipt_rejected(self):
        """空收据应被拒绝"""
        from app.services.apple_receipt import verify_apple_receipt

        result = asyncio.run(verify_apple_receipt(receipt_data=""))
        assert result.get("valid") is False

        result2 = asyncio.run(verify_apple_receipt(receipt_data="short"))
        assert result2.get("valid") is False
