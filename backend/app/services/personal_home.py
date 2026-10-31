"""Personalised home for 顺时 / Seasons: one pure engine, two languages.

What it uses (only things the user entered or did in the app, nothing inferred about health):
  * profile  - goal, life stage, preferred support time, region/hemisphere, age group, optional self-chosen
               constitution tendency (domestic only, labelled "self-chosen, not a diagnosis")
  * activity - completed actions (with times), cards already shown (for rotation)
  * clock    - local time of day, weekday/weekend, public holiday (domestic), solar term / season
It does not diagnose, name diseases, suggest drugs or promise outcomes; the content library is lifestyle only and a
test scans every card for forbidden words. Users can switch personalisation off (everyone then gets the generic board).

Scoring is additive and printed back to the user as the card's ``reason``/``basis``:
  goal +6 (+2 per extra matching goal; -5 for another goal's card when the user chose goals)   time-of-day +3   preferred support time +2   season +2   day type +1
  constitution tendency +2      reinforcement +1.5 (a category the user completed in the last 7 days)
  rotation: shown in the last 3 days -8, last 7 days -6, last 14 days -2;  completed this week -4
  tie-break: a stable hash of (user, date, card) so two similar users still differ and one user varies by day.
Cards shown today are not penalised, so a refresh returns the same board.
"""

from __future__ import annotations

import hashlib
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta
from typing import Iterable, Optional, Sequence

TIMES = ("morning", "midday", "afternoon", "evening", "night")
SEASONS = ("spring", "summer", "autumn", "winter")
GOALS = ("sleep", "breathing", "exercise", "family", "mood", "food")
CONSTITUTIONS = ("平和", "气虚", "阳虚", "阴虚", "痰湿", "湿热", "血瘀", "气郁")

FORBIDDEN_ZH = ("治疗", "治愈", "诊断", "确诊", "处方", "药", "疗效", "根治", "保证", "投资")
FORBIDDEN_EN = ("cure", "diagnos", "prescri", "medicat", "treatment", "guarantee", "invest", "disease", "therapy")


def _c(cid, cat, zh, en, goals=(), times=(), seasons=(), day=None, cons=(), minutes=3):
    return {"id": cid, "category": cat, "zh": zh, "en": en, "goals": tuple(goals), "times": tuple(times),
            "seasons": tuple(seasons), "day": day, "cons": tuple(cons), "minutes": minutes}


