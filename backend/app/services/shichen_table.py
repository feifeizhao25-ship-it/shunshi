"""完整时辰养生表。

和国内首页十二时辰卡片是同一份白话：只写休息和吃饭。
允许名单就是这十二段。不在名单里的句子（包括旧接口里的「养心安神」）整段丢掉，不改写半句来凑。
药效、茶饮、剂量、经络名命中也丢掉。
孕期 / 哺乳期再按现有禁忌名单滤一遍，不改那些表。
"""

from __future__ import annotations

import re
from typing import Any

from .home_recommend import text_blocked_for_stage

# 和首页整页文案守卫同一类。补X 里「补充水分」这种白话留下。
_VISIBLE_EFFICACY = re.compile(
    r"补(?!充)[\u4e00-\u9fff]|滋[\u4e00-\u9fff]|益[\u4e00-\u9fff]"
    r"|健脾|理气|疏肝|安神|养心|通调|驱寒|暖胃|经活跃|精华|糟粕"
    r"|固精|润肠|通便|感冒|尤宜|引火归元|运化|清心导浊"
)
_DOSAGE = re.compile(r"\d+\s*(?:mg|ml|g|毫克|毫升|克|片|颗|枚|勺)", re.IGNORECASE)
_MERIDIAN_TERMS = (
    "经络",
    "经活跃",
    "当令",
    "胆经",
    "肝经",
    "肺经",
    "大肠经",
    "胃经",
    "脾经",
    "心经",
    "小肠经",
    "膀胱经",
    "肾经",
    "心包经",
    "三焦经",
    "养百脉",
)
def _span(start_end: str) -> str:
    start, end = start_end.split("-")
    return f"{start}:00 - {end}:00"


def _row(
    entry_id: str,
    name: str,
    span: str,
    period: str,
    principle: str,
    short: str,
    advice: str,
    quote: str,
    actions: tuple[tuple[str, str], ...],
) -> dict[str, Any]:
    return {
        "id": entry_id,
        "name": name,
        "time_range": _span(span),
        "period": period,
        "headline": f"{name} · {short}",
        "principle": principle,
        "principle_short": short,
        "advice": advice,
        "quote": quote,
        "actions": [{"title": title, "description": description} for title, description in actions],
    }


# 文案与 android-cn / ios-cn ultimate_home_page.dart 的 _shiChenList 相同。
SHICHEN_ENTRIES: tuple[dict[str, Any], ...] = (
    _row("zi", "子时", "23-1", "深夜", "该睡觉了", "早点睡", "把灯调暗，放下手机", "这个点适合睡觉。把灯调暗，手机放远一点，好好睡一觉。", (("准备睡觉", "把灯调暗，躺下休息。"), ("放下手机", "不再看屏幕，让自己慢慢睡着。"))),
    _row("chou", "丑时", "1-3", "凌晨", "继续睡觉", "接着睡", "夜还很长，接着睡", "夜还很长。继续睡，明天再处理事情。", (("继续睡觉", "这个点还早，接着睡。"), ("别看手机", "屏幕亮着容易醒，把手机扣过去。"))),
    _row("yin", "寅时", "3-5", "黎明", "再睡一会儿", "再睡会", "天还没亮，可以再躺一会儿", "天还没亮。醒了也没关系，再躺一会儿，不必马上起床。", (("接着躺着", "天没亮就再睡一会儿。"), ("慢一点起", "要起床的话，先坐一会儿再下床。"))),
    _row("mao", "卯时", "5-7", "清晨", "起床喝水", "喝温水", "起床后先喝一杯温水，再活动一下", "清晨起床后喝一杯温水，做几分钟舒展，给新的一天一个轻松的开始。", (("喝杯温水", "起床后先喝一杯温水。"), ("起来走走", "在屋里走几步，伸个懒腰。"))),
    _row("chen", "辰时", "7-9", "早上", "吃早餐", "吃早餐", "吃一顿温热、好消化的早餐", "这个点适合吃早餐。吃一顿温热、好消化的早餐，够上午用就好。", (("热粥面条", "可以吃热粥或热面条，坐下来吃完。"), ("先吃再出门", "上午要出门的话，先把早餐吃上。"))),
    _row("si", "巳时", "9-11", "上午", "慢慢吃午饭", "慢慢吃", "午饭细嚼慢咽，吃完走一走", "上午适合把要紧的事做一做。午饭时慢慢吃，别吃太快。", (("做手头事", "上午把要紧的事做一做。"), ("午饭慢吃", "细嚼慢咽，吃完出去走十分钟。"))),
    _row("wu", "午时", "11-13", "中午", "午饭后歇会儿", "歇一会", "午饭后闭眼歇一会儿", "午饭后可以闭眼歇一会儿，下午会舒服一些。", (("闭眼歇歇", "午饭后把手机放下，闭眼歇一会儿。"), ("坐着休息", "找个地方坐一会儿，不必一直忙。"))),
    _row("wei", "未时", "13-15", "午后", "饭后走走", "走一走", "午饭后走一走，小口喝点水", "午饭过后，出去走十分钟，回来小口喝点水。", (("午后散步", "午饭后出去走十分钟。"), ("补充水分", "午后记得小口多喝水。"))),
    _row("shen", "申时", "15-17", "下午", "起来活动", "活动下", "起来走一走，喝点温水", "下午容易犯困，起身活动几分钟、喝点温水，精神会好一些。", (("起来走走", "下午适合起来走一走。"), ("喝点温水", "喝点温水，少吃太咸的。"))),
    _row("you", "酉时", "17-19", "傍晚", "晚饭清淡", "清淡饭", "晚饭清淡一点，别吃得太晚", "傍晚喝点温水，晚饭清淡一些，别吃得太晚。", (("喝点温水", "晚饭前喝点温水。"), ("晚饭清淡", "晚饭少油少盐，吃完可以坐一会儿。"))),
    _row("xu", "戌时", "19-21", "晚上", "放松一下", "放松下", "听听音乐，和家里人说说话", "晚饭后适合歇下来。听听音乐，或者和家里人说说话。", (("听听音乐", "放点喜欢的音乐，把一天放下。"), ("少看屏幕", "少刷手机，让眼睛歇一会儿。"))),
    _row("hai", "亥时", "21-23", "夜间", "准备睡觉", "准备睡", "温水泡脚，然后放下手机", "睡前用温水泡泡脚，看一会儿书，然后放下手机准备睡。", (("温水泡脚", "睡前用温水泡泡脚，然后放下手机。"), ("看看书", "放下手机，看一会儿书再睡。"))),
)


