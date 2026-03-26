"""
顺时 AI - Prompt 管理路由
CRUD + 版本管理 + 回滚 + 预览

作者: Claw 🦅
日期: 2026-03-18
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import List, Optional, Dict
import logging

from app.prompts.store import prompt_store, PromptVersion, PromptInfo

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/prompts", tags=["prompts"])


# ==================== Request Models ====================

class CreatePromptRequest(BaseModel):
    key: str = Field(..., description="Prompt 唯一标识，如 chat.system")
    content: str = Field(..., description="Prompt 内容")
    description: str = Field(default="", description="描述")
    category: str = Field(default="general", description="分类")
    created_by: str = Field(default="system", description="创建者")


class UpdatePromptRequest(BaseModel):
    content: str = Field(..., description="Prompt 新内容")
    changelog: str = Field(default="", description="更新说明")
    created_by: str = Field(default="system", description="更新者")


class PreviewRequest(BaseModel):
    variables: Dict[str, str] = Field(default_factory=dict, description="替换变量，如 {\"emotion\": \"焦虑\"}")


# ==================== 响应转换 ====================

def _version_to_dict(pv: PromptVersion) -> dict:
    return {
        "id": pv.id,
        "key": pv.prompt_key,
        "version": pv.version,
        "content": pv.content,
        "changelog": pv.changelog,
        "category": pv.category,
        "is_active": pv.is_active,
        "created_by": pv.created_by,
        "created_at": pv.created_at,
    }


def _info_to_dict(pi: PromptInfo) -> dict:
    return {
        "key": pi.key,
        "description": pi.description,
        "category": pi.category,
        "active_version": pi.active_version,
        "total_versions": pi.total_versions,
        "created_at": pi.created_at,
        "updated_at": pi.updated_at,
    }


# ==================== API Endpoints ====================

@router.get("")
async def list_prompts(
    category: Optional[str] = Query(None, description="按分类过滤"),
):
    """列出所有 prompts"""
    prompts = prompt_store.list_prompts(category=category)
    return {
        "success": True,
        "data": {
            "items": [_info_to_dict(p) for p in prompts],
            "total": len(prompts),
        },
    }


@router.get("/{key:path}")
async def get_prompt(
    key: str,
    user_id: Optional[str] = Query(None),
):
    """获取当前版本的 prompt 内容"""
    content = prompt_store.get_prompt(key, user_id=user_id)
    if not content:
        raise HTTPException(status_code=404, detail=f"Prompt '{key}' 不存在")

    # 获取版本信息
    versions = prompt_store.list_versions(key)
    active = next((v for v in versions if v.is_active), None)

    return {
        "success": True,
        "data": {
            "key": key,
            "content": content,
            "version": active.version if active else 0,
            "category": active.category if active else "",
        },
    }


@router.get("/{key:path}/versions")
async def list_versions(key: str):
    """列出 prompt 的所有版本"""
    versions = prompt_store.list_versions(key)
    if not versions:
        raise HTTPException(status_code=404, detail=f"Prompt '{key}' 不存在")
    return {
        "success": True,
        "data": {
            "items": [_version_to_dict(v) for v in versions],
            "total": len(versions),
        },
    }


@router.post("")
async def create_prompt(req: CreatePromptRequest):
    """创建新 prompt（第一个版本）"""
    try:
        pv = prompt_store.create_prompt(
            key=req.key,
            content=req.content,
            description=req.description,
            category=req.category,
            created_by=req.created_by,
        )
        return {"success": True, "data": _version_to_dict(pv)}
    except ValueError as e:
        raise HTTPException(status_code=409, detail=str(e))


@router.put("/{key:path}")
async def update_prompt(key: str, req: UpdatePromptRequest):
    """更新 prompt（自动创建新版本）"""
    try:
        pv = prompt_store.update_prompt(
            key=key,
            content=req.content,
            changelog=req.changelog,
            created_by=req.created_by,
        )
        return {"success": True, "data": _version_to_dict(pv)}
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.post("/{key:path}/rollback/{version:int}")
async def rollback_prompt(key: str, version: int):
    """回滚到指定版本"""
    try:
        pv = prompt_store.rollback(key, version)
        return {"success": True, "data": _version_to_dict(pv)}
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.delete("/{key:path}")
async def delete_prompt(key: str):
    """删除 prompt（含所有版本）"""
    deleted = prompt_store.delete_prompt(key)
    if not deleted:
        raise HTTPException(status_code=404, detail=f"Prompt '{key}' 不存在")
    return {"success": True, "message": f"已删除 prompt '{key}' 及其所有版本"}


@router.post("/{key:path}/preview")
async def preview_prompt(key: str, req: PreviewRequest = PreviewRequest()):
    """预览 prompt（替换变量后）"""
    content = prompt_store.preview(key, req.variables)
    if not content:
        raise HTTPException(status_code=404, detail=f"Prompt '{key}' 不存在")
    return {
        "success": True,
        "data": {
            "key": key,
            "content": content,
            "variables_applied": req.variables,
        },
    }