LIBRARY = [
    # sleep
    _c("sleep_earlier", "sleep", "今晚比平时早 20 分钟上床，睡前一小时把灯光调暗", "Go to bed 20 minutes earlier tonight and dim the lights an hour before.", ["sleep"], ["evening", "night"]),
    _c("sleep_screen", "sleep", "睡前 30 分钟放下手机，换成纸质书或轻音乐", "Put the phone down 30 minutes before bed; try a paper book or quiet music.", ["sleep"], ["evening", "night"]),
    _c("sleep_feet", "sleep", "睡前用温水泡脚 10 分钟，水温以舒适为准", "A warm foot soak for ten minutes before bed, at a comfortable temperature.", ["sleep"], ["evening", "night"], ["autumn", "winter"], cons=["阳虚", "气虚"]),
    _c("sleep_weekend", "sleep", "周末起床时间和工作日相差别超过一小时", "Keep weekend wake-up within an hour of your weekday time.", ["sleep"], ["morning", "evening"], day="weekend"),
    _c("sleep_caffeine", "sleep", "下午不再喝咖啡和浓茶，晚上更容易入睡", "No coffee or strong tea after lunch; evenings go easier.", ["sleep"], ["midday", "afternoon"]),
    _c("sleep_dry", "sleep", "晚上少吃辛辣和夜宵，睡前喝杯温水", "Skip spicy food and late snacks tonight; a glass of warm water before bed.", ["sleep", "food"], ["evening", "night"], cons=["阴虚", "湿热"]),
    # breathing / calm
    _c("breath_364", "breathing", "3 分钟呼吸：吸气 4 秒，呼气 6 秒，做 6 轮", "Three-minute breathing: in for 4, out for 6, six rounds.", ["breathing", "mood"], ["midday", "afternoon", "evening"], minutes=3),
    _c("breath_wake", "breathing", "起床后先喝杯温水，再做 3 次深呼吸", "After waking, a glass of warm water and three deep breaths.", ["breathing"], ["morning"], minutes=2),
    _c("breath_neck", "breathing", "工作间隙站起来，肩颈慢慢转 5 圈", "Stand up between tasks and roll your shoulders slowly five times.", ["breathing", "exercise"], ["midday", "afternoon"], cons=["气郁", "血瘀"], minutes=2),
    _c("breath_write", "breathing", "把今天最让你紧绷的一件事写下来，写完合上本子", "Write down the one thing that tightened you up today, then close the notebook.", ["breathing", "mood"], ["evening", "night"], cons=["气郁"], minutes=5),
    _c("breath_pause", "breathing", "每次手机提示音响起前，先停一口气再回消息", "Before you answer the next message, take one slow breath.", ["breathing", "mood"], ["midday", "afternoon"], minutes=1),
    # movement
    _c("move_walk", "exercise", "出门快走 15 分钟，边走边留意脚步和呼吸", "Take a brisk 15-minute walk and notice your steps and breath.", ["exercise"], ["morning", "afternoon"], minutes=15),
    _c("move_lunch", "exercise", "午饭后站着活动 5 分钟，不坐着刷手机", "Stand and move for five minutes after lunch instead of sitting with the phone.", ["exercise", "food"], ["midday"], cons=["痰湿", "气虚"], minutes=5),
    _c("move_weekend", "exercise", "约个人一起散步 30 分钟，周末的好安排", "Ask someone to walk with you for half an hour; a good weekend plan.", ["exercise", "family", "mood"], ["morning", "afternoon"], day="weekend", minutes=30),
    _c("move_stretch", "exercise", "拉伸 5 分钟：先肩颈，再腰背，再腿", "Five minutes of stretching: shoulders and neck, then back, then legs.", ["exercise", "breathing"], ["morning", "evening"], cons=["血瘀", "气郁"], minutes=5),
    _c("move_gentle", "exercise", "今天只做轻度活动：慢走或散步，不追求出汗", "Keep it gentle today: an easy walk, no need to push.", ["exercise"], ["morning", "afternoon"], cons=["气虚"], minutes=10),
    _c("move_stairs", "exercise", "今天能走楼梯就走楼梯，哪怕只有两层", "Take the stairs today, even if it is only two floors.", ["exercise"], ["morning", "midday"], day="weekday", minutes=2),
    # food (habits, not therapy)
    _c("food_breakfast", "food", "早餐加一份温热的粥或燕麦", "Add something warm to breakfast, like porridge or oats.", ["food"], ["morning"], cons=["阳虚", "气虚"]),
    _c("food_water", "food", "今天喝够水：每个整点喝几口", "Drink enough water today: a few sips every hour.", ["food"], ["morning", "midday", "afternoon"], ["summer", "autumn"]),
    _c("food_light", "food", "午饭清淡些，少油少糖，七分饱", "Keep lunch light, low in oil and sugar, and stop at about 70% full.", ["food"], ["midday"], cons=["痰湿", "湿热"]),
    _c("food_dinner", "food", "晚饭七分饱，吃完散步 10 分钟", "Stop dinner at about 70% full and take a 10-minute walk after.", ["food", "sleep"], ["evening"], minutes=10),
    _c("food_season_spring", "food", "春天多吃时令绿叶菜，少吃太油腻的", "Eat more seasonal greens this spring and fewer heavy, oily dishes.", ["food"], ["midday", "evening"], ["spring"]),
    _c("food_season_summer", "food", "天热时多喝水，少喝冰饮，常温的更舒服", "In the heat drink more water and fewer iced drinks; room temperature feels better.", ["food"], ["midday", "afternoon"], ["summer"]),
    _c("food_season_autumn", "food", "秋天干燥，多喝温水，可以吃些梨和银耳", "Autumn air is dry: drink warm water and add pears or white fungus if you like them.", ["food"], ["midday", "evening"], ["autumn"], cons=["阴虚"]),
    _c("food_season_winter", "food", "冬天吃温热的熟食，晚饭别吃得太晚", "Favour warm cooked food in winter and eat dinner earlier.", ["food"], ["evening"], ["winter"], cons=["阳虚"]),
    # mood
    _c("mood_free", "mood", "给自己 10 分钟没有任务的时间，什么都不用完成", "Give yourself ten minutes with no task at all.", ["mood", "breathing"], ["afternoon", "evening"], minutes=10),
    _c("mood_three", "mood", "记下今天三件让你感觉不错的小事", "Write down three small things that felt good today.", ["mood"], ["evening", "night"], minutes=5),
    _c("mood_call", "mood", "给一位朋友打个电话，聊五分钟", "Call a friend for five minutes.", ["mood", "family"], ["afternoon", "evening"], day="weekend", minutes=5),
    _c("mood_sun", "mood", "到有阳光的地方站 10 分钟", "Stand somewhere sunny for ten minutes.", ["mood", "exercise"], ["morning", "midday"], ["spring", "autumn", "winter"], minutes=10),
    # family
    _c("family_msg", "family", "给家人发条消息，提醒他们天气变化多添减衣服", "Send your family a message about the weather and what to wear.", ["family"], ["morning", "midday"], minutes=2),
    _c("family_meal", "family", "周末和家人一起做一顿饭", "Cook a meal with family this weekend.", ["family", "food"], ["afternoon", "evening"], day="weekend", minutes=40),
    _c("family_call", "family", "打个电话问候年长的亲人", "Phone an older relative to say hello.", ["family"], ["evening"], minutes=10),
    # seasonal weather (always eligible by season, goal-free)
    _c("season_spring", "seasonal", "春天早晚还凉，出门带件薄外套，多到户外走走", "Spring mornings and evenings are still cool; carry a light layer and get outside.", [], ["morning", "midday"], ["spring"]),
    _c("season_summer", "seasonal", "天热避开正午暴晒，外出带水，运动放在早晚", "Avoid midday sun in the heat, carry water, and exercise early or late.", [], ["morning", "midday", "afternoon"], ["summer"]),
    _c("season_autumn", "seasonal", "早晚转凉，添件外套，室内记得通风加湿", "Mornings and evenings cool down; add a layer and air the room.", [], ["morning", "evening"], ["autumn"]),
    _c("season_winter", "seasonal", "天冷注意头颈手脚保暖，雪天和雨天路滑慢走", "Keep head, neck, hands and feet warm, and walk carefully on slick ground.", [], ["morning", "evening"], ["winter"]),
    # rest / day type
    _c("rest_weekday", "rest", "午休闭目 10 分钟，下午会轻松一些", "Rest your eyes for ten minutes at lunch; the afternoon goes easier.", [], ["midday"], day="weekday", minutes=10),
    _c("rest_weekend", "rest", "周末留半天不安排事，想做什么做什么", "Keep half of the weekend free of plans.", [], ["morning", "afternoon"], day="weekend", minutes=1),
    _c("rest_screens", "rest", "每看 40 分钟屏幕，看看远处 20 秒", "Every 40 minutes of screen time, look at something far away for 20 seconds.", [], ["midday", "afternoon"], day="weekday", minutes=1),
    # extra everyday cards (any day) so small goal pools still rotate
    _c("sleep_room", "sleep", "把卧室调到舒服的凉爽，窗帘拉好，睡前不开大灯", "Make the bedroom comfortably cool and dark before you sleep.", ["sleep"], ["evening", "night"]),
    _c("sleep_list", "sleep", "睡前把明天要做的三件事写下来，脑子就能放下", "Write tomorrow's three tasks before bed so your mind can let go.", ["sleep", "mood"], ["evening", "night"], minutes=4),
    _c("breath_sigh", "breathing", "长长地叹三口气，肩膀跟着放下来", "Take three long sighs and let your shoulders drop.", ["breathing"], ["midday", "afternoon", "evening"], minutes=1),
    _c("breath_window", "breathing", "站到窗边或户外，慢慢深呼吸 5 次", "Stand by a window or outside and breathe slowly five times.", ["breathing", "mood"], ["morning", "midday"], minutes=2),
    _c("move_dance", "exercise", "放一首喜欢的歌，跟着动 5 分钟", "Play a song you like and move to it for five minutes.", ["exercise", "mood"], ["afternoon", "evening"], minutes=5),
    _c("move_balance", "exercise", "单脚站立 30 秒，左右各两次，扶着墙也可以", "Stand on one leg for 30 seconds, twice each side; touch a wall if you like.", ["exercise"], ["morning", "midday"], minutes=3),
    _c("food_sugar", "food", "今天把含糖饮料换成白水或淡茶", "Swap sugary drinks for water or weak tea today.", ["food"], ["midday", "afternoon"]),
    _c("food_slow", "food", "吃饭放慢一点，每口多嚼几下，不边吃边看屏幕", "Eat a little slower today, and not in front of a screen.", ["food", "mood"], ["midday", "evening"]),
    _c("mood_music", "mood", "听一首让你放松的歌，只听，不做别的事", "Listen to one song that relaxes you, and do nothing else.", ["mood", "breathing"], ["afternoon", "evening", "night"], minutes=4),
    _c("mood_thanks", "mood", "给一个帮过你的人发句谢谢", "Send a thank-you to someone who helped you.", ["mood", "family"], ["morning", "midday", "afternoon"], minutes=2),
    _c("family_walk", "family", "晚饭后和家人散步 15 分钟", "Walk with family for 15 minutes after dinner.", ["family", "exercise"], ["evening"], minutes=15),
    _c("family_photo", "family", "翻翻旧照片，和家人聊聊那天的事", "Look through old photos and talk with family about that day.", ["family", "mood"], ["afternoon", "evening"], minutes=15),
    _c("rest_break", "rest", "工作 50 分钟就起来接杯水，走一圈", "After 50 minutes of work, get some water and take a short walk.", [], ["midday", "afternoon"], minutes=3),
]
BY_ID = {c["id"]: c for c in LIBRARY}

