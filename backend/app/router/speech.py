"""
顺时 AI 语音 API 路由
/api/v1/speech/*

端点:
  POST /api/v1/speech/tts         - 文字转语音
  POST /api/v1/speech/asr         - 语音识别
  GET  /api/v1/speech/models      - 获取可用模型列表
  GET  /api/v1/speech/voices      - 获取可用音色列表
  POST /api/v1/speech/chat-voice  - AI 对话 + 语音回复 (组合端点)

作者: Claw 🦅
日期: 2026-03-19
"""

import io
import logging
import tempfile
import os
from typing import Optional

from fastapi import APIRouter, HTTPException, UploadFile, File, Form, Query
from fastapi.responses import Response, JSONResponse
from pydantic import BaseModel, Field

from app.services.speech_service import (
    SpeechService,
    get_speech_service,
    TTSError,
    ASRError,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/speech", tags=["speech"])


# ==================== 请求/响应模型 ====================

class TTSRequest(BaseModel):
    """TTS 请求"""
    text: str = Field(..., min_length=1, max_length=5000, description="要转换的文本")
    model: str = Field(default="fish-speech-1.5", description="TTS 模型 (fish-speech-1.5, fish-speech-1.4)")
    voice: str = Field(default="benjamin", description="音色 (benjamin, diana, alex)")
    response_format: str = Field(default="mp3", description="输出格式 (mp3, wav, pcm, opus)")
    speed: float = Field(default=1.0, ge=0.5, le=2.0, description="语速 (0.5-2.0)")


class ASRResponse(BaseModel):
    """ASR 响应"""
    text: str
    model: str
    language: str = ""
    confidence: float = 0.0
    duration_ms: int = 0
    latency_ms: int = 0


class ModelsResponse(BaseModel):
    """模型列表响应"""
    tts_models: list
    asr_models: list


class VoicesResponse(BaseModel):
    """音色列表响应"""
    voices: list


# ==================== 端点 ====================

@router.post("/tts", summary="文字转语音")
async def text_to_speech(request: TTSRequest):
    """
    将文字转换为语音
    
    支持的模型和音色:
    - fish-speech-1.5: benjamin (男声), diana (女声), alex (中性)
    - fish-speech-1.4: benjamin (男声)
    
    返回音频文件 (mp3/wav 格式)
    """
    try:
        service = get_speech_service()
        result = await service.text_to_speech(
            text=request.text,
            model=request.model,
            voice=request.voice,
            response_format=request.response_format,
            speed=request.speed,
        )
        
        # 返回音频流
        content_type_map = {
            "mp3": "audio/mpeg",
            "wav": "audio/wav",
            "pcm": "audio/pcm",
            "opus": "audio/opus",
        }
        content_type = content_type_map.get(request.response_format, "audio/mpeg")
        
        return Response(
            content=result.audio_data,
            media_type=content_type,
            headers={
                "X-Speech-Model": result.model,
                "X-Speech-Voice": result.voice,
                "X-Speech-Latency-Ms": str(result.latency_ms),
                "X-Speech-Format": result.format,
            },
        )
        
    except TTSError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"[Speech API] TTS 错误: {e}")
        raise HTTPException(status_code=500, detail=f"TTS 服务异常: {e}")


@router.post("/asr", summary="语音识别")
async def speech_to_text(
    file: UploadFile = File(..., description="音频文件 (wav, mp3, m4a, flac, ogg)"),
    model: str = Form(default="sensevoice", description="ASR 模型 (sensevoice, telespeech)"),
    language: Optional[str] = Form(default=None, description="指定语言 (zh, en, ja, ko, yue)"),
):
    """
    语音识别 (ASR)
    
    支持的模型:
    - sensevoice: 多语言识别 (中/英/日/韩/粤)
    - telespeech: 中文识别
    
    支持的音频格式: wav, mp3, m4a, flac, ogg
    最大文件: 25MB
    """
    try:
        # 读取音频数据
        audio_data = await file.read()
        
        if not audio_data:
            raise HTTPException(status_code=400, detail="音频文件为空")
        
        service = get_speech_service()
        result = await service.speech_to_text(
            audio_data=audio_data,
            model=model,
            filename=file.filename or "audio.wav",
            language=language,
        )
        
        return ASRResponse(
            text=result.text,
            model=result.model,
            latency_ms=result.latency_ms,
        )
        
    except ASRError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[Speech API] ASR 错误: {e}")
        raise HTTPException(status_code=500, detail=f"ASR 服务异常: {e}")


