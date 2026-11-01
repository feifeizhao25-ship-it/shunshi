"""Growth kit (lite) tests, stdlib only."""
from datetime import date, datetime, timedelta

import pytest

from app.growth.kit import attribution, claims, referral, seo_quality, sharecard
from app.growth.kit.flags import GrowthFlags


def test_flags_default_off():
    f = GrowthFlags.from_env({})
    assert not (f.growth_loop or f.referral or f.sharecard or f.seo_pages)
    assert GrowthFlags.from_env({"GROWTH_LOOP_ENABLED": "1"}).growth_loop


def test_attribution_parses_and_drops_pii():
    r = attribution.parse_attribution("https://x.test/p?utm_source=Reddit&utm_medium=social&utm_campaign=Spring-2027&utm_term=jane@example.com&gclid=abc")
    assert r["utm_source"] == "reddit" and r["channel"] == "social" and r["has_click_id"] is True
    assert "utm_term" not in r and "gclid" not in str(r)
    assert attribution.parse_attribution("https://x.test/", "https://www.perplexity.ai/search?q=a")["channel"] == "ai_search"
    assert attribution.parse_attribution("https://x.test/", "https://www.google.com/")["channel"] == "organic_search"
    assert attribution.parse_attribution("not a url")["channel"] == "direct"
    assert attribution.parse_attribution("https://x.test/?utm_medium=cpc")["channel"] == "paid"


def test_tagged_url_rejects_pii():
    assert "utm_source=x" in attribution.build_tagged_url("https://a.test/p", "x", "social", "c1")
    with pytest.raises(ValueError):
        attribution.build_tagged_url("https://a.test/p", "me@a.com", "social", "c1")


def test_referral_codes_deterministic_and_secret_bound():
    a = referral.make_code("u1", b"k1"); assert a == referral.make_code("u1", b"k1") and a != referral.make_code("u1", b"k2")
    assert len(a) == 8 and set(a) <= set(referral.CODE_ALPHABET)
    with pytest.raises(ValueError):
        referral.make_code("u1", b"")


NOW = datetime(2026, 11, 20, 12, 0)


def _claim(**kw):
    base = dict(inviter_id="a", invitee_id="b", claimed_at=NOW - timedelta(days=20), invitee_created_at=NOW - timedelta(days=20), qualified_at=NOW - timedelta(days=16))
    base.update(kw)
    return referral.Claim(**base)


def test_referral_flow_and_abuse():
    pol = referral.Policy()
    h = referral.History()
    assert referral.evaluate(_claim(), h, pol, NOW).status == "release"
    assert referral.evaluate(_claim(qualified_at=None), h, pol, NOW).status == "pending"
    assert referral.evaluate(_claim(qualified_at=NOW - timedelta(days=3)), h, pol, NOW).reasons == ("hold_period",)
    assert referral.evaluate(_claim(invitee_id="a"), h, pol, NOW).reasons == ("self_referral",)
    assert referral.evaluate(_claim(), referral.History(paired={("a", "b")}), pol, NOW).reasons == ("duplicate_pair",)
    assert referral.evaluate(_claim(invitee_created_at=NOW - timedelta(days=400)), h, pol, NOW).reasons == ("invitee_not_new",)
    d = referral.evaluate(_claim(inviter_device_fp="x", invitee_device_fp="x"), h, pol, NOW)
    assert d.status == "review" and "shared_device" in d.reasons and d.inviter_units == 0
    assert referral.evaluate(_claim(), referral.History(claims_last_24h=99), pol, NOW).status == "review"
    assert referral.evaluate(_claim(), referral.History(rewarded_lifetime=50), pol, NOW).reasons == ("lifetime_cap",)


def test_claims_scan_and_language():
    assert claims.scan("This tea cures insomnia")
    assert claims.scan("保证收益，稳赚")
    assert not claims.scan("Seasonal habits for general wellness. Estimates only. Not investment advice. More text follows.")
    assert claims.is_english_only("Hello 24 solar terms") and not claims.is_english_only("你好")


def test_sharecard_en_zh_and_errors():
    ok = sharecard.build(sharecard.CardInput("en", "wellness", "Spring Equinox routine", "A gentle evening wind-down for the season.", "https://seasonsvip.com/solar-terms/chunfen"))
    assert not ok["errors"] and "utm_medium=social-organic" in ok["og"]["og:url"] and ok["disclaimer"].startswith("For general wellness")
    assert "english_only_violation" in sharecard.build(sharecard.CardInput("en", "wellness", "春分", "x", "https://a.test"))["errors"]
    zh = sharecard.build(sharecard.CardInput("zh", "energy", "储能电价政策更新", "本周各省分时电价变化摘要", "https://a.test/p"))
    assert not zh["errors"] and "不构成投资建议" in zh["text"]
    bad = sharecard.build(sharecard.CardInput("en", "wellness", "Cures anxiety fast", "ok", "https://a.test"))
    assert any(e.startswith("claim:medical") for e in bad["errors"])
    assert "title_too_long" in sharecard.build(sharecard.CardInput("en", "culture", "x" * 80, "ok", "https://a.test"))["errors"]


BODY = ("Seasonal sleep routines for the Spring Equinox explain how day length changes and which gentle habits people use to wind down. " * 12)


def test_seo_gate_publish_and_holds():
    page = seo_quality.PageDraft("https://a.test/p", "en", "spring equinox sleep routine", "Spring Equinox sleep routine", BODY,
                                 [{"url": "https://www.hko.gov.hk", "date": "2026-10-01"}], True, "Drafted with AI and reviewed by a person.")
    assert seo_quality.check(page, [], today=date(2026, 11, 1))["publish"]
    r = seo_quality.check(page, [BODY], today=date(2026, 11, 1)); assert "near_duplicate" in r["reasons"] and r["noindex"]
    thin = seo_quality.PageDraft("u", "en", "q", "q", "short", [], True, "")
    assert {"thin_content", "no_sources", "missing_ai_note"} <= set(seo_quality.check(thin, [], today=date(2026, 11, 1))["reasons"])
    stale = seo_quality.PageDraft("u", "en", "spring equinox sleep routine", "Spring Equinox sleep routine", BODY, [{"url": "https://a", "date": "2024-01-01"}], False)
    assert "source_stale" in seo_quality.check(stale, [], today=date(2026, 11, 1))["reasons"]
    zh = seo_quality.PageDraft("u", "zh", "春分 作息 怎么调整", "春分作息怎么调整", "春分前后昼夜等长，作息可以循序渐进地调整。" * 30, [{"url": "https://a", "date": "2026-10-20"}], True, "本文由 AI 辅助起草并经人工审阅。")
    assert seo_quality.check(zh, [], today=date(2026, 11, 1))["publish"]
    assert '"@type": "Article"' in seo_quality.article_jsonld(page, "2026-11-01", "Org")
