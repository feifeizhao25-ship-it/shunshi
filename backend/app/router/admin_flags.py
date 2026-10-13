"""Domestic flag administration, limited to verified prompt rollout bindings."""
import re
from dataclasses import asdict
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, ConfigDict, StrictBool

from app.database.db import get_db, close_test_connection
from app.feature_flags.store import flag_store

router = APIRouter(prefix="/api/v1/admin/flags", tags=["功能开关"])


def editable(flag):
    # app/prompts/store.py consumes precisely prompt.<key>.gray.
    return flag["value_type"] == "boolean" and bool(re.fullmatch(r"prompt\.[A-Za-z0-9_.-]+\.gray", flag["key"]))


def present(flag):
    item = asdict(flag)
    item["editable"] = editable(item)
    item["binding"] = "提示词灰度配置" if item["editable"] else "尚未核实接入，仅供查看"
    # No need to expose user identities to display a rollout summary.
    item["whitelist_count"] = len(item.pop("user_whitelist"))
    return item


class UpdateFlag(BaseModel):
    model_config = ConfigDict(extra="forbid")
    value: StrictBool
    expected_updated_at: str


@router.get("")
def list_flags():
    flags = flag_store.list_flags()
    return {"success": True, "data": [present(flag) for flag in flags]}


@router.patch("/{key:path}")
def update_flag(key: str, request: UpdateFlag):
    db = get_db()
    try:
        db.execute("BEGIN IMMEDIATE")
        row = db.execute("SELECT * FROM feature_flags WHERE key = ?", (key,)).fetchone()
        if row is None:
            raise HTTPException(404, "开关不存在，请刷新")
        if not editable(dict(row)):
            raise HTTPException(422, "该配置未核实接入或不是布尔开关，不能在此修改")
        if row["updated_at"] != request.expected_updated_at:
            raise HTTPException(409, "配置已被其他管理员修改，请刷新后重试")
        # Whitelists override the default: switching off must not pretend to disable them.
        import json
        if not request.value and json.loads(row["user_whitelist"]):
            raise HTTPException(409, "此配置仍有白名单，请先完成白名单审核与移除")
        updated = datetime.now(timezone.utc).isoformat()
        db.execute(
            "UPDATE feature_flags SET value_default = ?, updated_at = ? WHERE key = ?",
            ("true" if request.value else "false", updated, key),
        )
        db.commit()
        return {"success": True, "key": key, "value": request.value, "updated_at": updated}
    except Exception:
        db.rollback()
        raise
    finally:
        close_test_connection(db)
