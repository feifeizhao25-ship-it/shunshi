"""
顺时 — 中国地区差异化养生建议 API 测试
包含 30+ pytest 测试，覆盖全部 5 个端点。
"""

import pytest
from fastapi.testclient import TestClient
from fastapi import FastAPI

# 假设 router 已被导入
from app.router.regional_wellness import router

app = FastAPI()
app.include_router(router)
client = TestClient(app)


# ─────────────────────────────────────────────────────────────────────────────
# 测试 GET /api/v1/regional/regions
# ─────────────────────────────────────────────────────────────────────────────

class TestListRegions:
    """测试所有区域列表端点"""

    def test_list_regions_success(self):
        """测试成功获取区域列表"""
        response = client.get("/api/v1/regional/regions")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "data" in data

    def test_list_regions_count(self):
        """测试返回 8 个区域"""
        response = client.get("/api/v1/regional/regions")
        data = response.json()["data"]
        assert data["total"] == 8
        assert len(data["regions"]) == 8

    def test_list_regions_all_regions_present(self):
        """测试所有预期的区域都存在"""
        response = client.get("/api/v1/regional/regions")
        regions = response.json()["data"]["regions"]
        region_codes = [r["region_code"] for r in regions]
        expected_codes = ["northeast", "north", "northwest", "east", "south", "central", "southwest", "tibet"]
        for code in expected_codes:
            assert code in region_codes

    def test_list_regions_has_required_fields(self):
        """测试每个区域都包含必需字段"""
        response = client.get("/api/v1/regional/regions")
        regions = response.json()["data"]["regions"]
        for region in regions:
            required_fields = [
                "region_code", "name", "provinces", "climate_type",
                "dominant_constitution", "seasonal_focus", "recommended_foods",
                "avoided_foods", "tcm_principle", "special_notes"
            ]
            for field in required_fields:
                assert field in region, f"Field {field} not found in region {region.get('region_code')}"

    def test_list_regions_provinces_is_list(self):
        """测试省份字段为列表"""
        response = client.get("/api/v1/regional/regions")
        regions = response.json()["data"]["regions"]
        for region in regions:
            assert isinstance(region["provinces"], list)
            assert len(region["provinces"]) > 0


# ─────────────────────────────────────────────────────────────────────────────
# 测试 GET /api/v1/regional/{region_code}
# ─────────────────────────────────────────────────────────────────────────────

class TestGetRegion:
    """测试区域详情端点"""

    @pytest.mark.parametrize("region_code", [
        "northeast", "north", "northwest", "east", "south", "central", "southwest", "tibet"
    ])
    def test_get_region_success(self, region_code):
        """测试获取所有有效区域的详情"""
        response = client.get(f"/api/v1/regional/{region_code}")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "data" in data

    @pytest.mark.parametrize("region_code", [
        "northeast", "north", "northwest", "east", "south", "central", "southwest", "tibet"
    ])
    def test_get_region_has_complete_info(self, region_code):
        """测试区域信息完整性"""
        response = client.get(f"/api/v1/regional/{region_code}")
        region = response.json()["data"]
        required_fields = [
            "region_code", "name", "provinces", "climate_type",
            "dominant_constitution", "seasonal_focus", "recommended_foods",
            "avoided_foods", "tcm_principle", "special_notes"
        ]
        for field in required_fields:
            assert field in region

    def test_get_region_invalid_code_404(self):
        """测试无效区域码返回 404"""
        response = client.get("/api/v1/regional/invalid_region")
        assert response.status_code == 404

    def test_get_region_northeast_details(self):
        """测试东北地区详情"""
        response = client.get("/api/v1/regional/northeast")
        region = response.json()["data"]
        assert region["region_code"] == "northeast"
        assert "黑龙江" in region["provinces"]
        assert "吉林" in region["provinces"]
        assert "辽宁" in region["provinces"]
        assert region["climate_type"] == "严寒干燥"

    def test_get_region_seasonal_focus_structure(self):
        """测试季节重点结构"""
        response = client.get("/api/v1/regional/northeast")
        region = response.json()["data"]
        seasonal_focus = region["seasonal_focus"]
        assert "spring" in seasonal_focus
        assert "summer" in seasonal_focus
        assert "autumn" in seasonal_focus
        assert "winter" in seasonal_focus

    def test_get_region_foods_are_lists(self):
        """测试食物字段为列表"""
        response = client.get("/api/v1/regional/east")
        region = response.json()["data"]
        assert isinstance(region["recommended_foods"], list)
        assert isinstance(region["avoided_foods"], list)
        assert len(region["recommended_foods"]) > 0
        assert len(region["avoided_foods"]) > 0


# ─────────────────────────────────────────────────────────────────────────────
# 测试 GET /api/v1/regional/{region_code}/seasonal
# ─────────────────────────────────────────────────────────────────────────────

