"""
Solar Wellness API — 顺时养生 wellness endpoints
Provides: current solar term, daily advice, shichen info, context
"""

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request
from typing import Optional
from datetime import datetime
from sqlalchemy.orm import Session

from app.config import Settings
from app.deps import current_user, get_session, get_settings
from app.locale_context import default_market, resolve_locale

router = APIRouter(prefix="/api/v1/solar-wellness", tags=["solar-wellness"])


@router.get("/current")
async def get_current_solar_wellness():
    """获取当前节气养生信息"""
    now = datetime.now()
    month = now.month
    day = now.day

    # Simple solar term mapping
    terms = [
        (1, 6, "小寒"), (1, 20, "大寒"),
        (2, 4, "立春"), (2, 19, "雨水"),
        (3, 6, "惊蛰"), (3, 21, "春分"),
        (4, 5, "清明"), (4, 20, "谷雨"),
        (5, 6, "立夏"), (5, 21, "小满"),
        (6, 6, "芒种"), (6, 21, "夏至"),
        (7, 7, "小暑"), (7, 23, "大暑"),
        (8, 7, "立秋"), (8, 23, "处暑"),
        (9, 8, "白露"), (9, 23, "秋分"),
        (10, 8, "寒露"), (10, 23, "霜降"),
        (11, 7, "立冬"), (11, 22, "小雪"),
        (12, 7, "大雪"), (12, 22, "冬至"),
    ]
    term_name = "春分"
    for t in terms:
        if month < t[0] or (month == t[0] and day < t[1]):
            break
        term_name = t[2]

    return {
        "success": True,
        "data": {
            "term": term_name,
            "season": get_season(month),
            "date": now.strftime("%Y-%m-%d"),
        }
    }


_USER_QUERY_KEYS = ("user_id", "userId")

# 国际版匿名客户端仍解析这五个字段。国内市场和国内域名不再下发里面的药效说法。
_LEGACY_ANONYMOUS_ADVICE = {
    "success": True,
    "data": {
        "morning": "晨起喝一杯温水，舒展筋骨",
        "noon": "午餐后小憩15分钟，养心安神",
        "evening": "晚餐清淡，避免油腻，助眠安神",
        "diet": "宜食当季蔬果，少食生冷",
        "exercise": "推荐八段锦或散步30分钟",
    },
}


def _hostname_is_cn(value: str | None) -> bool:
    host = (value or "").split(",")[0].strip().lower().rstrip(".")
    if not host:
        return False
    if host.startswith("["):
        end = host.find("]")
        host = host[1:end] if end > 1 else ""
    elif host.count(":") == 1:
        host = host.split(":", 1)[0]
    return host.endswith(".cn")


def _host_is_cn(request: Request) -> bool:
    """国内域名（请求实际到达的主机，或代理转来的原主机）不走国际版五个字段。"""
    forwarded = request.headers.get("x-forwarded-host")
    return any(
        _hostname_is_cn(value)
        for value in (request.url.hostname, request.headers.get("host"), forwarded)
    )


def _anonymous_keeps_legacy(request: Request) -> bool:
    """国际版匿名请求继续拿改版前的五个字段。国内市场或国内域名改为登录后才给时辰表。"""
    if _host_is_cn(request):
        return False
    market = (request.headers.get("x-app-market") or "").strip().lower()
    if market == "cn":
        return False
    if market == "global":
        return True
    accept = request.headers.get("accept-language")
    if accept:
        return resolve_locale(accept, None, request.headers.get("x-region")).is_global
    locale_query = (request.query_params.get("locale") or "").strip().lower()
    locale_primary = locale_query.replace("_", "-").split("-", 1)[0]
    if locale_primary == "en":
        return True
    if locale_primary == "zh":
        return False
    # 没有市场头时跟部署走：国内部署缺省 cn，国际部署把 SHUNSHI_DEFAULT_MARKET 设成 global。
    return default_market() == "global"


def _authenticated_user(
    request: Request,
    authorization: str | None = Header(default=None),
    settings: Settings = Depends(get_settings),
) -> str | None:
    """没有 Authorization 就是匿名。带了令牌就按现有登录依赖核验，无效则 401。"""
    if authorization is None or not authorization.strip():
        return None
    return current_user(request, authorization, settings)


