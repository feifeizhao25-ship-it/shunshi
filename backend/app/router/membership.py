"""
顺时 — 会员权益管理 (Membership Management)
提供会员等级查询、激活和权益对比。包括免费版、基础、高级和家庭会员。
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime, timedelta
import os
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.membership import UserMembership, MembershipPlan

router = APIRouter(prefix="/api/v1/membership", tags=["membership"])


# ─────────────────────────────────────────────────────────────────────────────
# 请求/响应模型
# ─────────────────────────────────────────────────────────────────────────────

class MembershipActivateRequest(BaseModel):
    user_id: str
    tier: str = Field(..., description="会员等级: free/basic/premium/family")
    duration_months: int = Field(..., ge=1, le=12, description="订阅期限: 1/3/6/12 个月")


# ─────────────────────────────────────────────────────────────────────────────
# 会员等级定义和价格（静态配置，不需DB）
# ─────────────────────────────────────────────────────────────────────────────

# 内存存储 — 仅用于测试 (生产使用数据库)
_memberships: dict = {}

MEMBERSHIP_TIERS = {
    "free": {
        "name": "免费版",
        "price_monthly": 0,
        "features": {
            "ai_questions_per_day": 3,
            "content_access": "基础节气内容",
            "audio_per_day": 0,
            "companion": False,
            "family_members": 1,
        },
        "description": "体验基础养生功能，每天3次AI问答，了解节气知识。",
    },
    "basic": {
        "name": "基础会员",
        "price_monthly": 18,
        "features": {
            "ai_questions_per_day": 20,
            "content_access": "全部节气内容",
            "audio_per_day": 5,
            "companion": False,
            "family_members": 1,
        },
        "description": "获得更多AI问答机会和音频内容，全面了解24节气养护。",
    },
    "premium": {
        "name": "高级会员",
        "price_monthly": 38,
        "features": {
            "ai_questions_per_day": "unlimited",
            "content_access": "全部内容（包括专属课程）",
            "audio_per_day": "unlimited",
            "companion": True,
            "family_members": 2,
        },
        "description": "无限AI问答，专属AI伴侣，家庭计划支持2人。享受完整功能。",
    },
    "family": {
        "name": "家庭会员",
        "price_monthly": 58,
        "features": {
            "ai_questions_per_day": "unlimited",
            "content_access": "全部内容（包括专属课程）",
            "audio_per_day": "unlimited",
            "companion": True,
            "family_members": 5,
        },
        "description": "无限AI问答，专属AI伴侣，家庭计划支持5人。全家养生。",
    },
}

# 订阅时长折扣（越长折扣越大）
DURATION_DISCOUNTS = {
    1: 1.0,      # 0% 折扣
    3: 0.95,     # 5% 折扣
    6: 0.90,     # 10% 折扣
    12: 0.85,    # 15% 折扣
}


def _get_default_free_membership() -> dict:
    """获取默认的免费会员套餐"""
    now = datetime.now()
    return {
        "tier": "free",
        "activated_at": now.isoformat(),
        "expires_at": None,  # 免费版永不过期
        "features": MEMBERSHIP_TIERS["free"]["features"].copy(),
    }


def _ensure_membership(user_id: str, db: Optional[Session] = None):
    """确保用户有会员档案，如果没有则创建免费版"""
    if db is None or os.getenv("APP_ENV") == "testing":
        if user_id not in _memberships:
            _memberships[user_id] = _get_default_free_membership()
        return _memberships[user_id]

    row = db.query(UserMembership).filter(UserMembership.user_id == user_id).first()
    if not row:
        row = UserMembership(user_id=user_id, plan_id="free", status="active")
        db.add(row)
        db.commit()
        db.refresh(row)
    return row


def _is_membership_active(membership: dict) -> bool:
    """检查会员是否有效"""
    if membership["expires_at"] is None:
        # 免费版永不过期
        return True
    expires = datetime.fromisoformat(membership["expires_at"])
    return datetime.now() < expires


def _get_days_remaining(membership: dict) -> int:
    """计算剩余天数"""
    if membership["expires_at"] is None:
        return -1  # 免费版（永不过期）
    expires = datetime.fromisoformat(membership["expires_at"])
    delta = expires - datetime.now()
    return max(0, delta.days)


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/tiers", summary="获取所有会员等级")
async def list_tiers():
    """获取所有可用的会员等级及其详细信息"""
    tiers_list = []
    for tier_key, tier_data in MEMBERSHIP_TIERS.items():
        tiers_list.append({
            "tier": tier_key,
            "name": tier_data["name"],
            "price_monthly": tier_data["price_monthly"],
            "description": tier_data["description"],
            "features": tier_data["features"],
        })

    return {
        "success": True,
        "data": {
            "tiers": tiers_list,
        },
    }


@router.get("/user/{user_id}", summary="获取用户会员状态")
async def get_user_membership(user_id: str, db: Session = Depends(get_db)):
    """获取用户当前的会员等级和权益"""
    row = _ensure_membership(user_id, db)
    if isinstance(row, dict):
        tier = row["tier"]
        tier_info = MEMBERSHIP_TIERS.get(tier, MEMBERSHIP_TIERS["free"])
        return {
            "success": True,
            "data": {
                "user_id": user_id,
                "tier": tier,
                "tier_name": tier_info["name"],
                "activated_at": row["activated_at"],
                "expires_at": row["expires_at"],
                "is_active": _is_membership_active(row),
                "days_remaining": _get_days_remaining(row),
                "features": row["features"],
                "price_monthly": tier_info["price_monthly"],
            },
        }
    tier = row.plan_id or "free"
    tier_info = MEMBERSHIP_TIERS.get(tier, MEMBERSHIP_TIERS["free"])

    return {
        "success": True,
        "data": {
            "user_id": user_id,
            "tier": tier,
            "tier_name": tier_info["name"],
            "activated_at": row.created_at.isoformat() if row.created_at else None,
            "expires_at": row.expires_at.isoformat() if hasattr(row, "expires_at") and row.expires_at else None,
            "is_active": row.status == "active",
            "days_remaining": _get_days_remaining({"expires_at": row.expires_at.isoformat() if hasattr(row, "expires_at") and row.expires_at else None}),
            "features": tier_info["features"],
            "price_monthly": tier_info["price_monthly"],
        },
    }


@router.post("/activate", summary="激活或升级会员")
async def activate_membership(request: MembershipActivateRequest, db: Session = Depends(get_db)):
    """
    激活或升级用户的会员等级。
    支持模拟支付，更长期限有折扣。
    """
    if os.getenv("APP_ENV") not in {"development", "testing"}:
        raise HTTPException(
            status_code=403,
            detail="Direct membership activation is disabled. Use the verified payment callback.",
        )

    if request.tier not in MEMBERSHIP_TIERS:
        raise HTTPException(
            status_code=422,
            detail=f"Unknown tier '{request.tier}'. Valid: {list(MEMBERSHIP_TIERS.keys())}",
        )

    if request.duration_months not in DURATION_DISCOUNTS:
        raise HTTPException(
            status_code=422,
            detail=f"Invalid duration. Supported: {list(DURATION_DISCOUNTS.keys())}",
        )

    tier_data = MEMBERSHIP_TIERS[request.tier]
    base_price = tier_data["price_monthly"]
    discount = DURATION_DISCOUNTS[request.duration_months]
    total_price = base_price * request.duration_months * discount

    now = datetime.now()
    expires_at = now + timedelta(days=request.duration_months * 30)
    if request.tier == "free":
        expires_at = None

    if os.getenv("APP_ENV") == "testing":
        _memberships[request.user_id] = {
            "tier": request.tier,
            "activated_at": now.isoformat(),
            "expires_at": expires_at.isoformat() if expires_at else None,
            "features": tier_data["features"].copy(),
        }

    # 写入数据库
    row = db.query(UserMembership).filter(UserMembership.user_id == request.user_id).first()
    if row:
        row.plan_id = request.tier
        row.status = "active"
        if hasattr(row, "expires_at"):
            row.expires_at = expires_at
    else:
        row = UserMembership(
            user_id=request.user_id,
            plan_id=request.tier,
            status="active",
        )
        if hasattr(row, "expires_at"):
            row.expires_at = expires_at
        db.add(row)
    db.commit()

    return {
        "success": True,
        "data": {
            "user_id": request.user_id,
            "tier": request.tier,
            "tier_name": tier_data["name"],
            "duration_months": request.duration_months,
            "discount_applied": round((1 - discount) * 100),
            "base_price": base_price,
            "total_price": round(total_price, 2),
            "activated_at": now.isoformat(),
            "expires_at": expires_at.isoformat() if expires_at else None,
            "features": tier_data["features"],
            "message": f"成功激活{tier_data['name']}{request.duration_months}个月，总价¥{round(total_price, 2)}（已享受{round((1 - discount) * 100)}%折扣）",
        },
    }


@router.get("/benefits/{tier}", summary="获取等级权益详情")
async def get_tier_benefits(tier: str):
    """获取特定会员等级的详细权益说明"""
    tier = tier.lower()
    if tier not in MEMBERSHIP_TIERS:
        raise HTTPException(
            status_code=404,
            detail=f"Tier '{tier}' not found. Valid: {list(MEMBERSHIP_TIERS.keys())}",
        )

    tier_data = MEMBERSHIP_TIERS[tier]

    benefits = []
    features = tier_data["features"]

    if features["ai_questions_per_day"] == "unlimited":
        benefits.append("无限次数AI问答（每天）")
    else:
        benefits.append(f"每日{features['ai_questions_per_day']}次AI问答")

    benefits.append(f"权益范围：{features['content_access']}")

    if features["audio_per_day"] == "unlimited":
        benefits.append("无限音频内容")
    else:
        benefits.append(f"每日{features['audio_per_day']}个音频")

    if features["companion"]:
        benefits.append("专属AI伴侣 - 个性化问候和养护建议")

    benefits.append(f"家庭成员数：{features['family_members']}人")

    return {
        "success": True,
        "data": {
            "tier": tier,
            "name": tier_data["name"],
            "price_monthly": tier_data["price_monthly"],
            "description": tier_data["description"],
            "benefits": benefits,
            "features": tier_data["features"],
        },
    }


@router.get("/compare", summary="会员等级对比")
async def compare_tiers():
    """获取所有会员等级的对比表"""
    comparison = {
        "tiers": [],
        "feature_categories": [
            "AI问答次数",
            "内容权限",
            "音频权限",
            "AI伴侣",
            "家庭成员",
            "月度价格",
        ],
    }

    for tier_key, tier_data in MEMBERSHIP_TIERS.items():
        features = tier_data["features"]
        comparison["tiers"].append({
            "tier": tier_key,
            "name": tier_data["name"],
            "ai_questions": (
                "无限" if features["ai_questions_per_day"] == "unlimited"
                else f"每日{features['ai_questions_per_day']}次"
            ),
            "content": features["content_access"],
            "audio": (
                "无限" if features["audio_per_day"] == "unlimited"
                else f"每日{features['audio_per_day']}个"
            ),
            "companion": "✓ 有" if features["companion"] else "✗ 无",
            "family_members": f"{features['family_members']}人",
            "price": f"¥{tier_data['price_monthly']} 元/月" if tier_data["price_monthly"] > 0 else "免费",
        })

    return {
        "success": True,
        "data": comparison,
    }