def visible_text_has_efficacy(text: str) -> bool:
    return bool(text) and _VISIBLE_EFFICACY.search(text) is not None


def text_has_dosage(text: str) -> bool:
    return bool(text) and _DOSAGE.search(text) is not None


def text_has_meridian(text: str) -> bool:
    return bool(text) and any(term in text for term in _MERIDIAN_TERMS)


def text_unsafe(text: str) -> bool:
    """药效、茶饮、剂量、经络名。命中就整段不要。"""
    if not text:
        return False
    if visible_text_has_efficacy(text) or text_has_dosage(text) or text_has_meridian(text):
        return True
    return "茶" in text


def _strings(value: Any) -> list[str]:
    if isinstance(value, str):
        return [value]
    if isinstance(value, dict):
        out: list[str] = []
        for item in value.values():
            out.extend(_strings(item))
        return out
    if isinstance(value, list):
        out = []
        for item in value:
            out.extend(_strings(item))
        return out
    return []


def entry_blob(row: dict) -> str:
    return "".join(_strings(row))


def _public(row: dict) -> dict:
    actions = [
        {"title": action["title"], "description": action["description"]}
        for action in row["actions"]
    ]
    return {
        "id": row["id"],
        "name": row["name"],
        "time_range": row["time_range"],
        "period": row["period"],
        "headline": row["headline"],
        "principle": row["principle"],
        "principle_short": row["principle_short"],
        "advice": row["advice"],
        "quote": row["quote"],
        "actions": actions,
    }


def select_shichen_entries(life_stage: str | None, source: tuple[dict, ...] | None = None) -> list[dict]:
    """只留下允许名单里的十二时辰。文案必须和名单逐字相同，再说不清的阶段就丢掉。"""
    rows = SHICHEN_ENTRIES if source is None else source
    allowed = {row["id"]: row for row in SHICHEN_ENTRIES}
    picked: list[dict] = []
    seen: set[str] = set()
    for row in rows:
        entry_id = str(row.get("id") or "")
        canonical = allowed.get(entry_id)
        if canonical is None or entry_id in seen:
            continue
        blob = entry_blob(row)
        if blob != entry_blob(canonical):
            continue
        if text_unsafe(blob) or text_blocked_for_stage(blob, life_stage):
            continue
        seen.add(entry_id)
        picked.append(_public(canonical))
    order = [row["id"] for row in SHICHEN_ENTRIES]
    picked.sort(key=lambda row: order.index(row["id"]))
    return picked
