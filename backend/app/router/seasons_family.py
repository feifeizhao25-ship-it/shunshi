"""
SEASONS Global Version - Family Management API
"""

import uuid
from datetime import datetime
from typing import Optional, List
from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel

router = APIRouter(prefix="/api/v1/seasons/family", tags=["seasons-family"])

# In-memory family data
families_db: dict = {}
family_members_db: dict = {}
family_invites_db: dict = {}

MAX_FAMILY_MEMBERS = 4


class FamilyCreateRequest(BaseModel):
    name: str
    owner_id: str
    subscription_tier: str = "family"


class InviteRequest(BaseModel):
    email: Optional[str] = None
    invite_code: Optional[str] = None


class MemberProfile(BaseModel):
    id: str
    name: Optional[str] = None
    email: Optional[str] = None
    role: str  # "owner" | "member"
    joined_at: str
    season: str = "spring"
    streak_days: int = 0
    reflections_count: int = 0
    last_active: Optional[str] = None
    avatar_emoji: str = "🌿"


def _generate_invite_code() -> str:
    import random
    import string
    chars = string.ascii_uppercase + string.digits
    return "SEASONS-" + "".join(random.choices(chars, k=8))


def _get_season_for_member() -> str:
    month = datetime.now().month
    if month in [3, 4, 5]: return "spring"
    elif month in [6, 7, 8]: return "summer"
    elif month in [9, 10, 11]: return "autumn"
    else: return "winter"


# ==================== Family CRUD ====================

@router.post("/")
async def create_family(body: FamilyCreateRequest):
    """Create a new family"""
    family_id = f"family_{uuid.uuid4().hex[:8]}"
    
    family = {
        "id": family_id,
        "name": body.name,
        "owner_id": body.owner_id,
        "subscription_tier": body.subscription_tier,
        "created_at": datetime.now().isoformat(),
        "member_count": 1,
        "max_members": MAX_FAMILY_MEMBERS,
    }
    families_db[family_id] = family
    
    # Add owner as first member
    owner_member = {
        "id": f"member_{uuid.uuid4().hex[:8]}",
        "family_id": family_id,
        "user_id": body.owner_id,
        "name": None,
        "email": None,
        "role": "owner",
        "joined_at": datetime.now().isoformat(),
        "season": _get_season_for_member(),
        "streak_days": 0,
        "reflections_count": 0,
        "last_active": datetime.now().isoformat(),
        "avatar_emoji": "🌿",
    }
    member_id = owner_member["id"]
    family_members_db[member_id] = owner_member
    
    return {"family": family, "member": owner_member}


@router.get("/{family_id}")
async def get_family(family_id: str):
    """Get family details"""
    family = families_db.get(family_id)
    if not family:
        raise HTTPException(status_code=404, detail=f"Family '{family_id}' not found. DB size: {len(families_db)}")
    return family


@router.get("/{family_id}/members")
async def get_family_members(family_id: str):
    """Get all family members"""
    if family_id not in families_db:
        raise HTTPException(status_code=404, detail="Family not found")
    
    members = [
        m for m in family_members_db.values()
        if m["family_id"] == family_id
    ]
    return members


@router.post("/{family_id}/invite")
async def invite_member(family_id: str, body: InviteRequest):
    """Generate an invite link for family"""
    if family_id not in families_db:
        raise HTTPException(status_code=404, detail="Family not found")
    
    family = families_db[family_id]
    current_members = len([
        m for m in family_members_db.values()
        if m["family_id"] == family_id
    ])
    
    if current_members >= MAX_FAMILY_MEMBERS:
        raise HTTPException(status_code=400, detail="Family is full (max 4 members)")
    
    invite_code = _generate_invite_code()
    invite = {
        "code": invite_code,
        "family_id": family_id,
        "family_name": family["name"],
        "created_at": datetime.now().isoformat(),
        "max_uses": 1,
        "uses": 0,
        "status": "active",
    }
    family_invites_db[invite_code] = invite
    
    return {
        "invite_code": invite_code,
        "invite_link": f"https://seasons.app/join?code={invite_code}",
        "expires_at": None,
    }


