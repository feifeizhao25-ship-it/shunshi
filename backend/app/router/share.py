"""
顺时 — 社交分享 API (shunshi-share)
生成分享卡片、社交分享内容、邀请链接
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, List, Dict
from datetime import datetime
import hashlib

router = APIRouter(prefix="/api/v1/share", tags=["share"])

_share_records: Dict[str, dict] = {}


from pydantic import model_validator

class ShareCardRequest(BaseModel):
    user_id: str = Field(..., description="用户ID")
    content_type: str = Field(default="wellness_plan", description="内容类型: wellness_plan/achievement/recipe/checkin/insight")
    content_id: str = Field(default="", description="内容ID")
    platform: str = Field(default="wechat", description="分享平台: wechat/weibo/instagram/line")
    custom_message: Optional[str] = Field(None, max_length=200, description="自定义分享语")
    
    # 兼容旧客户端字段名
    type: Optional[str] = Field(default=None, description="兼容字段: 内容类型")
    content: Optional[str] = Field(default=None, description="兼容字段: 内容ID")
    
    @model_validator(mode='after')
    def compat_fields(self):
        if self.type and self.content_type == "wellness_plan":
            self.content_type = self.type
        if self.content and self.content_id == "":
            self.content_id = self.content
        return self


class InviteRequest(BaseModel):
    user_id: str = Field(..., description="邀请人用户ID")
    channel: str = Field(default="wechat", description="邀请渠道")


SHARE_TEMPLATES = {
    "wellness_plan": {
        "title": "我的顺时养生计划",
        "template": "我在【顺时】制定了专属养生计划，遵循二十四节气调养身心。{custom}",
        "hashtags": ["#顺时", "#中医养生", "#节气养生"]
    },
    "achievement": {
        "title": "养生里程碑达成",
        "template": "🎉 我在【顺时】获得了新成就！坚持养生的路上不孤单。{custom}",
        "hashtags": ["#顺时打卡", "#养生挑战", "#健康生活"]
    },
    "recipe": {
        "title": "节气食疗推荐",
        "template": "🍜 分享一道顺应节气的养生食谱，来自【顺时】的精心推荐。{custom}",
        "hashtags": ["#节气食疗", "#中医食养", "#顺时健康"]
    },
    "checkin": {
        "title": "今日养生打卡",
        "template": "📅 今日养生打卡！遵循自然节律，每天进步一点点。{custom}",
        "hashtags": ["#顺时打卡", "#每日养生", "#健康习惯"]
    },
    "insight": {
        "title": "养生心得分享",
        "template": "💡 分享一个实用的养生小知识，来自【顺时】。{custom}",
        "hashtags": ["#养生知识", "#中医智慧", "#顺时"]
    }
}


def _generate_share_id(user_id: str, content_type: str, content_id: str) -> str:
    raw = f"{user_id}:{content_type}:{content_id}:{datetime.now().date()}"
    return hashlib.md5(raw.encode()).hexdigest()[:12]


@router.post("/card", summary="生成分享卡片")
async def generate_share_card(request: ShareCardRequest):
    template = SHARE_TEMPLATES.get(request.content_type)
    if not template:
        raise HTTPException(status_code=400, detail=f"不支持的内容类型: {request.content_type}")

    share_id = _generate_share_id(request.user_id, request.content_type, request.content_id)
    custom = request.custom_message or ""
    text = template["template"].format(custom=custom).strip()

    card = {
        "share_id": share_id,
        "title": template["title"],
        "text": text,
        "hashtags": template["hashtags"],
        "platform": request.platform,
        "share_url": f"https://shunshi.app/share/{share_id}",
        "image_url": f"https://cdn.shunshi.app/cards/{request.content_type}/{request.content_id}.jpg",
        "created_at": datetime.now().isoformat()
    }
    _share_records[share_id] = {**card, "user_id": request.user_id, "clicks": 0}
    return {"success": True, "data": {"card": card}}


@router.get("/card/{share_id}", summary="获取分享卡片信息")
async def get_share_card(share_id: str):
    if share_id not in _share_records:
        raise HTTPException(status_code=404, detail="分享卡片不存在")
    _share_records[share_id]["clicks"] += 1
    return {"success": True, "data": _share_records[share_id]}


@router.post("/invite", summary="生成邀请链接")
async def generate_invite_link(request: InviteRequest):
    invite_code = hashlib.md5(f"invite:{request.user_id}:{request.channel}".encode()).hexdigest()[:8]
    return {
        "success": True,
        "data": {
            "invite_code": invite_code,
            "invite_url": f"https://shunshi.app/invite/{invite_code}",
            "qr_code_url": f"https://api.shunshi.app/qr?code={invite_code}",
            "channel": request.channel,
            "reward_message": "邀请好友成功后，双方均可获得7天会员体验",
            "expires_in_days": 30
        }
    }


@router.get("/templates", summary="分享模板列表")
async def list_share_templates():
    templates = [{"type": k, "title": v["title"], "hashtags": v["hashtags"]} for k, v in SHARE_TEMPLATES.items()]
    return {"success": True, "data": {"templates": templates}}


@router.get("/stats/{user_id}", summary="用户分享统计")
async def get_share_stats(user_id: str):
    user_shares = [s for s in _share_records.values() if s.get("user_id") == user_id]
    total_clicks = sum(s.get("clicks", 0) for s in user_shares)
    return {
        "success": True,
        "data": {
            "total_shares": len(user_shares),
            "total_clicks": total_clicks,
            "shares": user_shares
        }
    }
