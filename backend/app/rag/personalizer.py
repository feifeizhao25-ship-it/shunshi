"""
个性化养生方案生成器
结合用户画像 + 知识库检索 + 当前时空上下文
支持年龄段/体质/季节/性别差异化推送
"""
import logging
from datetime import datetime, date
from typing import Optional

from .retriever import retrieve

logger = logging.getLogger(__name__)

# 当前季节和节气的简易映射（中国农历近似）
_SOLAR_TERMS = [
    # (month, day, name, season)
    (2, 4, "立春", "春"), (2, 19, "雨水", "春"), (3, 6, "惊蛰", "春"),
    (3, 21, "春分", "春"), (4, 5, "清明", "春"), (4, 20, "谷雨", "春"),
    (5, 6, "立夏", "夏"), (5, 21, "小满", "夏"), (6, 6, "芒种", "夏"),
    (6, 21, "夏至", "夏"), (7, 7, "小暑", "夏"), (7, 23, "大暑", "夏"),
    (8, 7, "立秋", "秋"), (8, 23, "处暑", "秋"), (9, 8, "白露", "秋"),
    (9, 23, "秋分", "秋"), (10, 8, "寒露", "秋"), (10, 23, "霜降", "秋"),
    (11, 7, "立冬", "冬"), (11, 22, "小雪", "冬"), (12, 7, "大雪", "冬"),
    (12, 22, "冬至", "冬"), (1, 6, "小寒", "冬"), (1, 20, "大寒", "冬"),
]

_GL_SEASONS = [
    (3, "spring"), (6, "summer"), (9, "autumn"), (12, "winter"),
]

# 九种体质中文/英文映射
_CONSTITUTION_MAP_CN = {
    "pinghe": "平和质", "qixu": "气虚质", "yangxu": "阳虚质",
    "yinxu": "阴虚质", "tanshi": "痰湿质", "shire": "湿热质",
    "xueyu": "血瘀质", "qiyu": "气郁质", "tebing": "特禀质",
}

_CONSTITUTION_MAP_GL = {
    "pinghe": "Balanced", "qixu": "Qi Deficiency", "yangxu": "Yang Deficiency",
    "yinxu": "Yin Deficiency", "tanshi": "Phlegm-Dampness", "shire": "Damp-Heat",
    "xueyu": "Blood Stasis", "qiyu": "Qi Stagnation", "tebing": "Special",
}

# 体质 → 茶饮映射
_TEA_BY_CONSTITUTION_CN = {
    "气虚": "黄芪红枣茶（补气养血）",
    "阳虚": "生姜红茶（温阳散寒）",
    "阴虚": "百合银耳羹（滋阴润肺）",
    "痰湿": "陈皮薏米茶（健脾祛湿）",
    "湿热": "薏仁茶 / 金银花茶（清热利湿）",
    "血瘀": "玫瑰花茶（活血化瘀）",
    "气郁": "玫瑰花茶 / 茉莉花茶（疏肝理气）",
    "特禀": "黄芪防风茶（固表防敏）",
}

_TEA_BY_CONSTITUTION_GL = {
    "Qi Deficiency": "Astragalus & Red Date Tea (tonifies qi and nourishes blood)",
    "Yang Deficiency": "Ginger Black Tea (warms yang and dispels cold)",
    "Yin Deficiency": "Lily Bulb & Tremella Soup (nourishes yin, moistens lungs)",
    "Phlegm-Dampness": "Tangerine Peel & Barley Tea (strengthens spleen, drains dampness)",
    "Damp-Heat": "Coix Seed & Honeysuckle Tea (clears heat, drains dampness)",
    "Blood Stasis": "Rose Petal Tea (invigorates blood circulation)",
    "Qi Stagnation": "Rose & Jasmine Tea (soothes liver, regulates qi)",
    "Special": "Astragalus & Saposhnikovia Tea (strengthens defensive qi)",
}

# 年龄段 → 运动映射
_EXERCISE_BY_AGE_CN = {
    "children": {"morning": "户外游戏或跳绳（20-30分钟）", "afternoon": "球类运动/游泳", "evening": "亲子散步/拉伸", "duration": "每日60分钟以上"},
    "teenager": {"morning": "慢跑或快走（15-20分钟）", "afternoon": "篮球/足球/游泳", "evening": "瑜伽拉伸", "duration": "每日45-60分钟"},
    "young_adult": {"morning": "跑步或HIIT训练（20-30分钟）", "afternoon": "健身/游泳/骑行", "evening": "瑜伽/冥想", "duration": "每日30-60分钟"},
    "professional": {"morning": "八段锦或快走（15-20分钟）", "afternoon": "工间操/颈椎活动", "evening": "散步或瑜伽", "duration": "每日30-45分钟"},
    "middle_age": {"morning": "太极拳或八段锦（20-30分钟）", "afternoon": "快走或游泳", "evening": "散步+穴位按摩", "duration": "每日30-40分钟"},
    "senior": {"morning": "太极拳/散步（20-30分钟）", "afternoon": "园艺/轻度运动", "evening": "慢步+舒展", "duration": "每日30分钟，量力而行"},
    "elderly": {"morning": "散步或坐式太极（15-20分钟）", "afternoon": "室内轻度活动", "evening": "靠墙站立/简单拉伸", "duration": "每日15-30分钟，安全第一"},
}

