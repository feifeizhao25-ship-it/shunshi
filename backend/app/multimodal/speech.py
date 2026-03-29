"""
顺时 AI MiniMax TTS 语音合成模块
MiniMax Text-to-Speech API

功能: 生成每日健康提示、冥想引导、运动指导音频

推荐音色（养生场景）:
  - female-yeping  温柔女声（推荐每日养生提示）
  - aisy            亲和女声
  - male-tianmei   甜美男声（适合运动指导）
  - male-qn-qingse  清新男声

作者: Claw 🦅
日期: 2026-03-27
"""

import os
import logging
from typing import Optional

import aiohttp

logger = logging.getLogger(__name__)

# MiniMax API 配置
MINIMAX_SPEECH_BASE_URL_V2 = "https://api.minimaxi.com/v1/t2a2_speech"  # 优先尝试
MINIMAX_SPEECH_BASE_URL_V1 = "https://api.minimaxi.com/v1/t2a_speech"  # fallback


async def generate_speech(
    text: str,
    voice: str = "female-yeping",
    speed: float = 1.0,
    format: str = "mp3",
) -> bytes:
    """
    生成每日健康提示、冥想引导、运动指导的音频

    Args:
        text: 要转换的文本（建议 2000 字以内）
        voice: 音色 ID，默认 "female-yeping"（温柔女声）
        speed: 语速，默认 1.0（范围 0.5-2.0）
        format: 输出格式，默认 "mp3"

    Returns:
        bytes: MP3 音频二进制数据

    Raises:
        ValueError: 参数校验失败
        RuntimeError: API 调用失败
    """
    api_key = os.environ.get("MINIMAX_API_KEY", "")
    if not api_key:
        raise ValueError("环境变量 MINIMAX_API_KEY 未设置")

    # 参数校验
    if not text or not text.strip():
        raise ValueError("text 不能为空")

    if speed < 0.25 or speed > 4.0:
        raise ValueError("speed 必须在 0.25-4.0 之间")

    valid_formats = {"mp3", "wav", "pcm", "ogg", "aac", "flac"}
    if format not in valid_formats:
        raise ValueError(f"format 必须是 {valid_formats} 之一")

    # 采样率和码率映射
    sample_rate_map = {"mp3": 32000, "wav": 48000, "pcm": 16000, "ogg": 32000, "aac": 32000, "flac": 48000}
    bitrate_map = {"mp3": 128000, "wav": 256000, "pcm": 256000, "ogg": 128000, "aac": 128000, "flac": 256000}

    sample_rate = sample_rate_map.get(format, 32000)
    bitrate = bitrate_map.get(format, 128000)

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }

    payload_v2 = {
        "model": "t2a-02.7",
        "text": text,
        "voice_setting": {
            "voice_id": voice,
            "speed": speed,
        },
        "audio_setting": {
            "sample_rate": sample_rate,
            "bitrate": bitrate,
            "format": format,
        },
    }

    logger.info(
        f"[MiniMax TTS] 生成请求 | voice={voice} | speed={speed} | format={format} | "
        f"text_len={len(text)}"
    )

    # 优先尝试 t2a-02.7 模型，失败则降级
    for attempt, (url, model, payload) in enumerate([
        (MINIMAX_SPEECH_BASE_URL_V2, "t2a-02.7", payload_v2),
        ("https://api.minimaxi.com/v1/t2a_speech", "speech-02.7", {
            **payload_v2,
            "model": "speech-02.7",
        }),
    ], 1):
        logger.info(f"[MiniMax TTS] 尝试模型 {attempt}: {model}")

        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    url, headers=headers, json=payload,
                    timeout=aiohttp.ClientTimeout(total=60),
                ) as resp:
                    status = resp.status

                    if status == 404 and attempt == 1:
                        logger.warning("[MiniMax TTS] t2a-02.7 模型不可用，尝试降级...")
                        continue

                    body = await resp.read()

                    if status != 200:
                        body_text = body[:500].decode("utf-8", errors="replace")
                        logger.error(
                            f"[MiniMax TTS] API 错误 | status={status} | model={model} | "
                            f"body={body_text}"
                        )
                        raise RuntimeError(
                            f"MiniMax TTS API 返回错误状态码 {status} (model={model})"
                        )

                    logger.info(
                        f"[MiniMax TTS] 成功 | model={model} | size={len(body)} bytes"
                    )
                    return body

        except aiohttp.ClientError as e:
            if attempt == 1 and "404" in str(e):
                logger.warning("[MiniMax TTS] 连接错误，尝试降级...")
                continue
            logger.error(f"[MiniMax TTS] 网络错误 (attempt {attempt}): {e}")
            raise RuntimeError(f"MiniMax TTS API 网络错误: {e}") from e

    # 所有尝试都失败
    raise RuntimeError("MiniMax TTS: 所有模型尝试均失败")
