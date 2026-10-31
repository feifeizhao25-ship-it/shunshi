"""资料库接口：条目（带展示规则的结论）、个性化「为你推荐」、关注/静音/总开关、访问记录。仅登录用户。"""

from __future__ import annotations

from typing import List, Optional

from fastapi import APIRouter, Depends, Header, HTTPException, Request
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from ..deps import current_user, get_session, get_settings
from ..library import service, store
from ..utils import solar_term_calendar

router = APIRouter(prefix="/api/v1/library", tags=["library"])


def _today():
    return solar_term_calendar.beijing_today()


class PrefsBody(BaseModel):
    enabled: Optional[bool] = None
    follow: List[str] = Field(default_factory=list)
    unfollow: List[str] = Field(default_factory=list)
    mute: List[str] = Field(default_factory=list)
    unmute: List[str] = Field(default_factory=list)


def _optional_user(request: Request, authorization: Optional[str], session: Session) -> Optional[str]:
    """条目本身不需要登录；登录了才带上「相对上次来访」的标记。令牌无效就当没登录。"""
    if not authorization or not authorization.startswith("Bearer "):
        return None
    try:
        return current_user(request, authorization, get_settings(request))
    except HTTPException:
        return None


@router.get("/entries")
def entries(request: Request, authorization: Optional[str] = Header(default=None), session: Session = Depends(get_session)):
    today = _today()
    items = store.annotated(today, "zh")
    uid = _optional_user(request, authorization, session)
    if uid:
        marks = service.visit_badges(session, uid, today, items)
        for e in items:
            if e["id"] in marks:
                e["badge"] = marks[e["id"]]
    return {"entries": items, "generated_for": today.isoformat(), "preview_pending": store.show_pending(), "personalized": bool(uid)}


@router.get("/entries/{entry_id}")
def entry_detail(entry_id: str):
    e = store.find(entry_id, _today(), "zh")
    if not e:
        raise HTTPException(status_code=404, detail="资料不存在或尚未上线")
    return e


@router.get("/feed")
def feed(session: Session = Depends(get_session), user_id: str = Depends(current_user)):
    return service.build_feed(session, user_id, _today(), "zh")


@router.get("/preferences")
def get_prefs(session: Session = Depends(get_session), user_id: str = Depends(current_user)):
    from ..library import feed as fd

    return {**service.preferences(session, user_id), "topics": [{"id": k, "name": v["zh"]} for k, v in fd.TOPICS.items()]}


@router.put("/preferences")
def put_prefs(body: PrefsBody, session: Session = Depends(get_session), user_id: str = Depends(current_user)):
    try:
        return service.set_preferences(session, user_id, enabled=body.enabled, follow=body.follow, unfollow=body.unfollow, mute=body.mute, unmute=body.unmute)
    except ValueError as e:
        raise HTTPException(status_code=422, detail="未知的主题") from e


@router.post("/visit")
def visit(session: Session = Depends(get_session), user_id: str = Depends(current_user)):
    service.record_visit(session, user_id, _today())
    return {"ok": True}


@router.post("/opened/{entry_id}")
def opened(entry_id: str, session: Session = Depends(get_session), user_id: str = Depends(current_user)):
    if not store.find(entry_id, _today(), "zh"):
        raise HTTPException(status_code=404, detail="资料不存在或尚未上线")
    service.record_open(session, user_id, entry_id, _today())
    return {"ok": True}
