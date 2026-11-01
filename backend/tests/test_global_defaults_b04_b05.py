"""复测 B04 / B05。
B04：国际部署里「缺少 X-Region / Accept-Language / X-App-Market」的客户端（第三方、旧客户端、curl）拿到中文。
B05：套餐用量的重置说明写「00:00 Beijing time」，对海外用户不合适。"""
import re

from app.locale_context import default_market, resolve_locale
from app.services import chat_quota, usage_report

CJK = re.compile(r"[\u4e00-\u9fff]")


def test_no_headers_on_an_international_deployment_is_english(monkeypatch):
    monkeypatch.setenv("SHUNSHI_DEFAULT_MARKET", "global")
    loc = resolve_locale(None, None, None)
    assert loc.is_global and loc.lang == "en"


def test_no_headers_stays_domestic_by_default(monkeypatch):
    monkeypatch.delenv("SHUNSHI_DEFAULT_MARKET", raising=False)
    assert resolve_locale(None, None, None).market == "cn"
    monkeypatch.setenv("SHUNSHI_DEFAULT_MARKET", "bogus")
    assert default_market() == "cn"


def test_explicit_headers_still_win_over_the_deployment_default(monkeypatch):
    monkeypatch.setenv("SHUNSHI_DEFAULT_MARKET", "global")
    assert resolve_locale(None, "cn", None).market == "cn"
    assert resolve_locale("zh-CN", None, None).market == "cn"
    monkeypatch.setenv("SHUNSHI_DEFAULT_MARKET", "cn")
    assert resolve_locale("en-GB", None, None).market == "global"


def test_english_reset_copy_no_longer_pins_beijing_time():
    en, zh = chat_quota.MESSAGES["exhausted"][1], chat_quota.MESSAGES["exhausted"][0]
    assert "Beijing" not in en and "UTC" not in en and "time zone" in en
    assert "北京时间" in zh  # domestic edition keeps its own copy
    src = open(usage_report.__file__, encoding="utf-8").read()
    assert "Beijing time (16:00 UTC)" not in src and not CJK.search(
        "Daily limits reset once a day. See resets_at for the exact moment in your own time zone.")