_EXERCISE_BY_AGE_GL = {
    "children": {"morning": "Outdoor play or jump rope (20-30 min)", "afternoon": "Ball sports / swimming", "evening": "Family walk / stretching", "duration": "60+ minutes daily"},
    "teenager": {"morning": "Jogging or brisk walk (15-20 min)", "afternoon": "Basketball / soccer / swimming", "evening": "Yoga stretching", "duration": "45-60 minutes daily"},
    "young_adult": {"morning": "Running or HIIT (20-30 min)", "afternoon": "Gym / swimming / cycling", "evening": "Yoga / meditation", "duration": "30-60 minutes daily"},
    "professional": {"morning": "Ba Duan Jin or brisk walk (15-20 min)", "afternoon": "Desk stretches / neck exercises", "evening": "Walking or yoga", "duration": "30-45 minutes daily"},
    "middle_age": {"morning": "Tai Chi or Ba Duan Jin (20-30 min)", "afternoon": "Brisk walking or swimming", "evening": "Walking + acupoint massage", "duration": "30-40 minutes daily"},
    "senior": {"morning": "Tai Chi / walking (20-30 min)", "afternoon": "Gardening / light activity", "evening": "Gentle walk + stretching", "duration": "30 minutes, pace yourself"},
    "elderly": {"morning": "Seated Tai Chi / short walk (15-20 min)", "afternoon": "Indoor gentle movement", "evening": "Wall standing / simple stretches", "duration": "15-30 minutes, safety first"},
}

# 年龄段 → 作息映射
_SLEEP_BY_AGE_CN = {
    "children": {"bedtime": "20:30–21:00", "waketime": "6:30–7:00", "hours": "9-11小时", "tips": "保证充足睡眠促进生长发育"},
    "teenager": {"bedtime": "22:00–22:30", "waketime": "6:30–7:00", "hours": "8-10小时", "tips": "避免睡前使用手机，保证深度睡眠"},
    "young_adult": {"bedtime": "23:00–23:30", "waketime": "7:00–7:30", "hours": "7-8小时", "tips": "减少熬夜，尽量在24点前入睡"},
    "professional": {"bedtime": "22:30–23:00", "waketime": "6:30–7:00", "hours": "7-8小时", "tips": "睡前一小时远离电子屏幕"},
    "middle_age": {"bedtime": "22:00–22:30", "waketime": "6:30–7:00", "hours": "7-8小时", "tips": "午休20-30分钟，避免过长"},
    "senior": {"bedtime": "21:30–22:00", "waketime": "6:00–6:30", "hours": "7-8小时", "tips": "温水泡脚15分钟有助入睡"},
    "elderly": {"bedtime": "21:00–21:30", "waketime": "6:00–6:30", "hours": "7-9小时", "tips": "注意卧室安全，起夜要开灯"},
}

_SLEEP_BY_AGE_GL = {
    "children": {"bedtime": "8:30-9:00 PM", "waketime": "6:30-7:00 AM", "hours": "9-11 hours", "tips": "Adequate sleep supports healthy growth"},
    "teenager": {"bedtime": "10:00-10:30 PM", "waketime": "6:30-7:00 AM", "hours": "8-10 hours", "tips": "Avoid phone use before bed for deep sleep"},
    "young_adult": {"bedtime": "11:00-11:30 PM", "waketime": "7:00-7:30 AM", "hours": "7-8 hours", "tips": "Minimize late nights, aim to sleep before midnight"},
    "professional": {"bedtime": "10:30-11:00 PM", "waketime": "6:30-7:00 AM", "hours": "7-8 hours", "tips": "Step away from screens 1 hour before bed"},
    "middle_age": {"bedtime": "10:00-10:30 PM", "waketime": "6:30-7:00 AM", "hours": "7-8 hours", "tips": "A 20-30 min midday nap is restorative"},
    "senior": {"bedtime": "9:30-10:00 PM", "waketime": "6:00-6:30 AM", "hours": "7-8 hours", "tips": "Warm foot soak 15 min before bed aids sleep"},
    "elderly": {"bedtime": "9:00-9:30 PM", "waketime": "6:00-6:30 AM", "hours": "7-9 hours", "tips": "Keep bedroom safe, use night lights"},
}

# 节气 → 推荐穴位
_ACUPOINTS_BY_SEASON_CN = {
    "春": {"points": ["太冲", "足三里", "合谷"], "method": "拇指按揉，每穴3-5分钟，力度适中", "focus": "疏肝理气、健脾助运"},
    "夏": {"points": ["内关", "神门", "涌泉"], "method": "拇指按揉或指腹按压，每穴3-5分钟", "focus": "养心安神、清热除烦"},
    "秋": {"points": ["肺俞", "列缺", "太渊"], "method": "拇指按揉或拍打，每穴3-5分钟", "focus": "润肺养阴、收敛肺气"},
    "冬": {"points": ["命门", "肾俞", "涌泉", "足三里"], "method": "掌擦或艾灸，每穴5-10分钟", "focus": "温补肾阳、固表御寒"},
}

_ACUPOINTS_BY_SEASON_GL = {
    "spring": {"points": ["Taichong (LV3)", "Zusanli (ST36)", "Hegu (LI4)"], "method": "Thumb press each point 3-5 minutes, moderate pressure", "focus": "Soothe the liver, strengthen the spleen"},
    "summer": {"points": ["Neiguan (PC6)", "Shenmen (HT7)", "Yongquan (KI1)"], "method": "Thumb press each point 3-5 minutes", "focus": "Nourish the heart, calm the spirit"},
    "autumn": {"points": ["Feishu (BL13)", "Lieque (LU7)", "Taiyuan (LU9)"], "method": "Thumb press or gentle tapping, 3-5 min each", "focus": "Moisten the lungs, nourish yin"},
    "winter": {"points": ["Mingmen (DU4)", "Shenshu (BL23)", "Yongquan (KI1)", "Zusanli (ST36)"], "method": "Palm rubbing or moxibustion, 5-10 min each", "focus": "Warm kidney yang, strengthen defenses"},
}

