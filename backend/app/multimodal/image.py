"""
顺时 AI MiniMax 图片生成模块
MiniMax Image Generation API

功能: 生成健康报告图表、养生配图、中医体质图等

作者: Claw 🦅
日期: 2026-03-27
"""

import os
import logging
from typing import Optional

import aiohttp

logger = logging.getLogger(__name__)

# MiniMax API 配置
MINIMAX_IMAGE_BASE_URL = "https://api.minimaxi.com/v1/image_generation"


async def generate_image(
    prompt: str,
    aspect_ratio: str = "1:1",
    model: str = "image-01",
    n: int = 1,
) -> dict:
    """
    生成健康报告图表或养生配图

    Args:
        prompt: 图片描述提示词
        aspect_ratio: 图片比例
            - "1:1"  朋友圈/正方形
            - "16:9" 横版（文章配图）
            - "9:16" 竖版（手机海报）
        model: 模型名，默认 "image-01"
        n: 生成数量，默认 1

    Returns:
        dict: 包含图片 URL 列表和元数据
            {
                "code": 0,
                "urls": ["https://..."],  # 图片 URL 列表
                "model": "image-01",
                "aspect_ratio": "1:1",
                "n": 1,
                "created_at": "2026-03-27T...",
            }

    Raises:
        ValueError: 参数校验失败
        RuntimeError: API 调用失败
    """
    api_key = os.environ.get("MINIMAX_API_KEY", "")
    if not api_key:
        raise ValueError("环境变量 MINIMAX_API_KEY 未设置")

    # 参数校验
    if not prompt or not prompt.strip():
        raise ValueError("prompt 不能为空")

    valid_ratios = {"1:1", "16:9", "9:16"}
    if aspect_ratio not in valid_ratios:
        raise ValueError(f"aspect_ratio 必须是 {valid_ratios} 之一")

    if n < 1 or n > 9:
        raise ValueError("n 必须在 1-9 之间")

    url = MINIMAX_IMAGE_BASE_URL
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": model,
        "prompt": prompt,
        "aspect_ratio": aspect_ratio,
        "response_format": "url",
        "n": n,
    }

    logger.info(
        f"[MiniMax Image] 生成请求 | ratio={aspect_ratio} | model={model} | n={n} | "
        f"prompt_preview={prompt[:50]}..."
    )

    try:
        async with aiohttp.ClientSession() as session:
            async with session.post(
                url, headers=headers, json=payload, timeout=aiohttp.ClientTimeout(total=120)
            ) as resp:
                status = resp.status
                body = await resp.json()

                if status != 200:
                    logger.error(f"[MiniMax Image] API 错误 | status={status} | body={body}")
                    raise RuntimeError(
                        f"MiniMax Image API 返回错误状态码 {status}: {body}"
                    )

                code = body.get("code", 0)
                if code != 0:
                    logger.error(f"[MiniMax Image] 业务错误 | code={code} | body={body}")
                    raise RuntimeError(f"MiniMax Image API 业务错误: code={code}")

                # 提取 URL 列表
                data = body.get("data", {})
                urls = data.get("urls", []) if isinstance(data, dict) else []

                result = {
                    "code": 0,
                    "urls": urls,
                    "model": model,
                    "aspect_ratio": aspect_ratio,
                    "n": len(urls),
                    "created_at": body.get("created_at", ""),
                }

                logger.info(f"[MiniMax Image] 成功 | 生成 {len(urls)} 张图片")
                return result

    except aiohttp.ClientError as e:
        logger.error(f"[MiniMax Image] 网络错误: {e}")
        raise RuntimeError(f"MiniMax Image API 网络错误: {e}") from e
    except ValueError:
        raise
    except RuntimeError:
        raise
    except Exception as e:
        logger.exception(f"[MiniMax Image] 未知错误: {e}")
        raise RuntimeError(f"MiniMax Image 未知错误: {e}") from e
