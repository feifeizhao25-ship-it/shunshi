"""
顺时 AI MiniMax 视频生成 API 路由
/api/v1/multimodal/videos

作者: Claw 🦅
日期: 2026-03-27
"""

import logging
from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

from app.multimodal.video import generate_video, query_video_status

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/multimodal/videos", tags=["multimodal"])


# ==================== 请求/响应模型 ====================

class VideoGenerateRequest(BaseModel):
    """视频生成请求"""
    prompt: str = Field(
        ..., min_length=1, max_length=2000,
        description="视频描述提示词（如：人物打太极，动作缓慢舒展，背景宁静）"
    )
    subject_image_url: str = Field(
        ..., description="人物参考图 URL（需是可访问的公网 URL）"
    )
    model: str = Field(default="S2V-01", description="模型名，默认 S2V-01")


class VideoGenerateResponse(BaseModel):
    """视频生成响应（异步，立即返回 task_id）"""
    code: int
    task_id: str = Field(description="任务 ID，用于查询视频状态")
    status: str = Field(default="pending", description="任务状态: pending | running | success | fail")
    model: str
    description: str


class VideoStatusRequest(BaseModel):
    """视频状态查询请求"""
    task_id: str = Field(..., description="generate_video 返回的 task_id")


class VideoStatusResponse(BaseModel):
    """视频状态响应"""
    code: int
    task_id: str
    status: str = Field(description="pending | running | success | fail")
    video_url: str | None = Field(default=None, description="成功时返回视频 URL")
    fail_reason: str | None = Field(default=None, description="失败时返回原因")


# ==================== 端点 ====================

@router.post(
    "",
    response_model=VideoGenerateResponse,
    summary="生成运动指导视频（八段锦/太极等）",
    description="""
MiniMax 视频生成接口，支持生成：
- 八段锦动作指导视频
- 太极拳演示视频
- 其他运动养生视频

注意：视频生成是异步的，此接口立即返回 task_id，
需通过 GET /api/v1/multimodal/videos/status 查询进度和结果。
    """,
)
async def create_video(req: VideoGenerateRequest) -> JSONResponse:
    """提交视频生成任务"""
    try:
        result = await generate_video(
            prompt=req.prompt,
            subject_image_url=req.subject_image_url,
            model=req.model,
        )
        return JSONResponse(content=result)
    except ValueError as e:
        logger.warning(f"[Multimodal Videos] 参数错误: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except RuntimeError as e:
        logger.error(f"[Multimodal Videos] 提交失败: {e}")
        raise HTTPException(status_code=502, detail=str(e))
    except Exception as e:
        logger.exception(f"[Multimodal Videos] 未知错误: {e}")
        raise HTTPException(status_code=500, detail=f"内部错误: {e}")


@router.get(
    "/status",
    response_model=VideoStatusResponse,
    summary="查询视频生成状态",
    description="通过 task_id 查询视频生成进度和结果",
)
async def get_video_status(task_id: str) -> JSONResponse:
    """查询视频生成状态"""
    try:
        result = await query_video_status(task_id=task_id)
        return JSONResponse(content=result)
    except ValueError as e:
        logger.warning(f"[Multimodal Videos Status] 参数错误: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except RuntimeError as e:
        logger.error(f"[Multimodal Videos Status] 查询失败: {e}")
        raise HTTPException(status_code=502, detail=str(e))
    except Exception as e:
        logger.exception(f"[Multimodal Videos Status] 未知错误: {e}")
        raise HTTPException(status_code=500, detail=f"内部错误: {e}")
