"""2026 节气分钟：以紫台与香港天文台公布的分钟为准。

取整规则（与来源冲突时不投票给第三方站）：
- 紫金山天文台年历（SS-01）与香港天文台（SS-02 十二中气、SS-03 二十四节气）只公布到分钟，
  且彼此一致到分钟。
- 嵌入表里的 PyEphem 秒级结果只作交叉校验，写入 ``computed_beijing_time``。
- 对外使用的 ``beijing_time`` 取两台公布分钟，秒记为 00。不得把秒直接截断成分钟
  （大寒计算值 09:44:41 截断会变成 09:44）。也不得用「秒≥30 才进位」覆盖两台一致的公布分钟
  （大雪计算值 10:52:17 按四舍五入仍是 10:52，公布分钟是 10:53）。
- 第三方站的截断分钟不入库。
"""

from __future__ import annotations

import json
from datetime import datetime, timedelta
from pathlib import Path

OFFICIAL_PATH = Path(__file__).resolve().parents[1] / "self_improve" / "data" / "solar_terms_pmo_2026.json"

ROUNDING_RULE = (
    "2026 交节分钟以紫金山天文台年历与香港天文台公布值为准，两台一致到分钟。"
    "PyEphem 秒级结果保留在 computed_beijing_time，不截断、也不用秒的四舍五入覆盖公布分钟。"
    "例：大寒计算值 09:44:41 公布为 09:45；大雪计算值 10:52:17 公布为 10:53。"
)

# 十二中气（SS-02 覆盖的那一半）。节气名与紫台表相同的分钟。
ZHONGQI = ("大寒", "雨水", "春分", "谷雨", "小满", "夏至", "大暑", "处暑", "秋分", "霜降", "小雪", "冬至")

# 农历/节气回归允许读出的字段。宜忌、吉凶一类不得出现在返回值里。
SOLAR_LUNAR_FIELDS = ("solar_term", "lunar_month", "lunar_day")
FORBIDDEN_ALMANAC_FIELDS = ("宜", "忌", "吉", "凶", "yi", "ji", "jixiong")


def load_official() -> dict:
    return json.loads(OFFICIAL_PATH.read_text(encoding="utf-8"))


def official_minutes() -> dict[str, str]:
    """节气名 → ``YYYY-MM-DD HH:MM``（无秒）。"""
    terms = load_official()["terms"]
    if len(terms) != 24:
        raise ValueError("2026 官方节气表必须是 24 条")
    return dict(terms)


def zhongqi_minutes() -> dict[str, str]:
    """SS-02 十二中气，分钟必须与紫台全表相同。"""
    official = official_minutes()
    recorded = load_official().get("hko_zhongqi") or {}
    if set(recorded) != set(ZHONGQI):
        raise ValueError("hko_zhongqi 必须正好是十二中气")
    for name in ZHONGQI:
        if recorded[name] != official[name]:
            raise ValueError(f"中气 {name} 与紫台分钟不一致: {recorded[name]} vs {official[name]}")
    return dict(recorded)


def truncate_minute(computed: str) -> str:
    """把秒直接丢掉。这是被拒绝的取整方式，只用于回归对照。"""
    moment = datetime.fromisoformat(computed)
    return moment.strftime("%Y-%m-%d %H:%M")


def half_up_minute(computed: str) -> str:
    """秒≥30 进一分钟。不能覆盖两台公布值，只用于说明冲突。"""
    moment = datetime.fromisoformat(computed).replace(microsecond=0)
    if moment.second >= 30:
        moment = moment.replace(second=0) + timedelta(minutes=1)
    return moment.strftime("%Y-%m-%d %H:%M")


def published_beijing_time(official_minute: str) -> str:
    """公布分钟写入表时补 ``:00``，日期与钟点都来自天文台，不来自截断。"""
    moment = datetime.strptime(official_minute, "%Y-%m-%d %H:%M")
    return moment.strftime("%Y-%m-%d %H:%M:%S")


def apply_official_minutes(terms: list[dict]) -> list[dict]:
    """2026 年条目：保留计算秒，并把 beijing_time 改成公布分钟。其他年份不动。"""
    official = official_minutes()
    out = []
    for item in terms:
        row = dict(item)
        if str(row.get("date", "")).startswith("2026-") and row.get("name") in official:
            computed = row.get("computed_beijing_time") or row["beijing_time"]
            row["computed_beijing_time"] = computed
            row["beijing_time"] = published_beijing_time(official[row["name"]])
            row["minute_source"] = "SS-01+SS-02/SS-03"
        out.append(row)
    return out


def solar_lunar_fields_only(year: int, month: int, day: int) -> dict | None:
    """若安装了 lunar-python，只返回节气名与农历月日。读不到库时返回 None。

    不调用宜忌、吉神、凶煞等接口。
    """
    try:
        from lunar_python import Solar
    except ImportError:
        return None
    lunar = Solar.fromYmd(year, month, day).getLunar()
    term = lunar.getJieQi() or ""
    if not term:
        prev = lunar.getPrevJieQi(True)
        term = prev.getName() if prev is not None else ""
    payload = {
        "solar_term": term,
        "lunar_month": lunar.getMonth(),
        "lunar_day": lunar.getDay(),
    }
    if set(payload) != set(SOLAR_LUNAR_FIELDS):
        raise RuntimeError("节气回归返回了节气与农历日期以外的字段")
    return payload
