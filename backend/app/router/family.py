# 家庭系统 API 路由
from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel, Field, field_validator
from typing import List, Literal, Optional
from datetime import datetime, timedelta
import secrets
import sqlite3
import uuid
import string
import json
from sqlalchemy import text
from sqlalchemy.orm import Session
from app.deps import get_session
from app.simple_models import User

from app.database.db import get_db, close_test_connection
from app.locale_context import bind_request_locale, tr

router = APIRouter(prefix="/api/v1/family", tags=["家庭"], dependencies=[Depends(bind_request_locale)])


def _family_people_including_buyer() -> int:
    """家庭档人数含购买人，唯一来源是权益注册表。"""
    from app.entitlements import get_registry
    return int(get_registry()["tiers"]["family"]["collaboration"]["family_members"])


def _family_relation_cap() -> int:
    """family_relations 里是绑定的家人，不含购买人。3 人（含你自己）= 2 条关系。"""
    people = _family_people_including_buyer()
    return 0 if people < 0 else max(0, people - 1)


def _family_full_detail():
    people = _family_people_including_buyer()
    return tr(
        f"家庭成员数量已达上限（{people}人，含你自己）",
        f"The family is full ({people} people, including you)",
    )

# ============ Models ============

from app.services.family_service import family_service as enhanced_family_service

class FamilyMember(BaseModel):
    id: str
    name: str
    relation: str
    age: Optional[int] = None
    status: str = "normal"
    last_active_at: Optional[str] = None
    health_data: Optional[dict] = None

class FamilyInfo(BaseModel):
    family_id: str
    family_name: str
    members: List[FamilyMember]
    invite_code: Optional[str] = None
    invite_expires_at: Optional[str] = None

