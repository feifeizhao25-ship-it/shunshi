"""
顺时 ShunShi - 系统提示卡 API 路由
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import Optional, List

from app.services.system_prompt_cards import prompt_card_service, CARD_TYPES

router = APIRouter(prefix="/api/v1/cards", tags=["系统提示卡"])


# ============ Models ============

class GenerateCardRequest(BaseModel):
    """生成卡片请求"""
    card_type: str  # recipe/acupoint/exercise/tea/sleep
    content_id: str
    locale: str = "zh-CN"


class RelevantCardsRequest(BaseModel):
    """相关卡片请求"""
    message: str
    locale: str = "zh-CN"
    limit: int = 3


# ============ API Endpoints ============

@router.get("/types")
async def list_card_types(locale: str = Query("zh-CN", description="语言: zh-CN/en-US")):
    """列出所有卡片类型"""
    types = []
    for key, val in CARD_TYPES.items():
        types.append({
            "type": key,
            "emoji": val["emoji"],
            "label": val["label_cn"] if locale != "en-US" else val["label_en"],
            "fields": val["fields"],
        })
    return {"success": True, "data": {"types": types}}


@router.post("/generate")
async def generate_card(request: GenerateCardRequest):
    """生成卡片"""
    try:
        card = prompt_card_service.generate_card(
            card_type=request.card_type,
            content_id=request.content_id,
            locale=request.locale,
        )
        return {"success": True, "data": card}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/list")
async def list_cards(
    card_type: str = Query(..., description="卡片类型"),
    locale: str = Query("zh-CN", description="语言"),
    limit: int = Query(5, description="返回数量", le=20),
    season: Optional[str] = Query(None, description="季节过滤"),
):
    """获取指定类型的卡片列表"""
    cards = prompt_card_service.get_cards_by_type(card_type, locale, limit, season)
    return {"success": True, "data": {"cards": cards, "total": len(cards)}}


@router.post("/relevant")
async def get_relevant_cards(request: RelevantCardsRequest):
    """根据消息推荐相关卡片"""
    cards = prompt_card_service.get_relevant_cards(
        user_message=request.message,
        locale=request.locale,
        limit=request.limit,
    )
    return {"success": True, "data": {"cards": cards, "total": len(cards)}}
