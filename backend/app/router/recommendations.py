"""
顺时 ShunShi - 智能推荐 API 路由
"""

from fastapi import APIRouter, Query
from typing import Optional

from app.services.recommendation_service import recommendation_service

router = APIRouter(prefix="/api/v1/recommendations", tags=["智能推荐"])


@router.get("/daily")
async def get_daily_recommendations(
    user_id: str = Query(..., description="用户ID"),
    locale: str = Query("zh-CN", description="语言: zh-CN/en-US"),
    limit: int = Query(3, description="推荐数量", le=10),
):
    """
    获取每日个性化推荐

    基于用户体质、当前季节、时辰、历史记录推荐内容
    """
    result = recommendation_service.get_daily_recommendations(user_id, locale, limit)
    return result


@router.get("/seasonal")
async def get_seasonal_recommendations(
    season: str = Query(..., description="季节: spring/summer/autumn/winter"),
    locale: str = Query("zh-CN", description="语言: zh-CN/en-US"),
    limit: int = Query(5, description="推荐数量", le=20),
):
    """获取季节推荐"""
    results = recommendation_service.get_seasonal_recommendations(season, locale, limit)
    return {"success": True, "data": {"items": results, "total": len(results)}}