def _claimed_user_ids(request: Request) -> list[str]:
    found: list[str] = []
    for key in _USER_QUERY_KEYS:
        found.extend(request.query_params.getlist(key))
    return [str(value) for value in found if value not in (None, "")]


@router.get("/daily-advice")
async def get_daily_advice(
    request: Request,
    constitution: Optional[str] = Query(None, description="体质类型，不参与这张表的文案"),
    session: Session = Depends(get_session),
    viewer: str | None = Depends(_authenticated_user),
):
    """十二时辰白话表。登录用户按令牌里的本人过滤；不把人生阶段写回响应。"""
    _ = constitution
    from app.services.home_recommend import life_stage_for
    from app.services.shichen_table import select_shichen_entries

    claimed = _claimed_user_ids(request)
    if viewer is None:
        # 没带令牌就不能按别人的 user_id 去查档案。
        # 国际版不带令牌，继续拿改版前的那五个字段，避免他们的解析被换掉。
        # 国内市场、中文请求和国内域名不带令牌时不返回药效说法，跟客户端已有的「请先登录」一致。
        if claimed or not _anonymous_keeps_legacy(request):
            raise HTTPException(status_code=401, detail="请先登录")
        return _LEGACY_ANONYMOUS_ADVICE
    if any(value != viewer for value in claimed):
        raise HTTPException(status_code=403, detail="只能访问自己的数据")

    stage = life_stage_for(session, viewer)
    plain = select_shichen_entries(None)
    entries = select_shichen_entries(stage)
    return {
        "success": True,
        "data": {
            "filtered": [row["id"] for row in entries] != [row["id"] for row in plain],
            "entries": entries,
        },
    }


@router.get("/shichen")
async def get_current_shichen():
    """获取当前时辰信息"""
    hour = datetime.now().hour
    shichen_data = [
        (23, 1, "子时", "胆经", "万籁俱寂·养胆气"),
        (1, 3, "丑时", "肝经", "肝血归藏·养肝阴"),
        (3, 5, "寅时", "肺经", "气血布散·养肺气"),
        (5, 7, "卯时", "大肠经", "天明排便·通肠腑"),
        (7, 9, "辰时", "胃经", "朝食养胃·补气血"),
        (9, 11, "巳时", "脾经", "运化水谷·健脾土"),
        (11, 13, "午时", "心经", "日中养心·调阴阳"),
        (13, 15, "未时", "小肠经", "分清泌浊·利消化"),
        (15, 17, "申时", "膀胱经", "多喝温水·泻火气"),
        (17, 19, "酉时", "肾经", "藏精纳气·养肾元"),
        (19, 21, "戌时", "心包经", "护心减压·畅情志"),
        (21, 23, "亥时", "三焦经", "百脉通调·备入眠"),
    ]

    current = shichen_data[0]
    for sc in shichen_data:
        start, end = sc[0], sc[1]
        if start <= end:
            if start <= hour < end:
                current = sc
                break
        else:
            if hour >= start or hour < end:
                current = sc
                break

    return {
        "success": True,
        "data": {
            "name": current[2],
            "meridian": current[3],
            "principle": current[4],
            "time_range": f"{current[0]}:00 - {current[1]}:00",
        }
    }


@router.get("/context")
async def get_wellness_context(
    user_id: Optional[str] = Query(None, description="用户ID"),
):
    """获取用户养生上下文"""
    now = datetime.now()
    return {
        "success": True,
        "data": {
            "date": now.strftime("%Y-%m-%d"),
            "hour": now.hour,
            "greeting": get_greeting(now.hour),
        }
    }


def get_season(month: int) -> str:
    if 3 <= month <= 5:
        return "spring"
    elif 6 <= month <= 8:
        return "summer"
    elif 9 <= month <= 11:
        return "autumn"
    return "winter"


def get_greeting(hour: int) -> str:
    if 5 <= hour < 11:
        return "早安，开启美好的一天"
    elif 11 <= hour < 13:
        return "午安，适时休息"
    elif 13 <= hour < 18:
        return "下午好，保持精力"
    elif 18 <= hour < 22:
        return "晚上好，放松身心"
    return "夜深了，早些休息"
