"""给用户看的唯一规则：什么叫「现行」，什么必须挂提示，什么绝不能显示。

顺序（先命中先生效）：
  未审核 -> pending（不显示）
  已废止 / 被取代 -> repealed（列表和推荐里都不出现；只有直接打开链接才看到「已废止」横幅）
  来源页出现废止迹象 -> repeal_hold（同上，核对完才恢复）
  征求意见稿 / 待核实 -> 显示，但带横幅，不当作现行，不推荐
  来源内容有变化（与审核时不一致） -> source_changed（显示，带横幅，不推荐）
  来源连续多次打不开 -> unverifiable（同上）
  距上次核对超过时限 -> review_due（同上）
  其余 -> current（显示「核对于 …」；近 30 天更新过的另显示「更新于 … + 变更说明」）
"""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from datetime import date
from typing import Optional

from .util import is_reviewed, parse_day, status_code

FAIL_LIMIT = 3
UPDATED_DAYS = 30

TEXT = {
    "zh": {
        "verified": "核对于 {d}", "updated": "更新于 {d}", "pending": "待审核",
        "repealed": "此条依据的文件已废止，只供查阅，不再适用。",
        "repeal_hold": "官方来源页出现「废止/失效」字样，正在人工核对，核对完成前不作为现行内容。",
        "draft": "这是征求意见稿，尚未生效，只供了解方向，请以正式文件为准。",
        "unverified": "这条的来源信息还在核实中，请以官方原文为准。",
        "source_changed": "官方来源近期有更新，本条内容还没有对照最新版本，请以官方原文为准。",
        "unverifiable": "暂时无法访问官方来源，本条无法确认是否仍是最新，请以官方原文为准。",
        "review_due": "已超过 {n} 天没有对照官方来源核对，请以官方原文为准。",
        "offline": "离线内容，核对于 {d}，联网后会自动更新。",
    },
    "en": {
        "verified": "Checked {d}", "updated": "Updated {d}", "pending": "Pending review",
        "repealed": "The document this entry relies on has been repealed. For reference only; it no longer applies.",
        "repeal_hold": "The official source page now mentions repeal or withdrawal. A person is checking it; until then this is not treated as current.",
        "draft": "This is a draft for consultation and is not in force. For direction only; rely on the final document.",
        "unverified": "The source details for this entry are still being verified. Please rely on the official text.",
        "source_changed": "The official source was updated recently and this entry has not been compared with the latest version. Please rely on the official text.",
        "unverifiable": "The official source cannot be reached right now, so we cannot confirm this is still the latest. Please rely on the official text.",
        "review_due": "It has been more than {n} days since this entry was checked against the official source. Please rely on the official text.",
        "offline": "Offline copy, checked {d}. It updates automatically when you are online.",
    },
}


@dataclass
class Decision:
    state: str
    visible: bool            # 在列表里出现
    feed_eligible: bool      # 可以被推荐 / 上首页卡片
    current: bool            # 可以当作「现行」展示
    banner: Optional[str] = None
    badges: list = field(default_factory=list)
    change_note: Optional[str] = None
    last_verified_at: Optional[str] = None
    updated_on: Optional[str] = None
    detail_reachable: bool = True

    def to_dict(self) -> dict:
        return asdict(self)


def effective_verified(entry: dict, st: Optional[dict]) -> Optional[date]:
    """人工核对日 与 自动核对（来源未变）日 中较晚的一个。"""
    days = [parse_day(entry.get("last_verified_at")), parse_day(entry.get("reviewed_at"))]
    if st and st.get("check") in ("ok", "minor_change"):
        days.append(parse_day(st.get("last_ok_at")))
    days = [d for d in days if d]
    return max(days) if days else None


def decide(entry: dict, st: Optional[dict], today: date, lang: str = "zh", *, ttl_default: int = 90,
           ttl_by_category: Optional[dict] = None, preview: bool = False) -> Decision:
    T = TEXT[lang]
    ver = effective_verified(entry, st)
    ver_s = ver.isoformat() if ver else None
    ttl = int(entry.get("ttl_days") or (ttl_by_category or {}).get(entry.get("category"), ttl_default))
    base = dict(last_verified_at=ver_s, updated_on=entry.get("updated_on"))
    if not is_reviewed(entry):
        return Decision("pending", preview, False, False, banner=T["pending"] if preview else None, **base)
    code = status_code(entry.get("status"))
    if code == "repealed" or entry.get("superseded_by"):
        return Decision("repealed", False, False, False, banner=T["repealed"], **base)
    check = (st or {}).get("check")
    if check == "repeal_signal":
        return Decision("repeal_hold", False, False, False, banner=T["repeal_hold"], **base)
    if code == "draft":
        return Decision("draft", True, False, False, banner=T["draft"], **base)
    if code == "unverified":
        return Decision("unverified", True, False, False, banner=T["unverified"], **base)
    if check == "changed":
        return Decision("source_changed", True, False, False, banner=T["source_changed"], **base)
    if check in ("url_broken", "unreachable", "refused") and int((st or {}).get("failures", 0)) >= FAIL_LIMIT:
        return Decision("unverifiable", True, False, False, banner=T["unverifiable"], **base)
    if ver is None or (today - ver).days > ttl:
        return Decision("review_due", True, False, False, banner=T["review_due"].format(n=ttl), **base)
    badges = [{"kind": "verified", "text": T["verified"].format(d=ver_s)}]
    upd = parse_day(entry.get("updated_on"))
    note = None
    if upd and 0 <= (today - upd).days <= UPDATED_DAYS:
        badges.append({"kind": "updated", "text": T["updated"].format(d=upd.isoformat())})
        note = entry.get("change_note")
    return Decision("current", True, True, True, badges=badges, change_note=note, **base)