GOAL_WORDS = (
    (("睡", "失眠", "熬夜", "sleep", "rest"), "sleep"),
    (("压力", "放松", "焦虑", "减压", "stress", "relax", "calm", "anxi"), "breathing"),
    (("情绪", "心情", "mood", "happy"), "mood"),
    (("精神", "累", "疲劳", "活力", "运动", "energy", "move", "active", "fit"), "exercise"),
    (("家人", "家庭", "父母", "孩子", "family"), "family"),
    (("饮食", "吃", "food", "eat", "diet", "nutrition"), "food"),
)
TIME_WORDS = {"morning": ("早", "morning"), "midday": ("中午", "noon", "midday", "lunch"), "afternoon": ("下午", "afternoon"),
              "evening": ("晚", "evening"), "night": ("夜", "night", "bed")}


@dataclass
class Profile:
    lang: str = "zh"                     # "zh" | "en"
    goals: frozenset = frozenset()
    support_time: Optional[str] = None   # one of TIMES
    constitution: Optional[str] = None   # domestic only, self-chosen
    life_stage: Optional[str] = None
    age_group: Optional[str] = None
    season: str = "spring"
    zone_tip: Optional[str] = None       # domestic region sentence
    enabled: bool = True


@dataclass
class Activity:
    completed: list = field(default_factory=list)   # [(category, datetime)] completed actions
    seen: list = field(default_factory=list)        # [(card_id, date)] cards shown on earlier days


