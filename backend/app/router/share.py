"""
顺时 — 社交分享 API (shunshi-share)
生成分享卡片、社交分享内容、邀请链接。

邀请和卡片写在增长表里，进程重启后还在。
"""

from datetime import datetime
from typing import Optional
from urllib.parse import quote

from fastapi import APIRouter, Depends, Header, HTTPException, Request
from pydantic import BaseModel, Field, model_validator
from sqlalchemy.orm import Session

from app.deps import current_user, get_session
from app.growth.kit.claims import scan as claim_scan
from app.growth.kit.flags import GrowthFlags
from app.growth.referral_store import (
    get_share,
    list_shares,
    save_invite,
    save_share,
    share_id_for,
    share_payload,
)

router = APIRouter(prefix="/api/v1/share", tags=["share"])


class ShareCardRequest(BaseModel):
    user_id: Optional[str] = Field(default=None, description="兼容字段：忽略。身份取自登录令牌；与令牌不一致会被拒绝（403）")
    content_type: str = Field(default="wellness_plan", description="内容类型: wellness_plan/achievement/recipe/checkin/insight/solar_term/constitution")
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
    user_id: Optional[str] = Field(default=None, description="兼容字段：忽略。身份取自登录令牌；与令牌不一致会被拒绝（403）")
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
    # 节气卡片、体质报告卡片（android-cn ShareUtil 使用）。文案由客户端放在 custom_message，仍走同一道禁用说法扫描。
    "solar_term": {
        "title": "节气养生小贴士",
        "template": "🌿 跟着节气调养身心，来自【顺时】的节气养生。{custom}",
        "hashtags": ["#节气养生", "#二十四节气", "#顺时"]
    },
    "constitution": {
        "title": "我的体质报告",
        "template": "🧘 我在【顺时】完成了中医体质自测，了解自己的体质倾向。{custom}",
        "hashtags": ["#体质自测", "#中医养生", "#顺时"]
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

INVITE_NOTE = "把这个邀请码发给朋友，注册时填上就能记到你的名下"


def _own_user(body_user_id: Optional[str], user_id: str) -> str:
    """身份只认登录令牌。旧客户端还会在请求体里带 user_id：一致就放行，不一致拒绝，不替别人生成。"""
    if body_user_id and body_user_id != user_id:
        raise HTTPException(status_code=403, detail="只能操作自己的数据")
    return user_id


@router.post("/card", summary="生成分享卡片")
def generate_share_card(
    request: ShareCardRequest,
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
):
    request.user_id = _own_user(request.user_id, user_id)
    template = SHARE_TEMPLATES.get(request.content_type)
    if not template:
        raise HTTPException(status_code=400, detail=f"不支持的内容类型: {request.content_type}")

    share_id = share_id_for(request.user_id, request.content_type, request.content_id)
    custom = request.custom_message or ""
    if GrowthFlags.from_env().sharecard:
        # Growth kit (SHARECARD_ENABLED, default off): hold copy that makes medical / fate-prediction /
        # investment / absolute claims. A hit is never auto-fixed; the caller edits the text.
        hits = claim_scan(custom)
        if hits:
            raise HTTPException(
                status_code=422,
                detail="分享文案含有不能使用的说法（医疗功效、命运预测、收益承诺或绝对化用语），请修改后再分享",
            )
    text = template["template"].format(custom=custom).strip()
    created_at = datetime.now().isoformat()

    save_share(
        session,
        {
            "share_id": share_id,
            "user_id": request.user_id,
            "content_type": request.content_type,
            "content_id": request.content_id,
            "platform": request.platform,
            "title": template["title"],
            "text": text,
            "hashtags": template["hashtags"],
            "share_url": f"https://shunshi.app/share/{share_id}",
            "image_url": f"https://cdn.shunshi.app/cards/{quote(request.content_type, safe='')}/{quote(request.content_id, safe='')}.jpg",
            "created_at": created_at,
        },
    )
    card = share_payload(get_share(session, share_id), include_private=False)
    return {"success": True, "data": {"card": card}}


@router.get("/card/{share_id}", summary="获取分享卡片信息")
def get_share_card(
    share_id: str,
    request: Request,
    authorization: Optional[str] = Header(default=None),
    session: Session = Depends(get_session),
):
    """落地页，不用登录。点击数照常累加；user_id 和点击数只给卡片本人看，匿名访问者拿不到。"""
    row = get_share(session, share_id)
    if row is None:
        raise HTTPException(status_code=404, detail="分享卡片不存在")
    row.clicks += 1
    viewer = None
    if authorization and authorization.startswith("Bearer "):
        try:
            viewer = current_user(request, authorization, request.app.state.settings)
        except HTTPException:
            viewer = None
    return {"success": True, "data": share_payload(row, include_private=(viewer == row.user_id))}


@router.post("/invite", summary="生成邀请链接")
def generate_invite_link(
    request: InviteRequest,
    user_id: str = Depends(current_user),
    session: Session = Depends(get_session),
):
    request.user_id = _own_user(request.user_id, user_id)
    row = save_invite(session, user_id=request.user_id, channel=request.channel)
    invite_code = row.invite_code
    return {
        "success": True,
        "data": {
            "invite_code": invite_code,
            "invite_url": f"https://shunshi.app/invite/{invite_code}",
            "qr_code_url": f"https://api.shunshi.app/qr?code={invite_code}",
            "channel": request.channel,
            "reward_message": INVITE_NOTE,
            "expires_in_days": 30,
        },
    }


@router.get("/templates", summary="分享模板列表")
def list_share_templates():
    templates = [{"type": k, "title": v["title"], "hashtags": v["hashtags"]} for k, v in SHARE_TEMPLATES.items()]
    return {"success": True, "data": {"templates": templates}}


@router.get("/stats/{user_id}", summary="用户分享统计")
def get_share_stats(
    user_id: str,
    viewer: str = Depends(current_user),
    session: Session = Depends(get_session),
):
    _own_user(user_id, viewer)
    user_shares = [share_payload(row, include_private=True) for row in list_shares(session, user_id)]
    total_clicks = sum(item.get("clicks", 0) for item in user_shares)
    return {
        "success": True,
        "data": {
            "total_shares": len(user_shares),
            "total_clicks": total_clicks,
            "shares": user_shares,
        },
    }