@router.get("/models", summary="获取可用语音模型")
async def get_models():
    """获取所有可用的 TTS 和 ASR 模型"""
    service = get_speech_service()
    return ModelsResponse(
        tts_models=service.get_available_tts_models(),
        asr_models=service.get_available_asr_models(),
    )


@router.get("/voices", summary="获取可用音色")
async def get_voices():
    """获取所有可用的 TTS 音色"""
    service = get_speech_service()
    voices = service.get_available_voices()
    return VoicesResponse(
        voices=[
            {
                "id": v.id,
                "label": v.label,
                "model": v.model_key,
            }
            for v in voices
        ]
    )


@router.post("/chat-voice", summary="AI 对话 + 语音回复")
async def chat_voice(
    file: UploadFile = File(..., description="语音消息"),
    model: str = Form(default="sensevoice", description="ASR 模型"),
    tts_model: str = Form(default="fish-speech-1.5", description="TTS 模型"),
    voice: str = Form(default="benjamin", description="回复音色"),
):
    """
    语音对话: 语音输入 → 文字识别 → AI 回复 → 语音输出
    
    流程:
    1. 将用户语音转为文字 (ASR)
    2. 调用 AI 聊天生成回复文字
    3. 将回复文字转为语音 (TTS)
    4. 返回语音 + 文字
    """
    try:
        # Step 1: ASR
        audio_data = await file.read()
        service = get_speech_service()
        
        asr_result = await service.speech_to_text(
            audio_data=audio_data,
            model=model,
            filename=file.filename or "audio.wav",
        )
        
        if not asr_result.text:
            raise HTTPException(status_code=400, detail="未能识别出语音内容")
        
        # Step 2: AI Chat
        try:
            from app.llm.siliconflow import chat as llm_chat
            
            ai_response = await llm_chat(
                model="deepseek-v3.2",
                prompt=asr_result.text,
                system_prompt="你是顺时，一个温暖贴心的AI养生健康陪伴助手。回答简洁温暖，不超过100字。",
                temperature=0.7,
                max_tokens=200,
            )
            reply_text = ai_response.choices[0].get("message", {}).get("content", "抱歉，我暂时无法回答。")
        except Exception as e:
            logger.warning(f"[Speech API] AI Chat 调用失败: {e}")
            reply_text = "抱歉，AI 服务暂时不可用。"
        
        # Step 3: TTS
        tts_result = await service.text_to_speech(
            text=reply_text[:500],  # 限制长度
            model=tts_model,
            voice=voice,
        )
        
        return JSONResponse(
            content={
                "asr_text": asr_result.text,
                "reply_text": reply_text,
                "audio_format": tts_result.format,
                "audio_base64": tts_result.audio_data.hex(),
                "asr_latency_ms": asr_result.latency_ms,
                "tts_latency_ms": tts_result.latency_ms,
                "total_latency_ms": asr_result.latency_ms + tts_result.latency_ms,
            },
            headers={
                "X-ASR-Latency-Ms": str(asr_result.latency_ms),
                "X-TTS-Latency-Ms": str(tts_result.latency_ms),
            },
        )
        
    except HTTPException:
        raise
    except ASRError as e:
        raise HTTPException(status_code=400, detail=f"语音识别失败: {e}")
    except TTSError as e:
        raise HTTPException(status_code=400, detail=f"语音合成失败: {e}")
    except Exception as e:
        logger.error(f"[Speech API] chat-voice 错误: {e}")
        raise HTTPException(status_code=500, detail=f"语音对话服务异常: {e}")