# 情绪建议按季节
_EMOTION_ADVICE_CN = {
    "春": {"focus": "疏肝解郁", "tip": "春季宜保持心情舒畅，多参加户外活动，避免情绪压抑"},
    "夏": {"focus": "静心安神", "tip": "夏季心火旺盛，宜静心养神，避免急躁，可听舒缓音乐"},
    "秋": {"focus": "收敛情绪", "tip": "秋季宜收摄心神，避免悲秋情绪，适当社交保持乐观"},
    "冬": {"focus": "藏精蓄锐", "tip": "冬季宜静养内收，减少过度消耗，享受安静的时光"},
}

_EMOTION_ADVICE_GL = {
    "spring": {"focus": "Release & Renew", "tip": "Keep a cheerful mood, spend time outdoors, avoid emotional suppression"},
    "summer": {"focus": "Calm & Center", "tip": "Summer heart-fire rises easily — stay calm, listen to soothing music, avoid irritability"},
    "autumn": {"focus": "Gather & Reflect", "tip": "Autumn invites introspection. Avoid melancholy by staying socially connected"},
    "winter": {"focus": "Rest & Recharge", "tip": "Winter is for stillness. Reduce overexertion and enjoy quiet moments of renewal"},
}


def _get_current_solar_term_cn() -> tuple[str, str]:
    """获取当前节气和季节（近似）"""
    now = datetime.now()
    month, day = now.month, now.day

    current = ("大寒", "冬")  # 默认
    for m, d, name, season in _SOLAR_TERMS:
        if (month == m and day >= d) or month > m:
            current = (name, season)

    return current


def _get_current_season_gl() -> str:
    """获取当前季节（英文）"""
    month = datetime.now().month
    current = "winter"
    for m, season in _GL_SEASONS:
        if month >= m:
            current = season
    return current


def _map_age_group(age: Optional[int]) -> str:
    """根据年龄映射年龄段"""
    if age is None:
        return ""
    if age < 13:
        return "children"
    elif age < 19:
        return "teenager"
    elif age < 26:
        return "young_adult"
    elif age < 36:
        return "professional"
    elif age < 56:
        return "middle_age"
    elif age < 71:
        return "senior"
    else:
        return "elderly"


def _map_life_stage(stage: Optional[str]) -> str:
    """life_stage 字段映射为中文描述"""
    _map = {
        "exploration": "探索期",
        "balancing": "平衡期",
        "companion": "陪伴期",
        "growth": "成长期",
        "stressed": "压力期",
        "healthy": "养生期",
    }
    return _map.get(stage, stage or "")


def _calc_age_from_birthday(birthday: Optional[str]) -> Optional[int]:
    """从 birthday 字符串计算年龄"""
    if not birthday:
        return None
    try:
        birth = date.fromisoformat(birthday)
        today = date.today()
        age = today.year - birth.year - ((today.month, today.day) < (birth.month, birth.day))
        return age
    except (ValueError, TypeError):
        return None


def _get_user_profile(user_id: str) -> dict:
    """
    获取用户画像数据
    尝试从数据库读取，失败则返回默认值
    """
    profile = {
        "user_id": user_id,
        "name": "",
        "constitution": None,
        "age": None,
        "age_group": "",
        "gender": None,
        "life_stage": None,
        "health_concerns": [],
        "recent_diary": None,
    }

    try:
        from app.database.db import get_db

        conn = get_db()
        cursor = conn.cursor()

        # 查询用户基本信息
        cursor.execute(
            "SELECT name, birthday, gender, life_stage FROM users WHERE id = ?",
            (user_id,)
        )
        row = cursor.fetchone()
        if row:
            profile["name"] = row[0] or ""
            profile["age"] = _calc_age_from_birthday(row[1])
            profile["gender"] = row[2]
            profile["life_stage"] = row[3]

        profile["age_group"] = _map_age_group(profile["age"])

        # 查询体质结果
        try:
            cursor.execute(
                "SELECT primary_type, scores FROM sa_constitution_results WHERE user_id = ? ORDER BY completed_at DESC LIMIT 1",
                (user_id,)
            )
            row = cursor.fetchone()
            if row:
                profile["constitution"] = row[0]
                if row[1]:
                    import json
                    profile["constitution_scores"] = json.loads(row[1]) if isinstance(row[1], str) else row[1]
        except Exception:
            pass

        # 查询最近的日记
        try:
            from datetime import timedelta
            cursor.execute(
                "SELECT entry_date, mood, sleep_quality, sleep_hours, diet, exercise, exercise_minutes, notes FROM sa_diary_entries WHERE user_id = ? AND entry_date >= ? ORDER BY entry_date DESC LIMIT 3",
                (user_id, (date.today() - timedelta(days=7)).isoformat())
            )
            rows = cursor.fetchall()
            if rows:
                import json
                profile["recent_diary"] = [
                    {
                        "date": str(r[0]),
                        "mood": r[1],
                        "sleep_quality": r[2],
                        "sleep_hours": r[3],
                        "diet": r[4],
                        "exercise": r[5],
                        "exercise_minutes": r[6],
                        "notes": r[7],
                    }
                    for r in rows
                ]

                concerns = set()
                for r in rows:
                    if r[2] is not None and r[2] <= 2:
                        concerns.add("睡眠")
                    if r[1] is not None and r[1] <= 2:
                        concerns.add("情绪")
                    if r[6] is not None and r[6] < 15:
                        concerns.add("运动")
                profile["health_concerns"] = list(concerns)
        except Exception:
            pass

    except Exception as e:
        logger.warning(f"[Personalizer] 获取用户画像失败: {e}")

    return profile


