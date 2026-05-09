"""
顺时 — 横幅/公告 API (shunshi-banner)
首页横幅、运营公告、节气活动推送
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import Optional, List, Dict
from datetime import datetime, date

router = APIRouter(prefix="/api/v1/banner", tags=["banner"])

_banners: Dict[str, dict] = {
    "banner_001": {
        "id": "banner_001", "title": "立春养生指南",
        "subtitle": "顺应春气升发，肝气得舒",
        "image_url": "https://cdn.shunshi.app/banners/lichun_2026.jpg",
        "link_url": "/solar-term/lichun",
        "link_type": "internal",
        "position": "home_top",
        "platforms": ["ios_cn", "android_cn", "ios_global", "android_global"],
        "start_date": "2026-02-04",
        "end_date": "2026-02-18",
        "is_active": True,
        "priority": 1,
        "solar_term": "lichun",
        "created_at": "2026-01-20T00:00:00"
    },
    "banner_002": {
        "id": "banner_002", "title": "会员专享 · 八段锦课程",
        "subtitle": "坚持21天，养成健康习惯",
        "image_url": "https://cdn.shunshi.app/banners/membership_promo.jpg",
        "link_url": "/membership",
        "link_type": "internal",
        "position": "home_middle",
        "platforms": ["ios_cn", "android_cn"],
        "start_date": "2026-01-01",
        "end_date": "2026-12-31",
        "is_active": True,
        "priority": 2,
        "solar_term": None,
        "created_at": "2026-01-01T00:00:00"
    }
}


class BannerCreateRequest(BaseModel):
    title: str = Field(..., max_length=50)
    subtitle: Optional[str] = Field(None, max_length=100)
    image_url: str
    link_url: str
    link_type: str = Field(default="internal", description="internal/external")
    position: str = Field(default="home_top")
    platforms: List[str] = Field(default=["ios_cn", "android_cn"])
    start_date: str
    end_date: str
    priority: int = Field(default=5, ge=1, le=10)
    solar_term: Optional[str] = None


@router.get("/active", summary="获取当前有效横幅")
async def get_active_banners(
    platform: Optional[str] = Query(None, description="平台: ios_cn/android_cn/ios_global/android_global"),
    position: Optional[str] = Query(None, description="位置: home_top/home_middle/splash")
):
    today = date.today().isoformat()
    banners = [
        b for b in _banners.values()
        if b["is_active"]
        and b["start_date"] <= today <= b["end_date"]
    ]
    if platform:
        banners = [b for b in banners if platform in b["platforms"]]
    if position:
        banners = [b for b in banners if b["position"] == position]
    banners.sort(key=lambda x: x["priority"])
    return {"success": True, "data": {"banners": banners, "total": len(banners)}}


@router.get("/list", summary="横幅管理列表")
async def list_banners(is_active: Optional[bool] = Query(None)):
    items = list(_banners.values())
    if is_active is not None:
        items = [b for b in items if b["is_active"] == is_active]
    return {"success": True, "data": {"banners": items, "total": len(items)}}


@router.get("/{banner_id}", summary="横幅详情")
async def get_banner(banner_id: str):
    if banner_id not in _banners:
        raise HTTPException(status_code=404, detail="横幅不存在")
    return {"success": True, "data": _banners[banner_id]}


@router.post("/", summary="创建横幅")
async def create_banner(request: BannerCreateRequest):
    banner_id = f"banner_{len(_banners) + 1:03d}"
    banner = {
        "id": banner_id,
        "title": request.title,
        "subtitle": request.subtitle,
        "image_url": request.image_url,
        "link_url": request.link_url,
        "link_type": request.link_type,
        "position": request.position,
        "platforms": request.platforms,
        "start_date": request.start_date,
        "end_date": request.end_date,
        "is_active": True,
        "priority": request.priority,
        "solar_term": request.solar_term,
        "created_at": datetime.now().isoformat()
    }
    _banners[banner_id] = banner
    return {"success": True, "data": {"banner": banner, "message": "横幅创建成功"}}


@router.delete("/{banner_id}", summary="停用横幅")
async def deactivate_banner(banner_id: str):
    if banner_id not in _banners:
        raise HTTPException(status_code=404, detail="横幅不存在")
    _banners[banner_id]["is_active"] = False
    return {"success": True, "data": {"message": "横幅已停用"}}
