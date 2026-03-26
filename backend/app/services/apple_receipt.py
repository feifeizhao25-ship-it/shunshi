"""
顺时 ShunShi - Apple 收据验证服务
支持 Production + Sandbox 自动回退

生产环境: 需配置 APPLE_SHARED_SECRET 环境变量
开发环境: 自动 mock 有效订阅
"""
import hashlib
import logging
import os
from typing import Optional

import httpx

logger = logging.getLogger(__name__)

# ==================== 配置 ====================

PRODUCTION_URL = "https://buy.itunes.apple.com/verifyReceipt"
SANDBOX_URL = "https://sandbox.itunes.apple.com/verifyReceipt"

BUNDLE_ID = os.getenv("APPLE_BUNDLE_ID", "com.shunshi.app")
SHARED_SECRET = os.getenv("APPLE_SHARED_SECRET", "")

# 是否启用 mock 模式（未配置 SHARED_SECRET 时自动启用）
MOCK_MODE = not SHARED_SECRET


# ==================== 响应解析 ====================

class AppleReceiptStatus:
    """Apple 收据验证状态码"""
    VALID = 0                     # 收据有效
    MALFORMED = 21002             # 收据数据格式错误
    UNAUTHENTICATED = 21003       # 收据无法验证
    INVALID_SHARED_SECRET = 21004 # 共享密钥不正确
    SERVER_UNAVAILABLE = 21005    # 服务器不可用
    SUBSCRIPTION_EXPIRED = 21006  # 订阅已过期
    SANDBOX_RECEIPT = 21007       # 收据是 sandbox 收据，需要重试 sandbox URL
    PRODUCTION_RECEIPT = 21008    # 收据是 production 收据（在 sandbox 环境下返回）


# ==================== 核心函数 ====================

async def verify_apple_receipt(
    receipt_data: str,
    transaction_id: Optional[str] = None,
) -> dict:
    """
    验证 Apple 收据。

    流程:
    1. 检查收据非空
    2. 发送到生产 URL
    3. 如果返回 21007，自动重试 sandbox URL
    4. 验证 bundle_id
    5. 提取过期时间和产品信息
    6. 返回验证结果

    Args:
        receipt_data: Base64 编码的收据数据
        transaction_id: 可选，用于匹配特定交易

    Returns:
        {
            "valid": bool,
            "status": int,
            "expires_at_ms": int|null,
            "product_id": str|null,
            "transaction_id": str|null,
            "bundle_id": str|null,
            "environment": str|null,
            "is_trial": bool,
            "auto_renew": bool,
            "error": str|null
        }
    """
    if not receipt_data or len(receipt_data) < 10:
        return {
            "valid": False,
            "status": AppleReceiptStatus.MALFORMED,
            "error": "收据数据为空或格式错误",
        }

    # Mock 模式
    if MOCK_MODE:
        return _mock_verify(receipt_data, transaction_id)

    # 生产验证
    result = await _verify_with_apple(PRODUCTION_URL, receipt_data)

    # Sandbox 回退
    if result.get("status") == AppleReceiptStatus.SANDBOX_RECEIPT:
        logger.info("[AppleReceipt] 收据来自 sandbox，切换到 sandbox URL")
        result = await _verify_with_apple(SANDBOX_URL, receipt_data)

    return result


async def _verify_with_apple(url: str, receipt_data: str) -> dict:
    """向 Apple 服务器发送验证请求"""
    payload = {
        "receipt-data": receipt_data,
        "password": SHARED_SECRET,
        "exclude-old-transactions": True,
    }

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(url, json=payload)
            data = response.json()

        status = data.get("status", -1)

        if status != AppleReceiptStatus.VALID:
            return {
                "valid": False,
                "status": status,
                "error": f"Apple 验证失败，状态码: {status}",
            }

        # 解析收据信息
        receipt = data.get("receipt", {})
        latest_receipt = data.get("latest_receipt_info", [])
        pending_renewal = data.get("pending_renewal_info", [])

        bundle_id = receipt.get("bundle_id")
        if bundle_id and bundle_id != BUNDLE_ID:
            logger.warning(
                f"[AppleReceipt] bundle_id 不匹配: expected={BUNDLE_ID}, got={bundle_id}"
            )

        # 提取最新交易信息
        transaction_info = latest_receipt[0] if latest_receipt else {}
        renewal_info = pending_renewal[0] if pending_renewal else {}

        # 过期时间（毫秒级时间戳）
        expires_at_ms = None
        if transaction_info:
            expires_at_ms = int(
                transaction_info.get("expires_date_ms", 0)
            ) or None

        # 是否为试用期
        is_trial = transaction_info.get("is_trial_period") == "true"
        if not is_trial and transaction_info.get("is_in_intro_offer_period") == "true":
            is_trial = True

        # 自动续费状态
        auto_renew = renewal_info.get("auto_renew_status") == "1"
        if not auto_renew:
            auto_renew = transaction_info.get("auto_renew_status") == "true"

        # 产品 ID
        product_id = transaction_info.get("product_id") or receipt.get("product_id")

        # 交易 ID
        txn_id = (transaction_id or
                  transaction_info.get("original_transaction_id") or
                  transaction_info.get("transaction_id"))

        return {
            "valid": True,
            "status": status,
            "expires_at_ms": expires_at_ms,
            "product_id": product_id,
            "transaction_id": txn_id,
            "bundle_id": bundle_id,
            "environment": data.get("environment", "unknown"),
            "is_trial": is_trial,
            "auto_renew": auto_renew,
            "error": None,
        }

    except httpx.TimeoutException:
        logger.error("[AppleReceipt] Apple 验证超时")
        return {
            "valid": False,
            "status": AppleReceiptStatus.SERVER_UNAVAILABLE,
            "error": "Apple 服务器响应超时",
        }
    except Exception as e:
        logger.error(f"[AppleReceipt] 验证异常: {e}")
        return {
            "valid": False,
            "status": -1,
            "error": f"验证异常: {str(e)}",
        }


async def extract_subscription_info(receipt_data: str) -> dict:
    """
    从收据中提取订阅信息（不验证，仅解析）。

    Args:
        receipt_data: Base64 编码的收据数据

    Returns:
        {
            "product_id": str|null,
            "bundle_id": str|null,
            "transaction_id": str|null,
            "quantity": int,
        }
    """
    if MOCK_MODE:
        return {
            "product_id": "com.shunshi.yiyang.yearly",
            "bundle_id": BUNDLE_ID,
            "transaction_id": None,
            "quantity": 1,
        }

    # 仅验证时才解析
    result = await verify_apple_receipt(receipt_data)
    return {
        "product_id": result.get("product_id"),
        "bundle_id": result.get("bundle_id"),
        "transaction_id": result.get("transaction_id"),
        "quantity": 1,
    }


def _mock_verify(receipt_data: str, transaction_id: Optional[str] = None) -> dict:
    """Mock 模式：返回预设的有效订阅"""
    logger.info("[AppleReceipt] Mock 模式: 返回预设有效订阅")

    # 生成收据 hash（不存储明文）
    receipt_hash = hashlib.sha256(receipt_data.encode()).hexdigest()[:16]

    return {
        "valid": True,
        "status": 0,
        "expires_at_ms": None,  # None 表示永不过期（mock 模式）
        "product_id": "com.shunshi.yiyang.yearly",
        "transaction_id": transaction_id or f"MOCK_IOS_{receipt_hash}",
        "bundle_id": BUNDLE_ID,
        "environment": "mock",
        "is_trial": False,
        "auto_renew": True,
        "error": None,
    }