class TestSeasonalWellness:
    """测试当季养生方案端点"""

    @pytest.mark.parametrize("region_code", [
        "northeast", "north", "northwest", "east", "south", "central", "southwest", "tibet"
    ])
    def test_seasonal_wellness_success(self, region_code):
        """测试获取所有区域的当季方案"""
        response = client.get(f"/api/v1/regional/{region_code}/seasonal")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "data" in data

    @pytest.mark.parametrize("region_code", [
        "northeast", "north", "northwest", "east", "south", "central", "southwest", "tibet"
    ])
    def test_seasonal_wellness_has_required_fields(self, region_code):
        """测试当季方案包含必需字段"""
        response = client.get(f"/api/v1/regional/{region_code}/seasonal")
        data = response.json()["data"]
        required_fields = [
            "region_code", "region_name", "current_season", "seasonal_focus",
            "climate_type", "dominant_constitution", "recommended_foods",
            "avoided_foods", "tcm_principle", "special_notes", "activity_suggestions"
        ]
        for field in required_fields:
            assert field in data

    def test_seasonal_wellness_invalid_region_404(self):
        """测试无效区域返回 404"""
        response = client.get("/api/v1/regional/invalid/seasonal")
        assert response.status_code == 404

    def test_seasonal_wellness_current_season_valid(self):
        """测试当前季节为有效值"""
        response = client.get("/api/v1/regional/northeast/seasonal")
        current_season = response.json()["data"]["current_season"]
        assert current_season in ["spring", "summer", "autumn", "winter"]

    def test_seasonal_wellness_has_seasonal_focus(self):
        """测试季节重点不为空"""
        response = client.get("/api/v1/regional/east/seasonal")
        seasonal_focus = response.json()["data"]["seasonal_focus"]
        assert isinstance(seasonal_focus, str)
        assert len(seasonal_focus) > 0

    def test_seasonal_wellness_activities_is_list(self):
        """测试活动建议为列表"""
        response = client.get("/api/v1/regional/south/seasonal")
        activities = response.json()["data"]["activity_suggestions"]
        assert isinstance(activities, list)
        assert len(activities) > 0


# ─────────────────────────────────────────────────────────────────────────────
# 测试 GET /api/v1/regional/province/{province_name}
# ─────────────────────────────────────────────────────────────────────────────

class TestGetRegionByProvince:
    """测试按省份查询端点"""

    @pytest.mark.parametrize("province", [
        "黑龙江", "吉林", "辽宁",  # 东北
        "北京", "天津", "河北", "山西", "内蒙古",  # 华北
        "陕西", "甘肃", "宁夏", "新疆", "青海",  # 西北
        "上海", "江苏", "浙江", "安徽", "福建", "江西",  # 华东
        "广东", "广西", "海南",  # 华南
        "湖北", "湖南", "河南",  # 华中
        "四川", "重庆", "云南", "贵州",  # 西南
        "西藏",  # 西藏
    ])
    def test_get_region_by_province_success(self, province):
        """测试查询所有有效省份"""
        response = client.get(f"/api/v1/regional/province/{province}")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "data" in data

    @pytest.mark.parametrize("province,expected_region", [
        ("黑龙江", "northeast"),
        ("江苏", "east"),
        ("广东", "south"),
        ("西藏", "tibet"),
    ])
    def test_get_region_by_province_mapping(self, province, expected_region):
        """测试省份到地区的映射正确"""
        response = client.get(f"/api/v1/regional/province/{province}")
        data = response.json()["data"]
        assert data["region_code"] == expected_region

    def test_get_region_by_province_invalid_404(self):
        """测试无效省份返回 404"""
        response = client.get("/api/v1/regional/province/无效省份")
        assert response.status_code == 404

    def test_get_region_by_province_has_region_info(self):
        """测试返回完整的地区信息"""
        response = client.get("/api/v1/regional/province/江苏")
        data = response.json()["data"]
        assert "province_name" in data
        assert "region_code" in data
        assert "region" in data
        assert data["province_name"] == "江苏"

    @pytest.mark.parametrize("province", [
        "黑龙江", "江苏", "广东", "四川", "西藏"
    ])
    def test_get_region_by_province_chinese_encoding(self, province):
        """测试中文省份名称 URL 编码支持"""
        # 使用百分比编码的中文
        from urllib.parse import quote
        encoded_province = quote(province)
        response = client.get(f"/api/v1/regional/province/{encoded_province}")
        assert response.status_code == 200


# ─────────────────────────────────────────────────────────────────────────────
# 测试 GET /api/v1/regional/{region_code}/constitution
# ─────────────────────────────────────────────────────────────────────────────

