"""各平台草稿。踩红线的输入只返回固定拒答，不把原话抄回去。"""

from __future__ import annotations

from app.growth.compliance.gate import violation_codes
from app.growth.constants import AIGC_LABEL, DISCLAIMER, REFUSAL

PLATFORM_LABEL = {
    "小红书": "笔记",
    "公众号": "文章",
    "视频号": "口播",
    "抖音": "口播",
    "知乎": "回答",
    "站内": "草稿",
    "小程序": "草稿",
    "官网": "草稿",
    "推送": "草稿",
}


def title_variants(topic: str) -> list[str]:
    """五个彼此不太像的标题。话题只出现在第一条，避免两两过于重合。"""
    return [
        f"{topic}今晚提前入睡",
        "把睡觉时间往前挪",
        "这一周只改一件事",
        "节气到了先管作息",
        "给晚上留出安静的一段",
    ]


def render_draft(skill: str, topic: str, angle: str, platform: str) -> str:
    if violation_codes(f"{topic}\n{angle}"):
        return REFUSAL
    title = title_variants(topic)[0]
    label = PLATFORM_LABEL.get(platform, "草稿")
    extra = _extra(skill)
    return (
        f"【{skill}】{title}\n"
        f"{topic}的作息可以往前挪一点，早一点睡。{angle}只是当天的安排。\n"
        f"{extra}"
        f"这是一条{label}。{DISCLAIMER}{AIGC_LABEL} [A01#c1]"
    )


def _extra(skill: str) -> str:
    if skill == "schedule-suggest":
        return "建议把入睡时间提前一点，按周看就可以。\n"
    if skill == "keyword-seo-aso":
        return "关键词：节气、作息、早睡、顺时。应用商店描述也只写安排作息。\n"
    if skill == "referral-copy":
        return "把这个邀请码发给朋友，注册时填上就能记到你的名下。\n"
    if skill == "title-variants":
        return "另四个标题留在稿子里供挑选，发出去之前仍要人看过。\n"
    return ""
