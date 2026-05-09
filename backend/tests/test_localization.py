"""
测试：多语言本地化引擎
"""

import pytest
from fastapi.testclient import TestClient
from app.router.localization import router


@pytest.fixture
def client():
    """创建测试客户端。"""
    from fastapi import FastAPI
    app = FastAPI()
    app.include_router(router)
    return TestClient(app)


class TestGetTerms:
    """GET /terms 端点测试"""

    def test_get_terms_default_lang(self, client):
        """测试默认语言（英文）返回术语列表。"""
        response = client.get("/api/v1/localization/terms")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "total" in data["data"]
        assert "terms" in data["data"]
        assert len(data["data"]["terms"]) > 0

    def test_get_terms_multiple_languages(self, client):
        """测试多种语言的术语返回。"""
        languages = ["en", "ja", "ko", "es", "fr", "de", "zh-CN", "zh-TW"]
        for lang in languages:
            response = client.get(f"/api/v1/localization/terms?lang={lang}")
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True
            assert data["data"]["language"] == lang
            assert len(data["data"]["terms"]) > 0

    def test_get_terms_with_search_english(self, client):
        """测试英文搜索功能。"""
        response = client.get("/api/v1/localization/terms?lang=en&search=qi")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["total"] > 0

    def test_get_terms_with_search_chinese(self, client):
        """测试中文搜索功能。"""
        response = client.get("/api/v1/localization/terms?search=气")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["total"] > 0

    def test_get_terms_no_search_results(self, client):
        """测试无搜索结果情况。"""
        response = client.get("/api/v1/localization/terms?search=nonexistent_term_xyz")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["total"] == 0

    def test_get_terms_returns_chinese(self, client):
        """测试返回结果包含中文。"""
        response = client.get("/api/v1/localization/terms?lang=en")
        data = response.json()
        for term in data["data"]["terms"]:
            assert "chinese" in term
            assert "pinyin" in term


class TestGetTermDetail:
    """GET /terms/{term_id} 端点测试"""

    def test_get_term_detail_qi(self, client):
        """测试获取「气」术语详情。"""
        response = client.get("/api/v1/localization/terms/qi")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["term_id"] == "qi"
        assert data["data"]["chinese"] == "气"
        assert "definition_en" in data["data"]
        assert "cultural_context" in data["data"]

    def test_get_term_detail_yin_yang(self, client):
        """测试获取「阴阳」术语详情。"""
        response = client.get("/api/v1/localization/terms/yin_yang")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["term_id"] == "yin_yang"

    def test_get_term_detail_all_languages(self, client):
        """测试术语包含所有支持的语言翻译。"""
        response = client.get("/api/v1/localization/terms/constitution")
        data = response.json()
        term = data["data"]
        assert "english" in term
        assert "japanese" in term
        assert "korean" in term
        assert "spanish" in term
        assert "french" in term
        assert "german" in term

    def test_get_term_detail_invalid_term(self, client):
        """测试无效的术语 ID 返回 404。"""
        response = client.get("/api/v1/localization/terms/invalid_term_xyz")
        assert response.status_code == 404

    def test_get_term_detail_contains_misconception(self, client):
        """测试术语详情包含常见误解。"""
        response = client.get("/api/v1/localization/terms/qi")
        data = response.json()
        assert "common_misconception_en" in data["data"]
        assert len(data["data"]["common_misconception_en"]) > 0


class TestGetLanguages:
    """GET /languages 端点测试"""

    def test_get_languages_list(self, client):
        """测试获取语言列表。"""
        response = client.get("/api/v1/localization/languages")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "total_languages" in data["data"]
        assert "languages" in data["data"]
        assert data["data"]["total_languages"] > 0

    def test_get_languages_contains_completion(self, client):
        """测试语言列表包含完成度百分比。"""
        response = client.get("/api/v1/localization/languages")
        data = response.json()
        for lang in data["data"]["languages"]:
            assert "lang_code" in lang
            assert "name" in lang
            assert "completion_percentage" in lang
            assert 0 <= lang["completion_percentage"] <= 100

    def test_get_languages_includes_english(self, client):
        """测试语言列表包含英文。"""
        response = client.get("/api/v1/localization/languages")
        data = response.json()
        lang_codes = [l["lang_code"] for l in data["data"]["languages"]]
        assert "en" in lang_codes

    def test_get_languages_includes_chinese(self, client):
        """测试语言列表包含中文（简体和繁体）。"""
        response = client.get("/api/v1/localization/languages")
        data = response.json()
        lang_codes = [l["lang_code"] for l in data["data"]["languages"]]
        assert "zh-CN" in lang_codes
        assert "zh-TW" in lang_codes


