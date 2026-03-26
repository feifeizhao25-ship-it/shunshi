"""
顺时 ShunShi - 系统提示卡服务
AI 在对话中发送结构化卡片（食谱/穴位/运动/茶饮/睡眠建议）

作者: Claw 🦅
日期: 2026-03-18
"""

import json
import logging
from typing import Optional, Dict, Any, List
from datetime import datetime

from app.database.db import get_db

logger = logging.getLogger(__name__)


# ==================== 卡片类型定义 ====================

CARD_TYPES = {
    "recipe": {
        "emoji": "🍲",
        "label_cn": "食疗推荐",
        "label_en": "Recipe Recommendation",
        "fields": ["title", "emoji", "description", "ingredients", "steps", "difficulty", "duration", "tags", "season"],
    },
    "acupoint": {
        "emoji": "🎯",
        "label_cn": "穴位保健",
        "label_en": "Acupressure Point",
        "fields": ["title", "emoji", "location", "method", "effect", "duration", "tags"],
    },
    "exercise": {
        "emoji": "🏃",
        "label_cn": "运动推荐",
        "label_en": "Exercise Recommendation",
        "fields": ["title", "emoji", "description", "benefits", "difficulty", "duration", "tags", "season"],
    },
    "tea": {
        "emoji": "🍵",
        "label_cn": "茶饮推荐",
        "label_en": "Tea Recommendation",
        "fields": ["title", "emoji", "ingredients", "steps", "description", "tags", "season"],
    },
    "sleep": {
        "emoji": "😴",
        "label_cn": "睡眠建议",
        "label_en": "Sleep Tip",
        "fields": ["title", "emoji", "method", "effect", "duration", "tags", "best_time"],
    },
}


