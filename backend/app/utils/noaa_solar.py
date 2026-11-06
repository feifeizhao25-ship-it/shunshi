"""NOAA 风格的日出日落（公有领域算法，基于 Meeus，见 NOAA Solar Calculation Details）。

只计算太阳升起和落下的时刻，供 SEASONS「今日日照」对照。高纬度可能整日不升或不落。
分点、至点若要按半球换算，应使用 Skyfield；本模块不下载星历，也不改现有的季节判断。
"""

from __future__ import annotations

import math
from datetime import date, datetime, timedelta, timezone

# 官方日出常用的大气折射修正天顶角（度）。
OFFICIAL_ZENITH = 90.833


def _day_of_year(day: date) -> int:
    return int(day.strftime("%j"))


def sun_times(
    latitude: float,
    longitude: float,
    day: date,
    zenith: float = OFFICIAL_ZENITH,
) -> dict:
    """返回 UTC 的日出、日落。极昼或极夜时对应字段为 None，并带 status。"""
    n = _day_of_year(day)
    lng_hour = longitude / 15.0

    def _clock(approx_hour: float) -> datetime | None:
        t = n + ((approx_hour - lng_hour) / 24.0)
        m = math.radians((0.9856 * t) - 3.289)
        lon = math.degrees(m) + (1.916 * math.sin(m)) + (0.020 * math.sin(2 * m)) + 282.634
        lon %= 360.0
        lon_r = math.radians(lon)
        ra = math.degrees(math.atan(0.91764 * math.tan(lon_r)))
        ra %= 360.0
        lq = math.floor(lon / 90.0) * 90.0
        rq = math.floor(ra / 90.0) * 90.0
        ra = (ra + (lq - rq)) / 15.0
        sin_dec = 0.39782 * math.sin(lon_r)
        cos_dec = math.cos(math.asin(sin_dec))
        lat_r = math.radians(latitude)
        cos_h = (math.cos(math.radians(zenith)) - (sin_dec * math.sin(lat_r))) / (cos_dec * math.cos(lat_r))
        if cos_h > 1 or cos_h < -1:
            return None
        if approx_hour < 12:
            h = (360.0 - math.degrees(math.acos(cos_h))) / 15.0
        else:
            h = math.degrees(math.acos(cos_h)) / 15.0
        local = h + ra - (0.06571 * t) - 6.622
        ut = (local - lng_hour) % 24.0
        midnight = datetime(day.year, day.month, day.day, tzinfo=timezone.utc)
        return midnight + timedelta(hours=ut)

    sunrise = _clock(6)
    sunset = _clock(18)
    if sunrise is None and sunset is None:
        status = "polar_day_or_night"
    elif sunrise is None or sunset is None:
        status = "polar_edge"
    else:
        status = "ok"
    return {
        "date": day.isoformat(),
        "latitude": latitude,
        "longitude": longitude,
        "sunrise_utc": sunrise,
        "sunset_utc": sunset,
        "status": status,
        "method": "NOAA solar calculator (Meeus), public domain",
        "zenith": zenith,
    }


def day_length_hours(latitude: float, longitude: float, day: date) -> float | None:
    times = sun_times(latitude, longitude, day)
    rise, sett = times["sunrise_utc"], times["sunset_utc"]
    if rise is None or sett is None:
        return None
    hours = (sett - rise).total_seconds() / 3600.0
    if hours < 0:
        hours += 24.0
    return hours
