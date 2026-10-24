"""首页卡片：按节气、法定假日/调休、地区气候、年龄段、用户目标和最近的行动记录给出 3–5 张生活方式建议卡。

每张卡都带 reason（为什么给你这张）和 basis（依据哪项输入），便于用户理解、也便于验收「可归因的不同」。
内容只涉及作息、饮食、运动、情绪和防护，不做诊断、不推荐药物。
地区和年龄都是用户自己填写的（/api/v1/settings/region、/api/v1/settings/age-profile）；没填就不用。
"""

from __future__ import annotations

import json
import time
from datetime import date, timedelta
from typing import Any, Optional

from sqlalchemy.orm import Session

from ..simple_models import UserSetting
from ..utils import cn_calendar, solar_term_calendar

REGION_KEY = "profile:region"
ONBOARDING_KEY = "profile:onboarding"
ACTION_LOG_KEY = "behavior:action_completions"

# 每个节气一句可执行的生活提示
TERM_TIPS = {
    "小寒": "注意头颈和脚部保暖，出门戴好帽子围巾",
    "大寒": "一年最冷的时候，进出门及时加减衣服",
    "立春": "早晚还冷，别急着减衣服，早睡早起多到户外走走",
    "雨水": "雨水多湿气重，衣物被褥常晾晒，饮食清淡少油腻",
    "惊蛰": "气温忽高忽低，注意增减衣服，可以开始户外运动",
    "春分": "昼夜等长，作息规律，多吃应季蔬菜",
    "清明": "适合踏青散步，花粉多的地方注意防过敏",
    "谷雨": "雨多潮湿，少吃生冷油腻，居室多通风",
    "立夏": "天气转热，午后可以小憩 20 分钟，多喝水",
    "小满": "闷热潮湿，饮食清淡，少喝冰饮",
    "芒种": "出汗多，及时补水，别对着空调直吹",
    "夏至": "白天最长，也要保证睡够，避开正午暴晒",
    "小暑": "注意防暑，外出带水，运动安排在早晚",
    "大暑": "一年最热的时候，防中暑，少在烈日下活动",
    "立秋": "早晚转凉但白天仍热，继续防暑补水",
    "处暑": "暑热渐退，早晚添件薄外套",
    "白露": "昼夜温差变大，晚上别再贪凉",
    "秋分": "秋燥渐起，多喝温水，可以吃些梨、银耳",
    "寒露": "早晚添衣，用温水代替冰饮",
    "霜降": "天气转凉快，注意膝盖和脚部保暖",
    "立冬": "早睡晚起，注意保暖，饮食以温热熟食为主",
    "小雪": "天冷干燥，室内注意加湿和通风",
    "大雪": "天寒地冻，出门注意防滑保暖",
    "冬至": "白天最短，早睡晚起，适量活动别久坐",
}

# 省级行政区 → 气候大区（粗分，只用于生活提示）
ZONES = {
    "东北": ("黑龙江", "吉林", "辽宁"),
    "华北": ("北京", "天津", "河北", "山西", "内蒙古", "山东", "河南"),
    "西北": ("陕西", "甘肃", "宁夏", "新疆"),
    "青藏高原": ("青海", "西藏"),
    "华东华中": ("上海", "江苏", "浙江", "安徽", "江西", "湖北", "湖南"),
    "华南": ("广东", "广西", "海南", "福建", "香港", "澳门", "台湾"),
    "西南": ("四川", "重庆", "贵州", "云南"),
}
PROVINCES = tuple(p for provinces in ZONES.values() for p in provinces)

ZONE_TIPS = {
    "东北": {"春": "春天风大干燥，多喝水，出门注意防风", "夏": "夏季凉爽但早晚凉，注意添衣",
             "秋": "降温快，及早准备厚衣服，室内注意加湿", "冬": "严寒天气，出门做好头手脚保暖，雪天防滑"},
    "华北": {"春": "春季干燥多风沙，注意补水，风沙天少外出", "夏": "夏天炎热，注意防暑补水",
             "秋": "秋天干燥，多喝水，室内可以用加湿器", "冬": "供暖后室内干燥，注意加湿和开窗通风"},
    "西北": {"春": "风沙大、早晚温差大，注意防风保湿", "夏": "日照强、温差大，防晒同时备件外套",
             "秋": "干燥少雨，多喝水，皮肤注意保湿", "冬": "寒冷干燥，注意保暖和补水"},
    "青藏高原": {"春": "海拔高、紫外线强，注意防晒，活动别太猛", "夏": "白天日照强、夜里凉，注意防晒和保暖",
               "秋": "降温早，及早添衣，注意补水", "冬": "严寒缺氧，避免剧烈运动，注意保暖"},
    "华东华中": {"春": "春雨多湿气重，被褥常晾晒", "夏": "梅雨和酷暑，注意防潮防暑，少吃生冷",
               "秋": "秋燥渐起，多喝温水；秋老虎时继续防暑", "冬": "湿冷天气，室内没暖气时注意保暖"},
    "华南": {"春": "回南天潮湿，注意防潮除湿", "夏": "高温高湿，防暑补水，雷雨天少外出",
             "秋": "秋天依然偏热，继续防晒补水", "冬": "冬季温和但早晚凉，注意添衣"},
    "西南": {"春": "早晚温差大，注意增减衣服", "夏": "雨季潮湿，注意防潮，饮食清淡",
             "秋": "秋雨多，注意保暖防潮", "冬": "阴冷潮湿，注意保暖，有太阳时多晒晒"},
}

