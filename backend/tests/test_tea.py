"""
顺时 — 茶饮方剂路由测试
覆盖 /api/v1/tea 全部端点
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch
from datetime import datetime

from app.main import app

client = TestClient(app)

# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/tea/  — 茶饮列表
# ─────────────────────────────────────────────────────────────────────────────

class TestTeaList:
    def test_list_all_returns_200(self):
        resp = client.get("/api/v1/tea/")
        assert resp.status_code == 200
        body = resp.json()
        assert body["success"] is True
        assert "data" in body
        assert "teas" in body["data"]
        assert len(body["data"]["teas"]) >= 6  # limit=6 by default

    def test_list_contains_required_fields(self):
        resp = client.get("/api/v1/tea/")
        teas = resp.json()["data"]["teas"]
        for tea in teas:
            assert "id" in tea
            assert "name" in tea
            assert "seasons" in tea
            assert "constitution_types" in tea
            assert "benefits" in tea

    def test_filter_by_season_spring(self):
        resp = client.get("/api/v1/tea/?season=spring")
        assert resp.status_code == 200
        teas = resp.json()["data"]["teas"]
        for tea in teas:
            assert "spring" in tea["seasons"] or "all" in tea["seasons"]

    def test_filter_by_season_winter(self):
        resp = client.get("/api/v1/tea/?season=winter")
        assert resp.status_code == 200
        teas = resp.json()["data"]["teas"]
        assert len(teas) >= 1

    def test_filter_by_constitution(self):
        resp = client.get("/api/v1/tea/?constitution=qi_deficiency")
        assert resp.status_code == 200
        body = resp.json()
        assert body["success"] is True

    def test_filter_by_benefit(self):
        resp = client.get("/api/v1/tea/?benefit=安神")
        assert resp.status_code == 200
        body = resp.json()
        assert body["success"] is True

    def test_filter_combined(self):
        resp = client.get("/api/v1/tea/?season=summer&constitution=yin_deficiency")
        assert resp.status_code == 200
        body = resp.json()
        assert "teas" in body["data"]

    def test_total_count_present(self):
        resp = client.get("/api/v1/tea/")
        body = resp.json()
        assert "total" in body["data"]
        assert body["data"]["total"] >= len(body["data"]["teas"])


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/tea/daily  — 今日推荐
# ─────────────────────────────────────────────────────────────────────────────

class TestTeaDaily:
    def test_daily_returns_200(self):
        resp = client.get("/api/v1/tea/daily")
        assert resp.status_code == 200
        body = resp.json()
        assert body["success"] is True

    def test_daily_contains_season(self):
        resp = client.get("/api/v1/tea/daily")
        data = resp.json()["data"]
        assert "season" in data
        assert data["season"] in ("spring", "summer", "autumn", "winter")

    def test_daily_contains_recommendations(self):
        resp = client.get("/api/v1/tea/daily")
        data = resp.json()["data"]
        assert "recommended_teas" in data
        assert len(data["recommended_teas"]) >= 1

    def test_daily_south_hemisphere(self):
        resp = client.get("/api/v1/tea/daily?hemisphere=south")
        assert resp.status_code == 200
        body = resp.json()
        assert body["success"] is True

    def test_daily_with_constitution(self):
        resp = client.get("/api/v1/tea/daily?constitution=blood_stasis")
        assert resp.status_code == 200
        body = resp.json()
        assert body["success"] is True

    def test_daily_has_date(self):
        resp = client.get("/api/v1/tea/daily")
        data = resp.json()["data"]
        assert "date" in data

    @patch("app.router.tea.datetime")
    def test_daily_summer_season(self, mock_dt):
        mock_dt.now.return_value = datetime(2025, 7, 15)
        resp = client.get("/api/v1/tea/daily")
        assert resp.status_code == 200


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/tea/constitution/{type}  — 体质茶饮方案
# ─────────────────────────────────────────────────────────────────────────────

class TestTeaConstitution:
    VALID_TYPES = [
        "qi_deficiency", "yang_deficiency", "yin_deficiency",
        "damp", "damp_heat", "blood_stasis",
        "qi_stagnation", "blood_deficiency", "balanced",
    ]

    def test_valid_constitution_types(self):
        for ctype in self.VALID_TYPES:
            resp = client.get(f"/api/v1/tea/constitution/{ctype}")
            assert resp.status_code == 200, f"Failed for {ctype}"
            body = resp.json()
            assert body["success"] is True

    def test_constitution_contains_plan(self):
        resp = client.get("/api/v1/tea/constitution/qi_deficiency")
        data = resp.json()["data"]
        assert "constitution" in data
        assert "teas" in data

    def test_unknown_constitution_returns_404(self):
        resp = client.get("/api/v1/tea/constitution/unknown_type")
        assert resp.status_code == 404

    def test_balanced_constitution_returns_teas(self):
        resp = client.get("/api/v1/tea/constitution/balanced")
        assert resp.status_code == 200
        data = resp.json()["data"]
        assert len(data["teas"]) >= 1

    def test_constitution_includes_description(self):
        resp = client.get("/api/v1/tea/constitution/yang_deficiency")
        data = resp.json()["data"]
        # Should have some description or guidance
        assert "constitution" in data


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/tea/benefits  — 功效列表
# ─────────────────────────────────────────────────────────────────────────────

class TestTeaBenefits:
    def test_benefits_returns_200(self):
        resp = client.get("/api/v1/tea/benefits")
        assert resp.status_code == 200
        body = resp.json()
        assert body["success"] is True

    def test_benefits_is_list(self):
        resp = client.get("/api/v1/tea/benefits")
        data = resp.json()["data"]
        assert "benefits" in data
        assert isinstance(data["benefits"], list)
        assert len(data["benefits"]) >= 5

    def test_benefits_contain_chinese(self):
        resp = client.get("/api/v1/tea/benefits")
        benefits = resp.json()["data"]["benefits"]
        # At least one benefit should contain Chinese characters
        chinese_found = any(
            any('\u4e00' <= c <= '\u9fff' for c in b)
            for b in benefits
        )
        assert chinese_found


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/tea/{tea_id}  — 茶饮详情
# ─────────────────────────────────────────────────────────────────────────────

class TestTeaDetail:
    KNOWN_IDS = [
        "chrysanthemum_goji", "rose_hawthorn", "astragalus_red_date",
        "lotus_heart_licorice", "ginger_brown_sugar", "poria_barley",
        "mint_lemon_balm", "solomon_seal_mulberry",
    ]

    def test_known_tea_ids(self):
        for tea_id in self.KNOWN_IDS:
            resp = client.get(f"/api/v1/tea/{tea_id}")
            assert resp.status_code == 200, f"Failed for {tea_id}"
            body = resp.json()
            assert body["success"] is True

    def test_detail_contains_brewing_guide(self):
        resp = client.get("/api/v1/tea/chrysanthemum_goji")
        data = resp.json()["data"]
        assert "brewing_guide" in data or "ingredients" in data

    def test_detail_contains_name(self):
        resp = client.get("/api/v1/tea/rose_hawthorn")
        data = resp.json()["data"]
        assert "name" in data
        assert len(data["name"]) > 0

    def test_detail_contains_tcm_info(self):
        resp = client.get("/api/v1/tea/ginger_brown_sugar")
        data = resp.json()["data"]
        # Should have TCM-related info
        assert "benefits" in data or "tcm" in data or "effects" in data

    def test_unknown_tea_id_returns_404(self):
        resp = client.get("/api/v1/tea/nonexistent_tea")
        assert resp.status_code == 404

    def test_detail_has_story_or_origin(self):
        """茶饮应有文化背景说明"""
        resp = client.get("/api/v1/tea/chrysanthemum_goji")
        data = resp.json()["data"]
        # cultural story could be in various fields
        has_story = any(k in data for k in ("story", "origin", "culture", "description"))
        assert has_story
