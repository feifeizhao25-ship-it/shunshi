"""Read-only membership presentation from verified core entitlements."""
import time
from datetime import datetime, timezone
from fastapi import HTTPException
from app.entitlements import daily_chat_limit_for_plan, tier_for_product
from app.simple_models import Entitlement

_DOMESTIC_PLAN_NAMES = {
    "free": "免费版",
    "yangxin": "内容订阅",
    "yiyang": "会员",
    "jiahe": "家和版",
}
_DOMESTIC_FEATURES = {
    "free": {"basic_chat": True, "solar_terms": True},
    "yangxin": {"basic_chat": True, "solar_terms": True, "today_plan": True},
    "yiyang": {"basic_chat": True, "solar_terms": True, "today_plan": True},
    "jiahe": {"basic_chat": True, "solar_terms": True, "today_plan": True, "family": True},
}
# 对话额度以权益注册表为准（养心每天 100 条、颐养 / 家和每天 200 条）；不再宣称没有执行点的「深度建议、周总结」。
for _plan_id, _features in _DOMESTIC_FEATURES.items():
    _features["daily_chat_limit"] = daily_chat_limit_for_plan(_plan_id)
    _features["unlimited_chat"] = _features["daily_chat_limit"] == -1


# Exact known SKU aliases only. Unknown products never acquire paid display.
_PRODUCT_PLANS = {
    **{sku: 'yangxin' for sku in ('shunshi_yangxin_monthly', 'shunshi_yangxin_yearly',
        'shunshi_healing_monthly', 'yangxin_monthly', 'yangxin_yearly',
        'shunshi_content_yearly', 'content_yearly', 'content_apple_yearly', 'com.shunshi.content.yearly')},
    **{sku: 'yiyang' for sku in ('shunshi_yiyang_monthly', 'shunshi_yiyang_yearly',
        'yiyang_monthly', 'yiyang_yearly',
        'shunshi_member_yearly', 'member_yearly', 'member_apple_yearly', 'com.shunshi.member.yearly')},
    **{sku: 'jiahe' for sku in ('shunshi_family_monthly', 'shunshi_family_yearly',
        'family_monthly', 'family_yearly', 'jiahe_monthly', 'jiahe_yearly')},
}


# 会员唯一事实来源：Entitlement 表（由签名支付回调/商店恢复写入）。
# 旧版 router/subscription.py 的内存 dict 只作兜底，所有读会员档位的地方都先问这里。
_SESSION_FACTORY = None


def bind_session_factory(factory):
    global _SESSION_FACTORY
    _SESSION_FACTORY = factory


def entitlement_plan(user_id):
    """返回 (plan, expires_at) ；未绑定数据库或无有效权益时返回 None。"""
    if _SESSION_FACTORY is None or not user_id:
        return None
    with _SESSION_FACTORY() as session:
        state = membership_status(session, user_id)
    if not state['active']:
        return None
    return state['plan'], state['expires_at']


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
