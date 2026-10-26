"""内容模块（养生内容 / CMS / 音频详情）：fail-closed。

骨架未接入任何内容源（SHUNSHI_CONTENT_SOURCE_URL 未配置）时，
以下端点一律 503 configured:false，绝不返回编造的内容列表或详情。
客户端对非 2xx 已有错误态处理（wellness_category_page / content_detail_page /
audio_player_page 均会展示加载失败并可重试）。
"""

from fastapi import APIRouter, Depends, HTTPException

from ..config import Settings
from ..deps import current_user, get_settings

router = APIRouter(prefix="/api/v1", tags=["content"])


def _require_content_source(settings: Settings) -> None:
    if not settings.content_source_url:
        raise HTTPException(
            status_code=503,
            detail={
                "detail": "内容源未配置（缺少 SHUNSHI_CONTENT_SOURCE_URL）",
                "configured": False,
            },
        )


@router.get("/contents")
def list_contents(
    user_id: str = Depends(current_user),
    settings: Settings = Depends(get_settings),
):
    _require_content_source(settings)
    raise HTTPException(status_code=501, detail="内容源代理尚未实现")


@router.get("/contents/{content_id}")
def content_detail(
    content_id: str,
    user_id: str = Depends(current_user),
    settings: Settings = Depends(get_settings),
):
    _require_content_source(settings)
    raise HTTPException(status_code=501, detail="内容源代理尚未实现")


@router.post("/contents/{content_id}/like")
def like_content(
    content_id: str,
    user_id: str = Depends(current_user),
    settings: Settings = Depends(get_settings),
):
    _require_content_source(settings)
    raise HTTPException(status_code=501, detail="内容源代理尚未实现")


@router.get("/cms/content/{content_id}")
def cms_content_detail(
    content_id: str,
    user_id: str = Depends(current_user),
    settings: Settings = Depends(get_settings),
):
    _require_content_source(settings)
    raise HTTPException(status_code=501, detail="内容源代理尚未实现")


@router.get("/seasons/audio/{audio_id}")
def audio_detail(
    audio_id: str,
    user_id: str = Depends(current_user),
    settings: Settings = Depends(get_settings),
):
    _require_content_source(settings)
    raise HTTPException(status_code=501, detail="内容源代理尚未实现")