def goals_from_text(text: str) -> frozenset:
    t = (text or "").lower()
    return frozenset(g for words, g in GOAL_WORDS if any(w in t for w in words))


def time_from_text(text: str) -> Optional[str]:
    t = (text or "").lower()
    for k, words in TIME_WORDS.items():
        if any(w in t for w in words):
            return k
    return None


def time_bucket(hour: int) -> str:
    if 5 <= hour < 11:
        return "morning"
    if 11 <= hour < 14:
        return "midday"
    if 14 <= hour < 18:
        return "afternoon"
    if 18 <= hour < 22:
        return "evening"
    return "night"


def season_of(day: date, hemisphere: str = "north") -> str:
    m = day.month
    s = "winter" if m in (12, 1, 2) else "spring" if m in (3, 4, 5) else "summer" if m in (6, 7, 8) else "autumn"
    if hemisphere == "south":
        s = {"winter": "summer", "summer": "winter", "spring": "autumn", "autumn": "spring"}[s]
    return s


def greeting(bucket: str, lang: str) -> str:
    zh = {"morning": "早上好，今天从一件小事开始", "midday": "中午好，歇一歇再继续", "afternoon": "下午好，起来动一动",
          "evening": "晚上好，今天也照顾好自己", "night": "夜深了，早点放下手机休息"}
    en = {"morning": "Good morning. Start with one small thing.", "midday": "Good afternoon. Pause before you go on.",
          "afternoon": "Good afternoon. Time to move a little.", "evening": "Good evening. Be kind to yourself today.",
          "night": "It's late. Put the phone down and rest."}
    return (zh if lang == "zh" else en)[bucket]


def _noise(user_key: str, day: date, card_id: str) -> float:
    h = hashlib.sha256(f"{user_key}|{day.isoformat()}|{card_id}".encode()).digest()
    return int.from_bytes(h[:4], "big") / 2**32 * 1.2


def streak_days(completed: Sequence, today: date) -> int:
    days = {at.date() for _, at in completed}
    n, d = 0, today if today in days else today - timedelta(days=1)
    while d in days:
        n += 1
        d -= timedelta(days=1)
    return n


