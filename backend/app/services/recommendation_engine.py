"""
个性化推荐引擎
综合体质、节气、季节、健康状态，为用户推荐最合适的养生内容

评分权重:
  match_score = W_体质 × 体质匹配 + W_节气 × 节气匹配 + W_季节 × 季节匹配 + W_健康 × 健康匹配 + W_偏好 × 偏好匹配
"""

from typing import Dict, List, Any, Optional
from app.database.db import get_db, row_to_dict

# ═══════════════════════════════════════════
# 体质 → 内容映射规则
# ═══════════════════════════════════════════

CONSTITUTION_TAGS = {
    "pinghe": ["平和", "均衡", "四季", "通用", "常规"],
    "qixu": ["补气", "健脾", "益气", "气虚", "黄芪", "人参", "山药", "红枣", "补肺"],
    "yangxu": ["温阳", "暖胃", "散寒", "阳虚", "生姜", "羊肉", "桂圆", "艾灸", "温补"],
    "yinxu": ["滋阴", "润燥", "养血", "阴虚", "银耳", "百合", "枸杞", "麦冬", "静心"],
    "tanxu": ["祛湿", "化痰", "利水", "痰湿", "薏米", "赤豆", "冬瓜", "陈皮", "健脾化湿"],
    "shire": ["清热", "解毒", "祛湿", "湿热", "绿豆", "苦瓜", "冬瓜", "薄荷", "清淡"],
    "xueyu": ["活血", "化瘀", "舒筋", "血瘀", "山楂", "红花", "玫瑰", "丹参", "桃仁"],
    "qiyu": ["疏肝", "理气", "解郁", "气郁", "玫瑰花", "佛手", "柑橘", "菊花", "疏肝"],
    "tebing": ["固表", "抗敏", "益气", "特禀", "黄芪", "大枣", "灵芝", "防风", "温和"],
}

# 体质中文名映射
CONSTITUTION_NAMES = {
    "pinghe": "平和质", "qixu": "气虚质", "yangxu": "阳虚质",
    "yinxu": "阴虚质", "tanxu": "痰湿质", "shire": "湿热质",
    "xueyu": "血瘀质", "qiyu": "气郁质", "tebing": "特禀质",
}

# 体质 × 内容类型 权重
WEIGHTS = {
    "food_therapy": {"constitution": 40, "solar_term": 30, "season": 15, "health": 10, "preference": 5},
    "tea":          {"constitution": 35, "solar_term": 30, "season": 15, "health": 10, "preference": 10},
    "exercise":     {"constitution": 30, "solar_term": 25, "season": 25, "health": 15, "preference": 5},
    "acupressure":  {"constitution": 25, "solar_term": 10, "season": 10, "health": 20, "preference": 35},
    "sleep_tip":    {"constitution": 20, "solar_term": 15, "season": 15, "health": 40, "preference": 10},
    "emotion":      {"constitution": 15, "solar_term": 10, "season": 10, "health": 55, "preference": 10},
    "default":      {"constitution": 30, "solar_term": 20, "season": 20, "health": 20, "preference": 10},
}

# 健康状态维度 → 对应内容标签
HEALTH_CONTENT_MAP = {
    "sleep": {"low": ["安神", "助眠", "镇静", "放松", "百合", "莲子"], "medium": [], "high": []},
    "exercise": {"low": ["温和", "舒缓", "散步", "拉伸", "简单"], "medium": ["有氧", "适度"], "high": ["强化", "力量", "耐力"]},
    "mood": {"low": ["解郁", "疏肝", "愉悦", "安神", "玫瑰", "柑橘"], "medium": [], "high": []},
    "diet": {"low": ["开胃", "健脾", "消食"], "medium": [], "high": []},
}

# 节气 → 季节映射
SOLAR_TERM_SEASON = {
    "立春": "spring", "雨水": "spring", "惊蛰": "spring", "春分": "spring",
    "清明": "spring", "谷雨": "spring",
    "立夏": "summer", "小满": "summer", "芒种": "summer", "夏至": "summer",
    "小暑": "summer", "大暑": "summer",
    "立秋": "autumn", "处暑": "autumn", "白露": "autumn", "秋分": "autumn",
    "寒露": "autumn", "霜降": "autumn",
    "立冬": "winter", "小雪": "winter", "大雪": "winter", "冬至": "winter",
    "小寒": "winter", "大寒": "winter",
}

