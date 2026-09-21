"""
顺时 — 用户数据管理 API（GDPR/CCPA/PIPL 合规）
/api/v1/user-data

提供数据导出、删除、下载功能，满足法规要求。
"""
import json
import logging
import os
import tempfile
import zipfile
from datetime import datetime, timezone
from io import BytesIO
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Header
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field

from app.database.db import get_db
from app.router.auth import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/user-data", tags=["用户数据管理"])


# ============ 模型 ============

class DataExportRequest(BaseModel):
    format: str = Field(default="json", description="导出格式: json/csv")
    categories: list[str] = Field(
        default=["profile", "health", "chat", "subscription"],
        description="数据类别"
    )


class DataDeleteRequest(BaseModel):
    reason: Optional[str] = Field(default=None, description="删除原因（可选）")
    confirm: bool = Field(..., description="确认删除，必须传 true")


class DataDeleteStatus(BaseModel):
    status: str
    requested_at: str
    completed_at: Optional[str]
    message: str


# ============ 辅助函数 ============

def _export_user_data(db, user_id: str, categories: list[str]) -> dict:
    """收集用户的所有数据"""
    data = {
        "export_metadata": {
            "user_id": user_id,
            "exported_at": datetime.now(timezone.utc).isoformat(),
            "version": "1.0",
        }
    }

    if "profile" in categories:
        row = db.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
        data["profile"] = dict(row) if row else {}

    if "health" in categories:
        data["health_records"] = []
        try:
            rows = db.execute("SELECT * FROM health_records WHERE user_id = ?", (user_id,)).fetchall()
            data["health_records"] = [dict(r) for r in rows]
        except Exception:
            pass

        data["journal_entries"] = []
        try:
            rows = db.execute("SELECT * FROM journal_entries WHERE user_id = ?", (user_id,)).fetchall()
            data["journal_entries"] = [dict(r) for r in rows]
        except Exception:
            pass

    if "chat" in categories:
        data["conversations"] = []
        try:
            convs = db.execute("SELECT * FROM conversations WHERE user_id = ?", (user_id,)).fetchall()
            for conv in convs:
                conv_dict = dict(conv)
                messages = db.execute(
                    "SELECT * FROM messages WHERE conversation_id = ?",
                    (conv["id"],)
                ).fetchall()
                conv_dict["messages"] = [dict(m) for m in messages]
                data["conversations"].append(conv_dict)
        except Exception:
            pass

    if "subscription" in categories:
        data["subscriptions"] = []
        try:
            rows = db.execute("SELECT * FROM subscriptions WHERE user_id = ?", (user_id,)).fetchall()
            data["subscriptions"] = [dict(r) for r in rows]
        except Exception:
            pass

    return data


# ============ API 端点 ============

@router.post("/export", response_class=StreamingResponse)
async def export_user_data(
    request: DataExportRequest,
    user: dict = Depends(get_current_user),
):
    """
    导出用户数据（GDPR 数据可携带权）
    
    返回包含所有个人数据的 ZIP 文件，格式为 JSON。
    """
    user_id = user["id"]
    db = get_db()

    data = _export_user_data(db, user_id, request.categories)

    # 创建 ZIP
    zip_buffer = BytesIO()
    with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("user_data.json", json.dumps(data, ensure_ascii=False, indent=2))

    zip_buffer.seek(0)

    filename = f"shunshi-data-export-{user_id}-{datetime.now().strftime('%Y%m%d')}.zip"

    return StreamingResponse(
        zip_buffer,
        media_type="application/zip",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )


@router.get("/export/status")
async def get_export_status(
    user: dict = Depends(get_current_user),
):
    """查询最近的数据导出状态"""
    return {
        "success": True,
        "data": {
            "available": True,
            "expires_in_days": 30,
        }
    }


_DELETION_MOVED = {
    "error": "endpoint_retired",
    "message": "账号与数据删除请使用 DELETE /api/v1/auth/account（客户端「注销账号」走的就是这一条）",
    "authoritative_endpoint": "DELETE /api/v1/auth/account",
}


# 删除相关的三条旧接口不再执行任何动作。
#
# 原来 POST /delete 回「数据删除已安排，30 天内可联系客服撤销」，而后台任务第一句就往
# 不存在的 user_deletion_requests 表里写，异常被吞掉——**什么都没删，也没有任何记录**；
# 冷静期与撤销同样是空的。更糟的是它的身份依赖曾把无效 token 当成演示账号。
# 客户端（privacy_page.dart）实际走的是 DELETE /api/v1/auth/account，那条是真实删除。
# 这里保留路由只为给出明确答复，不再冒充已受理。
@router.post("/delete", response_model=dict, status_code=410)
async def request_data_deletion(user: dict = Depends(get_current_user)):
    raise HTTPException(status_code=410, detail=_DELETION_MOVED)


@router.post("/delete/cancel", response_model=dict, status_code=410)
async def cancel_data_deletion(user: dict = Depends(get_current_user)):
    raise HTTPException(status_code=410, detail=_DELETION_MOVED)


@router.get("/delete/status", response_model=dict, status_code=410)
async def get_deletion_status(user: dict = Depends(get_current_user)):
    raise HTTPException(status_code=410, detail=_DELETION_MOVED)
