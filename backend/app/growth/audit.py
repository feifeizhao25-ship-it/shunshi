"""追加审计。没有更新函数。"""

from __future__ import annotations

import json

from sqlalchemy.orm import Session

from app.growth.models import GrowthAuditLog


def append_audit(
    session: Session,
    *,
    action: str,
    decision: str = "no_change",
    object_key: str = "",
    version: str = "",
    actor: str = "system",
    detail: dict | None = None,
) -> GrowthAuditLog:
    row = GrowthAuditLog(
        action=action,
        decision=decision,
        object_key=object_key,
        version=version,
        actor=actor,
        detail_json=json.dumps(detail or {}, ensure_ascii=False),
    )
    session.add(row)
    session.flush()
    return row