def _build_personalized_queries(profile: dict, lang: str) -> list[str]:
    """基于用户画像构建检索 queries"""
    queries = []
    age_group = profile.get("age_group", "")
    constitution_key = profile.get("constitution", "")

    if lang == "cn":
        # 基础：当前节气 + 季节
        term, season = _get_current_solar_term_cn()
        queries.append(f"{term}养生建议")
        queries.append(f"{season}季养生注意事项")

        # 年龄段相关检索（补充篇）
        age_queries = {
            "children": ["儿童春季养生", "儿童饮食调理", "小儿推拿"],
            "teenager": ["青少年养生", "青春期营养", "考试压力缓解"],
            "young_adult": ["年轻人养生", "熬夜修复", "脱发调理"],
            "professional": ["职场养生", "上班族健康", "颈椎保护", "久坐修复"],
            "middle_age": ["中年人养生", "三高预防", "更年期调理"],
            "senior": ["退休养生", "老年人运动", "骨关节保养"],
            "elderly": ["高龄老人养生", "老人安全起居", "老人饮食注意"],
        }
        if age_group in age_queries:
            queries.extend(age_queries[age_group][:3])

        # 体质
        if constitution_key:
            const_name = _CONSTITUTION_MAP_CN.get(constitution_key, constitution_key)
            queries.append(f"{const_name}体质调养方法")
            queries.append(f"{const_name}体质{term}养生")

        # 健康关注点
        for concern in profile.get("health_concerns", []):
            queries.append(f"{concern}调理方法")
            queries.append(f"{season}季{concern}养生")

        # 性别
        gender = profile.get("gender")
        if gender == "female":
            if age_group in ("middle_age", "senior"):
                queries.append("更年期女性养生")
            elif age_group in ("young_adult", "professional"):
                queries.append("女性{season}季养生".format(season=season))

    else:
        season = _get_current_season_gl()
        queries.append(f"{season} season wellness tips")
        queries.append(f"seasonal health advice {season}")

        age_queries_en = {
            "children": ["children wellness tips", "kids nutrition", "children exercise"],
            "teenager": ["teen wellness", "teen nutrition", "exam stress relief"],
            "young_adult": ["young adult wellness", "sleep recovery", "hair care tips"],
            "professional": ["workplace wellness", "desk worker health", "neck care"],
            "middle_age": ["middle age wellness", "blood pressure prevention", "menopause care"],
            "senior": ["senior wellness", "elderly exercise", "joint care"],
            "elderly": ["elderly care", "senior safety", "elderly nutrition"],
        }
        if age_group in age_queries_en:
            queries.extend(age_queries_en[age_group][:3])

        if constitution_key:
            const_name = _CONSTITUTION_MAP_GL.get(constitution_key, constitution_key)
            queries.append(f"{const_name} constitution wellness tips")
            queries.append(f"{const_name} constitution {season} care")

        for concern in profile.get("health_concerns", []):
            queries.append(f"how to improve {concern} naturally")

    return queries


async def generate_daily_plan(user_id: str, lang: str = "cn") -> dict:
    """
    生成完整的每日养生推送方案

    根据用户画像（年龄/体质/性别/季节/节气）差异化推送
    """
    # 1. 获取用户画像
    profile = _get_user_profile(user_id)

    # 2. 构建检索 queries（按优先级排序）
    queries = _build_personalized_queries(profile, lang)

    # 3. 检索知识库（多维度检索）
    all_chunks = []
    seen_ids = set()

    for q in queries:
        chunks = retrieve(q, lang=lang, top_k=2)
        for chunk in chunks:
            if chunk["chunk_id"] not in seen_ids:
                seen_ids.add(chunk["chunk_id"])
                all_chunks.append(chunk)

    # 4. 获取时空上下文
    if lang == "cn":
        solar_term, season = _get_current_solar_term_cn()
        weekday = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"][datetime.now().weekday()]
    else:
        season = _get_current_season_gl()
        solar_term = ""
        weekday = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][datetime.now().weekday()]

    # 5. 体质信息
    constitution_key = profile.get("constitution")
    if lang == "cn":
        constitution_name = _CONSTITUTION_MAP_CN.get(constitution_key, "") if constitution_key else ""
    else:
        constitution_name = _CONSTITUTION_MAP_GL.get(constitution_key, "") if constitution_key else ""

    age_group = profile.get("age_group", "")
    gender = profile.get("gender", "")

    # 6. 组装方案
    greeting = _build_greeting(profile, solar_term, season, lang)
    diet_plan = _build_diet_plan(profile, all_chunks, season, lang)
    exercise_plan = _build_exercise_plan(profile, age_group, season, all_chunks, lang)
    acupoint_plan = _build_acupoint_plan(season, all_chunks, lang)
    sleep_plan = _build_sleep_plan(profile, age_group, season, all_chunks, lang)
    emotional_plan = _build_emotional_plan(season, profile, all_chunks, lang)
    schedule = _build_schedule(age_group, lang)

    plan = {
        "date": datetime.now().strftime("%Y-%m-%d"),
        "weekday": weekday,
        "solar_term": solar_term,
        "season": season,
        "greeting": greeting,
        "user_profile": {
            "name": profile.get("name", ""),
            "constitution": constitution_name,
            "age": profile.get("age"),
            "age_group": age_group,
            "gender": gender,
            "life_stage": profile.get("life_stage", ""),
        },
        "diet": diet_plan,
        "exercise": exercise_plan,
        "acupoints": acupoint_plan,
        "sleep": sleep_plan,
        "emotional": emotional_plan,
        "schedule": schedule,
        "knowledge_sources": [
            {"chunk_id": c["chunk_id"], "heading": c["heading_path"][-1] if c["heading_path"] else ""}
            for c in all_chunks[:6]
        ],
    }

    return plan


