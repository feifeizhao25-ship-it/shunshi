"""N01/N04：国际版请求（X-App-Market: global）的内容类接口不返回中文，危机资源按地区给核验过的热线。"""
import re

import pytest

CJK = re.compile(r"[\u4e00-\u9fff]")
GL = {"X-App-Market": "global", "Accept-Language": "en-US"}


@pytest.fixture()
def c(client, auth_headers):
    client.headers.update(auth_headers)
    return client


def _no_cjk(r):
    assert r.status_code == 200, (r.request.url, r.status_code, r.text[:200])
    assert not CJK.search(r.text), (str(r.request.url), CJK.findall(r.text)[:10])


@pytest.mark.parametrize("path", [
    "/api/v1/solar-terms", "/api/v1/solar-terms/current", "/api/v1/solar-terms/today",
    "/api/v1/solar-terms/upcoming", "/api/v1/solar-terms/schedule", "/api/v1/solar-terms/notifications",
    "/api/v1/library/feed", "/api/v1/library/entries", "/api/v1/library/preferences",
    "/api/v1/meditation/library", "/api/v1/mental/meditation-guides", "/api/v1/mental/crisis-resources",
    "/api/v1/journal/entries/me", "/api/v1/gamification/me",
])
def test_global_response_has_no_chinese(c, path):
    r = c.get(path, headers=GL)
    if path.endswith("/entries/me"):
        uid = c.get("/api/v1/gamification/me", headers=GL).json()
        uid = (uid.get("data") or uid).get("user_id") or "me"
        r = c.get(f"/api/v1/journal/entries/{uid}", headers=GL)
    _no_cjk(r)


def test_cn_solar_terms_still_chinese(c):
    r = c.get("/api/v1/solar-terms/current")
    assert CJK.search(r.text)


def test_explicit_locale_param_wins(c):
    assert CJK.search(c.get("/api/v1/solar-terms/current?locale=zh-CN", headers=GL).text)


def test_global_library_is_an_honest_empty_state(c):
    f = c.get("/api/v1/library/feed", headers=GL).json()
    assert f["items"] == [] and f["available"] is False and "Chinese only" in f["note"]
    assert c.get("/api/v1/library/entries/anything", headers=GL).status_code == 404
    # 国内版不变
    assert c.get("/api/v1/library/entries").json()["entries"] is not None


@pytest.mark.parametrize("region,needle", [("US", "988"), ("GB", "116 123"), ("AU", "13 11 14"), ("NZ", "1737"), ("CA", "9-8-8")])
def test_crisis_resources_are_local_to_the_region(c, region, needle):
    r = c.get("/api/v1/mental/crisis-resources", headers={**GL, "X-Region": region}).json()["data"]
    assert needle in r["resources"][0]["contact"]
    assert "12356" not in str(r) and "120" not in r["crisis_hotlines"]["emergency"]


def test_crisis_resources_unknown_region_gives_directory_not_china_numbers(c):
    r = c.get("/api/v1/mental/crisis-resources", headers={**GL, "X-Region": "FR"}).json()["data"]
    assert r["resources"] == [] and "findahelpline.com" in r["crisis_hotlines"]["directory"]["url"]
    s = str(r)
    assert "12356" not in s and "120" not in s and "110" not in s.replace("1100", "")


def test_crisis_resources_cn_keeps_12356(c):
    r = c.get("/api/v1/mental/crisis-resources")
    assert "12356" in r.text
