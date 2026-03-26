"""
顺时 ShunShi - 节气养生增强服务
24节气详细养生方案 + 倒计时 + 当前节气高亮

作者: Claw 🦅
日期: 2026-03-18
"""

import math
import logging
from datetime import datetime, date, timedelta
from typing import Optional, Dict, Any, List

from app.database.db import get_db

logger = logging.getLogger(__name__)


# ==================== 2026年24节气精确日期 ====================

SOLAR_TERMS_2026 = [
    {"name": "立春", "name_en": "Beginning of Spring", "month": 2, "day": 4, "emoji": "🌱", "season": "spring"},
    {"name": "雨水", "name_en": "Rain Water", "month": 2, "day": 19, "emoji": "💧", "season": "spring"},
    {"name": "惊蛰", "name_en": "Awakening of Insects", "month": 3, "day": 5, "emoji": "⚡", "season": "spring"},
    {"name": "春分", "name_en": "Spring Equinox", "month": 3, "day": 20, "emoji": "🌸", "season": "spring"},
    {"name": "清明", "name_en": "Clear and Bright", "month": 4, "day": 5, "emoji": "🌿", "season": "spring"},
    {"name": "谷雨", "name_en": "Grain Rain", "month": 4, "day": 20, "emoji": "🌧️", "season": "spring"},
    {"name": "立夏", "name_en": "Beginning of Summer", "month": 5, "day": 6, "emoji": "☀️", "season": "summer"},
    {"name": "小满", "name_en": "Grain Buds", "month": 5, "day": 21, "emoji": "🌾", "season": "summer"},
    {"name": "芒种", "name_en": "Grain in Ear", "month": 6, "day": 6, "emoji": "🌾", "season": "summer"},
    {"name": "夏至", "name_en": "Summer Solstice", "month": 6, "day": 21, "emoji": "🌞", "season": "summer"},
    {"name": "小暑", "name_en": "Minor Heat", "month": 7, "day": 7, "emoji": "🔥", "season": "summer"},
    {"name": "大暑", "name_en": "Major Heat", "month": 7, "day": 23, "emoji": "🌡️", "season": "summer"},
    {"name": "立秋", "name_en": "Beginning of Autumn", "month": 8, "day": 7, "emoji": "🍂", "season": "autumn"},
    {"name": "处暑", "name_en": "End of Heat", "month": 8, "day": 23, "emoji": "🍃", "season": "autumn"},
    {"name": "白露", "name_en": "White Dew", "month": 9, "day": 7, "emoji": "💧", "season": "autumn"},
    {"name": "秋分", "name_en": "Autumn Equinox", "month": 9, "day": 23, "emoji": "🍁", "season": "autumn"},
    {"name": "寒露", "name_en": "Cold Dew", "month": 10, "day": 8, "emoji": "🍂", "season": "autumn"},
    {"name": "霜降", "name_en": "Frost Descent", "month": 10, "day": 23, "emoji": "❄️", "season": "autumn"},
    {"name": "立冬", "name_en": "Beginning of Winter", "month": 11, "day": 7, "emoji": "❄️", "season": "winter"},
    {"name": "小雪", "name_en": "Minor Snow", "month": 11, "day": 22, "emoji": "🌨️", "season": "winter"},
    {"name": "大雪", "name_en": "Major Snow", "month": 12, "day": 7, "emoji": "⛄", "season": "winter"},
    {"name": "冬至", "name_en": "Winter Solstice", "month": 12, "day": 22, "emoji": "☀️", "season": "winter"},
    {"name": "小寒", "name_en": "Minor Cold", "month": 1, "day": 5, "emoji": "🥶", "season": "winter"},
    {"name": "大寒", "name_en": "Major Cold", "month": 1, "day": 20, "emoji": "🥶", "season": "winter"},
]

# 按日历顺序排列
SOLAR_TERMS_ORDERED = sorted(SOLAR_TERMS_2026, key=lambda x: (x["month"], x["day"]))


