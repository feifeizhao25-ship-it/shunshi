"""
顺时 - 记忆系统 API 路由
"""

from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException, Query, Depends
from pydantic import BaseModel
from typing import Optional, List, Dict, Any

from app.services.memory_system import memory_system, MemoryType
from app.deps import current_user

router = APIRouter(prefix="/api/v1/memory", tags=["记忆系统"])


# ============ Models ============

class CreateMemoryRequest(BaseModel):
    """创建记忆请求"""
    user_id: Optional[str] = None
    type: str  # preference / habit / emotional_trend / reflection_theme
    content: str
    confidence: float = 1.0
    source: str = "manual"
    metadata: Optional[Dict[str, Any]] = None


class ExtractMemoryRequest(BaseModel):
    """提取记忆请求"""
    text: str


class ExtractMemoryResponse(BaseModel):
    """提取记忆响应"""
    candidates: List[Dict[str, Any]]


class ClearMemoryRequest(BaseModel):
    """清除记忆请求"""
    user_id: str


# ============ API 端点 ============

@router.get("/context")
async def get_user_context(user_id: str = Depends(current_user)):
    """
    获取用户上下文

    构建用户画像，包含偏好、习惯、情绪趋势、反思主题。
    此接口主要给AI对话系统调用，用于个性化对话。
    """
    context = memory_system.get_user_context(user_id)
    return context


@router.get("/list")
async def list_memories(
    user_id: str = Depends(current_user),
    type: Optional[str] = Query(None, description="记忆类型过滤"),
    limit: int = Query(50, description="返回数量限制", le=100),
):
    """
    列出用户记忆

    支持按类型过滤，返回最近创建的记忆列表
    """
    memories = memory_system.get_recent_memories(
        user_id=user_id,
        limit=limit,
        memory_type=type,
    )
    return {
        "user_id": user_id,
        "count": len(memories),
        "memories": memories,
    }


@router.get("/stats")
async def get_memory_stats(user_id: str = Depends(current_user)):
    """获取用户记忆统计"""
    stats = memory_system.get_memory_stats(user_id)
    return stats


@router.post("/create")
async def create_memory(request: CreateMemoryRequest, user_id: str = Depends(current_user)):
    """
    手动创建一条记忆

    可由AI对话系统在分析对话后调用
    """
    # 验证记忆类型
    valid_types = [mt.value for mt in MemoryType]
    if request.type not in valid_types:
        raise HTTPException(
            status_code=400,
            detail=f"无效的记忆类型: {request.type}，有效值: {valid_types}",
        )

    if request.user_id and request.user_id != user_id:
        raise HTTPException(status_code=403, detail="不能为其他用户创建记忆")

    item = memory_system.update_user_memory(
        user_id=user_id,
        memory_type=request.type,
        content=request.content,
        confidence=request.confidence,
        source=request.source,
        metadata=request.metadata,
    )
    return {"success": True, "memory": item.to_dict()}


@router.post("/extract")
async def extract_memories(request: ExtractMemoryRequest):
    """
    从文本中提取潜在记忆

    基于关键词规则分析对话文本，返回可提取的记忆候选
    """
    candidates = memory_system.extract_preferences(request.text)
    return ExtractMemoryResponse(candidates=candidates)


@router.post("/clear")
async def clear_all_memories(request: ClearMemoryRequest, user_id: str = Depends(current_user)):
    """
    清除用户所有记忆

    当用户在隐私设置中关闭 Memory 开关时调用此接口。
    请求: { user_id: str }
    响应: { success: true, cleared_count: N }
    """
    if request.user_id != user_id:
        raise HTTPException(status_code=403, detail="不能清除其他用户的记忆")
    count = memory_system.delete_all_memories(user_id)
    return {
        "success": True,
        "cleared_count": count,
        "message": f"已清除 {count} 条记忆",
    }