def _build_greeting(profile: dict, solar_term: str, season: str, lang: str) -> str:
    """构建个性化问候"""
    name = profile.get("name", "")
    age_group = profile.get("age_group", "")
    _greetings = {
        "cn": {
            "children": f"小朋友你好！{solar_term}到了，今天也是健康成长的一天！",
            "teenager": f"{name}，{solar_term}时节，精力充沛的你今天也要元气满满！",
            "young_adult": f"{name}，{solar_term}了！年轻人也要注意养生，早睡早起哦~",
            "professional": f"{name}早上好！{solar_term}时节，工作再忙也要照顾好自己。",
            "middle_age": f"{name}您好，{solar_term}已至。中年养生，贵在坚持。",
            "senior": f"{name}您好！{solar_term}到了，今天也要保持好心情，适度运动。",
            "elderly": f"{name}您好！{solar_term}时节，注意保暖，保重身体。",
            "": f"{solar_term}时节，祝您健康快乐每一天！",
        },
        "gl": {
            "children": f"Hello little one! {solar_term if solar_term else 'A new day'} is here — another great day to grow healthy and strong!",
            "teenager": f"Good morning! Stay energized and balanced this season.",
            "young_adult": f"Hey there! Remember, wellness habits now pay dividends for decades. Start today!",
            "professional": f"Good morning! Busy day ahead? Take mindful breaks — your health is your greatest asset.",
            "middle_age": f"Welcome! This season invites steady, consistent wellness habits. You've got this.",
            "senior": f"Good day! Stay active, stay social, and enjoy the season at your own pace.",
            "elderly": f"Hello! Take it gently today. Rest when needed, move when able. Be well.",
            "": f"Wishing you a healthy and balanced day!",
        },
    }

    lang_map = _greetings.get(lang, _greetings["cn"])
    greeting = lang_map.get(age_group, lang_map.get("", ""))
    return greeting


