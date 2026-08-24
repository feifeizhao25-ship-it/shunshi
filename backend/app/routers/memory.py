"""记忆模块：契约以 Flutter 客户端实际调用为准。

客户端实际路径（settings_page.dart）：
- GET  /api/v1/settings/memory      → {"enabled": bool}
- POST /api/v1/settings/memory      body {"enabled": bool}
- DELETE /api/v1/memory/all         清空该用户记忆（设置 + 对话）
- DELETE /api/v1/conversations      仅清对话记录

注：需求 brief 提到的 DELETE /api/v1/memory、PUT /api/v1/memory/toggle
在客户端代码中不存在，按「后端适配已出包客户端」原则未实现。
"""

import json

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from ..deps import current_user, get_session
from ..simple_models import Message, UserSetting

router = APIRouter(prefix="/api/v1", tags=["memory"])

MEMORY_KEY = "settings:memory"
DEFAULT_MEMORY = {"enabled": False}


def _read_setting(session: Session, user_id: str, key: str) -> dict:
    row = session.get(UserSetting, {"user_id": user_id, "key": key})
    if not row:
        return dict(DEFAULT_MEMORY)
    try:
        return json.loads(row.value)
    except json.JSONDecodeError:
        return dict(DEFAULT_MEMORY)


class MemoryToggle(BaseModel):
    enabled: bool


@router.get("/settings/memory")
def get_memory(user_id: str = Depends(current_user), session: Session = Depends(get_session)):
    return _read_setting(session, user_id, MEMORY_KEY)


@router.post("/settings/memory")
def set_memory(
    body: MemoryToggle,
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
):
    session.merge(
        UserSetting(user_id=user_id, key=MEMORY_KEY, value=json.dumps({"enabled": body.enabled}))
    )
    return {"enabled": body.enabled}


@router.delete("/memory/all")
def delete_memory(user_id: str = Depends(current_user), session: Session = Depends(get_session)):
    session.execute(delete(UserSetting).where(UserSetting.user_id == user_id))
    session.execute(delete(Message).where(Message.user_id == user_id))
    return {"deleted": True}


@router.delete("/conversations")
def delete_conversations(
    user_id: str = Depends(current_user), session: Session = Depends(get_session)
):
    session.execute(delete(Message).where(Message.user_id == user_id))
    return {"deleted": True}
