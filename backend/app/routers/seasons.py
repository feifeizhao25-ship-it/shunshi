"""季节/首页模块：契约以 Flutter 客户端实际调用为准（home_page.dart / onboarding_page.dart / audio_player_page.dart）。

- GET  /api/v1/seasons/home/dashboard?hemisphere=...
       客户端解包 data["greeting"] / data["daily_insight"]["text"] / data["suggestions"][]
       （android-cn 的 home_page 读 gentle_suggestions[i].reason/title/duration_min，两个键给同一份列表）。
       卡片由 app/services/home_cards.py 按节气、法定假日/调休、用户自填的地区和年龄段、目标、
       最近 7 天的行动记录生成，每张卡带 reason/basis；只给生活方式建议，不诊断、不推荐药物。
- POST /api/v1/seasons/onboarding/complete  真实落库 onboarding 档案（settings 表）
- POST /api/v1/seasons/audio/progress       真实落库播放进度（audio_progress 表）
"""

import json
import time

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from ..deps import current_user, get_session
from ..simple_models import AudioProgress, UserSetting

router = APIRouter(prefix="/api/v1/seasons", tags=["seasons"])

ONBOARDING_KEY = "profile:onboarding"


def _greeting(now: float | None = None) -> str:
    """按北京时间时段给出问候语（以前按服务器本地时区，部署在 UTC 机器上早上 8 点会说「夜深了」）。"""
    from datetime import datetime

    from ..utils.solar_term_calendar import BEIJING

    hour = datetime.fromtimestamp(time.time() if now is None else now, BEIJING).hour
    if hour < 6:
        return "夜深了，注意休息"
    if hour < 12:
        return "早上好，新的一天开始了"
    if hour < 18:
        return "下午好，记得稍作放松"
    return "晚上好，今天也照顾好自己"


@router.get("/home/dashboard")
def home_dashboard(
    hemisphere: str = "north",
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
):
    from ..services.home_cards import build_dashboard

    board = build_dashboard(session, user_id)
    return {
        "greeting": _greeting(),
        **board,
        "gentle_suggestions": board["suggestions"],
        "hemisphere": hemisphere,
        "updated_at": int(time.time()),
    }


class OnboardingBody(BaseModel):
    feeling: str | None = Field(default=None, max_length=64)
    help_goal: str | None = Field(default=None, max_length=64)
    life_stage: str | None = Field(default=None, max_length=64)
    support_time: str | None = Field(default=None, max_length=64)
    style_preference: str | None = Field(default=None, max_length=64)


@router.post("/onboarding/complete")
def onboarding_complete(
    body: OnboardingBody,
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
):
    profile = body.model_dump(exclude_none=True)
    session.merge(
        UserSetting(
            user_id=user_id,
            key=ONBOARDING_KEY,
            value=json.dumps(profile, ensure_ascii=False),
        )
    )
    return {"saved": True, "profile": profile}


class AudioProgressBody(BaseModel):
    audio_id: str = Field(min_length=1, max_length=64)
    progress_seconds: int = Field(ge=0)
    completed: bool = False


@router.post("/audio/progress")
def report_audio_progress(
    body: AudioProgressBody,
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
):
    session.merge(
        AudioProgress(
            user_id=user_id,
            audio_id=body.audio_id,
            progress_seconds=body.progress_seconds,
            completed=body.completed,
            updated_at=int(time.time()),
        )
    )
    return {"saved": True}
