"""
顺时 AI - Feature Flag 管理 API

GET    /api/v1/flags              — 列出所有 flags
GET    /api/v1/flags/{key}        — 获取 flag 详情
POST   /api/v1/flags              — 创建 flag
PATCH  /api/v1/flags/{key}        — 更新 flag
DELETE /api/v1/flags/{key}        — 删除 flag
POST   /api/v1/flags/evaluate     — 评估某用户某 flag（调试用）

管理 API 需要 admin 权限（Bearer token 校验）

作者: Claw 🦅
日期: 2026-03-18
"""

import os
import logging
from typing import Optional
from dataclasses import asdict

from fastapi import APIRouter, HTTPException, Header, Query
from pydantic import BaseModel, Field

from app.feature_flags.store import flag_store

logger = logging.getLogger(__name__)

router = APIRouter(tags=["feature-flags"])

# ==================== Admin 鉴权 ====================

# 从环境变量读取 admin token，默认开发用
ADMIN_TOKEN = os.environ.get("ADMIN_TOKEN", "dev-admin-token")


def _verify_admin(authorization: Optional[str] = None):
    """校验 admin token"""
    if not authorization:
        raise HTTPException(status_code=401, detail="缺少 Authorization header")
    token = authorization.replace("Bearer ", "") if authorization.startswith("Bearer ") else authorization
    if token != ADMIN_TOKEN:
        raise HTTPException(status_code=403, detail="无效的 admin token")


# ==================== Pydantic Models ====================

class FlagCreateRequest(BaseModel):
    key: str = Field(..., min_length=1, max_length=128, description="Flag key (如 prompt.v2_enabled)")
    value: bool | str | dict | list = Field(..., description="Flag 默认值")
    rollout_pct: float = Field(100.0, ge=0.0, le=100.0, description="灰度百分比")
    user_whitelist: list[str] = Field(default_factory=list, description="白名单用户 ID 列表")
    description: str = Field("", max_length=512, description="描述")
    category: str = Field("general", description="分类: prompt/skill/payment/content/general")


class FlagUpdateRequest(BaseModel):
    value: Optional[bool | str | dict | list] = None
    rollout_pct: Optional[float] = Field(None, ge=0.0, le=100.0)
    user_whitelist: Optional[list[str]] = None
    description: Optional[str] = Field(None, max_length=512)
    category: Optional[str] = None


class EvaluateRequest(BaseModel):
    key: str = Field(..., description="Flag key")
    user_id: Optional[str] = Field(None, description="用户 ID（用于灰度计算）")


# ==================== Endpoints ====================

@router.get("")
async def list_flags(
    category: Optional[str] = Query(None, description="按分类过滤"),
    authorization: Optional[str] = Header(None),
):
    """列出所有 feature flags"""
    _verify_admin(authorization)
    flags = flag_store.list_flags(category=category)
    return {
        "total": len(flags),
        "flags": [asdict(f) for f in flags],
    }


@router.get("/{key:path}")
async def get_flag(
    key: str,
    authorization: Optional[str] = Header(None),
):
    """获取单个 flag 详情"""
    _verify_admin(authorization)
    flag = flag_store.get_flag(key)
    if flag is None:
        raise HTTPException(status_code=404, detail=f"Flag '{key}' 不存在")
    return asdict(flag)


@router.post("")
async def create_flag(
    req: FlagCreateRequest,
    authorization: Optional[str] = Header(None),
):
    """创建新 flag"""
    _verify_admin(authorization)

    existing = flag_store.get_flag(req.key)
    if existing:
        raise HTTPException(status_code=409, detail=f"Flag '{req.key}' 已存在")

    flag_store.set_flag(
        key=req.key,
        value=req.value,
        rollout_pct=req.rollout_pct,
        user_whitelist=req.user_whitelist,
        description=req.description,
        category=req.category,
    )
    flag = flag_store.get_flag(req.key)
    return {"message": "创建成功", "flag": asdict(flag)}


@router.patch("/{key:path}")
async def update_flag(
    key: str,
    req: FlagUpdateRequest,
    authorization: Optional[str] = Header(None),
):
    """更新 flag"""
    _verify_admin(authorization)

    existing = flag_store.get_flag(key)
    if existing is None:
        raise HTTPException(status_code=404, detail=f"Flag '{key}' 不存在")

    # 读取当前值用于合并
    update_kwargs = {}
    if req.value is not None:
        update_kwargs["value"] = req.value
    if req.rollout_pct is not None:
        update_kwargs["rollout_pct"] = req.rollout_pct
    if req.user_whitelist is not None:
        update_kwargs["user_whitelist"] = req.user_whitelist
    if req.description is not None:
        update_kwargs["description"] = req.description
    if req.category is not None:
        update_kwargs["category"] = req.category

    if update_kwargs:
        flag_store.set_flag(key=key, **update_kwargs)

    flag = flag_store.get_flag(key)
    return {"message": "更新成功", "flag": asdict(flag)}


@router.delete("/{key:path}")
async def delete_flag(
    key: str,
    authorization: Optional[str] = Header(None),
):
    """删除 flag"""
    _verify_admin(authorization)

    if not flag_store.delete_flag(key):
        raise HTTPException(status_code=404, detail=f"Flag '{key}' 不存在")
    return {"message": f"Flag '{key}' 已删除"}


@router.post("/evaluate")
async def evaluate_flag(
    req: EvaluateRequest,
    authorization: Optional[str] = Header(None),
):
    """
    评估某用户某 flag 的结果（调试用）
    返回启用状态、原因、用户 hash 值等调试信息
    """
    _verify_admin(authorization)
    return flag_store.evaluate(req.key, req.user_id)