def _label(kind: str, lang: str, value: str = "") -> str:
    zh = {"goal": "你选的目标", "time": "现在是", "support": "你希望的陪伴时间", "season": "当前季节", "day": "今天是",
          "cons": "你自己选的体质倾向（自评，不是诊断）", "reinforce": "你最近做过同类小行动", "base": "今天的生活提示"}
    en = {"goal": "your goal", "time": "it is", "support": "the time of day you prefer", "season": "the current season",
          "day": "today is", "cons": "", "reinforce": "you did something similar recently", "base": "today's general tip"}
    return (zh if lang == "zh" else en)[kind]


NAMES = {
    "zh": {"sleep": "睡个好觉", "breathing": "放松减压", "exercise": "白天更有精神", "family": "照顾家人", "mood": "好心情", "food": "吃得舒服",
           "morning": "早晨", "midday": "中午", "afternoon": "下午", "evening": "晚上", "night": "深夜",
           "spring": "春季", "summer": "夏季", "autumn": "秋季", "winter": "冬季", "weekend": "周末", "weekday": "工作日"},
    "en": {"sleep": "sleep better", "breathing": "calm down", "exercise": "more energy", "family": "look after family", "mood": "mood", "food": "eat well",
           "morning": "morning", "midday": "midday", "afternoon": "afternoon", "evening": "evening", "night": "late night",
           "spring": "spring", "summer": "summer", "autumn": "autumn", "winter": "winter", "weekend": "the weekend", "weekday": "a weekday"},
}


def _reason(parts: list, lang: str) -> tuple[str, list]:
    """parts: [(kind, value)] -> sentence + basis list."""
    nm = NAMES[lang]
    bits, basis = [], []
    for kind, value in parts:
        basis.append(kind)
        if kind == "goal":
            bits.append(f"{_label('goal', lang)}：{nm[value]}" if lang == "zh" else f"you chose \"{nm[value]}\"")
        elif kind == "time":
            bits.append(f"现在是{nm[value]}" if lang == "zh" else f"it is {nm[value]}")
        elif kind == "support":
            bits.append(f"你希望{nm[value]}有人提醒" if lang == "zh" else f"you asked for {nm[value]} reminders")
        elif kind == "season":
            bits.append(f"现在是{nm[value]}" if lang == "zh" else f"it is {nm[value]}")
        elif kind == "day":
            bits.append(f"今天是{nm[value]}" if lang == "zh" else f"today is {nm[value]}")
        elif kind == "cons":
            bits.append(f"{_label('cons', lang)}：{value}")
        elif kind == "reinforce":
            bits.append(_label("reinforce", lang))
    if not bits:
        bits, basis = [_label("base", lang)], ["base"]
    return ("，".join(bits) if lang == "zh" else "Because " + " and ".join(bits)), basis


def score_card(card: dict, profile: Profile, activity: Activity, user_key: str, day: date, bucket: str, daytype: str, recent_cats: set):
    parts, score = [], 0.0
    extra_goals = [g for g in card["goals"] if g in profile.goals]
    if extra_goals:
        score += 6 + 2 * (len(extra_goals) - 1)
        parts.append(("goal", extra_goals[0]))
    elif profile.goals:
        # the user told us what they want; cards for other goals / generic cards only fill the gaps
        score -= 5 if card["goals"] else 1.5
    if card["times"] and bucket in card["times"]:
        score += 3
        parts.append(("time", bucket))
    elif card["times"] and bucket not in card["times"]:
        score -= 2
    if profile.support_time and card["times"] and profile.support_time in card["times"]:
        score += 2
        parts.append(("support", profile.support_time))
    if card["seasons"]:
        if profile.season in card["seasons"]:
            score += 2
            parts.append(("season", profile.season))
        else:
            score -= 5
    if card["day"]:
        if card["day"] == daytype:
            score += 1
            parts.append(("day", daytype))
        else:
            score -= 3
    if profile.lang == "zh" and profile.constitution and profile.constitution in card["cons"]:  # domestic only
        score += 2
        parts.append(("cons", profile.constitution))
    if card["category"] in recent_cats and card["goals"]:
        score += 1.5
        parts.append(("reinforce", ""))
    for cid, seen_day in activity.seen:
        if cid != card["id"]:
            continue
        age = (day - seen_day).days
        if age <= 0:
            continue
        score -= 8 if age <= 3 else 6 if age <= 7 else 2 if age <= 14 else 0
    for cat, at in activity.completed:
        if cat == card["category"] and 0 <= (day - at.date()).days <= 7 and card["goals"]:
            score -= 1  # variety: do not hand back the same kind again right after it was done
    score += _noise(user_key, day, card["id"])
    return score, parts


