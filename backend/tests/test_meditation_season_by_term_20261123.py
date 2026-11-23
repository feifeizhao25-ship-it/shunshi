"""冥想库「当季推荐」按节气算季节（立冬起算冬），不按公历月份。"""
from datetime import date

from app.router import meditation_cn as m


def test_after_lidong_is_winter_not_autumn():
    # 2026 立冬 11-07；11-22 小雪。旧实现按月份把整个 11 月算成秋。
    assert m._current_season(date(2026, 11, 22)) == "winter"
    assert m._current_season(date(2026, 11, 8)) == "winter"


def test_before_lidong_is_still_autumn():
    assert m._current_season(date(2026, 11, 6)) == "autumn"


def test_lichun_starts_spring_not_march():
    # 2026 立春 02-04；按月份旧实现 2 月是冬。
    assert m._current_season(date(2026, 2, 10)) == "spring"
    assert m._current_season(date(2026, 2, 3)) == "winter"


def test_lixia_and_liqiu_boundaries():
    assert m._current_season(date(2026, 5, 10)) == "summer"   # 立夏 05-05
    assert m._current_season(date(2026, 8, 10)) == "autumn"   # 立秋 08-07
