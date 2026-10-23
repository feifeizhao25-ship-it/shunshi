"""
顺时 — 会员权益查询 (Membership)
会员档位、价格、权益对比。只做展示，不自己定义档位和价格：
- 档位与价格：app/router/subscription.py 的 SUBSCRIPTION_PLANS（与支付宝 / 微信 / Apple 实际收费的 SKU 同价）；
- 对话额度、音频时长、家庭人数：app/entitlements_registry.json（chat_quota 等实际执行的就是它）。
以前这里另有一套「基础 18 / 高级 38 / 家庭 58 元」和「每天 3 次 / 无限 AI 问答、专属 AI 伴侣」，与收费和执行都对不上。
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime, timedelta
import os
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.entitlements import get_registry, registry_tier_for_plan
from app.models.membership import UserMembership, MembershipPlan
from app.router.subscription import SUBSCRIPTION_PLANS

router = APIRouter(prefix="/api/v1/membership", tags=["membership"])


# ─────────────────────────────────────────────────────────────────────────────
# 请求/响应模型
# ─────────────────────────────────────────────────────────────────────────────

class MembershipActivateRequest(BaseModel):
    user_id: str
    tier: str = Field(..., description="会员档位: free/yangxin/yiyang/jiahe")
    duration_months: int = Field(..., ge=1, le=12, description="1（月付）或 12（年付）")


# ─────────────────────────────────────────────────────────────────────────────
# 会员档位：由 SUBSCRIPTION_PLANS + 权益注册表推导，不在这里另写数字
# ─────────────────────────────────────────────────────────────────────────────

# 内存存储 — 仅用于测试 (生产使用数据库)
_memberships: dict = {}

SUPPORTED_DURATIONS = (1, 12)  # 只有月付和年付两种 SKU


def _registry_features(plan_id: str) -> dict:
    tier = get_registry()["tiers"][registry_tier_for_plan(plan_id)]
    chats = tier["quotas"]["ai_daily_messages"]
    audio = tier["quotas"]["audio_daily_minutes"]
    return {
        "ai_questions_per_day": "unlimited" if chats == -1 else chats,
        "audio_minutes_per_day": "unlimited" if audio == -1 else audio,
        "content_access": "全部养生内容" if tier["knowledge"]["wellness_library"] == "full" else "基础养生内容",
        "family_members": tier["collaboration"]["family_members"],
    }


def _describe(features: dict) -> str:
    chats = features["ai_questions_per_day"]
    parts = ["不限次数AI问答" if chats == "unlimited" else f"每天{chats}次AI问答", features["content_access"]]
    if isinstance(features["family_members"], int) and features["family_members"] > 1:
        parts.append(f"最多{features['family_members']}人（含你自己）一起使用")
    return "，".join(parts) + "。"


def _build_tiers() -> dict:
    tiers = {}
    for plan_id, plan in SUBSCRIPTION_PLANS.items():
        features = _registry_features(plan_id)
        tiers[plan_id] = {
            "name": plan["name"],
            "price_monthly": plan.get("price", 0),
            "price_yearly": plan.get("price_yearly"),
            "features": features,
            "description": _describe(features),
        }
    return tiers


MEMBERSHIP_TIERS = _build_tiers()


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
            "price_yearly": tier_data["price_yearly"],
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
            detail="不能直接开通会员，请通过已验证的支付完成购买",
        )

    if request.tier not in MEMBERSHIP_TIERS:
        raise HTTPException(
            status_code=422,
            detail=f"没有这个会员档位，可选：{'、'.join(MEMBERSHIP_TIERS)}",
        )

    if request.duration_months not in SUPPORTED_DURATIONS:
        raise HTTPException(
            status_code=422,
            detail="只支持月付（1 个月）或年付（12 个月）",
        )

    tier_data = MEMBERSHIP_TIERS[request.tier]
    # 0S3：付费档只卖年付；本接口仅开发 / 测试环境可用，非 12 个月按年价折算
    base_price = tier_data["price_monthly"] if tier_data["price_monthly"] is not None else round(tier_data["price_yearly"] / 12, 2)
    if request.duration_months == 12 and tier_data.get("price_yearly") is not None:
        total_price = tier_data["price_yearly"]
    else:
        total_price = base_price * request.duration_months
    full_price = total_price if tier_data["price_monthly"] is None else base_price * request.duration_months
    discount = (total_price / full_price) if full_price else 1.0

    now = datetime.now()
    # 与 SKU 的 duration_days 一致：月付 30 天、年付 365 天
    expires_at = now + timedelta(days=365 if request.duration_months == 12 else 30)
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
            "message": f"成功激活{tier_data['name']}{request.duration_months}个月，总价¥{round(total_price, 2)}",
        },
    }


@router.get("/benefits/{tier}", summary="获取等级权益详情")
async def get_tier_benefits(tier: str):
    """获取特定会员等级的详细权益说明"""
    tier = tier.lower()
    if tier not in MEMBERSHIP_TIERS:
        raise HTTPException(
            status_code=404,
            detail=f"没有这个会员档位，可选：{'、'.join(MEMBERSHIP_TIERS)}",
        )

    tier_data = MEMBERSHIP_TIERS[tier]

    benefits = []
    features = tier_data["features"]

    if features["ai_questions_per_day"] == "unlimited":
        benefits.append("不限次数AI问答（每天）")
    else:
        benefits.append(f"每日{features['ai_questions_per_day']}次AI问答")

    benefits.append(f"权益范围：{features['content_access']}")

    if features["audio_minutes_per_day"] == "unlimited":
        benefits.append("音频内容不限时长")
    else:
        benefits.append(f"每日{features['audio_minutes_per_day']}分钟音频")

    benefits.append(f"家庭成员数：{features['family_members']}人（含你自己）")

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
            "音频时长",
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
                "不限" if features["ai_questions_per_day"] == "unlimited"
                else f"每日{features['ai_questions_per_day']}次"
            ),
            "content": features["content_access"],
            "audio": (
                "不限" if features["audio_minutes_per_day"] == "unlimited"
                else f"每日{features['audio_minutes_per_day']}分钟"
            ),
            "family_members": f"{features['family_members']}人",
            "price": (
                f"¥{tier_data['price_yearly']} 元/年" if tier_data["price_monthly"] is None
                else f"¥{tier_data['price_monthly']} 元/月" if tier_data["price_monthly"] > 0 else "免费"
            ),
        })

    return {
        "success": True,
        "data": comparison,
    }
