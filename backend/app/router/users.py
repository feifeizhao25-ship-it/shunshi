"""兼容旧版用户管理路径，使用核心账号的认证、导出和注销流程。"""
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy.orm import Session
from app.config import Settings
from app.deps import current_user, get_session, get_settings
from app.database.db import get_db, close_test_connection
from app.routers.user import _collect_user_data, delete_account

router = APIRouter(prefix="/api/v1/users", tags=["用户管理"])


def _require_owner(requested: str, actor: str):
    if requested != actor:
        raise HTTPException(status_code=403, detail="只能操作本人账号")


@router.delete("/{user_id}")
def delete_user(user_id: str, request: Request,
    confirm: bool = Query(False, description="必须确认为 true 才能执行删除"),
    actor: str = Depends(current_user), session: Session = Depends(get_session),
    settings: Settings = Depends(get_settings)):
    _require_owner(user_id, actor)
    if not confirm:
        raise HTTPException(status_code=400, detail="必须确认删除操作。请设置 confirm=true 确认删除。")
    result = delete_account(request=request, user_id=actor, session=session, settings=settings)
    counts = {}
    for store, key in (("core", "deleted_rows"), ("records", "deleted_record_rows"), ("product", "deleted_product_rows")):
        counts.update({f"{store}.{table}": count for table, count in result[key].items()})
    complete = not result["erasure_incomplete_tables"]
    return {**result, "success": complete,
        "message": "账号已注销，支付与退款记录按规则保留" if complete else "账号已注销，部分数据清理尚未完成",
        "deleted_at": datetime.now(timezone.utc).isoformat(),
        "deleted_records": counts, "total_records_deleted": sum(counts.values())}


@router.get("/{user_id}/export")
def export_user_data(user_id: str, actor: str = Depends(current_user), session: Session = Depends(get_session)):
    _require_owner(user_id, actor)
    data = _collect_user_data(session, actor)
    db = get_db()
    try:
        tables = {row[0] for row in db.execute("SELECT name FROM sqlite_master WHERE type='table'")}
        missing = []
        for key, table in (("profile", "user_profiles"), ("subscriptions", "subscriptions"),
                           ("memories", "memory_items"), ("conversations", "conversations")):
            if table not in tables:
                data[key] = []
                missing.append(key)
                continue
            rows = db.execute(f'SELECT * FROM "{table}" WHERE user_id = ?', (actor,)).fetchall()
            data[key] = [dict(row) for row in rows]
        data.update(user_id=actor, exported_at=datetime.now(timezone.utc).isoformat(), unavailable_legacy_sections=missing,
                    export_scope="核心账号及已列出的历史记录，不代表全部产品模块数据")
        return data
    finally:
        close_test_connection(db)