SEASON_MAP = {
    "spring": ("春季", "春"), "summer": ("夏季", "夏"),
    "autumn": ("秋季", "秋"), "winter": ("冬季", "冬"),
}


def _parse_json(val):
    """安全解析 JSON"""
    if not val or val in ("[]", "null"):
        return []
    import json
    try:
        return json.loads(val) if isinstance(val, str) else val
    except (json.JSONDecodeError, TypeError):
        return []


def _score_constitution_match(item_tags: List[str], constitution_type: str) -> float:
    """体质匹配评分 (0-100)"""
    if constitution_type == "pinghe":
        return 60  # 平和质通用匹配
    target_tags = CONSTITUTION_TAGS.get(constitution_type, [])
    if not target_tags or not item_tags:
        return 50
    matched = sum(1 for t in target_tags if any(t.lower() in tag.lower() for tag in item_tags))
    if matched == 0:
        return 30
    return min(100, 50 + (matched / len(target_tags)) * 50)


def _score_solar_term_match(item_season: str, solar_term: str) -> float:
    """节气匹配评分 (0-100)"""
    term_season = SOLAR_TERM_SEASON.get(solar_term, "")
    if not term_season or not item_season:
        return 40
    # 精确匹配
    if item_season.lower() == term_season:
        return 100
    # 模糊匹配
    term_cn = SEASON_MAP.get(term_season, ("", ""))[0]
    term_cn_short = SEASON_MAP.get(term_season, ("", ""))[1]
    if item_season and (term_cn in item_season or term_cn_short in item_season):
        return 85
    # 四季皆宜
    if "四季" in item_season or "皆宜" in item_season:
        return 70
    return 20


def _score_season_match(item_season: str, season: str) -> float:
    """季节匹配评分"""
    return _score_solar_term_match(item_season, {"spring": "立春", "summer": "立夏", "autumn": "立秋", "winter": "立冬"}.get(season, ""))


def _score_health_match(item_tags: List[str], health_status: Dict[str, float]) -> float:
    """健康状态匹配评分"""
    if not health_status or not item_tags:
        return 50
    scores = []
    for dimension, value in health_status.items():
        if value >= 70:  # 状态好，不需要特殊推荐
            scores.append(70)
            continue
        level = "low" if value < 50 else "medium"
        if dimension in HEALTH_CONTENT_MAP:
            target_tags = HEALTH_CONTENT_MAP[dimension].get(level, [])
            if target_tags and item_tags:
                matched = sum(1 for t in target_tags if any(t.lower() in tag.lower() for tag in item_tags))
                if matched > 0:
                    scores.append(70 + (matched / len(target_tags)) * 30)
                else:
                    scores.append(40)
            else:
                scores.append(50)
    return sum(scores) / len(scores) if scores else 50


def calculate_match_score(
    item: Dict[str, Any],
    constitution_type: str = "pinghe",
    solar_term: str = "",
    season: str = "",
    health_status: Optional[Dict[str, float]] = None,
) -> Dict[str, Any]:
    """
    计算单条内容的个性化匹配度

    Returns:
        {
            "match_score": 85,
            "match_reasons": ["适合气虚质", "春季养肝"],
            "scores": {"constitution": 80, "solar_term": 90, ...}
        }
    """
    content_type = item.get("type", "")
    weights = WEIGHTS.get(content_type, WEIGHTS["default"])
    tags = _parse_json(item.get("tags", "[]"))
    item_season = item.get("season_tag", "")

    # 各维度评分
    s_constitution = _score_constitution_match(tags, constitution_type)
    s_solar_term = _score_solar_term_match(item_season, solar_term)
    s_season = _score_season_match(item_season, season)
    s_health = _score_health_match(tags, health_status or {})
    s_preference = 50  # 暂无用户偏好数据

    # 加权总分
    total = (
        weights["constitution"] * s_constitution +
        weights["solar_term"] * s_solar_term +
        weights["season"] * s_season +
        weights["health"] * s_health +
        weights["preference"] * s_preference
    ) / sum(weights.values())

    # 匹配原因
    reasons = []
    if s_constitution >= 70:
        reasons.append(f"适合{CONSTITUTION_NAMES.get(constitution_type, constitution_type)}")
    if s_solar_term >= 70 and solar_term:
        reasons.append(f"{solar_term}时节推荐")
    if s_season >= 70 and season:
        reasons.append(f"{SEASON_MAP.get(season, ('', ''))[0]}养生")

    return {
        "match_score": round(total, 1),
        "match_reasons": reasons,
        "scores": {
            "constitution": round(s_constitution, 1),
            "solar_term": round(s_solar_term, 1),
            "season": round(s_season, 1),
            "health": round(s_health, 1),
        }
    }


