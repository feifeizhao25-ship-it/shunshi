"""
顺时 AI MiniMax 图片生成 API 路由
/api/v1/multimodal/images

作者: Claw 🦅
日期: 2026-03-27
"""

import logging
from fastapi import APIRouter, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

from app.multimodal.image import generate_image

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/multimodal/images", tags=["multimodal"])


# ==================== 请求/响应模型 ====================

class ImageGenerateRequest(BaseModel):
    """图片生成请求"""
    prompt: str = Field(..., min_length=1, max_length=4000, description="图片描述提示词")
    aspect_ratio: str = Field(
        default="1:1",
        description="图片比例: 1:1(朋友圈) | 16:9(横版) | 9:16(竖版/手机)"
    )
    model: str = Field(default="image-01", description="模型名，默认 image-01")
    n: int = Field(default=1, ge=1, le=9, description="生成数量，1-9")


class ImageGenerateResponse(BaseModel):
    """图片生成响应"""
    code: int = Field(description="状态码，0 表示成功")
    urls: list[str] = Field(description="生成的图片 URL 列表")
    model: str
    aspect_ratio: str
    n: int
    created_at: str = ""


# ==================== 端点 ====================

@router.post(
    "",
    response_model=ImageGenerateResponse,
    summary="生成健康报告图表/养生配图",
    description="""
MiniMax 图片生成接口，支持生成：
- 中医体质雷达图
- 健康报告图表
- 养生配图（朋友圈/横版/竖版）
    """,
)
async def create_image(req: ImageGenerateRequest) -> JSONResponse:
    """生成图片"""
    try:
        result = await generate_image(
            prompt=req.prompt,
            aspect_ratio=req.aspect_ratio,
            model=req.model,
            n=req.n,
        )
        return JSONResponse(content=result)
    except ValueError as e:
        logger.warning(f"[Multimodal Images] 参数错误: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except RuntimeError as e:
        logger.error(f"[Multimodal Images] 生成失败: {e}")
        raise HTTPException(status_code=502, detail=str(e))
    except Exception as e:
        logger.exception(f"[Multimodal Images] 未知错误: {e}")
        raise HTTPException(status_code=500, detail=f"内部错误: {e}")