@router.post("/join")
async def join_family(
    invite_code: str = Query(...),
    user_id: str = Query(...),
    user_name: Optional[str] = Query(None),
    user_email: Optional[str] = Query(None),
):
    """Join a family using invite code"""
    if invite_code not in family_invites_db:
        raise HTTPException(status_code=404, detail="Invalid invite code")
    
    invite = family_invites_db[invite_code]
    if invite["status"] != "active":
        raise HTTPException(status_code=400, detail="Invite code is no longer valid")
    
    family_id = invite["family_id"]
    
    # Check if family is full
    current_members = len([
        m for m in family_members_db.values()
        if m["family_id"] == family_id
    ])
    if current_members >= MAX_FAMILY_MEMBERS:
        raise HTTPException(status_code=400, detail="Family is full")
    
    # Add member
    member_id = f"member_{uuid.uuid4().hex[:8]}"
    member = {
        "id": member_id,
        "family_id": family_id,
        "user_id": user_id,
        "name": user_name,
        "email": user_email,
        "role": "member",
        "joined_at": datetime.now().isoformat(),
        "season": _get_season_for_member(),
        "streak_days": 0,
        "reflections_count": 0,
        "last_active": datetime.now().isoformat(),
        "avatar_emoji": _get_random_avatar(),
    }
    family_members_db[member_id] = member
    
    # Update invite usage
    family_invites_db[invite_code]["uses"] += 1
    if family_invites_db[invite_code]["uses"] >= family_invites_db[invite_code]["max_uses"]:
        family_invites_db[invite_code]["status"] = "used"
    
    return {
        "success": True,
        "family_id": family_id,
        "member": member,
    }


@router.delete("/{family_id}/members/{member_id}")
async def remove_member(family_id: str, member_id: str, user_id: str = Query(...)):
    """Remove a member from family (owner only)"""
    if family_id not in families_db:
        raise HTTPException(status_code=404, detail="Family not found")
    
    family = families_db[family_id]
    if family["owner_id"] != user_id:
        raise HTTPException(status_code=403, detail="Only the owner can remove members")
    
    if member_id in family_members_db:
        del family_members_db[member_id]
    
    return {"success": True}


# ==================== Family Overview ====================

@router.get("/{family_id}/overview")
async def get_family_overview(family_id: str):
    """Get family overview with member activity"""
    if family_id not in families_db:
        raise HTTPException(status_code=404, detail="Family not found")
    
    members = [
        m for m in family_members_db.values()
        if m["family_id"] == family_id
    ]
    
    # Calculate shared stats
    total_members = len(members)
    active_today = len([
        m for m in members
        if m.get("last_active") and
        (datetime.now() - datetime.fromisoformat(m["last_active"])).days < 1
    ])
    avg_streak = sum(m.get("streak_days", 0) for m in members) // total_members if total_members else 0
    total_reflections = sum(m.get("reflections_count", 0) for m in members)
    
    # Family wellness level
    if avg_streak >= 7 and active_today == total_members:
        wellness_level = "thriving"
    elif avg_streak >= 3:
        wellness_level = "engaging"
    elif avg_streak >= 1:
        wellness_level = "starting"
    else:
        wellness_level = "beginning"
    
    return {
        "family_id": family_id,
        "family_name": families_db[family_id]["name"],
        "total_members": total_members,
        "max_members": MAX_FAMILY_MEMBERS,
        "active_today": active_today,
        "avg_streak": avg_streak,
        "total_reflections": total_reflections,
        "wellness_level": wellness_level,
        "current_season": _get_season_for_member(),
        "members": [
            {
                "id": m["id"],
                "name": m.get("name") or f"Member {i+1}",
                "role": m["role"],
                "avatar_emoji": m.get("avatar_emoji", "🌿"),
                "streak_days": m.get("streak_days", 0),
                "reflections_count": m.get("reflections_count", 0),
                "last_active": m.get("last_active"),
                "is_active_today": (
                    m.get("last_active") and
                    (datetime.now() - datetime.fromisoformat(m["last_active"])).days < 1
                ),
            }
            for i, m in enumerate(members)
        ],
        "shared_ritual_suggestion": _get_shared_ritual_suggestion(),
    }


def _get_random_avatar() -> str:
    import random
    avatars = ["🌿", "🍃", "🌸", "🌺", "🌻", "🌼", "🍂", "❄️", "🌙", "⭐", "🧘", "💜", "🩵", "💚"]
    return random.choice(avatars)


def _get_shared_ritual_suggestion() -> dict:
    month = datetime.now().month
    if month in [3, 4, 5]:
        season = "spring"
        ritual = "Morning gratitude sharing"
    elif month in [6, 7, 8]:
        season = "summer"
        ritual = "Evening sunset reflection"
    elif month in [9, 10, 11]:
        season = "autumn"
        ritual = "Gratitude circle"
    else:
        season = "winter"
        ritual = "Cozy evening check-in"
    
    return {
        "season": season,
        "ritual": ritual,
        "duration_minutes": 5,
        "best_time": "evening",
    }
