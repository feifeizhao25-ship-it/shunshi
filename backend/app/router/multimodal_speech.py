"""
顺时 AI MiniMax TTS 语音合成 API 路由
/api/v1/multimodal/speech

作者: Claw 🦅
日期: 2026-03-27
"""

import logging
from fastapi import APIRouter, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel, Field

from app.multimodal.speech import generate_speech

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/multimodal/speech", tags=["multimodal"])


# ==================== 请求/响应模型 ====================

class SpeechGenerateRequest(BaseModel):
    """TTS 请求"""
    text: str = Field(..., min_length=1, max_length=5000, description="要转换的文本")
    voice: str = Field(
        default="female-yeping",
        description="音色 ID:"
                    " female-yeping(温柔女声) | aisy(亲和女声) | "
                    "male-tianmei(甜美男声) | male-qn-qingse(清新男声)"
    )
    speed: float = Field(default=1.0, ge=0.25, le=4.0, description="语速 0.25-4.0")
    format: str = Field(default="mp3", description="输出格式: mp3 | wav | pcm | ogg | aac | flac")


# ==================== 端点 ====================

@router.post(
    "",
    summary="生成健康提示/冥想引导/运动指导音频",
    description="""
MiniMax TTS 语音合成接口，支持生成：
- 每日健康提示语音
- 冥想引导音频
- 运动指导语音（八段锦、太极等）

默认使用温柔女声（female-yeping），适合养生场景。
    """,
)
async def create_speech(req: SpeechGenerateRequest) -> Response:
    """生成语音"""
    try:
        audio_bytes = await generate_speech(
            text=req.text,
            voice=req.voice,
            speed=req.speed,
            format=req.format,
        )
        content_type_map = {
            "mp3": "audio/mpeg",
            "wav": "audio/wav",
            "pcm": "audio/pcm",
            "ogg": "audio/ogg",
            "aac": "audio/aac",
            "flac": "audio/flac",
        }
        content_type = content_type_map.get(req.format, "audio/mpeg")

        logger.info(
            f"[Multimodal Speech] 成功 | voice={req.voice} | "
            f"format={req.format} | size={len(audio_bytes)} bytes"
        )
        return Response(
            content=audio_bytes,
            media_type=content_type,
            headers={
                "Content-Disposition": f'attachment; filename="shunshi_speech.{req.format}"',
                "Content-Length": str(len(audio_bytes)),
            },
        )
    except ValueError as e:
        logger.warning(f"[Multimodal Speech] 参数错误: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except RuntimeError as e:
        logger.error(f"[Multimodal Speech] 生成失败: {e}")
        raise HTTPException(status_code=502, detail=str(e))
    except Exception as e:
        logger.exception(f"[Multimodal Speech] 未知错误: {e}")
        raise HTTPException(status_code=500, detail=f"内部错误: {e}")
