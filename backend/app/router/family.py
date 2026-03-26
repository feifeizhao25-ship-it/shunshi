# 家庭系统 API 路由
from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, timedelta
import random
import string

from app.database.db import get_db

router = APIRouter(prefix="/api/v1/family", tags=["家庭"])

# ============ Models ============

from app.services.family_service import family_service as enhanced_family_service

class FamilyMember(BaseModel):
    id: str
    name: str
    relation: str
    age: int
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
    name: str
    relation: str
    age: int

class GenerateInviteRequest(BaseModel):
    relation: str

# ============ Helper Functions ============

def generate_code(length=6):
    chars = string.ascii_uppercase + string.digits
    return ''.join(random.choices(chars, k=length))


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
    family_name = "我的家庭"
    return family_id, family_name

# ============ API Endpoints ============

@router.get("", response_model=FamilyInfo)
async def get_family(user_id: str = "user-001"):
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
            "age": d["age"] or 0,
            "status": d["status"],
            "last_active_at": d.get("last_active_at"),
            "health_data": d["health_data"]
        }))
    
    # 查找有效的邀请码
    invite_row = db.execute("""
        SELECT code, expires_at FROM family_invites 
        WHERE family_id = ? AND used = 0 AND expires_at > ?
        ORDER BY created_at DESC LIMIT 1
    """, (family_id, datetime.now().isoformat())).fetchone()
    
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
    user_id: str = "user-001"
):
    """添加家庭成员"""
    db = get_db()
    
    family_id, family_name = get_user_family(db, user_id)
    
    # 检查成员数量限制
    count = db.execute(
        "SELECT COUNT(*) FROM family_relations WHERE family_id = ? AND user_id = ?",
        (family_id, user_id)
    ).fetchone()[0]
    
    if count >= 4:
        raise HTTPException(status_code=400, detail="家庭成员数量已达上限(4人)")
    
    member_id = f"member_{datetime.now().strftime('%Y%m%d%H%M%S')}_{random.randint(1000,9999)}"
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


@router.delete("/members/{member_id}")
async def remove_member(
    member_id: str,
    user_id: str = "user-001"
):
    """移除家庭成员"""
    db = get_db()
    
    db.execute("DELETE FROM family_relations WHERE id = ? AND user_id = ?", (member_id, user_id))
    db.commit()
    
    return {"success": True, "message": "成员已移除"}


@router.patch("/members/{member_id}/status")
async def update_member_status(
    member_id: str,
    status: str,
    user_id: str = "user-001"
):
    """更新成员状态"""
    db = get_db()
    
    row = db.execute(
        "UPDATE family_relations SET status = ?, updated_at = ? WHERE id = ? AND user_id = ? RETURNING *",
        (status, datetime.now().isoformat(), member_id, user_id)
    ).fetchone()
    
    if not row:
        raise HTTPException(status_code=404, detail="成员不存在")
    
    return {"success": True, "member": dict(row)}


