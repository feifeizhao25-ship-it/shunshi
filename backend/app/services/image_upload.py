"""
顺时 OSS/S3 图片上传服务
支持: 阿里云OSS / AWS S3 / MinIO / 本地存储

作者: Claw
日期: 2026-04-19
"""

import os
import uuid
import time
import logging
from typing import Optional
from datetime import datetime

import aiofiles
from fastapi import UploadFile

logger = logging.getLogger(__name__)

# ==================== 配置 ====================

STORAGE_BACKEND = os.environ.get("STORAGE_BACKEND", "local")  # local | oss | s3 | minio

# OSS 配置 (阿里云)
OSS_ACCESS_KEY_ID = os.environ.get("OSS_ACCESS_KEY_ID", "")
OSS_ACCESS_KEY_SECRET = os.environ.get("OSS_ACCESS_KEY_SECRET", "")
OSS_ENDPOINT = os.environ.get("OSS_ENDPOINT", "oss-cn-hangzhou.aliyuncs.com")
OSS_BUCKET_NAME = os.environ.get("OSS_BUCKET_NAME", "shunshi-assets")
OSS_CDN_DOMAIN = os.environ.get("OSS_CDN_DOMAIN", "cdn.shunshi.app")

# S3/MinIO 配置
S3_ACCESS_KEY = os.environ.get("S3_ACCESS_KEY", "")
S3_SECRET_KEY = os.environ.get("S3_SECRET_KEY", "")
S3_ENDPOINT = os.environ.get("S3_ENDPOINT", "")
S3_BUCKET = os.environ.get("S3_BUCKET", "shunshi-assets")
S3_REGION = os.environ.get("S3_REGION", "us-east-1")

# 本地存储
LOCAL_UPLOAD_DIR = os.environ.get("LOCAL_UPLOAD_DIR", "./static/uploads")

# 允许的文件类型
ALLOWED_EXTENSIONS = {
    ".jpg", ".jpeg", ".png", ".gif", ".webp", ".svg", ".bmp"
}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB


# ==================== 工具函数 ====================

def _get_extension(filename: str) -> str:
    """获取文件扩展名（小写）"""
    return os.path.splitext(filename)[1].lower()


def _generate_key(prefix: str, filename: str) -> str:
    """生成唯一的存储 key: prefix/YYYY/MM/DD/uuid.ext"""
    ext = _get_extension(filename) or ".jpg"
    now = datetime.now()
    date_path = now.strftime("%Y/%m/%d")
    unique_id = uuid.uuid4().hex[:12]
    return f"{prefix}/{date_path}/{unique_id}{ext}"


def _validate_file(filename: str, size: int) -> None:
    """校验文件类型和大小"""
    ext = _get_extension(filename)
    if ext not in ALLOWED_EXTENSIONS:
        raise ValueError(f"不支持的文件类型: {ext}，允许: {ALLOWED_EXTENSIONS}")
    if size > MAX_FILE_SIZE:
        raise ValueError(f"文件过大: {size} bytes，最大 {MAX_FILE_SIZE} bytes")


# ==================== 本地存储 ====================

async def _upload_local(file_bytes: bytes, key: str) -> str:
    """上传到本地目录"""
    filepath = os.path.join(LOCAL_UPLOAD_DIR, key)
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    async with aiofiles.open(filepath, "wb") as f:
        await f.write(file_bytes)
    return f"/static/uploads/{key}"


# ==================== OSS 存储 ====================

async def _upload_oss(file_bytes: bytes, key: str, content_type: str) -> str:
    """上传到阿里云 OSS"""
    try:
        import oss2
        auth = oss2.Auth(OSS_ACCESS_KEY_ID, OSS_ACCESS_KEY_SECRET)
        bucket = oss2.Bucket(auth, OSS_ENDPOINT, OSS_BUCKET_NAME)
        bucket.put_object(key, file_bytes, headers={"Content-Type": content_type})
        return f"https://{OSS_CDN_DOMAIN}/{key}"
    except ImportError:
        logger.warning("[OSS] oss2 未安装，回退到本地上传")
        return await _upload_local(file_bytes, key)
    except Exception as e:
        logger.error(f"[OSS] 上传失败: {e}，回退到本地")
        return await _upload_local(file_bytes, key)


