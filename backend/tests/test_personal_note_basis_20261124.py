"""首页个性化说明只列真正用到的依据（问题 21）。"""
from app.services.personal_home import _on_note


def test_region_not_mentioned_when_not_used():
    note = _on_note("zh", ["day", "goal", "season", "solar_term", "time"])
    assert "地区" not in note
    assert "你填写的目标" in note and "节气" in note
    assert "不是诊断或治疗建议" in note and "关闭个性化" in note


def test_region_and_activity_listed_only_when_used():
    note = _on_note("zh", ["goal", "region", "activity", "reinforce"])
    assert "你所在的地区" in note
    assert note.count("你在应用里的操作") == 1


def test_empty_used_falls_back_to_calendar():
    assert "日期和节气" in _on_note("zh", [])


def test_english_note_unchanged():
    assert _on_note("en", ["region"]).startswith("These tips use only what you entered")
