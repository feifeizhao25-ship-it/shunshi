"""
顺时 AI MiniMax 多模态模块
Multimodal capabilities via MiniMax API

支持:
  - 图片生成 (image.py)
  - TTS 语音合成 (speech.py)
  - 视频生成 (video.py)

作者: Claw 🦅
日期: 2026-03-27
"""

from .image import generate_image
from .speech import generate_speech
from .video import generate_video, query_video_status

__all__ = [
    "generate_image",
    "generate_speech",
    "generate_video",
    "query_video_status",
]