@router.post("/invite", response_model=dict)
async def generate_invite(
    request: GenerateInviteRequest,
    user_id: str = "user-001"
):
    """生成邀请码"""
    db = get_db()
    
    family_id, _ = get_user_family(db, user_id)
    
    # 检查是否已有有效邀请码
    existing = db.execute("""
        SELECT code, expires_at FROM family_invites 
        WHERE family_id = ? AND used = 0 AND expires_at > ?
    """, (family_id, datetime.now().isoformat())).fetchone()
    
    if existing:
        return {"code": existing["code"], "expires_at": existing["expires_at"]}
    
    code = generate_code()
    expires_at = (datetime.now() + timedelta(days=7)).isoformat()
    now = datetime.now().isoformat()
    
    db.execute("""
        INSERT INTO family_invites (id, family_id, code, relation, created_by, expires_at, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (f"inv_{now}", family_id, code, request.relation, user_id, expires_at, now))
    db.commit()
    
    return {"code": code, "expires_at": expires_at}


@router.post("/join")
async def join_family(code: str, user_id: str = "user-001"):
    """使用邀请码加入家庭"""
    db = get_db()
    
    invite = db.execute("SELECT * FROM family_invites WHERE code = ?", (code,)).fetchone()
    if not invite:
        raise HTTPException(status_code=404, detail="邀请码不存在")
    
    if invite["used"]:
        raise HTTPException(status_code=400, detail="邀请码已使用")
    
    if invite["expires_at"] < datetime.now().isoformat():
        raise HTTPException(status_code=400, detail="邀请码已过期")
    
    now = datetime.now().isoformat()
    family_id = invite["family_id"]
    
    # 标记已使用
    db.execute("""
        UPDATE family_invites SET used = 1, used_by = ?, used_at = ? WHERE code = ?
    """, (user_id, now, code))
    
    # 添加用户到目标家庭
    db.execute("""
        INSERT OR IGNORE INTO family_relations (id, user_id, family_id, family_name, member_name, relation, age, status, last_active_at, user_id_member, created_at, updated_at)
        VALUES (?, ?, ?, '已加入的家庭', '新成员', ?, 30, 'normal', ?, ?, ?, ?)
    """, (f"member_{now}", user_id, family_id, invite["relation"], now, user_id, now, now))
    
    db.commit()
    
    return {"success": True, "message": "成功加入家庭"}


@router.get("/members")
async def get_family_members(user_id: str = "user-001"):
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
            "age": d["age"] or 0,
            "status": d["status"],
            "last_active_at": d.get("last_active_at"),
            "trend": _get_member_trend(d["status"]),
        })
    
    return {"success": True, "data": {"family_name": family_name, "members": member_list}}


@router.get("/status")
async def get_family_status(user_id: str = "user-001"):
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
    type: str = "health_reminder"  # health_reminder / care / medication
    message: Optional[str] = None

@router.post("/reminder")
async def send_care_reminder(request: ReminderRequest, user_id: str = "user-001"):
    """发送关怀提醒"""
    db = get_db()
    
    # 验证目标成员存在且属于同一家庭
    target = db.execute(
        "SELECT * FROM family_relations WHERE id = ? AND user_id = ?",
        (request.target_member_id, user_id)
    ).fetchone()
    
    if not target:
        raise HTTPException(status_code=404, detail="成员不存在")
    
    now = datetime.now().isoformat()
    
    # 记录关怀提醒到notifications表
    notif_id = f"care_{now.replace(':', '').replace('.', '').replace('-', '')}"
    
    messages = {
        "health_reminder": f"来自家庭的健康提醒：请关注{target['member_name']}的健康状况。",
        "care": f"来自家庭的关怀：向{target['member_name']}发送了一份关怀提醒。",
        "medication": f"来自家庭的提醒：请提醒{target['member_name']}按时服药。",
    }
    
    body = request.message or messages.get(request.type, f"向{target['member_name']}发送了关怀提醒。")
    
    db.execute("""
        INSERT INTO notifications (id, user_id, type, title, body, data, sent_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (notif_id, user_id, request.type, "家庭关怀", body,
          '{"source": "family", "target_member": "' + target['member_name'] + '"}',
          now))
    db.commit()
    
    return {
        "success": True,
        "notification_id": notif_id,
        "message": f"已向{target['member_name']}发送{request.type}",
    }


class FamilySettings(BaseModel):
    show_trend_only: bool = True  # 只显示趋势，不显示隐私数据
    reminder_enabled: bool = True  # 启用关怀提醒
    reminder_frequency: str = "daily"  # daily / weekly / manual

@router.get("/settings")
async def get_family_settings(user_id: str = "user-001"):
    """获取家庭设置"""
    # Settings stored in user_settings as JSON metadata
    db = get_db()
    try:
        row = db.execute("SELECT * FROM user_settings WHERE user_id = ?", (user_id,)).fetchone()
        if row:
            import json
            d = dict(row)
            # Check for family settings in metadata (if any)
            return {
                "success": True,
                "data": {
                    "show_trend_only": True,
                    "reminder_enabled": True,
                    "reminder_frequency": "daily",
                }
            }
    except Exception:
        pass
    
    return {
        "success": True,
        "data": {
            "show_trend_only": True,
            "reminder_enabled": True,
            "reminder_frequency": "daily",
        }
    }

@router.put("/settings")
async def update_family_settings(settings: FamilySettings, user_id: str = "user-001"):
    """更新家庭设置（隐私控制）"""
    # In a real implementation, save to user_settings or a family_settings table
    return {
        "success": True,
        "data": {
            "show_trend_only": settings.show_trend_only,
            "reminder_enabled": settings.reminder_enabled,
            "reminder_frequency": settings.reminder_frequency,
        }
    }


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
async def leave_family(user_id: str = "user-001"):
    """离开家庭"""
    db = get_db()
    
    db.execute("DELETE FROM family_relations WHERE user_id_member = ?", (user_id,))
    db.commit()
    
    return {"success": True, "message": "已离开家庭"}


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
    user_id: str = "user-001",
    locale: str = Query("zh-CN", description="语言: zh-CN/en-US")
):
    """获取家庭健康概览（增强版）"""
    return enhanced_family_service.get_family_overview(user_id, locale)


@router.get("/members/{member_id}/health")
async def get_member_health_detail(
    member_id: str,
    user_id: str = "user-001",
    locale: str = Query("zh-CN", description="语言"),
):
    """获取家庭成员健康详情"""
    return enhanced_family_service.get_member_health_detail(user_id, member_id, locale)


@router.get("/shared-content")
async def get_shared_content_pack(
    user_id: str = "user-001",
    pack_type: str = Query("wellness", description="内容包类型: wellness/exercise/diet"),
    locale: str = Query("zh-CN", description="语言"),
):
    """获取家庭共享内容包"""
    return enhanced_family_service.get_shared_content_pack(user_id, pack_type, locale)