class TestTranslate:
    """GET /translate 端点测试"""

    def test_translate_qi_to_japanese(self, client):
        """测试翻译「气」到日语。"""
        response = client.get("/api/v1/localization/translate?term=qi&to=ja")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["term"] == "Qi (Vital Energy)"
        assert data["data"]["translation"] == "気"

    def test_translate_to_multiple_languages(self, client):
        """测试翻译到多种语言。"""
        target_langs = ["en", "ja", "ko", "es", "fr", "de"]
        for lang in target_langs:
            response = client.get(f"/api/v1/localization/translate?term=yin_yang&to={lang}")
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True
            assert "translation" in data["data"]

    def test_translate_invalid_term(self, client):
        """测试无效术语返回 404。"""
        response = client.get("/api/v1/localization/translate?term=invalid_xyz&to=en")
        assert response.status_code == 404

    def test_translate_unsupported_language(self, client):
        """测试不支持的目标语言返回 400。"""
        response = client.get("/api/v1/localization/translate?term=qi&to=invalid_lang")
        assert response.status_code == 400

    def test_translate_chinese_to_english(self, client):
        """测试中文术语名到英文翻译。"""
        response = client.get("/api/v1/localization/translate?term=dampness&to=zh-CN")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_translate_missing_parameters(self, client):
        """测试缺少必需参数。"""
        response = client.get("/api/v1/localization/translate?term=qi")
        assert response.status_code == 422

        response = client.get("/api/v1/localization/translate?to=en")
        assert response.status_code == 422


class TestFormatDate:
    """POST /format-date 端点测试"""

    def test_format_date_english(self, client):
        """测试以英文格式化日期。"""
        payload = {"date": "2025-06-01", "lang": "en"}
        response = client.post("/api/v1/localization/format-date", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "formatted_date" in data["data"]

    def test_format_date_multiple_languages(self, client):
        """测试多种语言的日期格式。"""
        langs = ["en", "ja", "ko", "es", "fr", "de", "zh-CN"]
        for lang in langs:
            payload = {"date": "2025-06-01", "lang": lang}
            response = client.post("/api/v1/localization/format-date", json=payload)
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True

    def test_format_date_invalid_format(self, client):
        """测试无效的日期格式。"""
        payload = {"date": "06/01/2025", "lang": "en"}
        response = client.post("/api/v1/localization/format-date", json=payload)
        assert response.status_code == 400

    def test_format_date_missing_date(self, client):
        """测试缺少日期参数。"""
        payload = {"lang": "en"}
        response = client.post("/api/v1/localization/format-date", json=payload)
        assert response.status_code == 400

    def test_format_date_unsupported_language(self, client):
        """测试不支持的语言。"""
        payload = {"date": "2025-06-01", "lang": "unsupported_lang"}
        response = client.post("/api/v1/localization/format-date", json=payload)
        assert response.status_code == 404

    def test_format_date_default_language(self, client):
        """测试使用默认语言。"""
        payload = {"date": "2025-06-01"}
        response = client.post("/api/v1/localization/format-date", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True


class TestGetLocalizationConfig:
    """GET /config/{lang_code} 端点测试"""

    def test_get_config_english(self, client):
        """测试获取英文配置。"""
        response = client.get("/api/v1/localization/config/en")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["lang_code"] == "en"
        assert "date_format" in data["data"]
        assert "measurement_system" in data["data"]

    def test_get_config_all_languages(self, client):
        """测试获取所有支持语言的配置。"""
        languages = ["zh-CN", "zh-TW", "en", "ja", "ko", "es", "fr", "de", "th"]
        for lang in languages:
            response = client.get(f"/api/v1/localization/config/{lang}")
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True
            assert data["data"]["lang_code"] == lang

    def test_get_config_contains_measurement(self, client):
        """测试配置包含测量系统。"""
        response = client.get("/api/v1/localization/config/en")
        data = response.json()
        assert data["data"]["measurement_system"] in ["metric", "imperial"]
        assert data["data"]["temperature_unit"] in ["C", "F"]

    def test_get_config_unsupported_language(self, client):
        """测试不支持的语言返回 404。"""
        response = client.get("/api/v1/localization/config/invalid_lang")
        assert response.status_code == 404

    def test_get_config_different_date_formats(self, client):
        """测试不同语言的日期格式不同。"""
        en_response = client.get("/api/v1/localization/config/en")
        fr_response = client.get("/api/v1/localization/config/fr")
        assert en_response.json()["data"]["date_format"] != fr_response.json()["data"]["date_format"]

    def test_get_config_thai_basic_support(self, client):
        """测试泰语基础支持。"""
        response = client.get("/api/v1/localization/config/th")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["lang_code"] == "th"


class TestIntegration:
    """集成测试"""

    def test_search_and_get_detail(self, client):
        """测试搜索后获取详情。"""
        search_response = client.get("/api/v1/localization/terms?search=deficiency")
        search_data = search_response.json()
        assert search_data["data"]["total"] > 0

        term_id = search_data["data"]["terms"][0]["term_id"]
        detail_response = client.get(f"/api/v1/localization/terms/{term_id}")
        assert detail_response.status_code == 200

    def test_translate_and_verify_source(self, client):
        """测试翻译并验证源信息。"""
        response = client.get("/api/v1/localization/translate?term=qi&to=ko")
        data = response.json()
        assert data["data"]["chinese"] == "气"
        assert data["data"]["source_lang"] == "en"
        assert data["data"]["target_lang"] == "ko"

    def test_terms_cover_major_concepts(self, client):
        """测试术语库包含主要概念。"""
        concepts = ["qi", "yin_yang", "constitution", "meridian", "dampness"]
        for concept in concepts:
            response = client.get(f"/api/v1/localization/terms/{concept}")
            assert response.status_code == 200

    def test_all_term_translations_consistent(self, client):
        """测试所有术语翻译数据一致。"""
        response = client.get("/api/v1/localization/terms?lang=en")
        terms = response.json()["data"]["terms"]
        assert len(terms) >= 20  # 至少 20 个核心概念


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
