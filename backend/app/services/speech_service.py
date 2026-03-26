"""
顺时 AI 语音服务 - 硅基流动 (SiliconFlow)
Speech Service: TTS + ASR via SiliconFlow API

支持的模型:
  TTS (Text-to-Speech):
    - FunAudioLLM/CosyVoice2-0.5B (中文主力, 预设音色: alex, benjamin, diana, anna, eric, shuangkuai)
    - fishaudio/fish-speech-1.5 (预设音色: benjamin, diana, alex)
    - fishaudio/fish-speech-1.4 (预设音色: benjamin)
  
  ASR (Speech-to-Text):
    - TeleAI/TeleSpeechASR (中文语音识别)
    - FunAudioLLM/SenseVoiceSmall (多语言语音识别)

作者: Claw 🦅
日期: 2026-03-19
"""

import os
import io
import logging
import tempfile
import json
import time
import uuid
import asyncio
from typing import Optional, List, Dict, Any, Tuple
from dataclasses import dataclass, field
from enum import Enum

import aiohttp

logger = logging.getLogger(__name__)


# ==================== 配置 ====================

SILICONFLOW_API_KEY = os.getenv("SILICONFLOW_API_KEY", "")
SILICONFLOW_BASE_URL = "https://api.siliconflow.cn/v1"

# TTS 模型配置
TTS_MODELS = {
    "cosyvoice2": {
        "model": "FunAudioLLM/CosyVoice2-0.5B",
        "voices": ["alex", "benjamin", "diana", "anna", "eric", "shuangkuai"],
        "voice_labels": {
            "alex": "Alex (中性·中文主力)",
            "benjamin": "Benjamin (男声·英文)",
            "diana": "Diana (女声·英文)",
            "anna": "Anna (女声·温柔)",
            "eric": "Eric (男声·磁性)",
            "shuangkuai": "双快 (童声·活泼)",
        },
        "max_input": 5000,
        "format": "mp3",
        "language": "zh",
    },
    "fish-speech-1.5": {
        "model": "fishaudio/fish-speech-1.5",
        "voices": ["benjamin", "diana", "alex"],
        "voice_labels": {
            "benjamin": "Benjamin (男声·英文)",
            "diana": "Diana (女声·英文)",
            "alex": "Alex (中性·英文)",
        },
        "max_input": 5000,
        "format": "mp3",
        "language": "en",
    },
    "fish-speech-1.4": {
        "model": "fishaudio/fish-speech-1.4",
        "voices": ["benjamin"],
        "voice_labels": {
            "benjamin": "Benjamin (男声·英文)",
        },
        "max_input": 5000,
        "format": "mp3",
        "language": "en",
    },
}

# ASR 模型配置
ASR_MODELS = {
    "telespeech": {
        "model": "TeleAI/TeleSpeechASR",
        "languages": ["zh", "en"],
        "max_file_size_mb": 25,
    },
    "sensevoice": {
        "model": "FunAudioLLM/SenseVoiceSmall",
        "languages": ["zh", "en", "ja", "ko", "yue"],
        "max_file_size_mb": 25,
    },
}

# 默认模型 — CosyVoice2 中文为主力
DEFAULT_TTS_MODEL = "cosyvoice2"
DEFAULT_TTS_VOICE = "alex"
DEFAULT_ASR_MODEL = "sensevoice"


# ==================== 数据模型 ====================

class TTSError(Exception):
    """TTS 错误"""
    pass


class ASRError(Exception):
    """ASR 错误"""
    pass


@dataclass
class TTSResult:
    """TTS 结果"""
    audio_data: bytes        # 音频二进制数据
    format: str              # mp3, wav, etc.
    model: str               # 使用的模型
    voice: str               # 使用的音色
    duration_ms: int = 0     # 音频时长(毫秒)
    input_text: str = ""     # 输入文本
    latency_ms: int = 0      # 延迟(毫秒)


@dataclass
class ASRResult:
    """ASR 结果"""
    text: str                # 识别文本
    model: str               # 使用的模型
    language: str = ""       # 检测到的语言
    confidence: float = 0.0  # 置信度
    duration_ms: int = 0     # 音频时长(毫秒)
    latency_ms: int = 0      # 延迟(毫秒)


@dataclass
class VoiceInfo:
    """音色信息"""
    id: str
    label: str
    model_key: str


# ==================== 语音服务 ====================