def compose(profile: Profile, activity: Activity, user_key: str, now: datetime, daytype: str = "weekday",
            extra_cards: Iterable[dict] = (), limit: int = 4) -> dict:
    """Pure function: same inputs, same board. ``extra_cards`` are already-built anchor cards (solar term, holiday)."""
    day = now.date()
    bucket = time_bucket(now.hour)
    lang = profile.lang
    recent_cats = {cat for cat, at in activity.completed if 0 <= (day - at.date()).days <= 7}
    streak = streak_days(activity.completed, day)

    if not profile.enabled:
        return {"greeting": greeting(bucket, lang), "hero": None, "cards": list(extra_cards)[:limit],
                "streak": None, "personalization": {"enabled": False, "used": [], "note": _off_note(lang)}}

    scored = []
    for card in LIBRARY:
        if (card["seasons"] and profile.season not in card["seasons"]) or (card["day"] and card["day"] != daytype):
            continue  # a weekend card on a Wednesday, or a winter card in summer, is simply wrong
        s, parts = score_card(card, profile, activity, user_key, day, bucket, daytype, recent_cats)
        scored.append((s, card, parts))
    scored.sort(key=lambda t: (-t[0], t[1]["id"]))

    picked, cats = [], set()

    def take(floor: float, want: int) -> None:
        for s, card, parts in scored:
            if len(picked) >= want:
                return
            if card["category"] in cats or s < floor:
                continue
            cats.add(card["category"])
            reason, basis = _reason(parts, lang)
            picked.append({"id": card["id"], "category": card["category"], "title": card[lang], "description": card[lang],
                           "reason": reason, "basis": basis[0], "bases": basis, "duration_min": card["minutes"], "score": round(s, 2)})

    # a thin board is better than filler from another goal / wrong season or time, but never fewer than three cards
    take(1.0 if profile.goals else -1, limit)
    if len(picked) < 3:
        take(-1, 3)

    anchors = [dict(c, bases=[c.get("basis", "calendar")]) for c in extra_cards][:2]
    cards = anchors + picked[: max(1, 5 - len(anchors))]
    hero = next((c for c in cards if str(c.get("id", "")).startswith("day_")), picked[0] if picked else (cards[0] if cards else None))
    streak_card = _streak_card(streak, activity, day, lang)
    used = sorted({b for c in cards for b in c.get("bases", [c.get("basis")])} | ({"activity"} if (activity.completed or activity.seen) else set()))
    return {
        "greeting": greeting(bucket, lang),
        "hero": hero,
        "cards": cards,
        "streak": streak_card,
        "personalization": {"enabled": True, "used": used, "note": _on_note(lang)},
    }


def _streak_card(streak: int, activity: Activity, day: date, lang: str) -> dict:
    if not activity.completed:
        t = ("今天先做一件 1 分钟的小事就好，比如三次深呼吸", "Start with one one-minute thing today, like three deep breaths")
        return {"kind": "start", "days": 0, "text": t[0] if lang == "zh" else t[1]}
    last = max(at.date() for _, at in activity.completed)
    gap = (day - last).days
    if streak >= 3:
        return {"kind": "streak", "days": streak,
                "text": f"已经连续 {streak} 天做小行动，保持这个节奏就好" if lang == "zh" else f"{streak} days in a row. Keep that pace."}
    if gap >= 3:
        return {"kind": "welcome_back", "days": 0,
                "text": f"欢迎回来，隔了 {gap} 天，今天从最轻的一件开始" if lang == "zh" else f"Welcome back after {gap} days. Start with the lightest one."}
    return {"kind": "steady", "days": streak,
            "text": "今天再做一件小行动就很好" if lang == "zh" else "One more small action today is plenty."}


def _on_note(lang: str) -> str:
    return ("这些建议根据你自己填写的目标、地区和你在应用里的操作生成，只是生活方式提示，不是诊断或治疗建议。可在设置里关闭个性化。"
            if lang == "zh" else
            "These tips use only what you entered and did in the app. They are lifestyle ideas, not medical advice. You can turn personalisation off in settings.")


def _off_note(lang: str) -> str:
    return "个性化已关闭，显示通用提示。" if lang == "zh" else "Personalisation is off; showing general tips."


def forbidden_hits(text: str, lang: str) -> list:
    words = FORBIDDEN_ZH if lang == "zh" else FORBIDDEN_EN
    low = text.lower()
    return [w for w in words if w in low]