def get_personalized_recommendations(
    constitution_type: str = "pinghe",
    solar_term: str = "",
    season: str = "",
    health_status: Optional[Dict[str, float]] = None,
    categories: Optional[List[str]] = None,
    limit: int = 5,
    offset: int = 0,
    locale: str = "zh-CN",
) -> List[Dict[str, Any]]:
    """
    获取个性化推荐内容

    Args:
        constitution_type: 体质类型 (qixu/yangxu/...)
        solar_term: 当前节气名
        season: 当前季节 (spring/summer/autumn/winter)
        health_status: 健康状态 {"sleep": 72, "exercise": 45, "mood": 68}
        categories: 内容类型过滤 ["food_therapy", "tea", ...]
        limit: 返回数量
        offset: 偏移量
        locale: 语言

    Returns:
        排序后的推荐列表，每项含 match_score 和 match_reasons
    """
    db = get_db()
    conn = db.execute("SELECT * FROM contents WHERE locale = ?", (locale,))
    all_items = [row_to_dict(r) for r in conn.fetchall()]

    # 类型过滤
    if categories:
        all_items = [i for i in all_items if i["type"] in categories]

    # 计算每项匹配度
    scored = []
    for item in all_items:
        result = calculate_match_score(item, constitution_type, solar_term, season, health_status)
        enriched = {**item, **result}
        scored.append(enriched)

    # 按匹配度排序
    scored.sort(key=lambda x: x["match_score"], reverse=True)

    # 分页
    return scored[offset:offset + limit]


def get_today_digest(
    constitution_type: str = "pinghe",
    solar_term: str = "",
    season: str = "",
    health_status: Optional[Dict[str, float]] = None,
) -> Dict[str, Any]:
    """
    获取今日个性化养生摘要 (首页用)

    Returns:
        {
            "constitution": {"type": "qixu", "name": "气虚质", "advice": "..."},
            "solar_term": {"name": "惊蛰", "emoji": "⚡"},
            "recommendations": {
                "food_therapy": [...],
                "tea": [...],
                "exercise": [...],
                "acupressure": [...],
                "sleep_tip": [...],
            }
        }
    """
    # 各维度推荐 TOP 3
    categories = ["food_therapy", "tea", "exercise", "acupressure", "sleep_tip"]
    recommendations = {}
    for cat in categories:
        recs = get_personalized_recommendations(
            constitution_type=constitution_type,
            solar_term=solar_term,
            season=season,
            health_status=health_status,
            categories=[cat],
            limit=3,
        )
        # 只保留展示字段
        recommendations[cat] = [
            {
                "id": r["id"],
                "title": r["title"],
                "type": r["type"],
                "image_url": r.get("image_url", ""),
                "description": (r.get("description") or "")[:80],
                "difficulty": r.get("difficulty", ""),
                "duration": r.get("duration", ""),
                "tags": _parse_json(r.get("tags", "[]")),
                "ingredients": _parse_json(r.get("ingredients", "[]")),
                "steps": _parse_json(r.get("steps", "[]")),
                "match_score": r["match_score"],
                "match_reasons": r["match_reasons"],
                "is_premium": bool(r.get("is_premium", 0)),
            }
            for r in recs
        ]

    return {
        "constitution": {
            "type": constitution_type,
            "name": CONSTITUTION_NAMES.get(constitution_type, constitution_type),
        },
        "solar_term": {
            "name": solar_term,
            "season": season,
            "season_name": SEASON_MAP.get(season, ("", ""))[0] if season else "",
        },
        "recommendations": recommendations,
    }