class AddMemberRequest(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    relation: str = Field(min_length=1, max_length=30)
    age: Optional[int] = Field(default=None, ge=0, le=120, strict=True)

    @field_validator("name", "relation", mode="before")
    @classmethod
    def trim_text(cls, value):
        return value.strip() if isinstance(value, str) else value

class GenerateInviteRequest(BaseModel):
    relation: str

# ============ Helper Functions ============

def generate_code(length=6):
    chars = string.ascii_uppercase + string.digits
    return ''.join(secrets.choice(chars) for _ in range(length))


def get_user_family(db, user_id: str) -> tuple:
    """获取用户家庭信息 (family_id, family_name)
    如果用户没有家庭，自动创建
    """
    row = db.execute(
        "SELECT DISTINCT family_id, family_name FROM family_relations WHERE user_id = ?",
        (user_id,)
    ).fetchone()
    
    if row:
        return row["family_id"], row["family_name"]
    
    # 创建默认家庭
    family_id = f"family_{user_id}"
    family_name = tr("我的家庭", "My family")
    return family_id, family_name

# ============ API Endpoints ============

@router.get("", response_model=FamilyInfo)
async def get_family(user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人")):
    """获取家庭信息"""
    db = get_db()
    
    family_id, family_name = get_user_family(db, user_id)
    
    members = db.execute(
        "SELECT * FROM family_relations WHERE family_id = ? AND user_id = ?",
        (family_id, user_id)
    ).fetchall()
    
    member_list = []
    for m in members:
        d = dict(m)
        d["health_data"] = _parse_json(d.get("health_data", "{}"))
        member_list.append(FamilyMember(**{
            "id": d["id"],
            "name": d["member_name"],
            "relation": d["relation"],
            "age": d["age"],
            "status": d["status"],
            "last_active_at": d.get("last_active_at"),
            "health_data": d["health_data"]
        }))
    
    # 查找有效的邀请码
    invite_row = db.execute("""
        SELECT code, expires_at FROM family_invites 
        WHERE family_id = ? AND created_by = ? AND used = 0 AND expires_at > ?
        ORDER BY created_at DESC LIMIT 1
    """, (family_id, user_id, datetime.now().isoformat())).fetchone()
    
    return FamilyInfo(
        family_id=family_id,
        family_name=family_name,
        members=member_list,
        invite_code=invite_row["code"] if invite_row else None,
        invite_expires_at=invite_row["expires_at"] if invite_row else None
    )


@router.post("/members", response_model=FamilyMember)
async def add_member(
    request: AddMemberRequest,
    user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人")
):
    """添加家庭成员"""
    db = get_db()
    
    try:
        db.execute("BEGIN IMMEDIATE")
        family_id, family_name = get_user_family(db, user_id)

        # 检查成员数量限制
        count = db.execute(
            "SELECT COUNT(*) FROM family_relations WHERE family_id = ?",
            (family_id,)
        ).fetchone()[0]

        if count >= _family_relation_cap():
            raise HTTPException(status_code=400, detail=_family_full_detail())

        member_id = f"member_{uuid.uuid4().hex}"
        now = datetime.now().isoformat()

        db.execute("""
            INSERT INTO family_relations (id, user_id, family_id, family_name, member_name, relation, age, status, last_active_at, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, 'normal', ?, ?, ?)
        """, (member_id, user_id, family_id, family_name, request.name, request.relation, request.age, now, now, now))
        db.commit()

        return FamilyMember(
            id=member_id,
            name=request.name,
            relation=request.relation,
            age=request.age,
            status="normal",
            last_active_at=now,
            health_data={}
        )
    except Exception:
        db.rollback()
        raise
    finally:
        close_test_connection(db)


@router.delete("/members/{member_id}")
async def remove_member(
    member_id: str,
    user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人")
):
    """移除家庭成员"""
    db = get_db()
    
    try:
        removed = db.execute(
            "DELETE FROM family_relations WHERE id = ? AND user_id = ?",
            (member_id, user_id),
        ).rowcount
        if removed != 1:
            raise HTTPException(status_code=404, detail=tr("成员不存在", "Member not found"))
        db.commit()
        return {"success": True, "message": tr("成员已移除", "Member removed")}
    except Exception:
        db.rollback()
        raise
    finally:
        close_test_connection(db)


@router.patch("/members/{member_id}/status")
async def update_member_status(
    member_id: str,
    status: Literal["normal", "attention", "warning", "inactive"],
    user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人")
):
    """更新成员状态"""
    db = get_db()
    
    try:
        changed = db.execute(
            "UPDATE family_relations SET status = ?, updated_at = ? WHERE id = ? AND user_id = ?",
            (status, datetime.now().isoformat(), member_id, user_id),
        ).rowcount
        if changed != 1:
            raise HTTPException(status_code=404, detail=tr("成员不存在", "Member not found"))
        row = db.execute(
            "SELECT * FROM family_relations WHERE id = ? AND user_id = ?",
            (member_id, user_id),
        ).fetchone()
        db.commit()
        return {"success": True, "member": dict(row)}
    except Exception:
        db.rollback()
        raise
    finally:
        close_test_connection(db)


@router.post("/invite", response_model=dict)
async def generate_invite(request: GenerateInviteRequest, user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人")):
    """生成或复用当前邀请人、关系对应的邀请码。"""
    db = get_db()
    try:
        db.execute("BEGIN IMMEDIATE")
        family_id, _ = get_user_family(db, user_id)
        now = datetime.now().isoformat()
        existing = db.execute(
            """SELECT code, expires_at FROM family_invites
            WHERE family_id = ? AND created_by = ? AND relation = ?
            AND used = 0 AND expires_at > ? ORDER BY created_at DESC LIMIT 1""",
            (family_id, user_id, request.relation, now),
        ).fetchone()
        if existing:
            db.commit()
            return dict(existing)
        expires_at = (datetime.now() + timedelta(days=7)).isoformat()
        for _ in range(5):
            code = generate_code()
            try:
                db.execute(
                    """INSERT INTO family_invites
                    (id, family_id, code, relation, created_by, expires_at, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?)""",
                    (f"inv_{uuid.uuid4().hex}", family_id, code, request.relation, user_id, expires_at, now),
                )
                db.commit()
                return {"code": code, "expires_at": expires_at}
            except sqlite3.IntegrityError:
                # A code collision must not expose another family's invitation.
                continue
        raise HTTPException(status_code=503, detail=tr("邀请码生成繁忙，请稍后重试", "Invite codes are busy right now. Please try again shortly."))
    except Exception:
        db.rollback()
        raise
    finally:
        close_test_connection(db)


@router.post("/join")
async def join_family(code: str, user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人"), session: Session = Depends(get_session)):
    """一次性消费邀请码；失败时不消耗邀请码、不留下部分加入记录。"""
    db = get_db()
    try:
        db.execute("BEGIN IMMEDIATE")
        invite = db.execute("SELECT * FROM family_invites WHERE code = ?", (code,)).fetchone()
        if not invite:
            raise HTTPException(status_code=404, detail=tr("邀请码不存在", "Invite code not found"))
        if invite["used"]:
            raise HTTPException(status_code=400, detail=tr("邀请码已使用", "This invite code has already been used"))
        now = datetime.now().isoformat()
        if invite["expires_at"] <= now:
            raise HTTPException(status_code=400, detail=tr("邀请码已过期", "This invite code has expired"))
        if invite["created_by"] == user_id:
            raise HTTPException(status_code=400, detail=tr("不能使用自己生成的邀请码", "You cannot use your own invite code"))
        if session.get(User, invite["created_by"]) is None:
            raise HTTPException(status_code=410, detail=tr("邀请账号已不存在，请重新获取邀请", "The inviting account no longer exists. Please ask for a new invite."))
        if db.execute("SELECT 1 FROM family_relations WHERE user_id = ? LIMIT 1", (user_id,)).fetchone():
            raise HTTPException(status_code=409, detail=tr("当前已有家庭关系，请先退出或移除现有关系", "You are already in a family. Leave or remove the current one first."))
        family_id = invite["family_id"]
        count = db.execute("SELECT count(*) FROM family_relations WHERE family_id = ?", (family_id,)).fetchone()[0]
        if count >= _family_relation_cap():
            raise HTTPException(status_code=400, detail=_family_full_detail())
        db.execute(
            "UPDATE family_invites SET used = 1, used_by = ?, used_at = ? WHERE code = ? AND used = 0",
            (user_id, now, code),
        )
        db.execute(
            """INSERT INTO family_relations
            (id, user_id, family_id, family_name, member_name, relation, age, status,
             last_active_at, user_id_member, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, NULL, 'normal', ?, ?, ?, ?)""",
            (f"member_{uuid.uuid4().hex}", user_id, family_id, tr("已加入的家庭", "Joined family"), tr("新成员", "New member"), invite["relation"], now, user_id, now, now),
        )
        db.commit()
        return {"success": True, "message": tr("成功加入家庭", "Joined the family")}
    except Exception:
        db.rollback()
        raise
    finally:
        close_test_connection(db)


@router.get("/members")
async def get_family_members(user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人")):
    """获取家庭成员列表"""
    db = get_db()
    family_id, family_name = get_user_family(db, user_id)
    
    members = db.execute(
        "SELECT * FROM family_relations WHERE family_id = ? AND user_id = ?",
        (family_id, user_id)
    ).fetchall()
    
    member_list = []
    for m in members:
        d = dict(m)
        d["health_data"] = _parse_json(d.get("health_data", "{}"))
        member_list.append({
            "id": d["id"],
            "name": d["member_name"],
            "relation": d["relation"],
            "age": d["age"],
            "status": d["status"],
            "last_active_at": d.get("last_active_at"),
            "trend": _get_member_trend(d["status"]),
        })
    
    return {"success": True, "data": {"family_name": family_name, "members": member_list}}


@router.get("/status")
async def get_family_status(user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人")):
    """获取家人状态（趋势，不显示隐私）"""
    db = get_db()
    family_id, family_name = get_user_family(db, user_id)
    
    members = db.execute(
        "SELECT * FROM family_relations WHERE family_id = ? AND user_id = ?",
        (family_id, user_id)
    ).fetchall()
    
    # 只返回趋势信息，不暴露具体健康数据
    status_list = []
    for m in members:
        d = dict(m)
        status_list.append({
            "id": d["id"],
            "name": d["member_name"],
            "relation": d["relation"],
            "trend": _get_member_trend(d["status"]),
            "last_active_at": d.get("last_active_at"),
            "needs_attention": d["status"] in ("attention", "warning"),
        })
    
    return {
        "success": True,
        "data": {
            "family_name": family_name,
            "total_members": len(status_list),
            "members_needing_attention": sum(1 for s in status_list if s["needs_attention"]),
            "members": status_list,
        }
    }


class ReminderRequest(BaseModel):
    target_member_id: str
    type: Literal["health_reminder", "care", "medication"] = "health_reminder"
    message: Optional[str] = None

@router.post("/reminder")
async def send_care_reminder(request: ReminderRequest, user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人")):
    """发送关怀提醒"""
    db = get_db()

    try:
        # Serialize the preference check with both settings changes and the insert.
        db.execute("BEGIN IMMEDIATE")
        # 验证目标成员存在且属于同一家庭
        target = db.execute(
            "SELECT * FROM family_relations WHERE id = ? AND user_id = ?",
            (request.target_member_id, user_id)
        ).fetchone()

        if not target:
            raise HTTPException(status_code=404, detail=tr("成员不存在", "Member not found"))

        if not db.execute("SELECT id FROM users WHERE id = ?", (user_id,)).fetchone():
            raise HTTPException(status_code=404, detail=tr("用户不存在", "User not found"))

        if not _read_family_settings(db, user_id).reminder_enabled:
            raise HTTPException(status_code=409, detail=tr("家庭关怀提醒已关闭，请先在家庭设置中开启", "Family care reminders are turned off. Turn them on in family settings first."))

        now = datetime.now().isoformat()

        # 记录关怀提醒到notifications表
        notif_id = f"care_{now.replace(':', '').replace('.', '').replace('-', '')}"

        messages = {
            "health_reminder": tr(f"关怀提醒：请关注{target['member_name']}的健康状况。", f"Care reminder: please check in on {target['member_name']}."),
            "care": tr(f"关怀提醒：记得关心{target['member_name']}。", f"Care reminder: remember to look in on {target['member_name']}."),
            "medication": tr(f"关怀提醒：请提醒{target['member_name']}按时服药。", f"Care reminder: please remind {target['member_name']} about their routine."),
        }

        body = request.message or messages.get(request.type, tr(f"向{target['member_name']}发送了关怀提醒。", f"Care reminder sent to {target['member_name']}."))

        db.execute("""
            INSERT INTO notifications (id, user_id, type, title, body, data, sent_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            notif_id,
            user_id,
            request.type,
            tr("家庭关怀", "Family care"),
            body,
            json.dumps({"source": "family", "target_member": target["member_name"]}, ensure_ascii=False),
            now,
        ))
        db.commit()

        return {
            "success": True,
            "notification_id": notif_id,
            "delivery": "self_inbox",
            "message": tr("已保存到自己的通知列表", "Saved to your own notifications"),
        }
    except Exception:
        db.rollback()
        raise
    finally:
        close_test_connection(db)



class FamilySettings(BaseModel):
    # Detailed health sharing has no consent workflow; do not pretend to enable it.
    show_trend_only: Literal[True] = True
    reminder_enabled: bool = True
    reminder_frequency: Literal["daily", "weekly", "manual"] = "daily"


def _read_family_settings(db, user_id: str) -> FamilySettings:
    row = db.execute(
        "SELECT show_trend_only, reminder_enabled, reminder_frequency FROM family_settings WHERE user_id = ?",
        (user_id,),
    ).fetchone()
    return FamilySettings(**dict(row)) if row else FamilySettings()


@router.get("/settings")
async def get_family_settings(user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人")):
    """读取当前账号的家庭设置。"""
    db = get_db()
    try:
        return {"success": True, "data": _read_family_settings(db, user_id).model_dump(),
                "reminder_schedule_active": False}
    finally:
        close_test_connection(db)


@router.put("/settings")
async def update_family_settings(settings: FamilySettings, user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人")):
    """持久化设置；只更新本次明确提交的字段。"""
    db = get_db()
    try:
        db.execute("BEGIN IMMEDIATE")
        values = _read_family_settings(db, user_id).model_dump()
        values.update(settings.model_dump(exclude_unset=True))
        db.execute(
            """INSERT INTO family_settings
            (user_id, show_trend_only, reminder_enabled, reminder_frequency, updated_at)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(user_id) DO UPDATE SET
                show_trend_only=excluded.show_trend_only,
                reminder_enabled=excluded.reminder_enabled,
                reminder_frequency=excluded.reminder_frequency,
                updated_at=excluded.updated_at""",
            (user_id, int(values["show_trend_only"]), int(values["reminder_enabled"]),
             values["reminder_frequency"], datetime.now().isoformat()),
        )
        db.commit()
        return {"success": True, "data": values, "reminder_schedule_active": False,
                "message": tr("设置已保存；自动定时提醒尚未启用", "Settings saved. Automatic scheduled reminders are not enabled yet.")}
    except Exception:
        db.rollback()
        raise
    finally:
        close_test_connection(db)


def _get_member_trend(status: str) -> str:
    """根据成员状态返回趋势描述（隐私友好）"""
    trend_map = {
        "normal": "good",
        "attention": "attention",
        "warning": "attention",
        "inactive": "inactive",
    }
    return trend_map.get(status, "good")


@router.post("/leave")
async def leave_family(user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人")):
    """离开家庭"""
    db = get_db()
    
    try:
        db.execute("BEGIN IMMEDIATE")
        db.execute("DELETE FROM family_relations WHERE user_id_member = ?", (user_id,))
        db.execute("DELETE FROM family_invites WHERE created_by = ? AND used = 0", (user_id,))
        db.commit()
        return {"success": True, "message": tr("已离开家庭", "Left the family")}
    except Exception:
        db.rollback()
        raise
    finally:
        close_test_connection(db)


def _parse_json(s):
    """安全解析 JSON"""
    import json
    try:
        return json.loads(s) if s else {}
    except (json.JSONDecodeError, TypeError):
        return {}


# ============ 增强功能端点 ============

@router.get("/overview")
async def get_family_overview(
    user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人"),
    locale: str = Query("zh-CN", description="语言: zh-CN/en-US")
):
    """获取家庭健康概览（增强版）"""
    return enhanced_family_service.get_family_overview(user_id, locale)


@router.get("/members/{member_id}/health")
async def get_member_health_detail(
    member_id: str,
    user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人"),
    locale: str = Query("zh-CN", description="语言"),
):
    """获取家庭成员健康详情"""
    return enhanced_family_service.get_member_health_detail(user_id, member_id, locale)


@router.get("/shared-content")
async def get_shared_content_pack(
    user_id: str = Query(..., description="用户ID；不传由服务端按令牌补上本人"),
    pack_type: str = Query("wellness", description="内容包类型: wellness/exercise/diet"),
    locale: str = Query("zh-CN", description="语言"),
):
    """获取家庭共享内容包"""
    return enhanced_family_service.get_shared_content_pack(user_id, pack_type, locale)
