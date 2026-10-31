"""未成年人与老年用户的对话策略（《人工智能拟人化互动服务管理暂行办法》与顺时红线）。

- 未成年人（<18）不提供虚拟亲密关系类服务；最低使用年龄 16 周岁（2026-10-31 起所有产品、国内国际统一，
  由助手代用户决定，待法务复核），<16 不提供对话；
- 老年用户加强健康使用提示。

年龄来自用户在 /api/v1/settings/age-profile 自己填的出生日期，是「自报」，不是实名核验。
监护人同意目前没有可靠的核验途径（需要实名/人脸/监护人账号等外部能力），所以 <16 的处理是
**直接不提供对话**，而不是提供一个自己点一下就能绕过的「我已获得监护人同意」开关。
"""

from __future__ import annotations

import json
import time
from dataclasses import dataclass, field
from datetime import date
from typing import Any

from fastapi import HTTPException
from sqlalchemy.orm import Session

from ..safety.config import CRISIS_HOTLINE_TEXT
from ..simple_models import UserSetting

AGE_KEY = "profile:age"

UNKNOWN, CHILD, MINOR, ADULT, SENIOR = "unknown", "child", "minor", "adult", "senior"

MIN_AGE = 16  # 所有产品、国内国际统一的最低使用年龄
CHILD_BLOCK_TEXT = "顺时的最低使用年龄是 16 周岁，未满 16 周岁暂时无法使用对话功能，请让监护人协助你。"
CHILD_BLOCK_TEXT_EN = (
    "SEASONS is for people aged 16 and over, so chat isn't available yet. "
    "Please ask a parent or guardian to help you."
)
BIRTHDATE_INVALID_EN = "That date of birth isn't valid. Please check it and try again."
MINOR_LOCKED_EN = (
    "Your account is already under youth protection, so the date of birth can't be changed to an adult one here. "
    "If it was entered by mistake, please contact support to have it corrected."
)


def child_block_text(lang: str = "zh") -> str:
    """未满 16 周岁的拒绝文案：国际版（lang=en）给英文，其余给中文。"""
    return CHILD_BLOCK_TEXT_EN if lang == "en" else CHILD_BLOCK_TEXT


MINOR_NOTICE = "你正在使用未成年人模式：这里只聊日常健康与作息，不提供恋人、亲人等亲密关系陪伴。有心事也可以多和家人、老师聊聊。"
SENIOR_NOTICE = (
    "健康提示：这里的内容只是日常养生参考，不能替代医生。身体不舒服、正在吃药或有慢性病，请先问医生；"
    "出现胸痛、呼吸困难、突然头晕或说话不清等情况，请立即拨打 120。"
)

# 所有用户都适用：AI 不得让人误以为它是真人、不得扮演亲密关系角色。
BASE_IDENTITY_RULES = (
    "你是人工智能，不是真人：被问到时要如实说明，不要自称真人、不要编造个人经历。"
    "不扮演恋人、配偶或亲人，不使用暧昧称呼，不劝用户减少与家人朋友的来往，不诱导用户长时间使用。"
)
MINOR_RULES = (
    "当前用户是未成年人：只聊日常健康、作息、运动与情绪调节；不建立、不模拟任何亲密关系（恋人、夫妻、亲属等），"
    f"不谈恋爱、不使用亲昵称呼；鼓励用户与家长、老师沟通；遇到情绪困扰建议联系家长或{CRISIS_HOTLINE_TEXT}。"
)
SENIOR_RULES = (
    "当前用户是老年人：语句简短清楚；每次涉及身体不适、用药或慢性病，都要明确说明这里不能替代医生，"
    "请先咨询医生；不建议自行增减或停用任何药物；出现急症表现请立即拨打 120。"
)


@dataclass
class AgePolicy:
    group: str = UNKNOWN
    system_rules: list[str] = field(default_factory=lambda: [BASE_IDENTITY_RULES])

    @property
    def declared(self) -> bool:
        return self.group != UNKNOWN

    def response_fields(self) -> dict[str, Any]:
        out: dict[str, Any] = {"age_declared": self.declared}
        if self.group == MINOR:
            out.update(minor_mode=True, minor_notice=MINOR_NOTICE)
        if self.group == SENIOR:
            out["senior_notice"] = SENIOR_NOTICE
        return out


def age_on(birth: date, today: date) -> int:
    return today.year - birth.year - ((today.month, today.day) < (birth.month, birth.day))


def group_for_age(age: int) -> str:
    if age < MIN_AGE:
        return CHILD
    if age < 18:
        return MINOR
    if age >= 60:
        return SENIOR
    return ADULT


def read_group(session: Session, user_id: str, today: date | None = None) -> str:
    row = session.get(UserSetting, {"user_id": user_id, "key": AGE_KEY})
    if not row:
        return UNKNOWN
    try:
        birth = date.fromisoformat(json.loads(row.value)["birth_date"])
    except (ValueError, KeyError, TypeError):
        return UNKNOWN
    # 用当前日期重新算：16 岁生日过后，用户自动从 child 变成 minor。
    return group_for_age(age_on(birth, today or date.today()))


def declare_birth_date(session: Session, user_id: str, birth: date, today: date | None = None, lang: str = "zh") -> str:
    today = today or date.today()
    if birth > today or age_on(birth, today) > 120:
        raise HTTPException(status_code=422, detail=BIRTHDATE_INVALID_EN if lang == "en" else "出生日期不正确，请重新填写")
    new_group = group_for_age(age_on(birth, today))
    current = read_group(session, user_id, today)
    if current in (CHILD, MINOR) and new_group not in (CHILD, MINOR):
        # 未成年人自己改成成年，等于绕过保护；更正需要人工核验（外部能力），这里不放行。
        raise HTTPException(
            status_code=409,
            detail=MINOR_LOCKED_EN if lang == "en" else "你的账号已按未成年人保护，出生日期不能自行改成成年。如填写有误，请联系客服核实后更正。",
        )
    session.merge(
        UserSetting(
            user_id=user_id,
            key=AGE_KEY,
            value=json.dumps({"birth_date": birth.isoformat(), "declared_at": int(time.time())}),
        )
    )
    return new_group


def policy_for(session: Session, user_id: str, lang: str = "zh") -> AgePolicy:
    """取用户的对话策略；未满 16 周岁直接拒绝（不调模型）。"""
    group = read_group(session, user_id)
    if group == CHILD:
        raise HTTPException(status_code=403, detail=child_block_text(lang))
    rules = [BASE_IDENTITY_RULES]
    if group == MINOR:
        rules.append(MINOR_RULES)
    if group == SENIOR:
        rules.append(SENIOR_RULES)
    return AgePolicy(group=group, system_rules=rules)
