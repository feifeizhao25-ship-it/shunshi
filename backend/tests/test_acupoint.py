"""
顺时 - 穴位端点测试
test_acupoint.py
"""

import pytest


class TestAcupointList:
    """穴位列表端点测试"""

    def test_list_returns_200(self, client):
        """GET /api/v1/acupoints/ 返回 200"""
        response = client.get("/api/v1/acupoints/")
        assert response.status_code == 200

    def test_list_has_data_key(self, client):
        """响应包含 'data' 键且有 'acupoints' 列表"""
        response = client.get("/api/v1/acupoints/")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "acupoints" in data["data"]
        assert isinstance(data["data"]["acupoints"], list)

    def test_list_filter_by_season_spring(self, client):
        """GET /api/v1/acupoints/?season=spring 返回 200，有穴位数据"""
        response = client.get("/api/v1/acupoints/?season=spring")
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]["acupoints"]) > 0

    def test_list_filter_by_season_winter(self, client):
        """GET /api/v1/acupoints/?season=winter 返回 200"""
        response = client.get("/api/v1/acupoints/?season=winter")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["season"] == "winter"

    def test_list_filter_by_constitution(self, client):
        """GET /api/v1/acupoints/?constitution=qi_deficiency 返回 200"""
        response = client.get("/api/v1/acupoints/?constitution=qi_deficiency")
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]["acupoints"]) > 0
        # 验证返回的穴位包含 ST36（足三里）
        acupoint_ids = [a["id"] for a in data["data"]["acupoints"]]
        assert "ST36" in acupoint_ids

    def test_list_limit_respected(self, client):
        """GET /api/v1/acupoints/?limit=3 最多返回 3 个穴位"""
        response = client.get("/api/v1/acupoints/?limit=3")
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]["acupoints"]) <= 3


class TestAcupointDaily:
    """每日推荐穴位端点测试"""

    def test_daily_returns_200(self, client):
        """GET /api/v1/acupoints/daily 返回 200"""
        response = client.get("/api/v1/acupoints/daily")
        assert response.status_code == 200

    def test_daily_north_hemisphere(self, client):
        """GET /api/v1/acupoints/daily?hemisphere=north 包含穴位列表"""
        response = client.get("/api/v1/acupoints/daily?hemisphere=north")
        assert response.status_code == 200
        data = response.json()
        assert "acupoints" in data["data"]
        assert isinstance(data["data"]["acupoints"], list)

    def test_daily_south_hemisphere(self, client):
        """GET /api/v1/acupoints/daily?hemisphere=south 返回 200"""
        response = client.get("/api/v1/acupoints/daily?hemisphere=south")
        assert response.status_code == 200
        data = response.json()
        assert "season" in data["data"]

    def test_daily_with_constitution(self, client):
        """GET /api/v1/acupoints/daily?constitution=yin_deficiency 返回 200"""
        response = client.get("/api/v1/acupoints/daily?constitution=yin_deficiency")
        assert response.status_code == 200
        data = response.json()
        assert "acupoints" in data["data"]


class TestAcupointDetail:
    """穴位详情端点测试"""

    def test_get_st36(self, client):
        """GET /api/v1/acupoints/ST36 返回 200，id 为 ST36"""
        response = client.get("/api/v1/acupoints/ST36")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == "ST36"
        assert data["data"]["name"] == "足三里"

    def test_get_li4(self, client):
        """GET /api/v1/acupoints/LI4 返回 200"""
        response = client.get("/api/v1/acupoints/LI4")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["id"] == "LI4"

    def test_unknown_returns_404(self, client):
        """GET /api/v1/acupoints/UNKNOWN 返回 404"""
        response = client.get("/api/v1/acupoints/UNKNOWN")
        assert response.status_code == 404


class TestAcupointConstitution:
    """体质穴位方案端点测试"""

    def test_constitution_qi_deficiency(self, client):
        """GET /api/v1/acupoints/constitution/qi_deficiency 返回 200"""
        response = client.get("/api/v1/acupoints/constitution/qi_deficiency")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["constitution"] == "qi_deficiency"

    def test_constitution_has_plan(self, client):
        """响应数据包含 'plan' 键"""
        response = client.get("/api/v1/acupoints/constitution/qi_deficiency")
        assert response.status_code == 200
        data = response.json()
        assert "plan" in data["data"]
        assert "morning" in data["data"]["plan"]
        assert "evening" in data["data"]["plan"]

    def test_unknown_constitution_404(self, client):
        """GET /api/v1/acupoints/constitution/invalid_type 返回 404"""
        response = client.get("/api/v1/acupoints/constitution/invalid_type")
        assert response.status_code == 404
