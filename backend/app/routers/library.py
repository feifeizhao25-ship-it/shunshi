"""资料库接口：条目（带展示规则的结论）、个性化「为你推荐」、关注/静音/总开关、访问记录。仅登录用户。"""

from __future__ import annotations

from typing import List, Optional

from fastapi import APIRouter, Depends, Header, HTTPException, Request
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from ..deps import current_user, get_session, get_settings
from ..locale_context import RequestLocale, request_locale
from ..library import service, store
from ..utils import solar_term_calendar

router = APIRouter(prefix="/api/v1/library", tags=["library"])


def _today():
    return solar_term_calendar.beijing_today()


# 资料库的内容（官方文件的标题、摘要、出处）只有中文版，没有经过核对的英文版。
# 国际版请求（X-App-Market: global）不返回中文条目，也不临时机翻——返回英文的「暂不提供」状态。
LIB_EN_NOTE = "The reference library is currently available in Chinese only, so no entries are shown in the international edition."


def _en_topics():
    from ..library import feed as fd

    return [{"id": k, "name": v["en"]} for k, v in fd.TOPICS.items()]


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
def entries(request: Request, authorization: Optional[str] = Header(default=None), session: Session = Depends(get_session), loc: RequestLocale = Depends(request_locale)):
    today = _today()
    if loc.is_global:
        return {"entries": [], "generated_for": today.isoformat(), "preview_pending": False, "personalized": False, "available": False, "note": LIB_EN_NOTE}
    items = store.annotated(today, "zh")
    uid = _optional_user(request, authorization, session)
    if uid:
        marks = service.visit_badges(session, uid, today, items)
        for e in items:
            if e["id"] in marks:
                e["badge"] = marks[e["id"]]
    return {"entries": items, "generated_for": today.isoformat(), "preview_pending": store.show_pending(), "personalized": bool(uid)}


@router.get("/entries/{entry_id}")
def entry_detail(entry_id: str, loc: RequestLocale = Depends(request_locale)):
    if loc.is_global:
        raise HTTPException(status_code=404, detail="This reference entry is not available in English.")
    e = store.find(entry_id, _today(), "zh")
    if not e:
        raise HTTPException(status_code=404, detail="资料不存在或尚未上线")
    return e


@router.get("/feed")
def feed(session: Session = Depends(get_session), user_id: str = Depends(current_user), loc: RequestLocale = Depends(request_locale)):
    if loc.is_global:
        prefs = service.preferences(session, user_id)
        return {"items": [], "enabled": prefs["enabled"], "available": False,
                "topics": [{**t, "followed": t["id"] in prefs["followed"], "muted": t["id"] in prefs["muted"]} for t in _en_topics()],
                "since": None, "generated_for": _today().isoformat(), "note": LIB_EN_NOTE}
    return service.build_feed(session, user_id, _today(), "zh")


@router.get("/preferences")
def get_prefs(session: Session = Depends(get_session), user_id: str = Depends(current_user), loc: RequestLocale = Depends(request_locale)):
    from ..library import feed as fd

    lang = "en" if loc.is_global else "zh"
    return {**service.preferences(session, user_id), "topics": [{"id": k, "name": v[lang]} for k, v in fd.TOPICS.items()]}


@router.put("/preferences")
def put_prefs(body: PrefsBody, session: Session = Depends(get_session), user_id: str = Depends(current_user), loc: RequestLocale = Depends(request_locale)):
    try:
        return service.set_preferences(session, user_id, enabled=body.enabled, follow=body.follow, unfollow=body.unfollow, mute=body.mute, unmute=body.unmute)
    except ValueError as e:
        raise HTTPException(status_code=422, detail="Unknown topic" if loc.is_global else "未知的主题") from e


@router.post("/visit")
def visit(session: Session = Depends(get_session), user_id: str = Depends(current_user)):
    service.record_visit(session, user_id, _today())
    return {"ok": True}


@router.post("/opened/{entry_id}")
def opened(entry_id: str, session: Session = Depends(get_session), user_id: str = Depends(current_user), loc: RequestLocale = Depends(request_locale)):
    if not store.find(entry_id, _today(), "zh"):
        raise HTTPException(status_code=404, detail="Entry not found or not live yet" if loc.is_global else "资料不存在或尚未上线")
    service.record_open(session, user_id, entry_id, _today())
    return {"ok": True}
