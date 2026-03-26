"""
个性化推送调度服务
基于用户画像生成差异化推送内容（Mock模式，不实际推送）
"""
import logging
from datetime import datetime
from typing import Optional

from app.rag.personalizer import generate_daily_plan, _get_user_profile, _get_current_solar_term_cn, _get_current_season_gl

logger = logging.getLogger(__name__)


class PushScheduler:
    """个性化推送调度器（Mock模式）"""

    async def get_morning_push(self, user_id: str, lang: str = "cn") -> dict:
        """早晨推送 (7:00) — 问候+今日饮食建议+晨练"""
        plan = await generate_daily_plan(user_id, lang)
        profile = _get_user_profile(user_id)
        name = profile.get("name", "")

        if lang == "cn":
            title = f"早安，{name}！" if name else "早安！新的一天开始了"
            body = plan["greeting"] + "\n\n" + "【今日早餐】" + plan["diet"]["breakfast"]
            body += "\n\n【晨练建议】" + plan["exercise"]["morning"]
            if plan["diet"].get("tea_tip"):
                body += "\n\n【今日茶饮】" + plan["diet"]["tea"] + " — " + plan["diet"]["tea_tip"]
            else:
                body += "\n\n【今日茶饮】" + plan["diet"]["tea"]
        else:
            title = f"Good morning, {name}!" if name else "Good morning! A new day begins"
            body = plan["greeting"] + "\n\n[Breakfast] " + plan["diet"]["breakfast"]
            body += "\n\n[Morning Exercise] " + plan["exercise"]["morning"]
            body += "\n\n[Today's Tea] " + plan["diet"]["tea"]

        return {
            "type": "morning",
            "title": title,
            "body": body,
            "timestamp": datetime.now().isoformat(),
            "data": plan,
        }

    async def get_noon_push(self, user_id: str, lang: str = "cn") -> dict:
        """午间推送 (12:00) — 午餐建议+午休提醒+茶饮"""
        plan = await generate_daily_plan(user_id, lang)
        profile = _get_user_profile(user_id)
        name = profile.get("name", "")

        if lang == "cn":
            title = f"{name}，午餐时间到了" if name else "午间养生提醒"
            body = "【午餐建议】" + plan["diet"]["lunch"]
            body += "\n\n忌食提醒：" + plan["diet"]["avoid"]
            body += "\n\n建议午休20-30分钟，养心安神、恢复精力"
            if plan["diet"].get("tea"):
                body += "\n\n【午后茶饮】" + plan["diet"]["tea"]
        else:
            title = f"Time for lunch, {name}!" if name else "Midday wellness reminder"
            body = "[Lunch] " + plan["diet"]["lunch"]
            body += "\n\nAvoid: " + plan["diet"]["avoid"]
            body += "\n\nA 20-30 min midday nap restores energy and nourishes the heart."
            body += "\n\n[Afternoon Tea] " + plan["diet"]["tea"]

        return {
            "type": "noon",
            "title": title,
            "body": body,
            "timestamp": datetime.now().isoformat(),
            "data": {
                "diet": plan["diet"],
                "sleep": plan["sleep"],
            },
        }

    async def get_afternoon_push(self, user_id: str, lang: str = "cn") -> dict:
        """下午推送 (15:00) — 运动提醒+穴位按摩"""
        plan = await generate_daily_plan(user_id, lang)
        profile = _get_user_profile(user_id)
        name = profile.get("name", "")

        if lang == "cn":
            title = f"{name}，起来活动一下吧！" if name else "下午活动提醒"
            body = "【下午活动】" + plan["exercise"]["afternoon"]
            body += "\n\n【穴位按摩】今日推荐穴位：" + "、".join(plan["acupoints"]["today_points"])
            body += "\n方法：" + plan["acupoints"]["method"]
            body += "\n重点：" + plan["acupoints"]["focus"]
        else:
            title = f"Time to move, {name}!" if name else "Afternoon activity reminder"
            body = "[Afternoon Activity] " + plan["exercise"]["afternoon"]
            body += "\n\n[Acupoints] Today's recommended points: " + ", ".join(plan["acupoints"]["today_points"])
            body += "\nMethod: " + plan["acupoints"]["method"]
            body += "\nFocus: " + plan["acupoints"]["focus"]

        return {
            "type": "afternoon",
            "title": title,
            "body": body,
            "timestamp": datetime.now().isoformat(),
            "data": {
                "exercise": plan["exercise"],
                "acupoints": plan["acupoints"],
            },
        }

    async def get_evening_push(self, user_id: str, lang: str = "cn") -> dict:
        """晚间推送 (18:00) — 晚餐+泡脚建议"""
        plan = await generate_daily_plan(user_id, lang)
        profile = _get_user_profile(user_id)
        name = profile.get("name", "")

        if lang == "cn":
            title = f"{name}，辛苦了一天" if name else "晚间养生提醒"
            body = "【晚餐建议】" + plan["diet"]["dinner"]
            body += "\n\n【晚间舒缓】" + plan["exercise"]["evening"]
            body += "\n\n【情绪调养】" + plan["emotional"]["focus"] + "：" + plan["emotional"]["tip"]
        else:
            title = f"Evening wellness, {name}" if name else "Evening wellness reminder"
            body = "[Dinner] " + plan["diet"]["dinner"]
            body += "\n\n[Evening Relaxation] " + plan["exercise"]["evening"]
            body += "\n\n[Emotional Wellness] " + plan["emotional"]["tip"]

        return {
            "type": "evening",
            "title": title,
            "body": body,
            "timestamp": datetime.now().isoformat(),
            "data": {
                "diet": plan["diet"],
                "exercise": plan["exercise"],
                "emotional": plan["emotional"],
            },
        }

    async def get_night_push(self, user_id: str, lang: str = "cn") -> dict:
        """睡前推送 (21:30) — 睡眠建议+穴位+情绪"""
        plan = await generate_daily_plan(user_id, lang)
        profile = _get_user_profile(user_id)
        name = profile.get("name", "")

        if lang == "cn":
            title = f"{name}，该休息了" if name else "晚安，好梦"
            body = "【睡眠建议】建议入睡时间：" + plan["sleep"]["bedtime"]
            body += "，建议起床时间：" + plan["sleep"]["waketime"]
            body += "（" + plan["sleep"]["hours"] + "）"
            body += "\n\n" + plan["sleep"]["tips"]
            if plan["sleep"].get("extra_advice"):
                body += "\n\n" + plan["sleep"]["extra_advice"][:200]
            body += "\n\n晚安，祝您好梦~"
        else:
            title = f"Sweet dreams, {name}" if name else "Good night!"
            body = "[Sleep] Bedtime: " + plan["sleep"]["bedtime"]
            body += " | Wake: " + plan["sleep"]["waketime"]
            body += " (" + plan["sleep"]["hours"] + ")"
            body += "\n\n" + plan["sleep"]["tips"]
            body += "\n\nWishing you a restful night."
        
        return {
            "type": "night",
            "title": title,
            "body": body,
            "timestamp": datetime.now().isoformat(),
            "data": {
                "sleep": plan["sleep"],
                "acupoints": plan["acupoints"],
                "emotional": plan["emotional"],
            },
        }

    async def get_daily_push(self, user_id: str, lang: str = "cn") -> dict:
        """完整日推送方案"""
        plan = await generate_daily_plan(user_id, lang)
        profile = _get_user_profile(user_id)
        name = profile.get("name", "")

        if lang == "cn":
            title = f"{name}的今日养生方案" if name else "今日养生方案"
            solar_term, season = _get_current_solar_term_cn()
            subtitle = f"{solar_term}（{season}季）养生指南"
        else:
            title = f"{name}'s Daily Wellness Plan" if name else "Daily Wellness Plan"
            season = _get_current_season_gl()
            subtitle = f"{season.capitalize()} Season Wellness Guide"

        return {
            "type": "daily",
            "title": title,
            "subtitle": subtitle,
            "timestamp": datetime.now().isoformat(),
            "data": plan,
        }


# 全局实例
push_scheduler = PushScheduler()