AGE_TIPS = {
    "child": ("早睡早起，每天户外活动 1 小时", "按家长填写的年龄段"),
    "minor": ("别熬夜打游戏，每天留出户外活动时间", "按你填写的年龄段（未成年）"),
    "senior": ("早晚温差大，晨练等太阳出来后再去，起身动作放慢", "按你填写的年龄段（60 岁以上）"),
}

GOAL_TIPS = (
    (("睡", "失眠", "熬夜", "sleep"), "sleep", "今晚 23 点前放下手机，睡前用温水泡泡脚"),
    (("压力", "放松", "焦虑", "减压", "情绪", "stress", "relax", "calm"), "breathing", "给自己 3 分钟：慢慢吸气 4 秒、呼气 6 秒"),
    (("精神", "累", "疲劳", "活力", "energy"), "exercise", "午后起来走动 5 分钟，比喝咖啡更提神"),
    (("家人", "家庭", "父母", "孩子", "family"), "family", "给家人发一句关心，提醒他们天气变化添衣"),
)


GOAL_NAMES = {"sleep": "睡个好觉", "breathing": "放松减压", "exercise": "白天更有精神", "family": "照顾好家人"}


def zone_for(province: str) -> Optional[str]:
    for zone, provinces in ZONES.items():
        if province in provinces:
            return zone
    return None


def _read_json(session: Session, user_id: str, key: str) -> Any:
    row = session.get(UserSetting, {"user_id": user_id, "key": key})
    if not row:
        return None
    try:
        return json.loads(row.value)
    except (TypeError, ValueError):
        return None


def _card(card_id: str, category: str, title: str, reason: str, basis: str, minutes: int = 3) -> dict:
    return {
        "id": card_id,
        "category": category,
        "title": title,
        "description": title,
        "reason": reason,
        "basis": basis,
        "duration_min": minutes,
    }


def day_card(today: date) -> Optional[dict]:
    kind, name = cn_calendar.day_kind(today)
    tomorrow_kind, _ = cn_calendar.day_kind(today + timedelta(days=1))
    yesterday_kind, holiday_before = cn_calendar.day_kind(today - timedelta(days=1))
    src = cn_calendar.source_for(today)
    basis = "holiday_calendar" if src else "weekday"
    if kind == cn_calendar.MAKEUP_WORKDAY:
        return _card("day_makeup", "rest", "今天调休上班，别补觉到太晚，午后起来活动 3 分钟",
                     f"今天是{name}调休上班日（{src['source'] if src else ''}）", basis)
    if kind == cn_calendar.HOLIDAY and tomorrow_kind in (cn_calendar.WORKDAY, cn_calendar.MAKEUP_WORKDAY):
        return _card("day_back_to_work", "sleep", "明天上班，今晚提前半小时睡",
                     f"今天是{name}假期最后一天", basis)
    if kind == cn_calendar.HOLIDAY:
        return _card("day_holiday", "sleep", "假期也尽量按平时的点睡觉起床",
                     f"今天是{name}假期", basis)
    if kind == cn_calendar.WORKDAY and yesterday_kind == cn_calendar.HOLIDAY:
        return _card("day_first_workday", "rest", "节后第一天上班，事情别排太满，午休闭目 10 分钟",
                     f"{holiday_before}假期后的第一个工作日", basis)
    return None


def build_dashboard(session: Session, user_id: str, today: Optional[date] = None) -> dict:
    today = today or solar_term_calendar.beijing_today()
    term = solar_term_calendar.term_on(today)
    season = solar_term_calendar.season_of(term)
    starts_today = solar_term_calendar.term_start(today) == today
    term_reason = f"今天{term}交节" if starts_today else f"现在是{term}节气"

    cards: list[dict] = []
    special_day = day_card(today)
    if special_day:
        cards.append(special_day)
    cards.append(_card("term", "seasonal", f"{term}：{TERM_TIPS[term]}", term_reason, "solar_term"))

    region = _read_json(session, user_id, REGION_KEY) or {}
    province = region.get("province")
    zone = zone_for(province) if province else None
    if zone:
        cards.append(_card("region", "seasonal", ZONE_TIPS[zone][season],
                           f"你所在的{province}属于{zone}，现在是{season}季", "region"))

    from .age_policy import read_group

    group = read_group(session, user_id, today)
    if group in AGE_TIPS:
        text, reason = AGE_TIPS[group]
        cards.append(_card("age", "health", text, reason, "age_group"))

    onboarding = _read_json(session, user_id, ONBOARDING_KEY) or {}
    goal = str(onboarding.get("help_goal") or "")
    for words, category, text in GOAL_TIPS:
        if goal and any(w in goal for w in words):
            cards.append(_card(f"goal_{category}", category, text, f"按你选的目标：{GOAL_NAMES[category]}", "goal"))
            break

    log = _read_json(session, user_id, ACTION_LOG_KEY) or []
    week_ago = time.time() - 7 * 86400
    done = sum(1 for item in log if item.get("completed") and item.get("at", 0) >= week_ago)
    if done:
        cards.append(_card("progress", "progress", f"这一周你完成了 {done} 次小行动，继续保持",
                           "按你最近 7 天的完成记录", "behavior", minutes=1))

    kind, holiday_name = cn_calendar.day_kind(today)
    next_name, next_date = solar_term_calendar.next_term(today)
    return {
        "date": today.isoformat(),
        "solar_term": {"name": term, "season": season, "starts_today": starts_today,
                       "next": {"name": next_name, "date": next_date.isoformat()}},
        "day_type": {"kind": kind, "holiday": holiday_name, "calendar_covered": cn_calendar.covered(today),
                     "source": cn_calendar.source_for(today)},
        "daily_insight": {"text": f"{term_reason}：{TERM_TIPS[term]}。", "reason": term_reason},
        "suggestions": cards[:5],
    }
