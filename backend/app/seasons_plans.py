"""SEASONS（顺时国际版）订阅档位 —— 唯一定义。

用户 2026-11-01 决定：SEASONS 与顺时同规则，只卖年付，档位为 Free + Premium + Family。
金额取开发文档里已有的美元年付价（D11 SEASONS 资料 / 代码原有：Serenity $79.99、Harmony $119.99、Family $159.99），
合并两个旧付费档后：

- Premium  = 原 Serenity 的权益与价格（$79.99/年；权益全部能自动交付）
- Family   = $159.99/年；含购买人共 3 人（与顺时家庭席位同一口径，D4 20261015：最多 3 人）
- 不再有月付、不再有 enterprise；旧 serenity / harmony 订阅者按 premium 处理（LEGACY_ALIASES），不丢权益。

三处原先各写一份（seasons_subscription / stripe / stripe_service）互相矛盾（$9.99/$19.99/$29.99 月付 vs 年付），
现在都从这里读。Stripe 价格 ID 环境变量：STRIPE_PRICE_PREMIUM_YEARLY、STRIPE_PRICE_FAMILY_YEARLY（需要在 Stripe 里新建年付 Price；
旧的月付 Price 不能复用）。App Store / Google Play 的商品也要由本人在后台新建年付商品（代码无法代办）。
"""
from __future__ import annotations

import os
from typing import Optional

BILLING = "yearly"
CURRENCY = "usd"
FAMILY_MEMBERS = 3  # 含购买人

LEGACY_ALIASES = {"serenity": "premium", "harmony": "premium"}

PLANS: dict[str, dict] = {
    "free": {
        "id": "free",
        "name": "Free",
        "price": 0,
        "currency": CURRENCY,
        "period": None,
        "yearly_price": 0,
        "trial_days": 0,
        "features": [
            "5 messages per day",
            "Basic content library",
            "Limited reflections",
            "Daily suggestions",
        ],
        "description": "Start your wellness journey",
    },
    "premium": {
        "id": "premium",
        "name": "Premium",
        "price": 79.99,
        "currency": CURRENCY,
        "period": "year",
        "yearly_price": 79.99,
        "trial_days": 7,
        "features": [
            "Unlimited AI conversations",
            "Full content library",
            "Audio guides & soundscapes",
            "Weekly reflection summaries",
        ],
        "description": "Everything for your own routine, billed yearly",
    },
    "family": {
        "id": "family",
        "name": "Family",
        "price": 159.99,
        "currency": CURRENCY,
        "period": "year",
        "yearly_price": 159.99,
        "trial_days": 14,
        "family_members": FAMILY_MEMBERS,
        "features": [
            "Everything in Premium",
            f"Up to {FAMILY_MEMBERS} people including you",
            "Shared family dashboard",
            "Individual profiles",
        ],
        "description": "Share calm with your household, billed yearly",
    },
}

PAID_PLAN_IDS = tuple(p for p in PLANS if p != "free")


def canonical_plan_id(plan_id: Optional[str]) -> Optional[str]:
    """旧档名 → 现行档名；未知返回 None。"""
    if not plan_id:
        return None
    plan_id = str(plan_id).strip().lower()
    plan_id = LEGACY_ALIASES.get(plan_id, plan_id)
    return plan_id if plan_id in PLANS else None


def stripe_price_ids() -> dict[str, str]:
    return {pid: os.getenv(f"STRIPE_PRICE_{pid.upper()}_YEARLY", "").strip() for pid in PAID_PLAN_IDS}
