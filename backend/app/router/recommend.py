# 个性化推荐 API 路由

from typing import Optional, List
from fastapi import APIRouter, Query
from pydantic import BaseModel
from app.services.recommendation_engine import (
    get_personalized_recommendations,
    get_today_digest,
    _parse_json,
)

router = APIRouter(prefix="/api/v1/recommend", tags=["个性化推荐"])


class RecommendRequest(BaseModel):
    constitution_type: str = "pinghe"
    solar_term: str = ""
    season: str = ""
    health_status: Optional[dict] = None
    categories: Optional[List[str]] = None
    limit: int = 5
    offset: int = 0
    locale: str = "zh-CN"


def _format_item(r: dict) -> dict:
    """确保输出字段类型正确"""
    return {
        "id": r["id"],
        "title": r["title"],
        "type": r["type"],
        "image_url": r.get("image_url", ""),
        "description": (r.get("description") or "")[:120],
        "category": r.get("category", ""),
        "difficulty": r.get("difficulty", ""),
        "duration": r.get("duration", ""),
        "tags": _parse_json(r.get("tags", "[]")) if isinstance(r.get("tags"), str) else (r.get("tags") or []),
        "ingredients": _parse_json(r.get("ingredients", "[]")) if isinstance(r.get("ingredients"), str) else (r.get("ingredients") or []),
        "steps": _parse_json(r.get("steps", "[]")) if isinstance(r.get("steps"), str) else (r.get("steps") or []),
        "benefits": _parse_json(r.get("benefits", "[]")) if isinstance(r.get("benefits"), str) else (r.get("benefits") or []),
        "best_time": r.get("best_time", ""),
        "location": r.get("location", ""),
        "method": r.get("method", ""),
        "effect": r.get("effect", ""),
        "match_score": r.get("match_score", 0),
        "match_reasons": r.get("match_reasons", []),
        "is_premium": bool(r.get("is_premium", 0)),
    }


@router.post("/personalized")
async def personalized_recommendations(req: RecommendRequest):
    """个性化推荐内容列表"""
    results = get_personalized_recommendations(
        constitution_type=req.constitution_type,
        solar_term=req.solar_term,
        season=req.season,
        health_status=req.health_status,
        categories=req.categories,
        limit=req.limit,
        offset=req.offset,
        locale=req.locale,
    )
    items = [_format_item(r) for r in results]
    return {"success": True, "data": {"items": items, "total": len(items)}}


@router.post("/today-digest")
async def today_digest(req: RecommendRequest):
    """今日个性化养生摘要 (首页用)"""
    digest = get_today_digest(
        constitution_type=req.constitution_type,
        solar_term=req.solar_term,
        season=req.season,
        health_status=req.health_status,
    )
    return {"success": True, "data": digest}


@router.get("/content/{content_id}")
async def get_content_detail(content_id: str):
    """获取内容详情"""
    from app.database.db import get_db, row_to_dict
    db = get_db()
    row = db.execute("SELECT * FROM contents WHERE id = ?", (content_id,)).fetchone()
    if not row:
        return {"success": False, "error": "内容不存在"}
    item = row_to_dict(row)
    return {"success": True, "data": _format_item(item)}


@router.post("/content/{content_id}/like")
async def like_content(content_id: str):
    """点赞内容"""
    from app.database.db import get_db
    db = get_db()
    db.execute("UPDATE contents SET like_count = like_count + 1 WHERE id = ?", (content_id,))
    db.commit()
    return {"success": True}


@router.post("/content/{content_id}/view")
async def view_content(content_id: str):
    """记录浏览"""
    from app.database.db import get_db
    db = get_db()
    db.execute("UPDATE contents SET view_count = view_count + 1 WHERE id = ?", (content_id,))
    db.commit()
    return {"success": True}
