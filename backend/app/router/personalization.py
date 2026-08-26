"""七日个性化首页契约。

为真实客户端提供稳定的 dashboard/life-state/weekly-insight 路径，同时提供
5 人设 × 7 天的可复现验收数据。演示数据始终明确标注，不能冒充用户健康结论。
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

from fastapi import APIRouter, Header, HTTPException, Query
from pydantic import BaseModel, Field


router = APIRouter(prefix="/api/v1/personalization", tags=["个性化"])


@dataclass(frozen=True)
class Persona:
    persona_id: str
    display_name: str
    focus: str
    tone: str


CN_PERSONAS = (
    Persona("newcomer", "刚开始养生的小雨", "建立一个可坚持的小习惯", "简单、鼓励"),
    Persona("office_worker", "久坐上班族陈晨", "肩颈、睡眠与工作间歇", "直接、可执行"),
    Persona("parent", "关注全家状态的林姐", "家庭提醒与成员差异", "温暖、清晰"),
    Persona("active_senior", "规律生活的周叔", "稳健活动与异常提醒", "大字、低负担"),
    Persona("data_tracker", "喜欢看趋势的何川", "记录、趋势与证据", "结构化、带依据"),
)

GLOBAL_PERSONAS = (
    Persona("newcomer", "Maya, getting started", "one sustainable habit", "plain and encouraging"),
    Persona("office_worker", "Alex, desk-based professional", "sleep, posture and work breaks", "direct and actionable"),
    Persona("parent", "Jordan, family organizer", "household routines and consent", "warm and clear"),
    Persona("active_senior", "Sam, active older adult", "steady movement and warning signs", "calm and accessible"),
    Persona("data_tracker", "Taylor, quantified-self user", "records, trends and evidence", "structured and sourced"),
)

STAGES = (
    ("onboarding", "先认识你", "Set your focus"),
    ("first_action", "完成一个小行动", "Complete one small action"),
    ("data_building", "开始形成记录", "Build a useful signal"),
    ("pattern", "发现一个规律", "Notice a pattern"),
    ("adjustment", "按反馈微调", "Adjust from feedback"),
    ("action_plan", "生成下周行动", "Prepare next actions"),
    ("weekly_review", "回顾这一周", "Review the week"),
)


class ActionCompletion(BaseModel):
    action_type: str = Field(min_length=1, max_length=64)
    completed: bool
    rating: int = Field(default=0, ge=0, le=5)
    skill_name: str = Field(default="", max_length=80)
    duration_seconds: int = Field(default=0, ge=0, le=86_400)
    note: str = Field(default="", max_length=500)


def _language(accept_language: str | None, locale: str | None) -> Literal["zh", "en"]:
    requested = (locale or accept_language or "zh-CN").lower()
    return "zh" if requested.startswith("zh") else "en"


def _persona(persona_id: str, language: Literal["zh", "en"]) -> Persona:
    personas = CN_PERSONAS if language == "zh" else GLOBAL_PERSONAS
    for persona in personas:
        if persona.persona_id == persona_id:
            return persona
    raise HTTPException(status_code=404, detail="未知验收人设" if language == "zh" else "Unknown acceptance persona")


def _dashboard(persona: Persona, day: int, language: Literal["zh", "en"]) -> dict:
    stage_id, zh_title, en_title = STAGES[day - 1]
    if language == "zh":
        headline = zh_title
        summary = f"围绕“{persona.focus}”展示今天最重要的一件事，其余内容按需展开。"
        action = "查看今天的建议" if day < 7 else "查看本周总结"
        evidence = "演示验收数据，不代表医学诊断；正式结果需结合用户记录与来源日期。"
    else:
        headline = en_title
        summary = f"Lead with one useful step for {persona.focus}; keep secondary detail on demand."
        action = "Open today's guidance" if day < 7 else "Open weekly review"
        evidence = "Acceptance-demo data, not medical advice. Live results require user records and dated sources."
    return {
        "persona_id": persona.persona_id,
        "display_name": persona.display_name,
        "day": day,
        "stage": stage_id,
        "tone": persona.tone,
        "hero": {"headline": headline, "summary": summary, "action_label": action},
        "widgets": [
            {"id": "today", "priority": 1, "title": headline},
            {"id": "progress", "priority": 2, "title": f"{day}/7"},
            {"id": "evidence", "priority": 3, "title": evidence},
        ],
        "demo_mode": True,
        "evidence_status": "demo_disclosed",
    }


@router.get("/dashboard")
async def dashboard(
    persona_id: str = Query("newcomer"),
    day: int = Query(1, ge=1, le=7),
    locale: str | None = Query(None),
    accept_language: str | None = Header(None, alias="Accept-Language"),
):
    language = _language(accept_language, locale)
    return {"success": True, "data": _dashboard(_persona(persona_id, language), day, language)}


@router.get("/acceptance-week")
async def acceptance_week(
    locale: str | None = Query(None),
    accept_language: str | None = Header(None, alias="Accept-Language"),
):
    language = _language(accept_language, locale)
    personas = CN_PERSONAS if language == "zh" else GLOBAL_PERSONAS
    return {
        "success": True,
        "data": {
            "locale": "zh-CN" if language == "zh" else "en-US",
            "demo_mode": True,
            "personas": [
                {
                    "persona_id": persona.persona_id,
                    "display_name": persona.display_name,
                    "days": [_dashboard(persona, day, language) for day in range(1, 8)],
                }
                for persona in personas
            ],
        },
    }


@router.get("/life-state")
async def life_state(day: int = Query(1, ge=1, le=7)):
    return {"success": True, "data": {"day": day, "stage": STAGES[day - 1][0]}}


@router.post("/action/complete")
async def complete_action(body: ActionCompletion):
    return {
        "success": True,
        "data": {"recorded": True, "action_type": body.action_type, "completed": body.completed},
    }


@router.get("/anomaly-alert")
async def anomaly_alert():
    return {"success": True, "data": {"has_alert": False, "items": []}}


@router.get("/weekly-insight")
async def weekly_insight(
    locale: str | None = Query(None),
    accept_language: str | None = Header(None, alias="Accept-Language"),
):
    language = _language(accept_language, locale)
    message = "记录满七天后再总结趋势，数据不足时不生成结论。" if language == "zh" else (
        "Summarize trends only after seven days of records; do not infer from insufficient data."
    )
    return {"success": True, "data": {"status": "insufficient_data", "message": message}}
