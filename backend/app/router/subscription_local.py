"""
顺时 — 国际化订阅本地化管理
支持多货币定价、区域合规要求和本地化退款政策。
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from datetime import datetime
from enum import Enum

router = APIRouter(prefix="/api/v1/subscription-local", tags=["subscription_localization"])


# ─────────────────────────────────────────────────────────────────────────────
# 货币和定价数据
# ─────────────────────────────────────────────────────────────────────────────

CURRENCY_PRICING = {
    "USD": {
        "symbol": "$",
        "currency_name": "美元",
        "basic_monthly": 9.99,
        "premium_monthly": 14.99,
        "family_monthly": 24.99,
        "exchange_rate_note": "基准货币",
    },
    "EUR": {
        "symbol": "€",
        "currency_name": "欧元",
        "basic_monthly": 9.99,
        "premium_monthly": 14.99,
        "family_monthly": 24.99,
        "exchange_rate_note": "EUR/USD ≈ 1.08",
    },
    "GBP": {
        "symbol": "£",
        "currency_name": "英镑",
        "basic_monthly": 8.99,
        "premium_monthly": 13.49,
        "family_monthly": 22.49,
        "exchange_rate_note": "GBP/USD ≈ 1.27",
    },
    "AUD": {
        "symbol": "A$",
        "currency_name": "澳元",
        "basic_monthly": 14.99,
        "premium_monthly": 22.49,
        "family_monthly": 37.49,
        "exchange_rate_note": "AUD/USD ≈ 0.65",
    },
    "SGD": {
        "symbol": "S$",
        "currency_name": "新加坡元",
        "basic_monthly": 13.50,
        "premium_monthly": 20.50,
        "family_monthly": 34.00,
        "exchange_rate_note": "SGD/USD ≈ 0.75",
    },
    "CAD": {
        "symbol": "C$",
        "currency_name": "加元",
        "basic_monthly": 12.99,
        "premium_monthly": 19.49,
        "family_monthly": 32.49,
        "exchange_rate_note": "CAD/USD ≈ 0.73",
    },
    "JPY": {
        "symbol": "¥",
        "currency_name": "日元",
        "basic_monthly": 1080,
        "premium_monthly": 1620,
        "family_monthly": 2700,
        "exchange_rate_note": "JPY/USD ≈ 0.0067",
    },
    "KRW": {
        "symbol": "₩",
        "currency_name": "韩元",
        "basic_monthly": 11900,
        "premium_monthly": 17900,
        "family_monthly": 29900,
        "exchange_rate_note": "KRW/USD ≈ 0.00075",
    },
    "HKD": {
        "symbol": "HK$",
        "currency_name": "港元",
        "basic_monthly": 77.99,
        "premium_monthly": 116.99,
        "family_monthly": 194.99,
        "exchange_rate_note": "HKD/USD ≈ 0.128",
    },
    "TWD": {
        "symbol": "NT$",
        "currency_name": "新台币",
        "basic_monthly": 320,
        "premium_monthly": 480,
        "family_monthly": 800,
        "exchange_rate_note": "TWD/USD ≈ 0.031",
    },
    "MYR": {
        "symbol": "RM",
        "currency_name": "马来西亚林吉特",
        "basic_monthly": 45,
        "premium_monthly": 67.50,
        "family_monthly": 112.50,
        "exchange_rate_note": "MYR/USD ≈ 0.21",
    },
    "THB": {
        "symbol": "฿",
        "currency_name": "泰铢",
        "basic_monthly": 349,
        "premium_monthly": 524,
        "family_monthly": 873,
        "exchange_rate_note": "THB/USD ≈ 0.028",
    },
}


# ─────────────────────────────────────────────────────────────────────────────
# 区域合规要求
# ─────────────────────────────────────────────────────────────────────────────

REGION_COMPLIANCE = {
    "EU": {
        "gdpr_required": True,
        "data_retention_days": 90,
        "requires_explicit_consent": True,
        "age_minimum": 16,
        "vat_rate_percent": 21,
        "refund_policy_days": 14,
        "region_name": "欧洲",
        "notes": "GDPR 严格隐私保护，14 天无理由退款权利",
    },
    "UK": {
        "gdpr_required": True,
        "data_retention_days": 90,
        "requires_explicit_consent": True,
        "age_minimum": 16,
        "vat_rate_percent": 20,
        "refund_policy_days": 14,
        "region_name": "英国",
        "notes": "脱欧后仍有英国数据保护法（UK GDPR）",
    },
    "US": {
        "gdpr_required": False,
        "data_retention_days": 180,
        "requires_explicit_consent": False,
        "age_minimum": 13,
        "vat_rate_percent": 0,
        "refund_policy_days": 7,
        "region_name": "美国",
        "notes": "各州可能有不同规定，如加州 CCPA",
    },
    "AU": {
        "gdpr_required": False,
        "data_retention_days": 120,
        "requires_explicit_consent": True,
        "age_minimum": 13,
        "vat_rate_percent": 10,
        "refund_policy_days": 7,
        "region_name": "澳大利亚",
        "notes": "澳大利亚隐私法（APP）",
    },
    "SG": {
        "gdpr_required": False,
        "data_retention_days": 180,
        "requires_explicit_consent": True,
        "age_minimum": 13,
        "vat_rate_percent": 8,
        "refund_policy_days": 7,
        "region_name": "新加坡",
        "notes": "个人数据保护法（PDPA）",
    },
    "JP": {
        "gdpr_required": False,
        "data_retention_days": 150,
        "requires_explicit_consent": True,
        "age_minimum": 15,
        "vat_rate_percent": 10,
        "refund_policy_days": 8,
        "region_name": "日本",
        "notes": "个人信息保护法（APPI）",
    },
    "KR": {
        "gdpr_required": False,
        "data_retention_days": 180,
        "requires_explicit_consent": True,
        "age_minimum": 14,
        "vat_rate_percent": 10,
        "refund_policy_days": 7,
        "region_name": "韩国",
        "notes": "个人信息保护法（PIPA）",
    },
}


# ─────────────────────────────────────────────────────────────────────────────
# 退款政策（按档位和区域）
# ─────────────────────────────────────────────────────────────────────────────

REFUND_POLICIES = {
    "basic": {
        "EU": "购买后 14 天内可无条件全额退款。超过 14 天但服务质量不符，可在 30 天内申请退款（需提交理由）。",
        "UK": "购买后 14 天内可无条件全额退款。电子消费品规例适用。",
        "US": "购买后 7 天内可全额退款。7 天后不接受退款，但可免费转换为其他档位。",
        "AU": "购买后 7 天内可全额退款。澳大利亚消费者法保障 2 年服务质量。",
        "SG": "购买后 7 天内可全额退款。请通过应用内反馈提交退款申请。",
        "JP": "购买后 8 天内可全额退款。日本消费者保护法适用。",
        "KR": "购买后 7 天内可全额退款。韩国电子商务法规定。",
    },
    "premium": {
        "EU": "购买后 14 天内可无条件全额退款。超过 14 天但在 60 天内因质量问题可申请退款。支持订阅暂停（不收费）。",
        "UK": "购买后 14 天内可无条件全额退款。支持订阅管理和灵活暂停。",
        "US": "购买后 7 天内可全额退款。7-30 天内可转为免费试用期。支持随时取消。",
        "AU": "购买后 7 天内可全额退款。支持订阅灵活管理。",
        "SG": "购买后 7 天内可全额退款。可联系客服协商其他退款方案。",
        "JP": "购买后 8 天内可全额退款。可申请订阅暂停服务。",
        "KR": "购买后 7 天内可全额退款。支持多种取消选项。",
    },
    "family": {
        "EU": "购买后 14 天内可无条件全额退款。家庭计划可在任何时刻调整成员。超过 14 天因质量问题可在 90 天内申请退款。",
        "UK": "购买后 14 天内可无条件全额退款。家庭成员可单独退出而不影响整体计划。",
        "US": "购买后 7 天内可全额退款。家庭成员可独立退出。7-30 天内可转为家庭试用。",
        "AU": "购买后 7 天内可全额退款。支持家庭成员独立管理。",
        "SG": "购买后 7 天内可全额退款。家庭计划支持灵活调整成员。",
        "JP": "购买后 8 天内可全额退款。家庭成员可分别管理订阅。",
        "KR": "购买后 7 天内可全额退款。家庭计划支持成员变更。",
    },
}


# ─────────────────────────────────────────────────────────────────────────────
# 请求模型
# ─────────────────────────────────────────────────────────────────────────────

class PriceCalculationRequest(BaseModel):
    tier: str = Field(..., description="订阅档位: basic / premium / family")
    currency: str = Field(..., description="货币代码，如 USD, EUR, CNY 等")
    region: str = Field(..., description="区域代码，如 US, EU, AU 等")
    duration_months: int = Field(default=1, ge=1, le=12, description="订阅周期（月）")


# ─────────────────────────────────────────────────────────────────────────────
# 内存订阅存储
# ─────────────────────────────────────────────────────────────────────────────

_subscriptions: Dict[str, Dict[str, Any]] = {}


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/pricing/{currency_code}", summary="货币定价查询")
async def get_pricing_by_currency(currency_code: str):
    """
    查询指定货币的所有订阅档位定价。
    """
    currency_code = currency_code.upper()

    if currency_code not in CURRENCY_PRICING:
        raise HTTPException(
            status_code=404,
            detail=f"不支持的货币 '{currency_code}'。支持的货币: {list(CURRENCY_PRICING.keys())}",
        )

    pricing = CURRENCY_PRICING[currency_code]

    return {
        "success": True,
        "data": {
            "currency_code": currency_code,
            "currency_name": pricing["currency_name"],
            "symbol": pricing["symbol"],
            "plans": {
                "basic": {
                    "name": "基础版",
                    "monthly_price": pricing["basic_monthly"],
                    "currency": currency_code,
                    "features": ["基础健康数据同步", "每日健康概览", "基础TCM建议"],
                },
                "premium": {
                    "name": "高级版",
                    "monthly_price": pricing["premium_monthly"],
                    "currency": currency_code,
                    "features": ["完整健康数据同步", "深度TCM分析", "个性化养护计划", "优先客服支持"],
                },
                "family": {
                    "name": "家庭版",
                    "monthly_price": pricing["family_monthly"],
                    "currency": currency_code,
                    "features": ["最多6个家庭成员", "完整高级功能", "共享健康数据（可选）", "家庭报告"],
                },
            },
            "exchange_rate_note": pricing["exchange_rate_note"],
        },
    }


@router.get("/currencies", summary="支持货币列表")
async def get_supported_currencies():
    """
    返回所有支持的货币列表及其符号。
    """
    currencies = [
        {
            "code": code,
            "symbol": info["symbol"],
            "name": info["currency_name"],
            "exchange_rate_note": info["exchange_rate_note"],
        }
        for code, info in CURRENCY_PRICING.items()
    ]

    return {
        "success": True,
        "data": {
            "supported_currencies": currencies,
            "total_count": len(currencies),
            "timestamp": datetime.now().isoformat(),
        },
    }


@router.get("/compliance/{region_code}", summary="区域合规要求")
async def get_compliance_requirements(region_code: str):
    """
    查询指定区域的数据保护、隐私和退款等合规要求。
    """
    region_code = region_code.upper()

    if region_code not in REGION_COMPLIANCE:
        raise HTTPException(
            status_code=404,
            detail=f"未知区域 '{region_code}'。支持的区域: {list(REGION_COMPLIANCE.keys())}",
        )

    compliance = REGION_COMPLIANCE[region_code]

    return {
        "success": True,
        "data": {
            "region_code": region_code,
            "region_name": compliance["region_name"],
            "gdpr_required": compliance["gdpr_required"],
            "data_retention_days": compliance["data_retention_days"],
            "requires_explicit_consent": compliance["requires_explicit_consent"],
            "age_minimum": compliance["age_minimum"],
            "vat_rate_percent": compliance["vat_rate_percent"],
            "refund_policy_days": compliance["refund_policy_days"],
            "notes": compliance["notes"],
        },
    }


@router.post("/calculate", summary="含税价格计算")
async def calculate_price_with_tax(request: PriceCalculationRequest):
    """
    根据档位、货币、区域和订阅周期计算最终价格（含税）。
    """
    tier = request.tier.lower()
    currency = request.currency.upper()
    region = request.region.upper()

    # 验证档位
    valid_tiers = ["basic", "premium", "family"]
    if tier not in valid_tiers:
        raise HTTPException(
            status_code=422,
            detail=f"无效档位 '{tier}'。支持: {valid_tiers}",
        )

    # 验证货币
    if currency not in CURRENCY_PRICING:
        raise HTTPException(
            status_code=404,
            detail=f"不支持的货币 '{currency}'",
        )

    # 验证区域
    if region not in REGION_COMPLIANCE:
        raise HTTPException(
            status_code=404,
            detail=f"未知区域 '{region}'",
        )

    pricing = CURRENCY_PRICING[currency]
    compliance = REGION_COMPLIANCE[region]

    # 获取月价
    if tier == "basic":
        monthly_price = pricing["basic_monthly"]
    elif tier == "premium":
        monthly_price = pricing["premium_monthly"]
    else:  # family
        monthly_price = pricing["family_monthly"]

    # 计算总价
    subtotal = monthly_price * request.duration_months
    vat_rate = compliance["vat_rate_percent"] / 100
    vat_amount = subtotal * vat_rate
    total_price = subtotal + vat_amount

    return {
        "success": True,
        "data": {
            "tier": tier,
            "tier_name": {"basic": "基础版", "premium": "高级版", "family": "家庭版"}[tier],
            "currency": currency,
            "currency_symbol": pricing["symbol"],
            "region": region,
            "region_name": compliance["region_name"],
            "duration_months": request.duration_months,
            "monthly_price": monthly_price,
            "subtotal": round(subtotal, 2),
            "vat_rate_percent": compliance["vat_rate_percent"],
            "vat_amount": round(vat_amount, 2),
            "total_price": round(total_price, 2),
            "refund_policy_days": compliance["refund_policy_days"],
        },
    }


@router.get("/refund-policy/{tier}/{region}", summary="退款政策查询")
async def get_refund_policy(tier: str, region: str):
    """
    查询特定档位和区域的详细退款政策。
    """
    tier = tier.lower()
    region = region.upper()

    valid_tiers = ["basic", "premium", "family"]
    if tier not in valid_tiers:
        raise HTTPException(
            status_code=404,
            detail=f"无效档位 '{tier}'。支持: {valid_tiers}",
        )

    if region not in REFUND_POLICIES.get(tier, {}):
        raise HTTPException(
            status_code=404,
            detail=f"未找到 {tier} 档位在 {region} 地区的退款政策",
        )

    policy_text = REFUND_POLICIES[tier][region]
    compliance = REGION_COMPLIANCE.get(region, {})

    return {
        "success": True,
        "data": {
            "tier": tier,
            "tier_name": {"basic": "基础版", "premium": "高级版", "family": "家庭版"}[tier],
            "region": region,
            "region_name": compliance.get("region_name", region),
            "refund_days": compliance.get("refund_policy_days", 7),
            "policy": policy_text,
            "last_updated": datetime.now().isoformat(),
        },
    }


@router.get("/gift", summary="礼品卡信息")
async def get_gift_card_info():
    """
    返回订阅礼品卡的可用面值、使用说明和活动信息。
    """
    gift_options = [
        {
            "value_usd": 50,
            "tier_eligible": ["basic", "premium"],
            "months_coverage": "约 3-5 个月（取决于选择的档位）",
            "description": "3 个月基础版或 2 个月高级版的礼品卡",
        },
        {
            "value_usd": 100,
            "tier_eligible": ["basic", "premium", "family"],
            "months_coverage": "约 6-10 个月",
            "description": "6 个月基础版、3 个月高级版或 1 个月家庭版的礼品卡",
        },
        {
            "value_usd": 200,
            "tier_eligible": ["family"],
            "months_coverage": "约 2-3 个月家庭版",
            "description": "长期家庭计划的礼品卡，适合送礼",
        },
    ]

    return {
        "success": True,
        "data": {
            "gift_card_available": True,
            "available_denominations": gift_options,
            "usage_instructions": [
                "1. 购买礼品卡后，收到唯一的兑换代码",
                "2. 接收人在应用中选择'兑换礼品卡'",
                "3. 输入兑换代码，余额自动加入账户",
                "4. 可在应用内的'账户 > 我的订阅'中查看余额和有效期",
                "5. 余额在有效期内（通常 12 个月）自动应用到下次续费",
            ],
            "promotions": {
                "summer_discount": "6-8 月购买送礼品卡享 10% 折扣",
                "family_bundle": "家庭计划 3 个月送 1 个月免费",
            },
            "support_email": "gift@seasons-tcm.com",
        },
    }
