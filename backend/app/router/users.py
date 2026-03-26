"""
顺时 - 用户管理 API 路由
包含用户删除（GDPR合规）等管理端点
"""

import logging
from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException, Query, Path
from pydantic import BaseModel
from typing import Optional, Dict, Any

from app.database.db import get_db

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/users", tags=["用户管理"])


class DeleteUserRequest(BaseModel):
    """删除用户请求"""
    user_id: str
    confirm: bool = False


@router.delete("/{user_id}")
async def delete_user(
    user_id: str,
    confirm: bool = Query(False, description="必须确认为 true 才能执行删除"),
):
    """
    删除用户账户及所有关联数据（GDPR合规）

    级联删除顺序：
    1. 用户订阅记录 (subscriptions)
    2. 用户记忆 (memory_items)
    3. 用户会话/对话记录
    4. 用户档案

    ⚠️ 此操作不可逆
    """
    if not confirm:
        raise HTTPException(
            status_code=400,
            detail="必须确认删除操作。请设置 confirm=true 确认删除。",
        )

    logger.info(f"[UserDelete] 开始删除用户: user_id={user_id}")

    db = get_db()
    deleted_records: Dict[str, int] = {}

    try:
        # 1. 删除订阅记录
        try:
            db.execute("DELETE FROM subscriptions WHERE user_id = ?", (user_id,))
            deleted_records["subscriptions"] = db.row_count
        except Exception as e:
            logger.warning(f"[UserDelete] 删除订阅记录失败: {e}")

        # 2. 删除记忆
        try:
            db.execute("DELETE FROM memory_items WHERE user_id = ?", (user_id,))
            deleted_records["memory_items"] = db.row_count
        except Exception as e:
            logger.warning(f"[UserDelete] 删除记忆记录失败: {e}")

        # 3. 删除会话/对话记录
        try:
            db.execute("DELETE FROM conversations WHERE user_id = ?", (user_id,))
            deleted_records["conversations"] = db.row_count
        except Exception as e:
            logger.warning(f"[UserDelete] 删除会话记录失败: {e}")

        # 4. 删除用户档案
        try:
            db.execute("DELETE FROM user_profiles WHERE user_id = ?", (user_id,))
            deleted_records["user_profiles"] = db.row_count
        except Exception as e:
            logger.warning(f"[UserDelete] 删除用户档案失败: {e}")

        # 5. 删除认证令牌
        try:
            db.execute("DELETE FROM auth_tokens WHERE user_id = ?", (user_id,))
            deleted_records["auth_tokens"] = db.row_count
        except Exception as e:
            logger.warning(f"[UserDelete] 删除认证令牌失败: {e}")

        # 6. 删除通知记录
        try:
            db.execute("DELETE FROM notifications WHERE user_id = ?", (user_id,))
            deleted_records["notifications"] = db.row_count
        except Exception as e:
            logger.warning(f"[UserDelete] 删除通知记录失败: {e}")

        db.commit()

        logger.info(f"[UserDelete] 用户删除完成: user_id={user_id}, deleted={deleted_records}")

        return {
            "success": True,
            "message": "用户账户及所有关联数据已永久删除",
            "deleted_at": datetime.now(timezone.utc).isoformat(),
            "deleted_records": deleted_records,
            "total_records_deleted": sum(deleted_records.values()),
        }

    except Exception as e:
        db.rollback()
        logger.error(f"[UserDelete] 删除用户失败: user_id={user_id}, error={e}")
        raise HTTPException(status_code=500, detail=f"删除用户失败: {str(e)}")


@router.get("/{user_id}/export")
async def export_user_data(user_id: str = Path(..., description="用户ID")):
    """
    导出用户所有数据（GDPR合规）

    返回用户的完整数据副本。
    """
    db = get_db()
    data: Dict[str, Any] = {"user_id": user_id, "exported_at": datetime.now(timezone.utc).isoformat()}

    try:
        # 用户档案
        try:
            rows = db.execute("SELECT * FROM user_profiles WHERE user_id = ?", (user_id,)).fetchall()
            data["profile"] = [dict(r) for r in rows]
        except Exception:
            data["profile"] = []

        # 订阅信息
        try:
            rows = db.execute("SELECT * FROM subscriptions WHERE user_id = ?", (user_id,)).fetchall()
            data["subscriptions"] = [dict(r) for r in rows]
        except Exception:
            data["subscriptions"] = []

        # 记忆
        try:
            rows = db.execute("SELECT * FROM memory_items WHERE user_id = ?", (user_id,)).fetchall()
            data["memories"] = [dict(r) for r in rows]
        except Exception:
            data["memories"] = []

        # 对话
        try:
            rows = db.execute("SELECT * FROM conversations WHERE user_id = ?", (user_id,)).fetchall()
            data["conversations"] = [dict(r) for r in rows]
        except Exception:
            data["conversations"] = []

    except Exception as e:
        logger.error(f"[UserExport] 导出用户数据失败: user_id={user_id}, error={e}")
        raise HTTPException(status_code=500, detail=f"导出数据失败: {str(e)}")

    return data
