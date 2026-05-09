"""
顺时 AI MiniMax 视频生成模块
MiniMax Video Generation API

功能: 生成运动指导视频（八段锦、太极等）
注意: 视频生成是异步的，需要通过 task_id 查询状态

作者: Claw 🦅
日期: 2026-03-27
"""

import os
import logging
from typing import Optional, List

import aiohttp

logger = logging.getLogger(__name__)

# MiniMax API 配置
MINIMAX_VIDEO_GENERATE_URL = "https://api.minimax.chat/v1/video_generation"
MINIMAX_VIDEO_QUERY_URL = "https://api.minimax.chat/v1/query/video_generation"


async def generate_video(
    prompt: str,
    subject_image_url: str,
    model: str = "S2V-01",
) -> dict:
    """
    生成运动指导视频（八段锦、太极等）

    注意：视频生成是异步的，此接口立即返回 task_id，
    需通过 query_video_status(task_id) 查询进度和结果。

    Args:
        prompt: 视频描述提示词
        subject_image_url: 人物参考图 URL（需是可访问的公网 URL）
        model: 模型名，默认 "S2V-01"

    Returns:
        dict: 包含 task_id 和任务信息
            {
                "code": 0,
                "task_id": "vs_xxxxx",
                "status": "pending",
                "model": "S2V-01",
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

    if not subject_image_url or not subject_image_url.strip():
        raise ValueError("subject_image_url 不能为空")

    # 简单 URL 格式校验
    if not subject_image_url.startswith(("http://", "https://")):
        raise ValueError("subject_image_url 必须是有效的 HTTP/HTTPS URL")

    url = MINIMAX_VIDEO_GENERATE_URL
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": model,
        "prompt": prompt,
        "subject_reference": [
            {
                "type": "character",
                "image": [subject_image_url],
            }
        ],
    }

    logger.info(
        f"[MiniMax Video] 生成请求 | model={model} | "
        f"prompt_preview={prompt[:50]}... | image={subject_image_url[:60]}..."
    )

    try:
        async with aiohttp.ClientSession() as session:
            async with session.post(
                url, headers=headers, json=payload,
                timeout=aiohttp.ClientTimeout(total=30),
            ) as resp:
                status = resp.status
                body = await resp.json()

                if status != 200:
                    logger.error(f"[MiniMax Video] API 错误 | status={status} | body={body}")
                    raise RuntimeError(
                        f"MiniMax Video API 返回错误状态码 {status}: {body}"
                    )

                code = body.get("code", 0)
                if code != 0:
                    logger.error(f"[MiniMax Video] 业务错误 | code={code} | body={body}")
                    raise RuntimeError(f"MiniMax Video API 业务错误: code={code}")

                task_id = body.get("task_id", "")
                if not task_id:
                    raise RuntimeError(f"MiniMax Video 未返回 task_id: {body}")

                result = {
                    "code": 0,
                    "task_id": task_id,
                    "status": body.get("status", "pending"),
                    "model": model,
                    "description": prompt,
                }

                logger.info(f"[MiniMax Video] 任务已提交 | task_id={task_id}")
                return result

    except aiohttp.ClientError as e:
        logger.error(f"[MiniMax Video] 网络错误: {e}")
        raise RuntimeError(f"MiniMax Video API 网络错误: {e}") from e
    except ValueError:
        raise
    except RuntimeError:
        raise
    except Exception as e:
        logger.exception(f"[MiniMax Video] 未知错误: {e}")
        raise RuntimeError(f"MiniMax Video 未知错误: {e}") from e


async def query_video_status(task_id: str) -> dict:
    """
    查询视频生成状态

    Args:
        task_id: generate_video 返回的 task_id

    Returns:
        dict: 任务状态和结果
            {
                "code": 0,
                "task_id": "vs_xxxxx",
                "status": "success" | "pending" | "fail" | "running",
                "video_url": "https://...",  # 成功时返回
                "fail_reason": "...",          # 失败时返回
            }

    Raises:
        ValueError: task_id 为空
        RuntimeError: API 调用失败
    """
    api_key = os.environ.get("MINIMAX_API_KEY", "")
    if not api_key:
        raise ValueError("环境变量 MINIMAX_API_KEY 未设置")

    if not task_id or not task_id.strip():
        raise ValueError("task_id 不能为空")

    url = f"{MINIMAX_VIDEO_QUERY_URL}?task_id={task_id}"
    headers = {
        "Authorization": f"Bearer {api_key}",
    }

    logger.info(f"[MiniMax Video Query] 查询任务 | task_id={task_id}")

    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(
                url, headers=headers,
                timeout=aiohttp.ClientTimeout(total=30),
            ) as resp:
                status = resp.status
                body = await resp.json()

                if status != 200:
                    logger.error(f"[MiniMax Video Query] API 错误 | status={status} | body={body}")
                    raise RuntimeError(
                        f"MiniMax Video Query API 返回错误状态码 {status}: {body}"
                    )

                code = body.get("code", 0)
                if code != 0:
                    logger.error(f"[MiniMax Video Query] 业务错误 | code={code} | body={body}")
                    raise RuntimeError(f"MiniMax Video Query 业务错误: code={code}")

                result = {
                    "code": 0,
                    "task_id": task_id,
                    "status": body.get("status", "unknown"),
                    "video_url": body.get("video", {}).get("url") if isinstance(body.get("video"), dict) else None,
                    "fail_reason": body.get("fail_reason"),
                }

                logger.info(
                    f"[MiniMax Video Query] 状态更新 | task_id={task_id} | "
                    f"status={result['status']}"
                )
                return result

    except aiohttp.ClientError as e:
        logger.error(f"[MiniMax Video Query] 网络错误: {e}")
        raise RuntimeError(f"MiniMax Video Query API 网络错误: {e}") from e
    except ValueError:
        raise
    except RuntimeError:
        raise
    except Exception as e:
        logger.exception(f"[MiniMax Video Query] 未知错误: {e}")
        raise RuntimeError(f"MiniMax Video Query 未知错误: {e}") from e