def _build_diet_plan(profile: dict, chunks: list, season: str, lang: str) -> dict:
    """构建饮食方案"""
    constitution_key = profile.get("constitution")
    age_group = profile.get("age_group", "")

    # 从知识库提取饮食相关内容
    diet_chunks = []
    for c in chunks:
        content = c["content"]
        heading = str(c.get("heading_path", []))
        if any(kw in content or kw in heading for kw in
               (["饮食", "食疗", "食谱", "营养", "food", "diet", "recipe", "nutrition"])):
            diet_chunks.append(c)

    # 茶饮推荐（体质相关）
    if lang == "cn":
        tea_default = "枸杞菊花茶（养肝明目，四季皆宜）"
        if constitution_key:
            const_name = _CONSTITUTION_MAP_CN.get(constitution_key, "")
            for key, tea in _TEA_BY_CONSTITUTION_CN.items():
                if key in const_name:
                    tea_default = tea
                    break

        # 季节茶饮调整
        season_tea = {
            "春": "春季宜饮菊花茶、玫瑰花茶，疏肝解郁",
            "夏": "夏季宜饮绿茶、薄荷茶、酸梅汤，清热消暑",
            "秋": "秋季宜饮银耳莲子茶、百合雪梨茶，润肺养阴",
            "冬": "冬季宜饮姜枣茶、红茶、桂圆红枣茶，温补散寒",
        }
        tea_tip = season_tea.get(season, "")
    else:
        tea_default = "Chrysanthemum & Goji Tea (nourishes the liver, brightens the eyes)"
        if constitution_key:
            const_name = _CONSTITUTION_MAP_GL.get(constitution_key, "")
            for key, tea in _TEA_BY_CONSTITUTION_GL.items():
                if key in const_name:
                    tea_default = tea
                    break
        tea_tip = ""

    # 饮食方案差异化
    if lang == "cn":
        # 年龄段饮食差异
        breakfast_by_age = {
            "children": "小米山药粥 + 蒸蛋 + 水果（均衡营养，促进发育）",
            "teenager": "全麦面包 + 牛奶 + 鸡蛋 + 坚果（补充蛋白质和钙质）",
            "young_adult": "燕麦粥/豆浆 + 水煮蛋 + 水果（营养均衡，补充能量）",
            "professional": "五谷杂粮粥 + 鸡蛋 + 蔬菜（提神醒脑，养胃健脾）",
            "middle_age": "杂粮粥 + 凉拌菜 + 豆制品（低盐低脂，预防三高）",
            "senior": "小米粥 + 蒸蛋 + 软烂蔬菜（易消化，营养均衡）",
            "elderly": "米糊/粥 + 蒸蛋 + 软食（细软易消化，少量多餐）",
        }
        lunch_by_age = {
            "children": "米饭 + 鱼肉/鸡肉 + 时令蔬菜 + 紫菜蛋花汤",
            "teenager": "米饭 + 瘦肉 + 蔬菜 + 豆腐汤（营养充足支持发育）",
            "young_adult": "杂粮饭 + 蛋白质 + 蔬菜（控制外卖频率，注意搭配）",
            "professional": "糙米饭 + 鸡胸肉/鱼肉 + 蔬菜（少油少盐，不宜过饱）",
            "middle_age": "杂粮饭 + 清蒸鱼 + 蔬菜（控制总量，多膳食纤维）",
            "senior": "软米饭 + 豆腐/鱼肉 + 软烂蔬菜（七分饱为宜）",
            "elderly": "软饭/粥 + 蒸鱼/蛋羹 + 碎菜（细软温热）",
        }
        dinner_by_age = {
            "children": "面条/粥 + 蔬菜蛋花 + 水果（清淡易消化）",
            "teenager": "米饭 + 蔬菜 + 少量荤菜（不宜过饱）",
            "young_adult": "蔬菜沙拉/汤面 + 少量蛋白质（晚餐宜少宜清淡）",
            "professional": "汤面/粥 + 蔬菜（晚餐七分饱，20点后不进食）",
            "middle_age": "蔬菜粥/汤 + 少量蛋白质（清淡为主，不宜过晚）",
            "senior": "粥 + 软菜（少食晚餐，不宜过饱）",
            "elderly": "粥/米糊（少量，不宜过饱）",
        }
        avoid_by_constitution = {
            "气虚": "忌食生冷寒凉、过度辛散",
            "阳虚": "忌食寒凉生冷、冰饮冷食",
            "阴虚": "忌食辛辣燥热、羊肉狗肉",
            "痰湿": "忌食肥甘厚腻、甜食冷饮",
            "湿热": "忌食辛辣油腻、甜食酒类",
            "血瘀": "忌食寒凉收涩、过咸食物",
            "气郁": "忌饮浓茶咖啡，少食辛热",
            "特禀": "注意排查过敏食物",
        }
        avoid_text = ""
        if constitution_key:
            const_name = _CONSTITUTION_MAP_CN.get(constitution_key, "")
            for key, avoid in avoid_by_constitution.items():
                if key in const_name:
                    avoid_text = avoid
                    break
        if not avoid_text:
            avoid_text = "饮食有节，不宜过饥过饱"

        breakfast = breakfast_by_age.get(age_group, "温热粥品 + 鸡蛋 + 蔬菜")
        lunch = lunch_by_age.get(age_group, "杂粮饭 + 蛋白质 + 时令蔬菜")
        dinner = dinner_by_age.get(age_group, "清淡汤面/粥 + 蔬菜")

        # 食谱（从知识库取第一条饮食相关）
        recipe = ""
        if diet_chunks:
            recipe = diet_chunks[0]["content"][:400]
    else:
        breakfast = "A warm, nourishing breakfast with whole grains and protein"
        lunch = "Balanced meal with whole grains, lean protein, and seasonal vegetables"
        dinner = "Light, early dinner — soup, soft vegetables, easy to digest"
        avoid_text = "Eat in moderation, avoid overeating"
        tea_default = _TEA_BY_CONSTITUTION_GL.get(
            _CONSTITUTION_MAP_GL.get(constitution_key, ""), tea_default
        ) if constitution_key else tea_default
        tea_tip = ""
        recipe = ""
        if diet_chunks:
            recipe = diet_chunks[0]["content"][:400]

    return {
        "breakfast": breakfast,
        "lunch": lunch,
        "dinner": dinner,
        "tea": tea_default,
        "tea_tip": tea_tip,
        "avoid": avoid_text,
        "recipe": recipe,
    }


def _build_exercise_plan(profile: dict, age_group: str, season: str, chunks: list, lang: str) -> dict:
    """构建运动方案"""
    if lang == "cn":
        exercise_defaults = _EXERCISE_BY_AGE_CN.get(age_group, _EXERCISE_BY_AGE_CN.get("professional"))
    else:
        exercise_defaults = _EXERCISE_BY_AGE_GL.get(age_group, _EXERCISE_BY_AGE_GL.get("professional"))

    # 从知识库提取运动内容
    exercise_content = ""
    for c in chunks:
        content = c["content"]
        heading = str(c.get("heading_path", []))
        if any(kw in content or kw in heading for kw in
               (["运动", "锻炼", "功法", "八段锦", "太极", "exercise", "movement", "tai chi"])):
            exercise_content = content[:300]
            break

    return {
        "morning": exercise_defaults.get("morning", ""),
        "afternoon": exercise_defaults.get("afternoon", ""),
        "evening": exercise_defaults.get("evening", ""),
        "duration": exercise_defaults.get("duration", ""),
        "extra_tip": exercise_content,
    }