class SystemPromptCardService:
    """系统提示卡服务"""

    def __init__(self):
        pass

    def generate_card(
        self,
        card_type: str,
        content_id: str,
        locale: str = "zh-CN",
    ) -> Dict[str, Any]:
        """
        根据内容 ID 和类型生成卡片

        Args:
            card_type: 卡片类型 (recipe/acupoint/exercise/tea/sleep)
            content_id: 内容 ID
            locale: 语言 (zh-CN/en-US)

        Returns:
            卡片数据
        """
        if card_type not in CARD_TYPES:
            raise ValueError(f"无效的卡片类型: {card_type}")

        conn = get_db()
        content_table = "contents"
        
        # 根据类型确定查询条件
        type_mapping = {
            "recipe": ("food_therapy", "食疗", "Diet Therapy"),
            "acupoint": ("acupressure", "穴位", "Acupressure"),
            "exercise": ("exercise", "运动", "Exercise"),
            "tea": ("tea", "茶饮", "Tea"),
            "sleep": ("sleep_tip", "睡眠", "Sleep Tip"),
        }

        type_val, cat_cn, cat_en = type_mapping.get(card_type, (card_type, card_type, card_type))

        row = conn.execute(
            "SELECT * FROM contents WHERE id = ? AND locale = ?",
            (content_id, locale),
        ).fetchone()

        if not row:
            # Fallback: try zh-CN if en-US not found
            row = conn.execute(
                "SELECT * FROM contents WHERE id = ?",
                (content_id,),
            ).fetchone()

        if not row:
            raise ValueError(f"内容不存在: {content_id}")

        d = dict(row)
        
        card = {
            "card_type": card_type,
            "card_emoji": CARD_TYPES[card_type]["emoji"],
            "card_label": CARD_TYPES[card_type]["label_cn"] if locale != "en-US" else CARD_TYPES[card_type]["label_en"],
            "content_id": d["id"],
            "title": d["title"],
            "description": d.get("description", ""),
            "locale": d.get("locale", locale),
            "created_at": datetime.now().isoformat(),
        }

        # 解析 JSON 字段
        def parse_json_field(val):
            if not val:
                return []
            if isinstance(val, str):
                try:
                    return json.loads(val)
                except (json.JSONDecodeError, TypeError):
                    return [val]
            return val

        if card_type == "recipe":
            card.update({
                "emoji": self._get_recipe_emoji(d["title"], locale),
                "ingredients": parse_json_field(d.get("ingredients")),
                "steps": parse_json_field(d.get("steps")),
                "difficulty": d.get("difficulty", ""),
                "duration": d.get("duration", ""),
                "tags": parse_json_field(d.get("tags")),
                "season": d.get("season_tag"),
            })
        elif card_type == "acupoint":
            card.update({
                "emoji": "🎯",
                "location": d.get("location", ""),
                "method": d.get("method", ""),
                "effect": d.get("effect", ""),
                "duration": d.get("duration", ""),
                "tags": parse_json_field(d.get("tags")),
            })
        elif card_type == "exercise":
            card.update({
                "emoji": "🏃",
                "benefits": parse_json_field(d.get("benefits")),
                "difficulty": d.get("difficulty", ""),
                "duration": d.get("duration", ""),
                "tags": parse_json_field(d.get("tags")),
                "season": d.get("season_tag"),
            })
        elif card_type == "tea":
            card.update({
                "emoji": "🍵",
                "ingredients": parse_json_field(d.get("ingredients")),
                "steps": parse_json_field(d.get("steps")),
                "tags": parse_json_field(d.get("tags")),
                "season": d.get("season_tag"),
            })
        elif card_type == "sleep":
            card.update({
                "emoji": "😴",
                "method": d.get("method", ""),
                "effect": d.get("effect", ""),
                "duration": d.get("duration", ""),
                "best_time": d.get("best_time", ""),
                "tags": parse_json_field(d.get("tags")),
            })

        return card

    def get_cards_by_type(
        self,
        card_type: str,
        locale: str = "zh-CN",
        limit: int = 5,
        season: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        获取指定类型的卡片列表

        Args:
            card_type: 卡片类型
            locale: 语言
            limit: 返回数量
            season: 季节过滤

        Returns:
            卡片列表
        """
        conn = get_db()
        
        type_mapping = {
            "recipe": "food_therapy",
            "acupoint": "acupressure",
            "exercise": "exercise",
            "tea": "tea",
            "sleep": "sleep_tip",
        }

        type_val = type_mapping.get(card_type, card_type)
        
        query = "SELECT * FROM contents WHERE type = ? AND locale = ?"
        params: list = [type_val, locale]
        
        if season:
            query += " AND season_tag = ?"
            params.append(season)
        
        query += " ORDER BY RANDOM() LIMIT ?"
        params.append(limit)

        rows = conn.execute(query, params).fetchall()
        
        cards = []
        for row in rows:
            try:
                card = self.generate_card(card_type, dict(row)["id"], locale)
                cards.append(card)
            except (ValueError, KeyError):
                continue

        return cards

    def get_relevant_cards(
        self,
        user_message: str,
        locale: str = "zh-CN",
        limit: int = 3,
    ) -> List[Dict[str, Any]]:
        """
        根据用户消息智能推荐相关卡片

        Args:
            user_message: 用户消息
            locale: 语言
            limit: 返回数量

        Returns:
            相关卡片列表
        """
        # 关键词映射到卡片类型
        keyword_mapping = {
            "recipe": ["吃", "食", "汤", "粥", "菜", "食谱", "补", "养胃", "粥品", "甜品",
                       "eat", "food", "recipe", "soup", "cook", "meal", "diet", "nourish"],
            "acupoint": ["穴位", "按摩", "艾灸", "按揉", "按压", "经络",
                        "acupoint", "massage", "press", "acupressure", "meridian"],
            "exercise": ["运动", "锻炼", "功法", "太极", "瑜伽", "八段锦", "散步", "跑步", "健身",
                        "exercise", "workout", "yoga", "tai chi", "stretch", "fitness", "run"],
            "tea": ["茶", "喝", "饮", "泡", "茶饮", "冲泡",
                   "tea", "drink", "brew", "herbal", "infusion"],
            "sleep": ["睡眠", "失眠", "睡", "助眠", "入睡", "睡觉", "午休",
                     "sleep", "insomnia", "rest", "nap", "bedtime", "tired"],
        }

        matched_types = []
        msg_lower = user_message.lower()
        
        for card_type, keywords in keyword_mapping.items():
            for kw in keywords:
                if kw in msg_lower:
                    matched_types.append(card_type)
                    break

        if not matched_types:
            # 默认返回食疗和运动
            matched_types = ["recipe", "exercise"]

        # 确定季节
        month = datetime.now().month
        if month in (3, 4, 5):
            season = "spring"
        elif month in (6, 7, 8):
            season = "summer"
        elif month in (9, 10, 11):
            season = "autumn"
        else:
            season = "winter"

        cards = []
        for card_type in matched_types[:3]:
            type_cards = self.get_cards_by_type(card_type, locale, limit=2, season=season)
            cards.extend(type_cards)

        return cards[:limit]

    def _get_recipe_emoji(self, title: str, locale: str) -> str:
        """根据食谱标题返回 emoji"""
        emoji_map = {
            "粥": "🥣", "汤": "🍲", "茶": "🍵", "羹": "🥣",
            "粥品": "🥣", "甜品": "🍮", "茶饮": "🍵",
            "congee": "🥣", "soup": "🍲", "tea": "🍵", "sweet": "🍮",
        }
        for kw, emoji in emoji_map.items():
            if kw in title:
                return emoji
        return "🍽️"


# 全局实例
prompt_card_service = SystemPromptCardService()
