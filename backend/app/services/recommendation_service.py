"""
顺时 ShunShi - 智能推荐服务
基于用户体质/季节/时辰/历史记录推荐个性化养生内容

作者: Claw 🦅
日期: 2026-03-18
"""

import json
import random
import logging
from datetime import datetime, time
from typing import Optional, Dict, Any, List

from app.database.db import get_db

logger = logging.getLogger(__name__)


# ==================== 季节映射 ====================

MONTH_SEASON = {
    1: "winter", 2: "winter", 3: "spring", 4: "spring",
    5: "spring", 6: "summer", 7: "summer", 8: "summer",
    9: "autumn", 10: "autumn", 11: "autumn", 12: "winter",
}

# 时辰养生肖法
TIME_PERIODS = {
    "morning": {"hours": (5, 12), "focus": "energy", "label_cn": "晨起", "label_en": "Morning"},
    "afternoon": {"hours": (12, 17), "focus": "activity", "label_cn": "午后", "label_en": "Afternoon"},
    "evening": {"hours": (17, 21), "focus": "relax", "label_cn": "傍晚", "label_en": "Evening"},
    "night": {"hours": (21, 5), "focus": "rest", "label_cn": "夜晚", "label_en": "Night"},
}

# 体质 -> 建议类型权重
CONSTITUTION_WEIGHTS = {
    "气虚质": {"recipe": 0.4, "exercise": 0.3, "tea": 0.2, "sleep": 0.1},
    "阳虚质": {"recipe": 0.3, "exercise": 0.2, "tea": 0.3, "sleep": 0.2},
    "阴虚质": {"recipe": 0.3, "tea": 0.3, "sleep": 0.2, "exercise": 0.2},
    "痰湿质": {"recipe": 0.3, "exercise": 0.4, "tea": 0.2, "sleep": 0.1},
    "湿热质": {"recipe": 0.2, "exercise": 0.3, "tea": 0.3, "sleep": 0.2},
    "血瘀质": {"recipe": 0.2, "exercise": 0.4, "tea": 0.2, "sleep": 0.2},
    "气郁质": {"exercise": 0.3, "tea": 0.2, "recipe": 0.2, "sleep": 0.3},
    "特禀质": {"recipe": 0.3, "tea": 0.3, "sleep": 0.2, "exercise": 0.2},
    "平和质": {"recipe": 0.25, "exercise": 0.25, "tea": 0.25, "sleep": 0.25},
}

# 类型 -> 内容 type 映射
TYPE_CONTENT_MAP = {
    "recipe": "food_therapy",
    "exercise": "exercise",
    "tea": "tea",
    "sleep": "sleep_tip",
    "acupoint": "acupressure",
}