def _build_acupoint_plan(season: str, chunks: list, lang: str) -> dict:
    """构建穴位方案"""
    if lang == "cn":
        points_info = _ACUPOINTS_BY_SEASON_CN.get(season, _ACUPOINTS_BY_SEASON_CN.get("春"))
    else:
        gl_season = {"春": "spring", "夏": "summer", "秋": "autumn", "冬": "winter"}.get(season, "spring")
        points_info = _ACUPOINTS_BY_SEASON_GL.get(gl_season, _ACUPOINTS_BY_SEASON_GL.get("spring"))

    # 从知识库提取穴位内容
    acu_content = ""
    for c in chunks:
        content = c["content"]
        heading = str(c.get("heading_path", []))
        if any(kw in content or kw in heading for kw in
               (["穴位", "按摩", "推拿", "acupoint", "massage", "acupressure"])):
            acu_content = content[:300]
            break

    return {
        "today_points": points_info.get("points", []),
        "method": points_info.get("method", ""),
        "focus": points_info.get("focus", ""),
        "extra_tip": acu_content,
    }


def _build_sleep_plan(profile: dict, age_group: str, season: str, chunks: list, lang: str) -> dict:
    """构建睡眠方案"""
    if lang == "cn":
        sleep_defaults = _SLEEP_BY_AGE_CN.get(age_group, _SLEEP_BY_AGE_CN.get("professional"))
    else:
        sleep_defaults = _SLEEP_BY_AGE_GL.get(age_group, _SLEEP_BY_AGE_GL.get("professional"))

    # 从知识库提取睡眠内容
    sleep_content = ""
    for c in chunks:
        content = c["content"]
        heading = str(c.get("heading_path", []))
        if any(kw in content or kw in heading for kw in
               (["睡眠", "入睡", "泡脚", "助眠", "sleep", "bedtime", "foot soak"])):
            sleep_content = content[:300]
            break

    return {
        "bedtime": sleep_defaults.get("bedtime", ""),
        "waketime": sleep_defaults.get("waketime", ""),
        "hours": sleep_defaults.get("hours", ""),
        "tips": sleep_defaults.get("tips", ""),
        "extra_advice": sleep_content,
    }


def _build_emotional_plan(season: str, profile: dict, chunks: list, lang: str) -> dict:
    """构建情绪方案"""
    if lang == "cn":
        emotion_info = _EMOTION_ADVICE_CN.get(season, _EMOTION_ADVICE_CN["春"])
    else:
        gl_season = {"春": "spring", "夏": "summer", "秋": "autumn", "冬": "winter"}.get(season, "spring")
        emotion_info = _EMOTION_ADVICE_GL.get(gl_season, _EMOTION_ADVICE_GL["spring"])

    return {
        "focus": emotion_info.get("focus", ""),
        "tip": emotion_info.get("tip", ""),
    }


