"""
顺时 - 生命周期引擎测试
test_lifecycle.py
"""

import pytest
from datetime import datetime
from app.services.lifecycle_engine import (
    LifecycleEngine, LifeStage, STAGE_CONFIGS, SEASONAL_ADJUSTMENTS,
)


@pytest.fixture
def engine():
    return LifecycleEngine()


class TestLifeStageDetection:
    """生命阶段检测测试"""

    def test_adolescence_12(self, engine):
        birth_year = datetime.now().year - 12
        assert engine.detect_life_stage(birth_year) == LifeStage.ADOLESCENCE

    def test_adolescence_15(self, engine):
        birth_year = datetime.now().year - 15
        assert engine.detect_life_stage(birth_year) == LifeStage.ADOLESCENCE

    def test_adolescence_18(self, engine):
        birth_year = datetime.now().year - 18
        assert engine.detect_life_stage(birth_year) == LifeStage.ADOLESCENCE

    def test_striving_19(self, engine):
        birth_year = datetime.now().year - 19
        assert engine.detect_life_stage(birth_year) == LifeStage.STRIVING

    def test_striving_25(self, engine):
        birth_year = datetime.now().year - 25
        assert engine.detect_life_stage(birth_year) == LifeStage.STRIVING

    def test_striving_30(self, engine):
        birth_year = datetime.now().year - 30
        assert engine.detect_life_stage(birth_year) == LifeStage.STRIVING

    def test_stable_31(self, engine):
        birth_year = datetime.now().year - 31
        assert engine.detect_life_stage(birth_year) == LifeStage.STABLE

    def test_stable_40(self, engine):
        birth_year = datetime.now().year - 40
        assert engine.detect_life_stage(birth_year) == LifeStage.STABLE

    def test_stable_45(self, engine):
        birth_year = datetime.now().year - 45
        assert engine.detect_life_stage(birth_year) == LifeStage.STABLE

    def test_mature_46(self, engine):
        birth_year = datetime.now().year - 46
        assert engine.detect_life_stage(birth_year) == LifeStage.MATURE

    def test_mature_55(self, engine):
        birth_year = datetime.now().year - 55
        assert engine.detect_life_stage(birth_year) == LifeStage.MATURE

    def test_mature_60(self, engine):
        birth_year = datetime.now().year - 60
        assert engine.detect_life_stage(birth_year) == LifeStage.MATURE

    def test_silver_61(self, engine):
        birth_year = datetime.now().year - 61
        assert engine.detect_life_stage(birth_year) == LifeStage.SILVER

    def test_silver_70(self, engine):
        birth_year = datetime.now().year - 70
        assert engine.detect_life_stage(birth_year) == LifeStage.SILVER

    def test_before_adolescence_falls_to_adolescence(self, engine):
        birth_year = datetime.now().year - 8
        assert engine.detect_life_stage(birth_year) == LifeStage.ADOLESCENCE


class TestStageConfig:
    """阶段配置测试"""

    def test_all_stages_have_config(self, engine):
        for stage in LifeStage:
            config = engine.get_stage_config(stage)
            assert config is not None
            assert "name" in config
            assert "age_range" in config
            assert "focus_areas" in config
            assert "health_priorities" in config

    def test_adolescence_config(self, engine):
        config = engine.get_stage_config(LifeStage.ADOLESCENCE)
        assert config["name"] == "青春期"
        assert "生长发育" in config["focus_areas"]

    def test_striving_config(self, engine):
        config = engine.get_stage_config(LifeStage.STRIVING)
        assert config["name"] == "奋斗期"
        assert "亚健康" in config["focus_areas"][0]

    def test_stable_config(self, engine):
        config = engine.get_stage_config(LifeStage.STABLE)
        assert config["name"] == "稳定期"

    def test_mature_config(self, engine):
        config = engine.get_stage_config(LifeStage.MATURE)
        assert config["name"] == "成熟期"

    def test_silver_config(self, engine):
        config = engine.get_stage_config(LifeStage.SILVER)
        assert config["name"] == "银发期"


class TestRecommendedContent:
    """阶段推荐内容测试"""

    def test_adolescence_recommended_types(self, engine):
        config = engine.get_stage_config(LifeStage.ADOLESCENCE)
        types = config["recommended_content_types"]
        assert "eye_care" in types
        assert "exercise" in types

    def test_striving_recommended_types(self, engine):
        config = engine.get_stage_config(LifeStage.STRIVING)
        types = config["recommended_content_types"]
        assert "stress_relief" in types
        assert "sleep" in types

    def test_silver_recommended_types(self, engine):
        config = engine.get_stage_config(LifeStage.SILVER)
        types = config["recommended_content_types"]
        assert "recipe" in types
        assert "acupoint" in types


class TestSeasonalAdjustment:
    """季节调整测试"""

    def test_known_solar_term(self, engine):
        result = engine.get_seasonal_adjustment(LifeStage.STRIVING, "立春")
        assert result["solar_term"] == "立春"
        assert "focus" in result
        assert "suggestions" in result
        assert len(result["suggestions"]) > 0

    def test_unknown_solar_term(self, engine):
        result = engine.get_seasonal_adjustment(LifeStage.STABLE, "未知节气")
        assert result["solar_term"] == "未知节气"
        assert result["suggestions"] == []

    def test_all_solar_terms_have_suggestions_for_striving(self, engine):
        adjustments = engine.get_all_seasonal_adjustments(LifeStage.STRIVING)
        assert len(adjustments) > 0
        for adj in adjustments:
            assert "solar_term" in adj
            assert "focus" in adj

    def test_seasonal_suggestions_vary_by_stage(self, engine):
        """不同阶段在同一节气应有不同建议"""
        adj_s = engine.get_seasonal_adjustment(LifeStage.STRIVING, "立春")
        adj_m = engine.get_seasonal_adjustment(LifeStage.MATURE, "立春")
        assert adj_s["suggestions"] != adj_m["suggestions"]


class TestUserProfileSummary:
    """用户画像摘要测试"""

    def test_summary_with_solar_term(self, engine):
        birth_year = 1990
        summary = engine.get_user_profile_summary(birth_year, solar_term="立春")
        assert "age" in summary
        assert "life_stage" in summary
        assert "stage_name" in summary
        assert "seasonal" in summary
        assert summary["seasonal"]["solar_term"] == "立春"

    def test_summary_without_solar_term(self, engine):
        birth_year = 1970
        summary = engine.get_user_profile_summary(birth_year)
        assert "seasonal" not in summary

    def test_summary_daily_rhythm(self, engine):
        birth_year = 1990
        summary = engine.get_user_profile_summary(birth_year)
        assert "daily_rhythm" in summary
        rhythm = summary["daily_rhythm"]
        assert "sleep" in rhythm
        assert "meals" in rhythm
        assert "exercise" in rhythm
