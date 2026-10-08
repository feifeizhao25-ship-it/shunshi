"""生成 24 节气日期表（北京时间），供后端与 App 共用。

做法：节气时刻 = 太阳视黄经到达 15° 整数倍的时刻（立春 315°、春分 0°、冬至 270°……），
用 PyEphem 离线计算（不联网、不下载星历），二分法求根到秒级，换算成北京时间（UTC+8，无夏令时）。

产物：
- backend/app/data/solar_terms.json            后端查表用（唯一数据源）
- android-cn/lib/core/solar_term/solar_term_table.dart   由同一份 JSON 生成的 Dart 常量
- ios-cn/lib/core/solar_term/solar_term_table.dart       同上
  （后端测试 tests/test_solar_term_calendar.py 会逐条核对两份 Dart 表与 JSON 完全一致）

用法（需要先 ``pip install ephem``，ephem 只在生成时需要，运行时不需要）：
    python backend/scripts/generate_solar_terms.py
"""

from __future__ import annotations

import datetime as dt
import json
import math
from pathlib import Path

import ephem

FIRST_YEAR = 2024
LAST_YEAR = 2035

# 一年内按公历顺序：小寒（1 月）……冬至（12 月）；后面是太阳视黄经（度）
TERMS = [
    ("小寒", 285), ("大寒", 300), ("立春", 315), ("雨水", 330), ("惊蛰", 345), ("春分", 0),
    ("清明", 15), ("谷雨", 30), ("立夏", 45), ("小满", 60), ("芒种", 75), ("夏至", 90),
    ("小暑", 105), ("大暑", 120), ("立秋", 135), ("处暑", 150), ("白露", 165), ("秋分", 180),
    ("寒露", 195), ("霜降", 210), ("立冬", 225), ("小雪", 240), ("大雪", 255), ("冬至", 270),
]

BEIJING = dt.timezone(dt.timedelta(hours=8))
REPO = Path(__file__).resolve().parents[2]
JSON_PATH = REPO / "backend" / "app" / "data" / "solar_terms.json"
DART_PATHS = [
    REPO / "android-cn" / "lib" / "core" / "solar_term" / "solar_term_table.dart",
    REPO / "ios-cn" / "lib" / "core" / "solar_term" / "solar_term_table.dart",
]


def apparent_longitude(when: float) -> float:
    """太阳视黄经（度，0–360）：含章动与光行差的「视」位置，黄道取当日春分点。"""
    date = ephem.Date(when)
    sun = ephem.Sun()
    sun.compute(date, epoch=date)
    ecl = ephem.Ecliptic(ephem.Equatorial(sun.ra, sun.dec, epoch=date), epoch=date)
    return math.degrees(float(ecl.lon)) % 360.0


def solve(target_deg: float, guess: dt.datetime) -> dt.datetime:
    """在 guess 前后 6 天内二分求太阳视黄经 = target 的时刻（UTC）。"""

    def offset(t: float) -> float:
        return (apparent_longitude(t) - target_deg + 180.0) % 360.0 - 180.0

    lo = ephem.Date(guess - dt.timedelta(days=6))
    hi = ephem.Date(guess + dt.timedelta(days=6))
    if not (offset(lo) < 0 < offset(hi)):
        raise RuntimeError(f"区间内没有根：{target_deg}° 于 {guess}")
    for _ in range(60):  # 12 天 / 2^60 远小于 1 秒
        mid = (lo + hi) / 2
        if offset(mid) < 0:
            lo = mid
        else:
            hi = mid
    utc = ephem.Date((lo + hi) / 2).datetime().replace(tzinfo=dt.timezone.utc)
    return utc


def rough_guess(year: int, index: int) -> dt.datetime:
    # 小寒约在 1 月 5–6 日，之后每个节气约隔 15.2 天
    return dt.datetime(year, 1, 6) + dt.timedelta(days=15.22 * index)


