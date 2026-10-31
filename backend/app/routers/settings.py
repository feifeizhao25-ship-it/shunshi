"""通知与免打扰设置：契约以 Flutter 客户端实际调用为准（settings_page.dart）。

- GET  /api/v1/notifications/settings → {"push_enabled", "time_slots", "preferences"}
- POST /api/v1/notifications/settings body 同上，整体覆盖保存
- GET  /api/v1/settings/quiet-hours   → {"enabled", "start_time", "end_time"}
- POST /api/v1/settings/quiet-hours   body 同上（客户端实际用 POST；PUT 为等价别名）

未保存过时返回空态默认值，不编造用户偏好。
"""

import json
from datetime import date, datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from ..deps import current_user, get_session
from ..locale_context import RequestLocale, request_locale
from ..simple_models import UserSetting

router = APIRouter(prefix="/api/v1", tags=["settings"])

NOTIFICATIONS_KEY = "notifications:settings"
QUIET_HOURS_KEY = "settings:quiet-hours"

DEFAULT_NOTIFICATIONS = {"push_enabled": True, "time_slots": {}, "preferences": {}}
DEFAULT_QUIET_HOURS = {"enabled": False, "start_time": None, "end_time": None}


def _read(session: Session, user_id: str, key: str, default: dict) -> dict:
    row = session.get(UserSetting, {"user_id": user_id, "key": key})
    if not row:
        return dict(default)
    try:
        return json.loads(row.value)
    except json.JSONDecodeError:
        return dict(default)


def _write(session: Session, user_id: str, key: str, value: dict) -> dict:
    session.merge(
        UserSetting(user_id=user_id, key=key, value=json.dumps(value, ensure_ascii=False))
    )
    return value


class NotificationSettings(BaseModel):
    push_enabled: bool
    time_slots: dict[str, bool] = Field(default_factory=dict)
    preferences: dict[str, bool] = Field(default_factory=dict)


class QuietHours(BaseModel):
    enabled: bool
    start_time: str | None = Field(default=None, pattern=r"^\d{2}:\d{2}$")
    end_time: str | None = Field(default=None, pattern=r"^\d{2}:\d{2}$")


@router.get("/notifications/settings")
def get_notification_settings(
    user_id: str = Depends(current_user), session: Session = Depends(get_session)
):
    return _read(session, user_id, NOTIFICATIONS_KEY, DEFAULT_NOTIFICATIONS)


@router.post("/notifications/settings")
def set_notification_settings(
    body: NotificationSettings,
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
):
    return _write(session, user_id, NOTIFICATIONS_KEY, body.model_dump())


@router.get("/settings/quiet-hours")
def get_quiet_hours(
    user_id: str = Depends(current_user), session: Session = Depends(get_session)
):
    return _read(session, user_id, QUIET_HOURS_KEY, DEFAULT_QUIET_HOURS)


@router.post("/settings/quiet-hours")
@router.put("/settings/quiet-hours")
def set_quiet_hours(
    body: QuietHours,
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
):
    return _write(session, user_id, QUIET_HOURS_KEY, body.model_dump())


@router.get("/settings/quiet-hours/check")
def check_quiet_hours(
    user_id: str = Depends(current_user), session: Session = Depends(get_session)
):
    settings = _read(session, user_id, QUIET_HOURS_KEY, DEFAULT_QUIET_HOURS)
    start = settings.get("start_time")
    end = settings.get("end_time")
    is_quiet = False
    if settings.get("enabled") and start and end:
        current = datetime.now().strftime("%H:%M")
        is_quiet = start <= current < end if start < end else current >= start or current < end
    return {**settings, "is_quiet": is_quiet}


class RegionProfile(BaseModel):
    province: str = Field(min_length=2, max_length=12, description="省级行政区，如「四川」「广西壮族自治区」")


@router.get("/settings/region")
def get_region(
    user_id: str = Depends(current_user), session: Session = Depends(get_session)
):
    """用户自填的所在省份（只到省，不收集城市和定位），用于首页的地区气候提示。"""
    from ..services.home_cards import REGION_KEY, zone_for

    data = _read(session, user_id, REGION_KEY, {})
    province = data.get("province")
    return {"declared": bool(province), "province": province, "zone": zone_for(province) if province else None}


@router.post("/settings/region")
@router.put("/settings/region")
def set_region(
    body: RegionProfile,
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
):
    from ..services.home_cards import PROVINCES, REGION_KEY, zone_for

    # 「四川省」「广西壮族自治区」「香港特别行政区」都按开头的简称认
    raw = body.province.strip()
    province = next((p for p in PROVINCES if raw.startswith(p)), None)
    if province is None:
        raise HTTPException(status_code=422, detail="请选择一个省、自治区、直辖市或特别行政区")
    _write(session, user_id, REGION_KEY, {"province": province})
    return {"declared": True, "province": province, "zone": zone_for(province)}


@router.delete("/settings/region")
def clear_region(
    user_id: str = Depends(current_user), session: Session = Depends(get_session)
):
    """随时可以清除，清除后首页不再按地区给提示。"""
    from ..services.home_cards import REGION_KEY

    row = session.get(UserSetting, {"user_id": user_id, "key": REGION_KEY})
    if row:
        session.delete(row)
    return {"declared": False, "province": None, "zone": None}


class AgeProfile(BaseModel):
    birth_date: date


@router.get("/settings/age-profile")
def get_age_profile(
    user_id: str = Depends(current_user), session: Session = Depends(get_session)
):
    """只返回年龄段，不回传出生日期。"""
    from ..services.age_policy import read_group

    group = read_group(session, user_id)
    return {"declared": group != "unknown", "age_group": group}


@router.post("/settings/age-profile")
def set_age_profile(
    body: AgeProfile,
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
    locale: RequestLocale = Depends(request_locale),
):
    """填写出生日期（自报）。用于未成年人保护与老年用户的健康使用提示。"""
    from ..services.age_policy import declare_birth_date

    group = declare_birth_date(session, user_id, body.birth_date, lang=locale.lang)
    return {"declared": True, "age_group": group}


# ── Culture & locale preferences (optional, user-chosen, clearable) ──────────────────────────────────────
class CultureBody(BaseModel):
    diet: list[str] = Field(default_factory=list)
    observances: list[str] = Field(default_factory=list)
    units: str | None = None
    hemisphere: str | None = None


@router.get("/profile/culture")
def get_culture_profile(user_id: str = Depends(current_user), session: Session = Depends(get_session)):
    from ..services import culture_profile as cp

    return {
        **cp.read(session, user_id),
        "options": {
            "diet": list(cp.DIETS),
            "observances": list(cp.OBSERVANCES),
            "units": list(cp.UNITS),
            "hemisphere": list(cp.HEMISPHERES),
        },
    }


@router.put("/profile/culture")
def put_culture_profile(body: CultureBody, user_id: str = Depends(current_user), session: Session = Depends(get_session)):
    """Save or clear (send empty lists / nulls) the preferences. Values outside the fixed lists are refused."""
    from ..services import culture_profile as cp

    try:
        return cp.save(session, user_id, body.model_dump())
    except cp.CultureError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error