class SolarTermEnhancedService:
    """节气养生增强服务"""

    def __init__(self):
        pass

    def get_current_term(self) -> Dict[str, Any]:
        """获取当前节气（含倒计时）"""
        today = date.today()
        current = None
        next_term = None
        days_in_current = 0
        countdown = 0

        for i, term in enumerate(SOLAR_TERMS_ORDERED):
            term_date = date(2026, term["month"], term["day"])
            next_date = date(2026, SOLAR_TERMS_ORDERED[(i + 1) % 24]["month"], SOLAR_TERMS_ORDERED[(i + 1) % 24]["day"])

            if term_date <= today < next_date:
                current = term
                days_in_current = (next_date - today).days
                # 下一个节气
                next_term = SOLAR_TERMS_ORDERED[(i + 1) % 24]
                next_term_date = date(2026, next_term["month"], next_term["day"])
                countdown = (next_term_date - today).days
                break

        if not current:
            # 兜底: 找最近的
            min_delta = float('inf')
            for term in SOLAR_TERMS_ORDERED:
                td = date(2026, term["month"], term["day"])
                delta = abs((td - today).days)
                if delta < min_delta:
                    min_delta = delta
                    current = term

        return {
            "current": {
                "name": current["name"],
                "name_en": current["name_en"],
                "emoji": current["emoji"],
                "season": current["season"],
                "date": f"2026-{current['month']:02d}-{current['day']:02d}",
                "days_remaining": days_in_current,
            },
            "next": {
                "name": next_term["name"] if next_term else "",
                "name_en": next_term["name_en"] if next_term else "",
                "emoji": next_term["emoji"] if next_term else "",
                "countdown_days": countdown,
                "date": f"2026-{next_term['month']:02d}-{next_term['day']:02d}" if next_term else "",
            } if next_term else None,
        }

    def get_term_detail(
        self,
        term_name: str,
        locale: str = "zh-CN",
    ) -> Dict[str, Any]:
        """
        获取节气详细养生方案

        Args:
            term_name: 节气名称（中文或英文）
            locale: 语言

        Returns:
            详细养生方案
        """
        term = None
        for t in SOLAR_TERMS_ORDERED:
            if t["name"] == term_name or t["name_en"].lower() == term_name.lower():
                term = t
                break

        if not term:
            raise ValueError(f"节气不存在: {term_name}")

        # 从数据库获取相关内容
        conn = get_db()
        season = term["season"]

        # 食疗推荐
        diet_rows = conn.execute(
            """SELECT id, title, description, ingredients, steps, tags, difficulty, duration 
               FROM contents WHERE type = 'food_therapy' AND locale = ? AND season_tag = ?
               ORDER BY RANDOM() LIMIT 3""",
            (locale, season),
        ).fetchall()

        # 茶饮推荐
        tea_rows = conn.execute(
            """SELECT id, title, description, ingredients, steps, tags 
               FROM contents WHERE type = 'tea' AND locale = ? AND season_tag = ?
               ORDER BY RANDOM() LIMIT 2""",
            (locale, season),
        ).fetchall()

        # 运动推荐
        exercise_rows = conn.execute(
            """SELECT id, title, description, benefits, tags, difficulty, duration 
               FROM contents WHERE type = 'exercise' AND locale = ? AND (season_tag = ? OR season_tag IS NULL)
               ORDER BY RANDOM() LIMIT 2""",
            (locale, season),
        ).fetchall()

        # 穴位推荐
        acupoint_rows = conn.execute(
            """SELECT id, title, description, location, method, effect, tags, duration 
               FROM contents WHERE type = 'acupressure' AND locale = ?
               ORDER BY RANDOM() LIMIT 2""",
            (locale,),
        ).fetchall()

        # 睡眠建议
        sleep_rows = conn.execute(
            """SELECT id, title, description, method, effect, tags, best_time 
               FROM contents WHERE type = 'sleep_tip' AND locale = ?
               ORDER BY RANDOM() LIMIT 2""",
            (locale,),
        ).fetchall()

        def row_to_dict(r):
            """Convert sqlite3.Row to dict (Row doesn't support .get())"""
            return {k: r[k] for k in r.keys()} if hasattr(r, 'keys') else dict(r)

        def safe_get(d, key, default=""):
            return d.get(key, default) if isinstance(d, dict) else (d[key] if isinstance(d, dict) else default)

        def parse_json(val):
            if not val:
                return []
            import json
            try:
                return json.loads(val) if isinstance(val, str) else val
            except (json.JSONDecodeError, TypeError):
                return [val] if val else []

        return {
            "term": {
                "name": term["name"],
                "name_en": term["name_en"],
                "emoji": term["emoji"],
                "season": term["season"],
                "date": f"2026-{term['month']:02d}-{term['day']:02d}",
            },
            "wellness_plan": {
                "diet": [
                    {"id": row_to_dict(r)["id"], "title": row_to_dict(r)["title"], "description": safe_get(row_to_dict(r), "description"),
                     "ingredients": parse_json(safe_get(row_to_dict(r), "ingredients")), "steps": parse_json(safe_get(row_to_dict(r), "steps")),
                     "difficulty": safe_get(row_to_dict(r), "difficulty"), "duration": safe_get(row_to_dict(r), "duration"),
                     "tags": parse_json(safe_get(row_to_dict(r), "tags"))}
                    for r in diet_rows
                ],
                "tea": [
                    {"id": row_to_dict(r)["id"], "title": row_to_dict(r)["title"], "description": safe_get(row_to_dict(r), "description"),
                     "ingredients": parse_json(safe_get(row_to_dict(r), "ingredients")), "steps": parse_json(safe_get(row_to_dict(r), "steps")),
                     "tags": parse_json(safe_get(row_to_dict(r), "tags"))}
                    for r in tea_rows
                ],
                "exercise": [
                    {"id": row_to_dict(r)["id"], "title": row_to_dict(r)["title"], "description": safe_get(row_to_dict(r), "description"),
                     "benefits": parse_json(safe_get(row_to_dict(r), "benefits")), "difficulty": safe_get(row_to_dict(r), "difficulty"),
                     "duration": safe_get(row_to_dict(r), "duration"), "tags": parse_json(safe_get(row_to_dict(r), "tags"))}
                    for r in exercise_rows
                ],
                "acupoints": [
                    {"id": row_to_dict(r)["id"], "title": row_to_dict(r)["title"], "description": safe_get(row_to_dict(r), "description"),
                     "location": safe_get(row_to_dict(r), "location"), "method": safe_get(row_to_dict(r), "method"),
                     "effect": safe_get(row_to_dict(r), "effect"), "duration": safe_get(row_to_dict(r), "duration"),
                     "tags": parse_json(safe_get(row_to_dict(r), "tags"))}
                    for r in acupoint_rows
                ],
                "sleep": [
                    {"id": row_to_dict(r)["id"], "title": row_to_dict(r)["title"], "description": safe_get(row_to_dict(r), "description"),
                     "method": safe_get(row_to_dict(r), "method"), "effect": safe_get(row_to_dict(r), "effect"),
                     "best_time": safe_get(row_to_dict(r), "best_time"), "tags": parse_json(safe_get(row_to_dict(r), "tags"))}
                    for r in sleep_rows
                ],
                "routine": self._get_routine_advice(term["season"], locale),
            },
        }

    def get_all_terms_with_status(self, locale: str = "zh-CN") -> List[Dict[str, Any]]:
        """获取所有节气（含当前/过去/未来状态）"""
        today = date.today()
        result = []

        for i, term in enumerate(SOLAR_TERMS_ORDERED):
            term_date = date(2026, term["month"], term["day"])
            next_idx = (i + 1) % 24
            next_date = date(2026, SOLAR_TERMS_ORDERED[next_idx]["month"], SOLAR_TERMS_ORDERED[next_idx]["day"])

            if term_date <= today < next_date:
                status = "current"
            elif term_date < today:
                status = "past"
            else:
                status = "upcoming"

            name = term["name"] if locale != "en-US" else term["name_en"]

            result.append({
                "index": i + 1,
                "name": term["name"],
                "name_en": term["name_en"],
                "display_name": name,
                "emoji": term["emoji"],
                "season": term["season"],
                "date": f"2026-{term['month']:02d}-{term['day']:02d}",
                "status": status,
                "days_until": (term_date - today).days if status == "upcoming" else 0,
                "is_highlighted": status == "current",
            })

        return result

    def _get_routine_advice(self, season: str, locale: str) -> Dict[str, str]:
        """获取节气作息建议"""
        if locale == "en-US":
            return {
                "sleep": "Retire by 11 PM and rise with the sun. Adequate sleep is the foundation of seasonal wellness.",
                "diet": "Eat seasonal, locally sourced foods. Warm meals in winter, cooling dishes in summer.",
                "exercise": "30 minutes of moderate exercise daily. Morning is best — avoid strenuous activity late at night.",
                "emotion": "Maintain emotional balance. Spring: stay joyful. Summer: stay calm. Autumn: stay serene. Winter: stay peaceful.",
            }
        
        return {
            "sleep": "顺应节气调整作息，子时(23点)前入睡，卯时(5-7点)起床。",
            "diet": "饮食应季而食，春夏养阳，秋冬养阴，忌暴饮暴食。",
            "exercise": "每日适度运动30分钟，清晨为佳，避免夜间剧烈运动。",
            "emotion": "调畅情志，春舒肝气，夏养心神，秋防悲忧，冬宜藏精。",
        }


# 全局实例
solar_term_enhanced_service = SolarTermEnhancedService()
