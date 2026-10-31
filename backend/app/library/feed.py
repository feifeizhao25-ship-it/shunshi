"""「为你推荐」排序：纯函数，同样的输入得到同样的结果。

只用用户自己填写的和在应用里做过的事：目标、自选体质倾向（自评，不是诊断）、年龄段（未成年人不推饮食/体质/消费类）、
关注的主题、读过哪些；以及日历：节气、季节。没有地区专属的资料，所以不拿地区当推荐理由。
打分（加法，原因逐条写给用户看）：
  关注的主题 +5   目标匹配 +3   自选体质倾向 +3（体质类）   当前节气前后 3 天 +3 / 其余日子 +1（节气类）
  家人目标且条目针对儿童/老人 +2   读过同类 +1（上限 +2）   最近 14 天更新 +2 / 上次来访之后更新 +3（只对在意这个主题或看过旧版本的人）   上次来访之后新增 +2
  这条自己读过 -6（14 天内）   最近 3 天推荐过 -3、7 天内 -2   静音主题：不出现
"""

from __future__ import annotations

import hashlib
from dataclasses import dataclass, field
from datetime import date, timedelta
from typing import Optional

TOPICS = {
    "food": {"zh": "药食同源与食养", "en": "Food as medicine", "categories": ["药食同源"]},
    "move": {"zh": "运动健身", "en": "Movement", "categories": ["运动健身"]},
    "sleep": {"zh": "睡眠与情绪", "en": "Sleep & mood", "categories": ["睡眠与情绪"]},
    "season": {"zh": "节气与四季", "en": "Solar terms", "categories": ["节气"]},
    "body": {"zh": "体质调养", "en": "Constitution", "categories": ["体质"]},
    "buy": {"zh": "消费提醒", "en": "Buying tips", "categories": ["消费提醒"]},
}
CATEGORY_TOPIC = {c: t for t, v in TOPICS.items() for c in v["categories"]}
GOAL_TOPICS = {"sleep": ["sleep"], "breathing": ["sleep"], "mood": ["sleep"], "exercise": ["move"], "food": ["food", "buy"], "family": ["move"]}
GOAL_NAMES = {"sleep": "睡个好觉", "breathing": "放松减压", "exercise": "白天更有精神", "family": "照顾家人", "mood": "好心情", "food": "吃得舒服"}
MINOR_BLOCK = {"food", "body", "buy"}  # 未成年人不推送的主题
AUDIENCE_TAGS = {"child": ("儿童", "青少年"), "senior": ("老年人", "老人")}
RECENT_UPDATE_DAYS = 14


@dataclass
class Signals:
    lang: str = "zh"
    enabled: bool = True
    goals: frozenset = frozenset()
    constitution: Optional[str] = None
    season: str = "autumn"
    term: Optional[str] = None
    days_since_term: Optional[int] = None
    age_group: Optional[str] = None  # 'minor' | 'adult' | None
    followed: frozenset = frozenset()
    muted: frozenset = frozenset()
    opened: dict = field(default_factory=dict)   # entry_id -> date last opened
    shown: dict = field(default_factory=dict)    # entry_id -> date last shown in a feed
    last_visit: Optional[date] = None


def topic_of(entry: dict) -> str:
    return CATEGORY_TOPIC.get(entry.get("category", ""), "other")


def audience_of(entry: dict) -> set:
    tags = set(entry.get("tags", []))
    return {k for k, words in AUDIENCE_TAGS.items() if tags & set(words)}


def _noise(user_key: str, day: date, eid: str) -> float:
    h = hashlib.sha256(f"{user_key}|{day.isoformat()}|{eid}".encode()).digest()
    return int.from_bytes(h[:4], "big") / 2**32 * 0.9


def topic_list(sig: Signals) -> list:
    return [{"id": k, "name": v[sig.lang], "followed": k in sig.followed, "muted": k in sig.muted} for k, v in TOPICS.items()]


def _reason(parts: list, lang: str) -> str:
    zh = {"follow": lambda v: f"你关注了「{TOPICS[v]['zh']}」", "goal": lambda v: f"你选的目标：{GOAL_NAMES[v]}",
          "cons": lambda v: f"你自己选的体质倾向：{v}（自评，不是诊断）", "term": lambda v: f"现在是{v}前后",
          "season": lambda v: f"现在是{v}", "family": lambda v: "你想照顾家人", "read": lambda v: "你读过同类内容",
          "updated": lambda v: "最近有更新", "new": lambda v: "上次来之后新增的"}
    if not parts:
        return "今天的通用参考"
    return "；".join(zh[k](v) for k, v in parts)


