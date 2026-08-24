"""通知与免打扰设置：契约以 Flutter 客户端实际调用为准（settings_page.dart）。

- GET  /api/v1/notifications/settings → {"push_enabled", "time_slots", "preferences"}
- POST /api/v1/notifications/settings body 同上，整体覆盖保存
- GET  /api/v1/settings/quiet-hours   → {"enabled", "start_time", "end_time"}
- POST /api/v1/settings/quiet-hours   body 同上（客户端实际用 POST；PUT 为等价别名）

未保存过时返回空态默认值，不编造用户偏好。
"""

import json

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from ..deps import current_user, get_session
from ..models import UserSetting

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
