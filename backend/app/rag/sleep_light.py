"""作息与光照：只给时长、规律和白天见光、睡前减光。不写疾病收益，也不把 5 分钟研究说成 2 分钟。"""

from __future__ import annotations

import hashlib

from .claim_policy import two_minute_may_cite


def _stamp(row: dict) -> dict:
    stamped = dict(row)
    stamped["content_hash"] = hashlib.sha256(stamped["excerpt"].encode("utf-8")).hexdigest()
    return stamped

# 新入库的论文与官方页。复核人留空，状态待审核，不能单独支撑高风险结论。
SLEEP_LIGHT_SOURCES = tuple(_stamp(row) for row in (
    {
        "id": "SS-14",
        "title": "Recommended Amount of Sleep for a Healthy Adult",
        "publisher": "SLEEP / Watson et al. (AASM and SRS)",
        "doi": "10.5665/sleep.4716",
        "url": "https://doi.org/10.5665/sleep.4716",
        "published_at": "2015",
        "retrieved_at": "2026-11-06",
        "region": "INTL",
        "language": "en",
        "license": "期刊版权，引用即可",
        "excerpt": "AASM 与 SRS 联合共识：成年人规律睡眠不少于 7 小时。只用作息时长，不谈睡眠疾病。",
        "review_status": "待审核",
        "reviewer": "",
    },
    {
        "id": "SS-17",
        "title": "National Sleep Foundation's sleep time duration recommendations",
        "publisher": "Sleep Health / Hirshkowitz et al.",
        "doi": "10.1016/j.sleh.2014.12.010",
        "url": "https://doi.org/10.1016/j.sleh.2014.12.010",
        "published_at": "2015",
        "retrieved_at": "2026-11-06",
        "region": "INTL",
        "language": "en",
        "license": "期刊版权，引用即可",
        "excerpt": "NSF 按年龄段给出睡眠时长范围，作为时长的第二来源。不谈疾病。",
        "review_status": "待审核",
        "reviewer": "",
    },
    {
        "id": "SS-15",
        "title": "Recommendations for daytime, evening, and nighttime indoor light exposure",
        "publisher": "PLOS Biology / Brown et al.",
        "doi": "10.1371/journal.pbio.3001571",
        "url": "https://doi.org/10.1371/journal.pbio.3001571",
        "published_at": "2022",
        "retrieved_at": "2026-11-06",
        "region": "INTL",
        "language": "en",
        "license": "CC BY 4.0",
        "excerpt": "白天多见光、睡前减少亮光。具体照度数字未逐字核对，故不写入产品句子。",
        "review_status": "待审核",
        "reviewer": "",
    },
    {
        "id": "SE-06",
        "title": "About Sleep",
        "publisher": "US CDC",
        "url": "https://www.cdc.gov/sleep/about/index.html",
        "published_at": "2024-05-15",
        "retrieved_at": "2026-11-06",
        "region": "US",
        "language": "en",
        "license": "美国政府作品（公有领域）",
        "excerpt": "成人 18–60 岁每天不少于 7 小时；固定起床睡觉时间，睡前约 30 分钟离开屏幕。不转述页面上的健康收益清单。",
        "review_status": "待审核",
        "reviewer": "",
    },
    {
        "id": "SE-07",
        "title": "Sleep and tiredness",
        "publisher": "NHS",
        "url": "https://www.nhs.uk/live-well/sleep-and-tiredness/how-to-get-to-sleep/",
        "published_at": "",
        "retrieved_at": "2026-11-06",
        "region": "UK",
        "language": "en",
        "license": "Open Government Licence（需复核）",
        "excerpt": "英国市场的作息习惯参考。只保留习惯说法，不做医疗表述。",
        "review_status": "待审核",
        "reviewer": "",
    },
    {
        "id": "SE-08",
        "title": "Brief structured respiration practices enhance mood and reduce physiological arousal",
        "publisher": "Cell Reports Medicine / Balban et al.",
        "doi": "10.1016/j.xcrm.2022.100895",
        "url": "https://doi.org/10.1016/j.xcrm.2022.100895",
        "published_at": "2023",
        "retrieved_at": "2026-11-06",
        "region": "INTL",
        "language": "en",
        "license": "期刊版权，引用即可",
        "excerpt": "随机对照里的呼吸练习是每天 5 分钟。产品若写 2 分钟，不得把这项研究写成同等效果。",
        "review_status": "待审核",
        "reviewer": "",
        "not_equivalent_for_minutes": 2,
    },
))


def sleep_schedule_brief(lang: str) -> dict:
    """一句结论、三条依据、一个今日动作。依据里的新来源都是待审核。"""
    if lang == "en":
        brief = {
            "conclusion": "Keep a regular sleep schedule. Adults 18 to 60 are guided toward 7 or more hours.",
            "grounds": [
                "CDC duration: adults 18–60, 7 or more hours; 61–64, 7 to 9; 65 and older, 7 to 8.",
                "CDC and NHS habit lines: same bed and wake time, and screens off about 30 minutes before bed.",
                "AASM/SRS and the National Sleep Foundation also give duration ranges. Both are pending review.",
            ],
            "today_action": "Choose tomorrow's wake time now, and keep it even if tonight runs short.",
        }
    else:
        brief = {
            "conclusion": "成年人尽量把睡眠放在每天大约 7 至 8 小时，并尽量固定起床时间。",
            "grounds": [
                "《健康中国行动》把成人每日睡眠的倡导目标写为 7 至 8 小时，并提倡起居有常。这里不引用疾病风险。",
                "AASM 与睡眠研究会的共识是成年人规律睡眠不少于 7 小时。该条待审核。",
                "国家睡眠基金会按年龄给出时长范围，作为第二条时长来源。该条待审核。",
            ],
            "today_action": "今晚先定好明天的起床时间，到点就起来。",
        }
    brief["review_status"] = "待审核"
    brief["reviewer"] = ""
    brief["cites_disease"] = False
    return brief


def light_habit_brief(lang: str) -> dict:
    if lang == "en":
        conclusion = "Get daylight earlier in the day, and dim bright screens in the hour before bed."
        action = "Step outside for a few minutes this morning, and dim the bedroom lights before bed."
    else:
        conclusion = "白天尽早接触自然光，睡前一小时把亮屏调暗。"
        action = "今天早晨到户外站几分钟；睡前把卧室灯调暗。"
    return {
        "conclusion": conclusion,
        "grounds": [
            "Brown 等 2022 年的光照共识讨论白天、傍晚和夜间的室内光。具体照度尚未逐字核对，所以这里不写数字。",
            "作息来源只支持「规律时间」和「睡前减少亮光」，不支持疾病疗效。",
            "这条光照依据的状态是待审核，不能单独支撑高风险结论。",
        ],
        "today_action": action,
        "review_status": "待审核",
        "reviewer": "",
    }


def two_minute_calm_note(lang: str) -> dict:
    """两分钟的平静练习不引用 Balban 2023。"""
    note = (
        "A two-minute pause is a short habit. It is not the five-minute daily practice studied by Balban et al. (2023)."
        if lang == "en"
        else "两分钟只是一个很短的停顿，不能把它说成 Balban 等人 2023 年那项每天 5 分钟研究的同等效果。"
    )
    return {
        "text": note,
        "may_cite_balban_as_equivalent": False,
        "studied_source_citable_for_two_minutes": two_minute_may_cite("10.1016/j.xcrm.2022.100895"),
        "duration_minutes": 2,
        "studied_minutes": 5,
    }