def score(entry: dict, sig: Signals, topic_by_id: dict) -> tuple[float, list, list]:
    t = topic_of(entry)
    s, parts, codes = 0.0, [], []
    if t in sig.followed:
        s += 5; parts.append(("follow", t)); codes.append("follow")
    for g in sorted(sig.goals):
        if t in GOAL_TOPICS.get(g, []):
            s += 3; parts.append(("goal", g)); codes.append("goal"); break
    aud = audience_of(entry)
    if "family" in sig.goals and aud:
        s += 2; parts.append(("family", "")); codes.append("family")
    if t == "body" and sig.constitution:
        s += 3; parts.append(("cons", sig.constitution)); codes.append("constitution")
    if t == "season" and sig.term:
        if sig.days_since_term is not None and sig.days_since_term <= 3:
            s += 3; parts.append(("term", sig.term)); codes.append("term")
        else:
            s += 1; parts.append(("season", {"spring": "春季", "summer": "夏季", "autumn": "秋季", "winter": "冬季"}[sig.season])); codes.append("season")
    # 读过同类（别的条目、同主题）
    same_topic_reads = sum(1 for oid in sig.opened if oid != entry["id"] and topic_by_id.get(oid) == t)
    if same_topic_reads:
        s += min(2, same_topic_reads) * 1.0; parts.append(("read", "")); codes.append("read")
    return s, parts, codes


def rank(items: list[dict], sig: Signals, user_key: str, today: date, *, limit: int = 6) -> dict:
    """items：store.annotated() 的结果（每条带 display）。返回 {"items": [...], "enabled": bool}。"""
    if not sig.enabled:
        return {"items": [], "enabled": False}
    topic_by_id = {e["id"]: topic_of(e) for e in items}
    ref = sig.last_visit or (today - timedelta(days=14))
    out = []
    for e in items:
        d = e["display"]
        if not d["feed_eligible"]:
            continue
        t = topic_of(e)
        if t in sig.muted:
            continue
        if sig.age_group == "minor" and t in MINOR_BLOCK:
            continue
        s, parts, codes = score(e, sig, topic_by_id)
        badge = None
        appr, upd = _d(e.get("approved_at")), _d(e.get("updated_on"))
        # 「更新」只对在意这个主题的人、或者之前看过旧版本的人有意义；和他无关就不为它加分、不挂徽标
        relevant = s >= 3 or e["id"] in sig.shown or e["id"] in sig.opened
        if appr and appr > ref:
            badge = "new"; s += 2 if relevant else 1; parts.append(("new", "")); codes.append("new")
        elif upd and relevant and upd > ref:
            badge = "updated"; s += 3; parts.append(("updated", "")); codes.append("updated")
        elif upd and relevant and (today - upd).days <= RECENT_UPDATE_DAYS:
            s += 2; parts.append(("updated", "")); codes.append("updated")
        opened = sig.opened.get(e["id"])
        if opened and (today - opened).days <= 14 and badge != "updated":
            s -= 6
        shown = sig.shown.get(e["id"])
        if shown and shown < today:
            age = (today - shown).days
            s -= 3 if age <= 3 else 2 if age <= 7 else 0
        s += _noise(user_key, today, e["id"])
        out.append((s, e, parts, codes, badge, t))
    out.sort(key=lambda x: (-x[0], x[1]["id"]))
    items_out = []
    for s, e, parts, codes, badge, t in out[:limit]:
        src = e.get("source", {})
        items_out.append({
            "id": e["id"], "title": e["title"], "summary": e["summary"], "category": e["category"], "topic": t, "topic_name": TOPICS.get(t, {}).get(sig.lang, ""),
            "reason": _reason(parts, sig.lang), "reason_codes": codes, "badge": badge, "badges": d_badges(e), "change_note": e["display"]["change_note"],
            "last_verified_at": e["display"]["last_verified_at"], "updated_on": e.get("updated_on"), "status": e.get("status"),
            "source": {"title": src.get("title"), "publisher": src.get("publisher"), "url": src.get("url"), "doc_no": src.get("doc_no")}, "score": round(s, 2),
        })
    return {"items": items_out, "enabled": True}


def d_badges(e: dict) -> list:
    return e["display"]["badges"]


def _d(v) -> Optional[date]:
    from ..library_live.util import parse_day

    return parse_day(v)


def home_card(feed: dict, lang: str = "zh") -> Optional[dict]:
    """首页只放一张：有「新增/更新」或匹配度很高才出现，否则不打扰。"""
    its = feed.get("items") or []
    if not feed.get("enabled") or not its:
        return None
    pick = next((i for i in its if i["badge"]), None) or (its[0] if its[0]["score"] >= 5 else None)
    if not pick:
        return None
    title = f"资料库有更新：{pick['title']}" if pick["badge"] == "updated" else f"资料库新增：{pick['title']}" if pick["badge"] == "new" else f"为你选了一篇：{pick['title']}"
    return {"id": "library_for_you", "category": "library", "kind": "library", "title": title, "description": pick["summary"], "reason": pick["reason"],
            "basis": "library", "bases": ["library"], "href": "/reference-library", "entry_id": pick["id"]}
