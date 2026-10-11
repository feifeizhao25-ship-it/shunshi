"""Read-only membership presentation from verified core entitlements."""
import time
from datetime import datetime, timezone
from fastapi import HTTPException
from app.entitlements import tier_for_product
from app.simple_models import Entitlement

_DOMESTIC_PLAN_NAMES = {
    "free": "免费版",
    "yangxin": "养心版",
    "yiyang": "颐养版",
    "jiahe": "家和版",
}
_DOMESTIC_FEATURES = {
    "free": {"basic_chat": True, "solar_terms": True},
    "yangxin": {"basic_chat": True, "solar_terms": True, "unlimited_chat": True, "today_plan": True},
    "yiyang": {"basic_chat": True, "solar_terms": True, "unlimited_chat": True, "today_plan": True, "deep_suggestions": True, "weekly_summary": True},
    "jiahe": {"basic_chat": True, "solar_terms": True, "unlimited_chat": True, "today_plan": True, "deep_suggestions": True, "weekly_summary": True, "family": True},
}


# Exact known SKU aliases only. Unknown products never acquire paid display.
_PRODUCT_PLANS = {
    **{sku: 'yangxin' for sku in ('shunshi_yangxin_monthly', 'shunshi_yangxin_yearly',
        'shunshi_healing_monthly', 'yangxin_monthly', 'yangxin_yearly')},
    **{sku: 'yiyang' for sku in ('shunshi_yiyang_monthly', 'shunshi_yiyang_yearly',
        'yiyang_monthly', 'yiyang_yearly')},
    **{sku: 'jiahe' for sku in ('shunshi_family_monthly', 'shunshi_family_yearly',
        'family_monthly', 'family_yearly', 'jiahe_monthly', 'jiahe_yearly')},
}


def membership_status(session, user_id):
    row = session.get(Entitlement, user_id)
    tier = tier_for_product(row.product_id) if row and row.expires_at > time.time() else 'free'
    plan = _PRODUCT_PLANS.get(row.product_id, 'free') if tier != 'free' else 'free'
    active = plan != 'free'
    if not active:
        tier = 'free'
    return {
        'active': active, 'plan': plan, 'tier': tier, 'success': True,
        'product_id': row.product_id if active else None,
        'store': row.store if active else None,
        'expires_at': row.expires_at if active else None,
        'data': {'plan': plan, 'plan_name': _DOMESTIC_PLAN_NAMES[plan],
                 'status': 'active' if active else 'inactive', 'is_active': active,
                 'expires_at': row.expires_at if active else None,
                 'features': dict(_DOMESTIC_FEATURES[plan])},
    }


def account_membership(request, user_id):
    try:
        with request.app.state.session_factory() as session:
            state = membership_status(session, user_id)
    except Exception as exc:
        # An unavailable core store is not proof of either free or paid access.
        raise HTTPException(503, '会员状态暂时无法查询，请稍后重试') from exc
    return {'is_premium': state['active'], 'subscription_plan': state['plan'],
            'subscription_type': state['plan'],
            'subscription_expires_at': (datetime.fromtimestamp(state['expires_at'], timezone.utc).isoformat()
                                        if state['expires_at'] else None)}
