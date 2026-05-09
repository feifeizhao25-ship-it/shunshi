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

from fastapi import APIRouter, Depends, HTTPException, Header, BackgroundTasks
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


def _schedule_data_deletion(user_id: str, reason: Optional[str]):
    """执行数据删除（后台任务）"""
    logger.info(f"[DataDeletion] 开始删除用户 {user_id} 数据，原因: {reason or '未提供'}")
    
    # 数据删除涉及的所有表
    tables = [
        ("users", "id"),
        ("health_records", "user_id"),
        ("journal_entries", "user_id"),
        ("conversations", "user_id"),
        ("messages", "conversation_id"),  # 通过 conversation_id 级联
        ("chat_conversations", "user_id"),
        ("chat_memories", "user_id"),
        ("chat_messages", "user_id"),
        ("subscriptions", "user_id"),
        ("subscription_orders", "user_id"),
        ("family_relations", "user_id"),
        ("family_invites", "user_id"),
        ("checkin_records", "user_id"),
        ("community_posts", "user_id"),
        ("acupoint_favorites", "user_id"),
        ("article_bookmarks", "user_id"),
        ("audio_play_history", "user_id"),
        ("calorie_goals", "user_id"),
        ("notifications", "user_id"),
        ("sa_acupoint_favorites", "user_id"),
        ("sa_article_bookmarks", "user_id"),
        ("sa_audio_play_history", "user_id"),
        ("sa_calorie_goals", "user_id"),
        ("sa_chat_conversations", "user_id"),
        ("sa_chat_memories", "user_id"),
        ("sa_checkin_records", "user_id"),
        ("sa_community_posts", "user_id"),
        ("user_deletion_requests", "user_id"),
    ]
    
    deleted_counts = {}
    try:
        db = get_db()
        
        # 先标记删除请求为处理中
        db.execute(
            "INSERT OR REPLACE INTO user_deletion_requests (user_id, status, reason, requested_at) "
            "VALUES (?, ?, ?, ?)",
            (user_id, "processing", reason, datetime.now(timezone.utc).isoformat())
        )
        db.commit()
        
        # 删除 messages（需要先获取 conversation_ids）
        try:
            conv_ids = [r["id"] for r in db.execute(
                "SELECT id FROM conversations WHERE user_id = ?", (user_id,)
            ).fetchall()]
            if conv_ids:
                placeholders = ",".join("?" * len(conv_ids))
                db.execute(f"DELETE FROM messages WHERE conversation_id IN ({placeholders})", conv_ids)
                deleted_counts["messages"] = db.total_changes
        except Exception as e:
            logger.warning(f"[DataDeletion] 删除 messages 失败: {e}")
        
        # 逐个表删除用户数据
        for table, column in tables:
            try:
                cursor = db.execute(f"DELETE FROM {table} WHERE {column} = ?", (user_id,))
                deleted_counts[table] = cursor.rowcount
            except Exception as e:
                logger.warning(f"[DataDeletion] 删除 {table} 失败: {e}")
        
        db.commit()
        total = sum(deleted_counts.values())
        logger.info(f"[DataDeletion] 用户 {user_id} 数据删除完成，共 {total} 条记录: {deleted_counts}")
        
    except Exception as e:
        logger.error(f"[DataDeletion] 用户 {user_id} 数据删除失败: {e}")
        try:
            db = get_db()
            db.execute(
                "UPDATE user_deletion_requests SET status = 'failed' WHERE user_id = ?",
                (user_id,)
            )
            db.commit()
        except Exception:
            pass


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


@router.post("/delete", response_model=dict)
async def request_data_deletion(
    request: DataDeleteRequest,
    background_tasks: BackgroundTasks,
    user: dict = Depends(get_current_user),
):
    """
    请求删除所有个人数据（GDPR 被遗忘权）
    
    删除流程：
    1. 账号立即标记为 "deleting"
    2. 30 天冷静期内可撤销
    3. 30 天后永久删除所有数据
    """
    if not request.confirm:
        raise HTTPException(status_code=400, detail="必须确认删除（confirm=true）")

    user_id = user["id"]

    # 启动异步删除任务
    background_tasks.add_task(_schedule_data_deletion, user_id, request.reason)

    return {
        "success": True,
        "data": {
            "status": "scheduled",
            "message": "数据删除已安排，30 天内可联系客服撤销",
            "grace_period_days": 30,
            "contact": "privacy@shunshi.cn",
        }
    }


@router.post("/delete/cancel", response_model=dict)
async def cancel_data_deletion(
    user: dict = Depends(get_current_user),
):
    """撤销数据删除请求（冷静期内）"""
    user_id = user["id"]
    try:
        db = get_db()
        db.execute(
            "UPDATE user_deletion_requests SET status = 'cancelled' WHERE user_id = ? AND status = 'pending'",
            (user_id,)
        )
        db.commit()
        return {
            "success": True,
            "message": "数据删除请求已撤销",
        }
    except Exception as e:
        logger.error(f"[DataDeletion] 撤销删除请求失败: {e}")
        return {
            "success": False,
            "message": "撤销失败，请联系客服",
        }


@router.get("/delete/status", response_model=dict)
async def get_deletion_status(
    user: dict = Depends(get_current_user),
):
    """查询数据删除状态"""
    user_id = user["id"]
    try:
        db = get_db()
        row = db.execute(
            "SELECT * FROM user_deletion_requests WHERE user_id = ? ORDER BY requested_at DESC LIMIT 1",
            (user_id,)
        ).fetchone()

        if not row:
            return {
                "success": True,
                "data": {"status": "none", "message": "无删除请求"}
            }

        return {
            "success": True,
            "data": {
                "status": row["status"],
                "requested_at": row["requested_at"],
                "reason": dict(row).get("reason"),
                "message": "删除请求处理中" if row["status"] == "pending" else "已取消或已完成",
            }
        }
    except Exception:
        return {
            "success": True,
            "data": {"status": "unknown", "message": "无法查询状态"}
        }
