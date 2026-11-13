"""2026 节气时刻：紫金山天文台公布分钟为准，lunar-python 只交叉节气时刻。

相差超过 1 分钟，或公布分钟与紫台表不一致，就拦截。
不改写已公布的分钟，不读取黄历宜忌、吉凶或八字。
"""

from __future__ import annotations

from datetime import datetime

from .solar_term_calendar import TERM_NAMES, load_document
from .solar_term_publish import official_minutes

# lunar-python 的节气表里，跨年的那几个键有时是拼音。只用来对上中文节气名。
_PINYIN = {
    "XIAO_HAN": "小寒",
    "DA_HAN": "大寒",
    "LI_CHUN": "立春",
    "YU_SHUI": "雨水",
    "JING_ZHE": "惊蛰",
    "CHUN_FEN": "春分",
    "QING_MING": "清明",
    "GU_YU": "谷雨",
    "LI_XIA": "立夏",
    "XIAO_MAN": "小满",
    "MANG_ZHONG": "芒种",
    "XIA_ZHI": "夏至",
    "XIAO_SHU": "小暑",
    "DA_SHU": "大暑",
    "LI_QIU": "立秋",
    "CHU_SHU": "处暑",
    "BAI_LU": "白露",
    "QIU_FEN": "秋分",
    "HAN_LU": "寒露",
    "SHUANG_JIANG": "霜降",
    "LI_DONG": "立冬",
    "XIAO_XUE": "小雪",
    "DA_XUE": "大雪",
    "DONG_ZHI": "冬至",
}
MAX_DELTA_SECONDS = 60


class SolarTermBlocked(ValueError):
    def __init__(self, problems: list[str]):
        self.problems = problems
        super().__init__("节气核对未通过：" + "；".join(problems))


def lunar_term_times(year: int = 2026) -> dict[str, datetime]:
    """只取节气时刻。调用的是节气表。"""
    from lunar_python import Solar

    table = Solar.fromYmd(year, 6, 21).getLunar().getJieQiTable()
    found: dict[str, datetime] = {}
    for key, solar in table.items():
        name = key if key in TERM_NAMES else _PINYIN.get(key)
        if name not in TERM_NAMES:
            continue
        moment = datetime.strptime(solar.toYmdHms(), "%Y-%m-%d %H:%M:%S")
        if moment.year != year:
            continue
        found[name] = moment
    return found


def published_minutes_2026() -> dict[str, str]:
    """嵌入表里 2026 年的公布分钟，只读。"""
    out = {}
    for item in load_document()["terms"]:
        if str(item.get("date", "")).startswith("2026-"):
            out[item["name"]] = str(item["beijing_time"])[:16]
    return out


def crosscheck_2026(published: dict[str, str] | None = None, *, year: int = 2026) -> dict:
    """公布分钟必须与紫台相同；lunar-python 的时刻与紫台分钟相差不超过 1 分钟。

    不写回任何文件。不一致时抛出 SolarTermBlocked。
    """
    if year != 2026:
        raise SolarTermBlocked(["only_2026_table_is_checked"])
    official = official_minutes()
    lunar = lunar_term_times(2026)
    published = dict(published if published is not None else published_minutes_2026())
    problems: list[str] = []
    if set(official) != set(TERM_NAMES):
        problems.append("pmo_count")
    if set(lunar) != set(TERM_NAMES):
        missing = sorted(set(TERM_NAMES) - set(lunar))
        problems.append("lunar_missing:" + ",".join(missing))
    deltas: list[float] = []
    for name in TERM_NAMES:
        pmo = official.get(name, "")
        pub = str(published.get(name, ""))[:16]
        if pub != pmo:
            problems.append(f"published:{name}:{pub}!={pmo}")
        moment = lunar.get(name)
        if moment is None or not pmo:
            continue
        delta = abs((moment - datetime.strptime(pmo, "%Y-%m-%d %H:%M")).total_seconds())
        deltas.append(delta)
        if delta > MAX_DELTA_SECONDS:
            problems.append(f"lunar:{name}:{int(delta)}s")
    if problems:
        raise SolarTermBlocked(problems)
    return {
        "ok": True,
        "blocked": False,
        "n": 24,
        "year": 2026,
        "max_delta_seconds": max(deltas) if deltas else None,
        "authority": "紫金山天文台",
        "crosscheck": "lunar-python",
        "fields": "jieqi_time",
    }