# ==================== S3/MinIO 存储 ====================

async def _upload_s3(file_bytes: bytes, key: str, content_type: str) -> str:
    """上传到 S3 / MinIO"""
    try:
        import boto3
        client = boto3.client(
            "s3",
            aws_access_key_id=S3_ACCESS_KEY,
            aws_secret_access_key=S3_SECRET_KEY,
            endpoint_url=S3_ENDPOINT or None,
            region_name=S3_REGION,
        )
        client.put_object(
            Bucket=S3_BUCKET,
            Key=key,
            Body=file_bytes,
            ContentType=content_type,
        )
        if S3_ENDPOINT:
            return f"{S3_ENDPOINT}/{S3_BUCKET}/{key}"
        return f"https://{S3_BUCKET}.s3.{S3_REGION}.amazonaws.com/{key}"
    except ImportError:
        logger.warning("[S3] boto3 未安装，回退到本地上传")
        return await _upload_local(file_bytes, key)
    except Exception as e:
        logger.error(f"[S3] 上传失败: {e}，回退到本地")
        return await _upload_local(file_bytes, key)


# ==================== 统一上传接口 ====================

CONTENT_TYPE_MAP = {
    ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
    ".png": "image/png", ".gif": "image/gif",
    ".webp": "image/webp", ".svg": "image/svg+xml",
    ".bmp": "image/bmp",
}


async def upload_image(
    file: UploadFile,
    prefix: str = "images",
) -> dict:
    """
    统一图片上传接口

    Args:
        file: FastAPI UploadFile
        prefix: 存储路径前缀 (images/avatars/cards/banners...)

    Returns:
        {
            "url": "https://cdn.shunshi.app/images/2026/04/19/xxx.jpg",
            "key": "images/2026/04/19/xxx.jpg",
            "size": 12345,
            "content_type": "image/jpeg",
            "filename": "original.jpg",
        }
    """
    # 读取文件
    file_bytes = await file.read()
    size = len(file_bytes)
    filename = file.filename or "upload.jpg"

    # 校验
    _validate_file(filename, size)

    # 生成 key
    key = _generate_key(prefix, filename)
    ext = _get_extension(filename)
    content_type = CONTENT_TYPE_MAP.get(ext, "application/octet-stream")

    # 根据后端上传
    start = time.time()
    if STORAGE_BACKEND == "oss":
        url = await _upload_oss(file_bytes, key, content_type)
    elif STORAGE_BACKEND in ("s3", "minio"):
        url = await _upload_s3(file_bytes, key, content_type)
    else:
        url = await _upload_local(file_bytes, key)

    elapsed = time.time() - start
    logger.info(f"[Upload] {filename} -> {url} ({size} bytes, {elapsed:.2f}s)")

    return {
        "url": url,
        "key": key,
        "size": size,
        "content_type": content_type,
        "filename": filename,
    }


async def upload_bytes(
    file_bytes: bytes,
    filename: str = "image.jpg",
    prefix: str = "images",
) -> dict:
    """上传原始字节 (用于 AI 生成的图片等)"""
    size = len(file_bytes)
    _validate_file(filename, size)
    key = _generate_key(prefix, filename)
    ext = _get_extension(filename)
    content_type = CONTENT_TYPE_MAP.get(ext, "application/octet-stream")

    if STORAGE_BACKEND == "oss":
        url = await _upload_oss(file_bytes, key, content_type)
    elif STORAGE_BACKEND in ("s3", "minio"):
        url = await _upload_s3(file_bytes, key, content_type)
    else:
        url = await _upload_local(file_bytes, key)

    return {
        "url": url,
        "key": key,
        "size": size,
        "content_type": content_type,
        "filename": filename,
    }
