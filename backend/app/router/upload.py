"""
顺时 图片上传 API
/api/v1/upload

作者: Claw
日期: 2026-04-19
"""

import logging
from typing import Optional

from fastapi import APIRouter, HTTPException, UploadFile, File, Form, Depends

from app.services.image_upload import upload_image

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/upload", tags=["upload"])


# ==================== 端点 ====================

@router.post(
    "/image",
    summary="上传图片",
    description="""
上传图片到 OSS/S3/本地存储。

支持格式: jpg, jpeg, png, gif, webp, svg, bmp
最大大小: 10MB
""",
)
async def upload_image_endpoint(
    file: UploadFile = File(..., description="图片文件"),
    prefix: str = Form(default="images", description="存储路径前缀: images/avatars/cards/banners"),
) -> dict:
    """上传单个图片"""
    try:
        result = await upload_image(file, prefix=prefix)
        return {"success": True, "data": result}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.exception(f"[Upload] 上传失败: {e}")
        raise HTTPException(status_code=500, detail=f"上传失败: {e}")


@router.post(
    "/images",
    summary="批量上传图片",
    description="批量上传多张图片，最多 9 张",
)
async def upload_images_endpoint(
    files: list[UploadFile] = File(..., description="图片文件列表"),
    prefix: str = Form(default="images"),
) -> dict:
    """批量上传图片"""
    if len(files) > 9:
        raise HTTPException(status_code=400, detail="最多上传 9 张图片")

    results = []
    for f in files:
        try:
            result = await upload_image(f, prefix=prefix)
            results.append(result)
        except ValueError as e:
            results.append({"error": str(e), "filename": f.filename})
        except Exception as e:
            results.append({"error": f"上传失败: {e}", "filename": f.filename})

    success_count = sum(1 for r in results if "url" in r)
    return {
        "success": True,
        "data": {
            "total": len(files),
            "success": success_count,
            "failed": len(files) - success_count,
            "results": results,
        },
    }


@router.get(
    "/config",
    summary="获取上传配置",
    description="返回当前存储后端和允许的文件类型",
)
async def get_upload_config() -> dict:
    """获取上传配置信息"""
    import os
    return {
        "success": True,
        "data": {
            "storage_backend": os.environ.get("STORAGE_BACKEND", "local"),
            "max_file_size": "10MB",
            "allowed_types": ["jpg", "jpeg", "png", "gif", "webp", "svg", "bmp"],
            "cdn_domain": os.environ.get("OSS_CDN_DOMAIN", ""),
        },
    }