def compute(first_year: int = FIRST_YEAR, last_year: int = LAST_YEAR) -> list[dict]:
    items = []
    # 首年 1 月初还在上一年的冬至里，把上一年冬至也放进表，查表才完整
    plan = [(first_year - 1, 23)] + [(y, i) for y in range(first_year, last_year + 1) for i in range(24)]
    for year, index in plan:
        name, deg = TERMS[index]
        utc = solve(deg, rough_guess(year, index))
        bj = utc.astimezone(BEIJING)
        items.append({
            "name": name,
            "longitude": deg,
            "date": bj.strftime("%Y-%m-%d"),
            "beijing_time": bj.strftime("%Y-%m-%d %H:%M:%S"),
        })
    return items


def build_document(items: list[dict]) -> dict:
    return {
        "description": "24 节气交节日期（北京时间）。某天的节气 = 日期不晚于这一天的最后一个交节条目。",
        "method": "太阳视黄经每 15° 一个节气；PyEphem 离线计算，二分求根到秒，换算为北京时间（UTC+8）。",
        "generator": "backend/scripts/generate_solar_terms.py",
        "ephem_version": ephem.__version__,
        "timezone": "Asia/Shanghai（UTC+8）",
        "years": [FIRST_YEAR, LAST_YEAR],
        "note": "表中首条为上一年冬至，用来覆盖首年 1 月初。超出年份范围时调用方按最近一年的月日近似（后端）或回退到旧近似（App），需在 2035 年前重新生成。",
        "terms": items,
    }


def render_dart(items: list[dict]) -> str:
    lines = [
        "// 由 backend/scripts/generate_solar_terms.py 根据 backend/app/data/solar_terms.json 生成，请勿手改。",
        "// 后端测试 backend/tests/test_solar_term_calendar.py 逐条核对本文件与 JSON 一致。",
        "// 节气按太阳视黄经每 15° 天文计算，日期为北京时间。",
        "",
        "class SolarTermDate {",
        "  final String date; // yyyy-MM-dd，北京时间交节当天",
        "  final String name;",
        "  const SolarTermDate(this.date, this.name);",
        "}",
        "",
        "const List<SolarTermDate> kSolarTermTable = [",
    ]
    lines += [f"  SolarTermDate('{item['date']}', '{item['name']}')," for item in items]
    lines += [
        "];",
        "",
        "String _ymd(DateTime d) =>",
        "    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';",
        "",
        "/// 北京时间的今天（与手机时区无关）。",
        "DateTime beijingNow() => DateTime.now().toUtc().add(const Duration(hours: 8));",
        "",
        "/// 某一天（按其年月日）所处的节气；超出表的范围返回 null，调用方自行回退。",
        "String? solarTermNameOn(DateTime day) {",
        "  final key = _ymd(day);",
        "  if (key.compareTo(kSolarTermTable.first.date) < 0) return null;",
        "  if (key.compareTo('${kSolarTermTable.last.date.substring(0, 4)}-12-31') > 0) return null;",
        "  String? current;",
        "  for (final t in kSolarTermTable) {",
        "    if (t.date.compareTo(key) <= 0) {",
        "      current = t.name;",
        "    } else {",
        "      break;",
        "    }",
        "  }",
        "  return current;",
        "}",
        "",
        "/// 北京时间今天的节气；超出表的范围返回 null。",
        "String? currentSolarTermName() => solarTermNameOn(beijingNow());",
        "",
    ]
    return "\n".join(lines)


def main() -> None:
    items = compute()
    JSON_PATH.parent.mkdir(parents=True, exist_ok=True)
    JSON_PATH.write_text(json.dumps(build_document(items), ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    dart = render_dart(items)
    for path in DART_PATHS:
        if path.parent.parent.exists():  # lib/core 存在才写
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(dart, encoding="utf-8")
    print(f"写入 {len(items)} 条：{JSON_PATH}")


if __name__ == "__main__":
    main()
