"""
顺时 ShunShi - Google Play 购买验证服务
使用 Service Account 调用 Google Play Developer API

生产环境: 需配置 GOOGLE_SERVICE_ACCOUNT_JSON 环境变量
开发环境: 自动 mock 有效订阅
"""
import hashlib
import json
import logging
import os
from typing import Optional

import httpx

logger = logging.getLogger(__name__)

# ==================== 配置 ====================

GOOGLE_PLAY_PACKAGE = os.getenv("GOOGLE_PACKAGE_NAME", "com.shunshi.app")

# Service Account JSON（从环境变量读取）
_service_account_json = os.getenv("GOOGLE_SERVICE_ACCOUNT_JSON", "")
SERVICE_ACCOUNT = json.loads(_service_account_json) if _service_account_json else None

# Google Play Developer API
PURCHASE_API = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{package}/purchases/subscriptions/{subscription_id}/tokens/{token}"
PRODUCT_API = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{package}/purchases/products/{product_id}/tokens/{token}"

# 是否启用 mock 模式
MOCK_MODE = SERVICE_ACCOUNT is None


# ==================== 核心函数 ====================

async def verify_google_purchase(
    package_name: str,
    product_id: str,
    purchase_token: str,
    is_subscription: bool = True,
) -> dict:
    """
    验证 Google Play 购买。

    使用 Service Account 获取 access_token，
    然后调用 Google Play Developer API 验证购买。

    Args:
        package_name: 应用包名
        product_id: 产品 ID
        purchase_token: 购买令牌
        is_subscription: 是否为订阅（True）或一次性产品（False）

    Returns:
        {
            "valid": bool,
            "expiry_time_ms": int|null,
            "auto_renewing": bool,
            "product_id": str,
            "purchase_token": str,
            "order_id": str|null,
            "error": str|null
        }
    """
    if not purchase_token or len(purchase_token) < 10:
        return {
            "valid": False,
            "product_id": product_id,
            "purchase_token": purchase_token,
            "error": "购买令牌为空或格式错误",
        }

    # Mock 模式
    if MOCK_MODE:
        return _mock_verify(product_id, purchase_token, is_subscription)

    # 生产验证
    try:
        access_token = await _get_access_token()
        if not access_token:
            return {
                "valid": False,
                "product_id": product_id,
                "purchase_token": purchase_token,
                "error": "无法获取 Google API access token",
            }

        result = await _verify_with_google(
            access_token=access_token,
            package_name=package_name,
            product_id=product_id,
            purchase_token=purchase_token,
            is_subscription=is_subscription,
        )
        return result

    except Exception as e:
        logger.error(f"[GooglePurchase] 验证异常: {e}")
        return {
            "valid": False,
            "product_id": product_id,
            "purchase_token": purchase_token,
            "error": f"验证异常: {str(e)}",
        }


async def _get_access_token() -> Optional[str]:
    """使用 Service Account JWT 获取 Google API access token"""
    if not SERVICE_ACCOUNT:
        return None

    import time
    import jwt  # PyJWT

    now = int(time.time())
    scope = "https://www.googleapis.com/auth/androidpublisher"

    payload = {
        "iss": SERVICE_ACCOUNT["client_email"],
        "scope": scope,
        "aud": "https://oauth2.googleapis.com/token",
        "iat": now,
        "exp": now + 3600,
    }

    # 签名
    private_key = SERVICE_ACCOUNT["private_key"]
    token = jwt.encode(payload, private_key, algorithm="RS256")

    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            "https://oauth2.googleapis.com/token",
            data={
                "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
                "assertion": token,
            },
        )

    if response.status_code != 200:
        logger.error(f"[GooglePurchase] 获取 token 失败: {response.status_code}")
        return None

    return response.json().get("access_token")


async def _verify_with_google(
    access_token: str,
    package_name: str,
    product_id: str,
    purchase_token: str,
    is_subscription: bool,
) -> dict:
    """调用 Google Play Developer API 验证购买"""
    if is_subscription:
        url = PURCHASE_API.format(
            package=package_name,
            subscription_id=product_id,
            token=purchase_token,
        )
    else:
        url = PRODUCT_API.format(
            package=package_name,
            product_id=product_id,
            token=purchase_token,
        )

    headers = {"Authorization": f"Bearer {access_token}"}

    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.get(url, headers=headers)

    if response.status_code != 200:
        logger.error(
            f"[GooglePurchase] API 返回 {response.status_code}: "
            f"{response.text[:200]}"
        )
        return {
            "valid": False,
            "product_id": product_id,
            "purchase_token": purchase_token,
            "error": f"Google API 错误: {response.status_code}",
        }

    data = response.json()

    # 订阅验证结果
    if is_subscription:
        expiry_time_ms = int(data.get("expiryTimeMillis", 0)) or None
        auto_renewing = data.get("autoResume", False) or data.get("autoRenewing", False)
        cancel_reason = data.get("cancelReason")
        # cancelReason=0 表示用户主动取消，但仍可能在过期前有效
        is_expired = (
            data.get("expiryTimeMillis") and
            int(data["expiryTimeMillis"]) < int(time.time() * 1000)
        )

        if is_expired:
            return {
                "valid": False,
                "expiry_time_ms": expiry_time_ms,
                "auto_renewing": auto_renewing,
                "product_id": product_id,
                "purchase_token": purchase_token,
                "order_id": data.get("orderId"),
                "error": "订阅已过期",
            }

        return {
            "valid": True,
            "expiry_time_ms": expiry_time_ms,
            "auto_renewing": auto_renewing,
            "product_id": product_id,
            "purchase_token": purchase_token,
            "order_id": data.get("orderId"),
            "cancel_reason": cancel_reason,
            "error": None,
        }

    # 一次性产品
    consumption_state = data.get("consumptionState", 0)
    purchase_state = data.get("purchaseState", 0)

    if purchase_state != 0:  # 0 = purchased
        return {
            "valid": False,
            "product_id": product_id,
            "purchase_token": purchase_token,
            "order_id": data.get("orderId"),
            "error": "产品未购买",
        }

    return {
        "valid": True,
        "expiry_time_ms": None,
        "auto_renewing": False,
        "product_id": product_id,
        "purchase_token": purchase_token,
        "order_id": data.get("orderId"),
        "error": None,
    }


def _mock_verify(product_id: str, purchase_token: str, is_subscription: bool) -> dict:
    """Mock 模式：返回预设的有效订阅"""
    logger.info("[GooglePurchase] Mock 模式: 返回预设有效订阅")

    token_hash = hashlib.sha256(purchase_token.encode()).hexdigest()[:16]

    return {
        "valid": True,
        "expiry_time_ms": None,  # None = 永不过期（mock 模式）
        "auto_renewing": True,
        "product_id": product_id,
        "purchase_token": purchase_token,
        "order_id": f"GPA. MOCK-{token_hash}",
        "environment": "mock",
        "error": None,
    }