class RecommendationService:
    """智能推荐服务"""

    def __init__(self):
        pass

    def get_daily_recommendations(
        self,
        user_id: str,
        locale: str = "zh-CN",
        limit: int = 3,
    ) -> Dict[str, Any]:
        """
        获取每日个性化推荐

        Args:
            user_id: 用户 ID
            locale: 语言 (zh-CN/en-US)
            limit: 推荐数量

        Returns:
            推荐结果
        """
        now = datetime.now()
        month = now.month
        hour = now.hour
        season = MONTH_SEASON.get(month, "spring")

        # 获取用户体质
        constitution = self._get_user_constitution(user_id)

        # 获取用户偏好
        preferences = self._get_user_preferences(user_id)

        # 根据体质获取推荐权重
        weights = CONSTITUTION_WEIGHTS.get(constitution, CONSTITUTION_WEIGHTS["平和质"])

        # 根据时辰调整权重
        time_period = self._get_time_period(hour)
        adjusted_weights = self._adjust_weights_by_time(weights, time_period)

        # 加上季节偏好标签
        season_tags = {
            "spring": ["春季", "养肝", "春", "spring", "liver"],
            "summer": ["夏季", "清热", "夏", "summer", "cooling"],
            "autumn": ["秋季", "润肺", "秋", "autumn", "lung"],
            "winter": ["冬季", "温补", "冬", "winter", "warming"],
        }

        # 选择推荐类型
        selected_types = self._select_types(adjusted_weights, limit + 2)

        # 获取推荐内容
        conn = get_db()
        recommendations = []

        for rec_type in selected_types:
            content_type = TYPE_CONTENT_MAP.get(rec_type, rec_type)
            tags = season_tags.get(season, [])
            
            # 构建查询
            query = """
                SELECT * FROM contents 
                WHERE type = ? AND locale = ?
            """
            params: list = [content_type, locale]

            # 季节过滤
            if season:
                query += " AND (season_tag = ? OR season_tag IS NULL)"
                params.append(season)

            # 排除已查看的
            viewed = self._get_viewed_content_ids(user_id)
            if viewed:
                placeholders = ",".join(["?"] * len(viewed))
                query += f" AND id NOT IN ({placeholders})"
                params.extend(viewed)

            query += " ORDER BY RANDOM() LIMIT 1"

            row = conn.execute(query, params).fetchone()
            if row:
                d = dict(row)
                recommendations.append({
                    "content_id": d["id"],
                    "type": rec_type,
                    "title": d["title"],
                    "description": d.get("description", ""),
                    "category": d.get("category", ""),
                    "difficulty": d.get("difficulty", ""),
                    "duration": d.get("duration", ""),
                    "tags": self._parse_json(d.get("tags")),
                    "season": season,
                    "time_period": time_period,
                    "reason": self._generate_reason(rec_type, constitution, season, time_period, locale),
                    "emoji": self._get_type_emoji(rec_type),
                })

        return {
            "success": True,
            "data": {
                "user_id": user_id,
                "constitution": constitution,
                "season": season,
                "time_period": time_period,
                "date": now.strftime("%Y-%m-%d"),
                "recommendations": recommendations[:limit],
            }
        }

    def get_seasonal_recommendations(
        self,
        season: str,
        locale: str = "zh-CN",
        limit: int = 5,
    ) -> List[Dict[str, Any]]:
        """获取季节推荐"""
        conn = get_db()
        
        type_labels = {
            "food_therapy": ("🍲", "食疗推荐" if locale != "en-US" else "Recipe"),
            "exercise": ("🏃", "运动推荐" if locale != "en-US" else "Exercise"),
            "tea": ("🍵", "茶饮推荐" if locale != "en-US" else "Tea"),
            "sleep_tip": ("😴", "睡眠建议" if locale != "en-US" else "Sleep Tip"),
        }

        results = []
        for content_type, (emoji, label) in type_labels.items():
            row = conn.execute(
                """SELECT * FROM contents 
                   WHERE type = ? AND locale = ? AND season_tag = ?
                   ORDER BY RANDOM() LIMIT 1""",
                (content_type, locale, season),
            ).fetchone()
            
            if row:
                d = dict(row)
                results.append({
                    "content_id": d["id"],
                    "type": content_type,
                    "title": d["title"],
                    "description": d.get("description", ""),
                    "category": d.get("category", ""),
                    "emoji": emoji,
                    "label": label,
                    "tags": self._parse_json(d.get("tags")),
                    "difficulty": d.get("difficulty", ""),
                    "duration": d.get("duration", ""),
                })

        return results[:limit]

    def _get_user_constitution(self, user_id: str) -> str:
        """获取用户体质"""
        conn = get_db()
        try:
            row = conn.execute(
                "SELECT primary_type FROM constitution_results WHERE user_id = ? ORDER BY completed_at DESC LIMIT 1",
                (user_id,),
            ).fetchone()
            if row:
                return row["primary_type"]
        except Exception:
            pass
        return "平和质"

    def _get_user_preferences(self, user_id: str) -> Dict[str, Any]:
        """获取用户偏好"""
        conn = get_db()
        try:
            row = conn.execute(
                "SELECT * FROM user_settings WHERE user_id = ?",
                (user_id,),
            ).fetchone()
            if row:
                return dict(row)
        except Exception:
            pass
        return {}

    def _get_time_period(self, hour: int) -> str:
        """获取当前时辰段"""
        if 5 <= hour < 12:
            return "morning"
        elif 12 <= hour < 17:
            return "afternoon"
        elif 17 <= hour < 21:
            return "evening"
        else:
            return "night"

    def _adjust_weights_by_time(self, weights: Dict[str, float], time_period: str) -> Dict[str, float]:
        """根据时辰调整推荐权重"""
        adjusted = dict(weights)
        
        time_boosts = {
            "morning": {"exercise": 1.3, "tea": 1.1},
            "afternoon": {"exercise": 1.2, "tea": 1.1},
            "evening": {"recipe": 1.1, "tea": 1.2},
            "night": {"sleep": 1.5, "tea": 1.1},
        }
        
        boosts = time_boosts.get(time_period, {})
        for key, factor in boosts.items():
            if key in adjusted:
                adjusted[key] *= factor
        
        return adjusted

    def _select_types(self, weights: Dict[str, float], count: int) -> List[str]:
        """根据权重选择推荐类型"""
        types = list(weights.keys())
        w = list(weights.values())
        
        # 归一化
        total = sum(w)
        if total == 0:
            return random.sample(types, min(count, len(types)))
        
        w_norm = [v / total for v in w]
        
        selected = []
        attempts = 0
        while len(selected) < count and attempts < count * 3:
            choice = random.choices(types, weights=w_norm, k=1)[0]
            if choice not in selected:
                selected.append(choice)
            attempts += 1
        
        return selected

    def _get_viewed_content_ids(self, user_id: str) -> List[str]:
        """获取用户已查看的内容 ID"""
        conn = get_db()
        try:
            rows = conn.execute(
                "SELECT DISTINCT content_id FROM user_content_views WHERE user_id = ?",
                (user_id,),
            ).fetchall()
            return [r["content_id"] for r in rows if r["content_id"]]
        except Exception:
            return []

    def _generate_reason(
        self, rec_type: str, constitution: str, season: str, time_period: str, locale: str
    ) -> str:
        """生成推荐理由"""
        if locale == "en-US":
            season_names = {"spring": "Spring", "summer": "Summer", "autumn": "Autumn", "winter": "Winter"}
            time_names = {"morning": "morning", "afternoon": "afternoon", "evening": "evening", "night": "nighttime"}
            return f"Recommended for {season_names.get(season, season)} {time_names.get(time_period, time_period)} wellness"
        
        season_names = {"spring": "春季", "summer": "夏季", "autumn": "秋季", "winter": "冬季"}
        time_names = {"morning": "晨起", "afternoon": "午后", "evening": "傍晚", "night": "夜间"}
        
        constitution_reasons = {
            "气虚质": "补气养身",
            "阳虚质": "温阳散寒",
            "阴虚质": "滋阴润燥",
            "痰湿质": "健脾祛湿",
            "湿热质": "清热利湿",
            "血瘀质": "活血化瘀",
            "气郁质": "疏肝解郁",
            "特禀质": "增强体质",
            "平和质": "日常保健",
        }
        
        s = season_names.get(season, "")
        t = time_names.get(time_period, "")
        c = constitution_reasons.get(constitution, "养生保健")
        
        return f"适合{c} · {s}{t}推荐"

    def _get_type_emoji(self, rec_type: str) -> str:
        """获取类型 emoji"""
        return {
            "recipe": "🍲", "exercise": "🏃", "tea": "🍵",
            "sleep": "😴", "acupoint": "🎯",
        }.get(rec_type, "✨")

    def _parse_json(self, val) -> Any:
        """安全解析 JSON"""
        if not val:
            return []
        if isinstance(val, str):
            try:
                return json.loads(val)
            except (json.JSONDecodeError, TypeError):
                return [val]
        return val


# 全局实例
recommendation_service = RecommendationService()