class SpeechService:
    """
    语音服务 - TTS + ASR
    
    通过硅基流动 API 实现:
    - 文字转语音 (TTS)
    - 语音识别 (ASR)
    """
    
    def __init__(self, api_key: str = None, base_url: str = None, timeout: int = 60):
        self.api_key = api_key or SILICONFLOW_API_KEY
        self.base_url = base_url or SILICONFLOW_BASE_URL
        self.timeout = timeout
        
        if not self.api_key:
            logger.warning("[SpeechService] SILICONFLOW_API_KEY 未配置")
    
    def _headers(self) -> Dict[str, str]:
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
    
    def _auth_headers(self) -> Dict[str, str]:
        return {
            "Authorization": f"Bearer {self.api_key}",
        }
    
    # ── TTS ──────────────────────────────────────
    
    async def text_to_speech(
        self,
        text: str,
        model: str = DEFAULT_TTS_MODEL,
        voice: str = DEFAULT_TTS_VOICE,
        response_format: str = "mp3",
        speed: float = 1.0,
    ) -> TTSResult:
        """
        文字转语音
        
        Args:
            text: 要转换的文本 (最多 5000 字符)
            model: TTS 模型 (fish-speech-1.5, fish-speech-1.4)
            voice: 音色 (benjamin, diana, alex)
            response_format: 输出格式 (mp3, wav, pcm, opus)
            speed: 语速 (0.5 - 2.0, 默认 1.0)
            
        Returns:
            TTSResult
            
        Raises:
            TTSError: TTS 转换失败
        """
        if not self.api_key:
            raise TTSError("SILICONFLOW_API_KEY 未配置")
        
        model_config = TTS_MODELS.get(model)
        if not model_config:
            raise TTSError(f"不支持的 TTS 模型: {model}, 可用: {list(TTS_MODELS.keys())}")
        
        if voice not in model_config["voices"]:
            raise TTSError(f"音色 '{voice}' 不在模型 {model} 的可用音色中: {model_config['voices']}")
        
        if len(text) > model_config["max_input"]:
            raise TTSError(f"文本过长: {len(text)} > {model_config['max_input']} 字符")
        
        sf_model = model_config["model"]
        sf_voice = f"{sf_model}:{voice}"
        
        payload = {
            "model": sf_model,
            "input": text,
            "voice": sf_voice,
            "response_format": response_format,
        }
        
        if speed != 1.0:
            payload["speed"] = speed
        
        url = f"{self.base_url}/audio/speech"
        start_time = time.time() * 1000
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    url,
                    headers=self._headers(),
                    json=payload,
                    timeout=aiohttp.ClientTimeout(total=self.timeout),
                ) as response:
                    if response.status == 200:
                        audio_data = await response.read()
                        latency = int(time.time() * 1000 - start_time)
                        
                        logger.info(
                            f"[SpeechService] TTS 成功: model={model}, voice={voice}, "
                            f"input={len(text)}chars, output={len(audio_data)}B, latency={latency}ms"
                        )
                        
                        return TTSResult(
                            audio_data=audio_data,
                            format=response_format,
                            model=model,
                            voice=voice,
                            input_text=text,
                            latency_ms=latency,
                        )
                    else:
                        error_text = await response.text()
                        logger.error(f"[SpeechService] TTS API 错误: {response.status} - {error_text}")
                        raise TTSError(f"API 错误 {response.status}: {error_text[:200]}")
                        
        except aiohttp.ClientTimeout:
            raise TTSError(f"请求超时 ({self.timeout}s)")
        except TTSError:
            raise
        except Exception as e:
            raise TTSError(f"TTS 请求失败: {e}")
    
    # ── ASR ──────────────────────────────────────
    
    async def speech_to_text(
        self,
        audio_data: bytes,
        model: str = DEFAULT_ASR_MODEL,
        filename: str = "audio.wav",
        language: str = None,
    ) -> ASRResult:
        """
        语音识别
        
        Args:
            audio_data: 音频二进制数据
            model: ASR 模型 (telespeech, sensevoice)
            filename: 文件名 (用于 Content-Type 推断)
            language: 指定语言 (zh, en, ja, ko, yue)，不指定则自动检测
            
        Returns:
            ASRResult
            
        Raises:
            ASRError: ASR 识别失败
        """
        if not self.api_key:
            raise ASRError("SILICONFLOW_API_KEY 未配置")
        
        model_config = ASR_MODELS.get(model)
        if not model_config:
            raise ASRError(f"不支持的 ASR 模型: {model}, 可用: {list(ASR_MODELS.keys())}")
        
        # 检查文件大小
        max_size = model_config["max_file_size_mb"] * 1024 * 1024
        if len(audio_data) > max_size:
            raise ASRError(f"音频文件过大: {len(audio_data)} > {max_size} bytes")
        
        url = f"{self.base_url}/audio/transcriptions"
        sf_model = model_config["model"]
        
        start_time = time.time() * 1000
        
        # 构建 multipart form data
        data = aiohttp.FormData()
        ext = os.path.splitext(filename)[1].lower()
        ct_map = {".wav": "audio/wav", ".mp3": "audio/mpeg", ".m4a": "audio/mp4",
                  ".flac": "audio/flac", ".ogg": "audio/ogg", ".webm": "audio/webm"}
        data.add_field("file", audio_data, filename=filename, content_type=ct_map.get(ext, "audio/wav"))
        data.add_field("model", sf_model)
        if language:
            data.add_field("language", language)
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    url,
                    headers=self._auth_headers(),
                    data=data,
                    timeout=aiohttp.ClientTimeout(total=self.timeout * 5),  # ASR 可能需要更长时间
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        text = result.get("text", "").strip()
                        latency = int(time.time() * 1000 - start_time)
                        
                        # 如果当前模型返回空文本，自动降级尝试备用模型
                        if not text and model == "sensevoice":
                            logger.info("[SpeechService] sensevoice 返回空文本，降级尝试 telespeech")
                            fallback_result = await self.speech_to_text(
                                audio_data=audio_data, model="telespeech",
                                filename=filename, language=language,
                            )
                            if fallback_result.text:
                                return fallback_result
                        
                        if not text:
                            logger.warning(f"[SpeechService] ASR 返回空文本: model={model}")
                        
                        logger.info(
                            f"[SpeechService] ASR 成功: model={model}, "
                            f"output={len(text)}chars, latency={latency}ms"
                        )
                        
                        return ASRResult(
                            text=text,
                            model=model,
                            latency_ms=latency,
                        )
                    else:
                        error_text = await response.text()
                        logger.error(f"[SpeechService] ASR API 错误: {response.status} - {error_text}")
                        raise ASRError(f"API 错误 {response.status}: {error_text[:200]}")
                        
        except aiohttp.ClientTimeout:
            raise ASRError(f"请求超时 ({self.timeout * 5}s)")
        except ASRError:
            raise
        except Exception as e:
            raise ASRError(f"ASR 请求失败: {e}")
    
    async def speech_to_text_from_file(
        self,
        file_path: str,
        model: str = DEFAULT_ASR_MODEL,
        language: str = None,
    ) -> ASRResult:
        """从文件路径进行语音识别"""
        with open(file_path, "rb") as f:
            audio_data = f.read()
        
        filename = os.path.basename(file_path)
        return await self.speech_to_text(audio_data, model=model, filename=filename, language=language)
    
    # ── 便捷方法 ──────────────────────────────
    
    def get_available_voices(self) -> List[VoiceInfo]:
        """获取所有可用音色"""
        voices = []
        for model_key, config in TTS_MODELS.items():
            for voice_id in config["voices"]:
                label = config["voice_labels"].get(voice_id, voice_id)
                voices.append(VoiceInfo(
                    id=f"{model_key}:{voice_id}",
                    label=label,
                    model_key=model_key,
                ))
        return voices
    
    def get_available_tts_models(self) -> List[Dict[str, Any]]:
        """获取可用 TTS 模型列表"""
        return [
            {
                "key": key,
                "model": config["model"],
                "voices": config["voices"],
                "voice_labels": config["voice_labels"],
                "max_input": config["max_input"],
                "format": config["format"],
            }
            for key, config in TTS_MODELS.items()
        ]
    
    def get_available_asr_models(self) -> List[Dict[str, Any]]:
        """获取可用 ASR 模型列表"""
        return [
            {
                "key": key,
                "model": config["model"],
                "languages": config["languages"],
                "max_file_size_mb": config["max_file_size_mb"],
            }
            for key, config in ASR_MODELS.items()
        ]


# ==================== 全局实例 ====================

_default_service: Optional[SpeechService] = None


def get_speech_service() -> SpeechService:
    """获取全局语音服务实例"""
    global _default_service
    if _default_service is None:
        _default_service = SpeechService()
    return _default_service