@router.get("/export")
async def export_memories(
    user_id: str = Depends(current_user),
    limit: int = Query(200, description="最大导出数量", le=500),
):
    """
    导出用户所有记忆为 JSON

    用于用户数据导出功能（GDPR合规）。
    响应: { user_id, memories: [...], exported_at }
    """
    memories = memory_system.get_recent_memories(
        user_id=user_id,
        limit=limit,
        memory_type=None,
    )
    return {
        "user_id": user_id,
        "count": len(memories),
        "memories": memories,
        "exported_at": datetime.now(timezone.utc).isoformat(),
    }


@router.delete("/all")
async def delete_all_memories(user_id: str = Depends(current_user)):
    """
    清除用户所有记忆（GDPR合规）

    ⚠️ 此操作不可逆
    """
    count = memory_system.delete_all_memories(user_id)
    return {
        "success": True,
        "deleted_count": count,
        "message": f"已清除 {count} 条记忆",
    }



class UpdateMemoryRequest(BaseModel):
    content: str
    confidence: Optional[float] = None

class RetentionRequest(BaseModel):
    retention_days: int

@router.get("/search")
async def search_memories(q: str = Query(..., min_length=1, description="搜索关键词"), user_id: str = Depends(current_user), limit: int = Query(50, le=100)):
    """按关键词搜索本人记忆。"""
    results = memory_system.search_memories(user_id, q, limit=limit)
    return {"user_id": user_id, "query": q, "count": len(results), "memories": results}


@router.get("/settings/retention")
async def get_retention(user_id: str = Depends(current_user)):
    """查询记忆保留期设置 (null=不限期)。"""
    return {"user_id": user_id, "retention_days": memory_system.get_retention_days(user_id)}

@router.put("/settings/retention")
async def set_retention(request: RetentionRequest, user_id: str = Depends(current_user)):
    """设置记忆保留期(天); <=0 不限期。设置后立即清理过期记忆。"""
    if request.retention_days < 0 or request.retention_days > 3650:
        raise HTTPException(status_code=422, detail="保留期须在 0-3650 天之间 (0=不限期)")
    deleted = memory_system.set_retention_days(user_id, request.retention_days)
    return {"success": True, "retention_days": request.retention_days, "pruned_count": deleted}

@router.put("/{memory_id}")
async def update_memory(memory_id: str, request: UpdateMemoryRequest, user_id: str = Depends(current_user)):
    """更新单条记忆内容 (仅本人)。"""
    ok = memory_system.update_memory_content(memory_id, user_id, request.content, request.confidence)
    if not ok:
        raise HTTPException(status_code=404, detail="记忆不存在或无权修改")
    return {"success": True, "message": "记忆已更新"}

@router.get("/report")
async def export_report(format: str = Query("pdf", description="pdf|docx|md"), user_id: str = Depends(current_user), limit: int = Query(200, le=500)):
    """导出可读养生记忆报告 (PDF/Word/Markdown); JSON 仍走 /export。"""
    from fastapi.responses import Response
    from app.services.report_export import build_pdf, build_docx, build_markdown
    memories = memory_system.get_recent_memories(user_id=user_id, limit=limit, memory_type=None)
    fmt = format.lower()
    if fmt == "md":
        return Response(content=build_markdown(user_id, memories), media_type="text/markdown", headers={"Content-Disposition": "attachment; filename=shunshi-report.md"})
    if fmt == "docx":
        return Response(content=build_docx(user_id, memories), media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document", headers={"Content-Disposition": "attachment; filename=shunshi-report.docx"})
    if fmt == "pdf":
        try:
            data = build_pdf(user_id, memories)
        except RuntimeError as exc:
            raise HTTPException(status_code=501, detail=str(exc))
        return Response(content=data, media_type="application/pdf", headers={"Content-Disposition": "attachment; filename=shunshi-report.pdf"})
    raise HTTPException(status_code=422, detail="format 仅支持 pdf|docx|md")

@router.delete("/{memory_id}")
async def delete_memory(
    memory_id: str,
    user_id: str = Depends(current_user),
):
    """
    删除单条记忆（GDPR合规）

    需要提供user_id进行权限校验
    """
    success = memory_system.delete_memory(memory_id, user_id)
    if not success:
        raise HTTPException(status_code=404, detail="记忆不存在或无权删除")
    return {"success": True, "message": "记忆已删除"}