def _build_schedule(age_group: str, lang: str) -> dict:
    """构建一日作息表"""
    if lang == "cn":
        schedules = {
            "children": {
                "06:30": "起床，喝温水一杯",
                "07:00": "营养早餐",
                "08:00": "户外活动/上学",
                "12:00": "午餐",
                "13:00": "午休（30-60分钟）",
                "15:30": "户外运动/玩耍",
                "18:00": "晚餐",
                "19:30": "亲子阅读/安静活动",
                "20:30": "洗漱准备入睡",
                "21:00": "入睡",
            },
            "teenager": {
                "06:30": "起床，喝温水",
                "07:00": "早餐（蛋白质+谷物）",
                "08:00": "开始学习/活动",
                "12:00": "午餐",
                "13:00": "午休（20-30分钟）",
                "15:00": "体育锻炼",
                "18:00": "晚餐",
                "19:30": "复习/放松",
                "21:00": "远离手机，准备入睡",
                "22:30": "入睡",
            },
            "young_adult": {
                "07:00": "起床，喝温水一杯",
                "07:30": "早餐",
                "08:00": "开始工作/学习",
                "12:00": "午餐（七分饱）",
                "13:00": "午休（20-30分钟）",
                "15:00": "起身活动，拉伸放松",
                "18:00": "晚餐（清淡为主）",
                "19:30": "散步/运动",
                "21:00": "远离电子屏幕",
                "22:30": "热水泡脚",
                "23:00": "入睡",
            },
            "professional": {
                "06:30": "起床，温水一杯",
                "07:00": "营养早餐",
                "08:00": "开始工作",
                "10:00": "工间休息，颈椎活动5分钟",
                "12:00": "午餐（细嚼慢咽）",
                "13:00": "午休（20-30分钟）",
                "15:00": "起身活动，穴位按摩",
                "18:00": "晚餐",
                "19:00": "散步30分钟",
                "21:00": "泡脚+放松",
                "22:30": "入睡",
            },
            "middle_age": {
                "06:30": "起床，温水一杯",
                "07:00": "杂粮早餐",
                "07:30": "太极拳/八段锦（20分钟）",
                "12:00": "午餐（低盐低脂）",
                "13:00": "午休（20-30分钟）",
                "15:00": "起身活动，穴位按摩",
                "18:00": "晚餐（七分饱）",
                "19:00": "散步30分钟",
                "21:00": "泡脚+穴位按摩",
                "22:00": "入睡",
            },
            "senior": {
                "06:00": "起床，温水一杯",
                "06:30": "营养早餐（粥+蛋+菜）",
                "07:30": "太极拳/散步（30分钟）",
                "12:00": "午餐（软烂易消化）",
                "13:00": "午休（30-40分钟）",
                "15:00": "轻度活动/社交",
                "18:00": "清淡晚餐",
                "19:00": "散步或园艺",
                "21:00": "泡脚+放松",
                "21:30": "入睡",
            },
            "elderly": {
                "06:30": "缓慢起床，温水一杯",
                "07:00": "米糊/软粥早餐",
                "08:00": "室内轻度活动或坐式太极",
                "10:00": "休息，喝茶聊天",
                "12:00": "软烂午餐（少量多餐）",
                "13:00": "午休（30-60分钟）",
                "15:00": "晒太阳，轻度活动",
                "18:00": "晚餐（粥/面汤）",
                "19:30": "安静休息",
                "21:00": "温水擦浴+泡脚",
                "21:30": "入睡",
            },
        }
        return schedules.get(age_group, schedules["professional"])
    else:
        schedules = {
            "children": {
                "06:30": "Wake up, drink warm water",
                "07:00": "Nutritious breakfast",
                "08:00": "Outdoor play / school",
                "12:00": "Lunch",
                "13:00": "Nap (30-60 min)",
                "15:30": "Outdoor sports / play",
                "18:00": "Dinner",
                "19:30": "Quiet reading time",
                "20:30": "Bedtime routine",
                "21:00": "Lights out",
            },
            "teenager": {
                "06:30": "Wake up, drink warm water",
                "07:00": "Breakfast (protein + grains)",
                "08:00": "Study / activities",
                "12:00": "Lunch",
                "13:00": "Nap (20-30 min)",
                "15:00": "Exercise or sports",
                "18:00": "Dinner",
                "19:30": "Review / relax",
                "21:00": "Screen-off time",
                "22:30": "Bedtime",
            },
            "young_adult": {
                "07:00": "Wake up, warm water",
                "07:30": "Breakfast",
                "08:00": "Work / study",
                "12:00": "Lunch (don't overeat)",
                "13:00": "Nap (20-30 min)",
                "15:00": "Move, stretch",
                "18:00": "Dinner (keep it light)",
                "19:30": "Walk / exercise",
                "21:00": "Screen-free time",
                "22:30": "Warm foot soak",
                "23:00": "Sleep",
            },
            "professional": {
                "06:30": "Wake up, warm water",
                "07:00": "Healthy breakfast",
                "08:00": "Start work",
                "10:00": "Break — neck stretches 5 min",
                "12:00": "Lunch (mindful eating)",
                "13:00": "Nap (20-30 min)",
                "15:00": "Move, acupoint massage",
                "18:00": "Dinner",
                "19:00": "30-min walk",
                "21:00": "Foot soak + relax",
                "22:30": "Bedtime",
            },
            "middle_age": {
                "06:30": "Wake up, warm water",
                "07:00": "Multi-grain breakfast",
                "07:30": "Tai Chi / Ba Duan Jin (20 min)",
                "12:00": "Lunch (low salt, low fat)",
                "13:00": "Nap (20-30 min)",
                "15:00": "Move, acupoint massage",
                "18:00": "Dinner (70% full)",
                "19:00": "30-min walk",
                "21:00": "Foot soak + massage",
                "22:00": "Bedtime",
            },
            "senior": {
                "06:00": "Wake up, warm water",
                "06:30": "Nourishing breakfast",
                "07:30": "Tai Chi / walking (30 min)",
                "12:00": "Lunch (soft, easy to digest)",
                "13:00": "Nap (30-40 min)",
                "15:00": "Light activity / social time",
                "18:00": "Light dinner",
                "19:00": "Walk or gardening",
                "21:00": "Foot soak + relax",
                "21:30": "Bedtime",
            },
            "elderly": {
                "06:30": "Rise slowly, warm water",
                "07:00": "Soft congee / porridge",
                "08:00": "Gentle seated exercises",
                "10:00": "Rest, tea, conversation",
                "12:00": "Soft lunch (small frequent meals)",
                "13:00": "Nap (30-60 min)",
                "15:00": "Sunlight, gentle activity",
                "18:00": "Light dinner (soup / noodles)",
                "19:30": "Quiet rest",
                "21:00": "Warm sponge bath + foot soak",
                "21:30": "Bedtime",
            },
        }
        return schedules.get(age_group, schedules["professional"])


# ============ 保留原有函数兼容 ============

async def generate_personalized_plan(user_id: str, lang: str = "cn") -> dict:
    """
    生成个性化养生方案（保留原有接口，内部调用 generate_daily_plan）
    """
    plan = await generate_daily_plan(user_id, lang)

    return {
        "time_context": {
            "solar_term": plan.get("solar_term", ""),
            "season": plan.get("season", ""),
            "date": plan["date"],
            "weekday": plan["weekday"],
        },
        "user_profile": plan["user_profile"],
        "today_advice": plan["greeting"] + "\n" + plan["diet"]["breakfast"],
        "weekly_diet_plan": f"早餐: {plan['diet']['breakfast']}\n午餐: {plan['diet']['lunch']}\n晚餐: {plan['diet']['dinner']}",
        "weekly_exercise_plan": f"晨练: {plan['exercise']['morning']}\n下午: {plan['exercise']['afternoon']}\n晚间: {plan['exercise']['evening']}",
        "tea_recommendations": plan["diet"]["tea"] + ("\n" + plan["diet"]["tea_tip"] if plan["diet"]["tea_tip"] else ""),
        "acupoint_advice": "、".join(plan["acupoints"]["today_points"]) + f"\n{plan['acupoints']['method']}",
        "emotional_wellness": plan["emotional"]["tip"],
        "sleep_schedule": f"入睡: {plan['sleep']['bedtime']}\n起床: {plan['sleep']['waketime']}\n{plan['sleep']['tips']}",
        "knowledge_sources": plan["knowledge_sources"],
    }