class TestGetRegionConstitution:
    """测试地区体质端点"""

    @pytest.mark.parametrize("region_code", [
        "northeast", "north", "east", "south"
    ])
    def test_get_region_constitution_success(self, region_code):
        """测试获取地区体质信息"""
        response = client.get(f"/api/v1/regional/{region_code}/constitution")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "data" in data

    @pytest.mark.parametrize("region_code", [
        "northeast", "north", "east", "south"
    ])
    def test_get_region_constitution_has_required_fields(self, region_code):
        """测试体质信息包含必需字段"""
        response = client.get(f"/api/v1/regional/{region_code}/constitution")
        data = response.json()["data"]
        assert "region_code" in data
        assert "dominant_constitution" in data
        assert "common_constitutions" in data or "adjustment_recommendations" in data

    def test_get_region_constitution_invalid_region_404(self):
        """测试无效地区返回 404"""
        response = client.get("/api/v1/regional/invalid_region/constitution")
        assert response.status_code == 404

    def test_get_region_constitution_northeast_yang_deficiency(self):
        """测试东北地区体质为阳虚"""
        response = client.get("/api/v1/regional/northeast/constitution")
        data = response.json()["data"]
        assert data["dominant_constitution"] == "阳虚"

    def test_get_region_constitution_east_damp_heat(self):
        """测试华东地区体质为湿热痰湿"""
        response = client.get("/api/v1/regional/east/constitution")
        data = response.json()["data"]
        assert "湿热" in data["dominant_constitution"]

    def test_get_region_constitution_south_damp_heat(self):
        """测试华南地区体质为湿热"""
        response = client.get("/api/v1/regional/south/constitution")
        data = response.json()["data"]
        assert data["dominant_constitution"] == "湿热"

    def test_get_region_constitution_profiles_is_list(self):
        """测试体质配置为列表"""
        response = client.get("/api/v1/regional/east/constitution")
        data = response.json()["data"]
        if "constitution_profiles" in data:
            assert isinstance(data["constitution_profiles"], list)


# ─────────────────────────────────────────────────────────────────────────────
# 集成测试
# ─────────────────────────────────────────────────────────────────────────────

class TestIntegration:
    """集成测试：多个端点协作"""

    def test_province_to_region_consistency(self):
        """测试省份查询与区域详情的一致性"""
        province_response = client.get("/api/v1/regional/province/江苏")
        region_code = province_response.json()["data"]["region_code"]

        region_response = client.get(f"/api/v1/regional/{region_code}")
        assert region_response.status_code == 200
        region = region_response.json()["data"]
        assert "江苏" in region["provinces"]

    def test_region_in_list_and_detail(self):
        """测试列表中的区域与详情端点一致"""
        list_response = client.get("/api/v1/regional/regions")
        regions_from_list = list_response.json()["data"]["regions"]
        northeast_from_list = next((r for r in regions_from_list if r["region_code"] == "northeast"), None)

        detail_response = client.get("/api/v1/regional/northeast")
        northeast_from_detail = detail_response.json()["data"]

        assert northeast_from_list["name"] == northeast_from_detail["name"]
        assert northeast_from_list["region_code"] == northeast_from_detail["region_code"]

    def test_seasonal_and_constitution_consistency(self):
        """测试当季方案与体质信息的一致性"""
        seasonal_response = client.get("/api/v1/regional/east/seasonal")
        seasonal_data = seasonal_response.json()["data"]

        constitution_response = client.get("/api/v1/regional/east/constitution")
        constitution_data = constitution_response.json()["data"]

        # 验证两者都提到了相同的地区
        assert seasonal_data["region_code"] == constitution_data["region_code"]

    def test_all_provinces_have_valid_region(self):
        """测试所有省份都能查询到有效的地区"""
        provinces = [
            "黑龙江", "吉林", "辽宁",
            "北京", "天津", "河北", "山西", "内蒙古",
            "陕西", "甘肃", "宁夏", "新疆", "青海",
            "上海", "江苏", "浙江", "安徽", "福建", "江西",
            "广东", "广西", "海南",
            "湖北", "湖南", "河南",
            "四川", "重庆", "云南", "贵州",
            "西藏",
        ]
        for province in provinces:
            response = client.get(f"/api/v1/regional/province/{province}")
            assert response.status_code == 200, f"Failed for province {province}"
            data = response.json()["data"]
            assert data["region_code"] is not None


# ─────────────────────────────────────────────────────────────────────────────
# 边界和错误测试
# ─────────────────────────────────────────────────────────────────────────────

class TestErrorHandling:
    """错误处理测试"""

    def test_invalid_region_code_format(self):
        """测试格式错误的区域码"""
        response = client.get("/api/v1/regional/123region")
        assert response.status_code == 404

    def test_case_sensitive_region_code(self):
        """测试区域码大小写敏感"""
        response = client.get("/api/v1/regional/NORTHEAST")
        assert response.status_code == 404

    def test_empty_region_code(self):
        """测试空区域码"""
        response = client.get("/api/v1/regional/")
        # 应该是 404 或其他错误，而不是 200
        assert response.status_code != 200

    def test_special_characters_in_province(self):
        """测试特殊字符省份名"""
        response = client.get("/api/v1/regional/province/!@#$")
        assert response.status_code == 404
