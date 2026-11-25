"""顺3：小雪不再对阴虚、湿热和孕期给出同一套温补主建议。"""
from app.router.solar_terms import SOLAR_TERMS, get_solar_term_by_name
from app.services.solar_audience import filter_solar_term


def _xiaoxue():
    return get_solar_term_by_name("小雪")


def test_unfiltered_xiaoxue_still_leads_with_warming_foods():
    term = _xiaoxue()
    assert term["suggestions"][0] == "温肾助阳"
    assert "羊肉" in term["foods"] and "桂圆" in term["foods"]


def test_yin_deficiency_xiaoxue_does_not_lead_with_warming():
    filtered = filter_solar_term(_xiaoxue(), constitution="阴虚")
    assert "温肾助阳" not in filtered["primary_suggestion"]
    assert "温肾助阳" not in " ".join(filtered["suggestions"])
    assert "温肾助阳" not in filtered["description"]
    blob = " ".join(filtered["foods"])
    assert "羊肉" not in blob and "桂圆" not in blob
    assert "银耳" in filtered["foods"]
    assert filtered["audience_notes"]
    assert "不是诊断" in filtered["audience_notes"][0]


def test_damp_heat_accepts_pinyin_and_full_name():
    for label in ("湿热", "湿热质", "shire"):
        filtered = filter_solar_term(_xiaoxue(), constitution=label)
        assert "温肾助阳" not in filtered["primary_suggestion"]
        assert "羊肉" not in filtered["foods"]


def test_pregnancy_gets_a_caution_and_drops_longan_and_lamb():
    filtered = filter_solar_term(_xiaoxue(), life_stage="孕期")
    assert any("孕期" in note and "产科医生" in note for note in filtered["audience_notes"])
    blob = " ".join(filtered["foods"])
    assert "桂圆" not in blob and "羊肉" not in blob


def test_child_and_medication_get_their_own_cautions():
    child = filter_solar_term(_xiaoxue(), life_stage="儿童")
    meds = filter_solar_term(_xiaoxue(), life_stage="正在服药")
    assert any("儿童" in note for note in child["audience_notes"])
    assert any("医生" in note for note in meds["audience_notes"])


def test_generic_term_is_unchanged_without_audience():
    original = _xiaoxue()
    filtered = filter_solar_term(original)
    assert filtered["foods"] == original["foods"]
    assert filtered["suggestions"] == original["suggestions"]
    assert filtered["audience_notes"] == []


def test_current_endpoint_filters_for_query(client):
    plain = client.get("/api/v1/solar-terms/current")
    assert plain.status_code == 200
    yin = client.get("/api/v1/solar-terms/current", params={"constitution": "阴虚"})
    assert yin.status_code == 200
    data = yin.json()["data"]
    # 只有当前真是小雪时，主建议才一定不含温肾助阳；其他节气也不得把温补词留在被过滤后的主建议里。
    if plain.json()["data"]["name"] == "小雪":
        assert data["suggestions"][0] != "温肾助阳"
        assert "羊肉" not in data["foods"] and "桂圆" not in data["foods"]
    assert "温肾助阳" not in (data.get("primary_suggestion") or "")
    assert data["audience_notes"]


def test_all_terms_remain_in_the_table():
    assert len(SOLAR_TERMS) == 24


def test_constitution_types_list_is_filled_and_marked_candidate(client):
    rows = client.get("/api/v1/constitution/types").json()
    assert len(rows) == 9
    for row in rows:
        assert row["characteristics"], row["type"]
        assert row["diet_recommendations"], row["type"]
        assert row["lifestyle_advice"], row["type"]
        assert row["diet_avoid"], row["type"]
        assert row["review_status"] == "待审核"
        assert "ZYYXH/T157-2009" in row["source"]
        assert "不是诊断" in row["source"]
