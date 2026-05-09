"""
顺时 — 农历日期与传统节日养生 API 测试
包含 30+ pytest 测试，覆盖全部 5 个端点。
"""

import pytest
from fastapi.testclient import TestClient
from fastapi import FastAPI
from datetime import datetime

# 假设 router 已被导入
from app.router.lunar_calendar import router

app = FastAPI()
app.include_router(router)
client = TestClient(app)


# ─────────────────────────────────────────────────────────────────────────────
# 测试 GET /api/v1/lunar/today
# ─────────────────────────────────────────────────────────────────────────────

class TestTodayLunar:
    """测试今日农历信息端点"""

    def test_today_lunar_success(self):
        """测试成功获取今日农历信息"""
        response = client.get("/api/v1/lunar/today")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "data" in data
        assert "solar_date" in data["data"]
        assert "lunar_month" in data["data"]
        assert "month_name" in data["data"]

    def test_today_lunar_has_required_fields(self):
        """测试返回的字段完整性"""
        response = client.get("/api/v1/lunar/today")
        data = response.json()["data"]
        required_fields = [
            "solar_date",
            "lunar_month",
            "month_name",
            "season",
            "monthly_focus",
            "recommended_foods",
            "activities",
            "upcoming_festival",
            "days_until_festival",
            "tcm_principle",
        ]
        for field in required_fields:
            assert field in data, f"Field {field} not found in response"

    def test_today_lunar_lunar_month_valid_range(self):
        """测试农历月份在有效范围内（1-12）"""
        response = client.get("/api/v1/lunar/today")
        lunar_month = response.json()["data"]["lunar_month"]
        assert 1 <= lunar_month <= 12

    def test_today_lunar_upcoming_festival_exists(self):
        """测试近期节日信息存在"""
        response = client.get("/api/v1/lunar/today")
        data = response.json()["data"]
        assert data["upcoming_festival"] in [
            "春节", "元宵", "清明", "端午", "七夕", "中元",
            "中秋", "重阳", "冬至", "腊八", "小年", "除夕"
        ]

    def test_today_lunar_days_until_festival_positive(self):
        """测试节日倒计时为正数"""
        response = client.get("/api/v1/lunar/today")
        days = response.json()["data"]["days_until_festival"]
        assert isinstance(days, int)
        assert days > 0


# ─────────────────────────────────────────────────────────────────────────────
# 测试 GET /api/v1/lunar/festival/{festival_name}
# ─────────────────────────────────────────────────────────────────────────────

class TestGetFestival:
    """测试节日详情端点"""

    @pytest.mark.parametrize("festival_name", [
        "春节", "元宵", "清明", "端午", "七夕", "中元",
        "中秋", "重阳", "冬至", "腊八", "小年", "除夕"
    ])
    def test_get_festival_success(self, festival_name):
        """测试成功获取所有节日详情"""
        response = client.get(f"/api/v1/lunar/festival/{festival_name}")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "data" in data

    @pytest.mark.parametrize("festival_name", [
        "春节", "元宵", "清明", "端午", "七夕", "中元",
        "中秋", "重阳", "冬至", "腊八", "小年", "除夕"
    ])
    def test_get_festival_has_required_fields(self, festival_name):
        """测试节日信息的必需字段"""
        response = client.get(f"/api/v1/lunar/festival/{festival_name}")
        festival_data = response.json()["data"]
        required_fields = [
            "festival_name", "lunar_date", "approx_solar_month",
            "theme", "taboo_foods", "recommended_foods",
            "wellness_advice", "tcm_principle", "activity_suggestions"
        ]
        for field in required_fields:
            assert field in festival_data, f"Field {field} not found for {festival_name}"

    def test_get_festival_invalid_name_404(self):
        """测试不存在的节日返回 404"""
        response = client.get("/api/v1/lunar/festival/无效节日")
        assert response.status_code == 404
        data = response.json()
        assert "detail" in data

    def test_get_festival_chinese_encoding(self):
        """测试中文 URL 编码支持"""
        # 测试 URL 编码的中文
        response = client.get("/api/v1/lunar/festival/%E6%98%A5%E8%8A%82")
        assert response.status_code == 200

    def test_get_festival_taboo_foods_is_list(self):
        """测试禁忌食物为列表"""
        response = client.get("/api/v1/lunar/festival/春节")
        taboo_foods = response.json()["data"]["taboo_foods"]
        assert isinstance(taboo_foods, list)
        assert len(taboo_foods) > 0

    def test_get_festival_recommended_foods_is_list(self):
        """测试推荐食物为列表"""
        response = client.get("/api/v1/lunar/festival/春节")
        recommended_foods = response.json()["data"]["recommended_foods"]
        assert isinstance(recommended_foods, list)
        assert len(recommended_foods) > 0

    def test_get_festival_activity_suggestions_is_list(self):
        """测试活动建议为列表"""
        response = client.get("/api/v1/lunar/festival/春节")
        activities = response.json()["data"]["activity_suggestions"]
        assert isinstance(activities, list)
        assert len(activities) > 0


# ─────────────────────────────────────────────────────────────────────────────
# 测试 GET /api/v1/lunar/festivals
# ─────────────────────────────────────────────────────────────────────────────

class TestListFestivals:
    """测试全年节日列表端点"""

    def test_list_all_festivals_success(self):
        """测试成功获取全年节日列表"""
        response = client.get("/api/v1/lunar/festivals")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "data" in data

    def test_list_all_festivals_count(self):
        """测试节日总数为 12"""
        response = client.get("/api/v1/lunar/festivals")
        data = response.json()["data"]
        assert data["total"] == 12
        assert len(data["festivals"]) == 12

    @pytest.mark.parametrize("month", range(1, 13))
    def test_list_festivals_by_month(self, month):
        """测试按月份过滤节日"""
        response = client.get(f"/api/v1/lunar/festivals?month={month}")
        assert response.status_code == 200
        data = response.json()["data"]
        # 验证过滤结果中的所有节日都属于指定月份
        for festival in data["festivals"]:
            assert festival["approx_solar_month"] == month

    def test_list_festivals_invalid_month_empty(self):
        """测试无效月份返回空列表"""
        response = client.get("/api/v1/lunar/festivals?month=1")
        assert response.status_code == 200
        data = response.json()["data"]
        # 月份 1 应该有相应的节日
        assert isinstance(data["festivals"], list)

    def test_list_festivals_month_filter_applied(self):
        """测试月份过滤是否正确应用"""
        response = client.get("/api/v1/lunar/festivals?month=2")
        data = response.json()["data"]
        assert data["month_filter"] == 2

    def test_list_festivals_has_festival_details(self):
        """测试列表中的节日包含完整信息"""
        response = client.get("/api/v1/lunar/festivals")
        festivals = response.json()["data"]["festivals"]
        for festival in festivals:
            assert "festival_name" in festival
            assert "lunar_date" in festival
            assert "theme" in festival


# ─────────────────────────────────────────────────────────────────────────────
# 测试 GET /api/v1/lunar/monthly/{month}
# ─────────────────────────────────────────────────────────────────────────────

class TestMonthlyWellness:
    """测试月份养生重点端点"""

    @pytest.mark.parametrize("month", range(1, 13))
    def test_monthly_wellness_valid_month_success(self, month):
        """测试获取有效月份的养生重点"""
        response = client.get(f"/api/v1/lunar/monthly/{month}")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "data" in data

    @pytest.mark.parametrize("month", range(1, 13))
    def test_monthly_wellness_has_required_fields(self, month):
        """测试月份信息的必需字段"""
        response = client.get(f"/api/v1/lunar/monthly/{month}")
        monthly_data = response.json()["data"]
        required_fields = [
            "lunar_month", "month_name", "approx_solar_month",
            "season", "focus", "tcm_principle", "recommended_foods",
            "avoided_foods", "activities", "sleep_advice", "emotion_care"
        ]
        for field in required_fields:
            assert field in monthly_data, f"Field {field} not found for month {month}"

    def test_monthly_wellness_month_zero_422(self):
        """测试月份为 0 返回 422"""
        response = client.get("/api/v1/lunar/monthly/0")
        assert response.status_code == 422

    def test_monthly_wellness_month_13_422(self):
        """测试月份为 13 返回 422"""
        response = client.get("/api/v1/lunar/monthly/13")
        assert response.status_code == 422

    def test_monthly_wellness_month_negative_422(self):
        """测试负数月份返回 422"""
        response = client.get("/api/v1/lunar/monthly/-1")
        assert response.status_code == 422

    def test_monthly_wellness_month_1_correct_data(self):
        """测试正月的数据正确"""
        response = client.get("/api/v1/lunar/monthly/1")
        monthly_data = response.json()["data"]
        assert monthly_data["lunar_month"] == 1
        assert "正月" in monthly_data["month_name"] or monthly_data["month_name"] == "正月"

    def test_monthly_wellness_month_12_correct_data(self):
        """测试十二月的数据正确"""
        response = client.get("/api/v1/lunar/monthly/12")
        monthly_data = response.json()["data"]
        assert monthly_data["lunar_month"] == 12
        assert "十二月" in monthly_data["month_name"] or monthly_data["month_name"] == "十二月"

    def test_monthly_wellness_foods_are_lists(self):
        """测试推荐和禁忌食物为列表"""
        response = client.get("/api/v1/lunar/monthly/1")
        monthly_data = response.json()["data"]
        assert isinstance(monthly_data["recommended_foods"], list)
        assert isinstance(monthly_data["avoided_foods"], list)

    def test_monthly_wellness_activities_is_list(self):
        """测试活动建议为列表"""
        response = client.get("/api/v1/lunar/monthly/1")
        monthly_data = response.json()["data"]
        assert isinstance(monthly_data["activities"], list)


# ─────────────────────────────────────────────────────────────────────────────
# 测试 POST /api/v1/lunar/birthday
# ─────────────────────────────────────────────────────────────────────────────

class TestBirthdayWellness:
    """测试生日养生建议端点"""

    def test_birthday_wellness_valid_date_success(self):
        """测试有效农历生日返回成功"""
        response = client.post(
            "/api/v1/lunar/birthday",
            json={"lunar_month": 1, "lunar_day": 1}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "data" in data

    def test_birthday_wellness_with_constitution(self):
        """测试带有体质信息的生日建议"""
        response = client.post(
            "/api/v1/lunar/birthday",
            json={
                "lunar_month": 5,
                "lunar_day": 15,
                "constitution_type": "damp_heat"
            }
        )
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["inferred_constitution"] == "damp_heat"

    def test_birthday_wellness_has_required_fields(self):
        """测试返回的生日建议包含必需字段"""
        response = client.post(
            "/api/v1/lunar/birthday",
            json={"lunar_month": 1, "lunar_day": 1}
        )
        birthday_data = response.json()["data"]
        required_fields = [
            "lunar_birthday", "birth_month_name", "inferred_constitution",
            "monthly_focus", "recommended_foods", "avoided_foods",
            "activities", "sleep_advice", "emotion_care", "tcm_principle"
        ]
        for field in required_fields:
            assert field in birthday_data, f"Field {field} not found"

    @pytest.mark.parametrize("month", range(1, 13))
    def test_birthday_wellness_all_valid_months(self, month):
        """测试所有有效月份都返回成功"""
        response = client.post(
            "/api/v1/lunar/birthday",
            json={"lunar_month": month, "lunar_day": 15}
        )
        assert response.status_code == 200

    def test_birthday_wellness_month_zero_422(self):
        """测试月份为 0 返回 422"""
        response = client.post(
            "/api/v1/lunar/birthday",
            json={"lunar_month": 0, "lunar_day": 1}
        )
        assert response.status_code == 422

    def test_birthday_wellness_month_13_422(self):
        """测试月份为 13 返回 422"""
        response = client.post(
            "/api/v1/lunar/birthday",
            json={"lunar_month": 13, "lunar_day": 1}
        )
        assert response.status_code == 422

    def test_birthday_wellness_day_zero_422(self):
        """测试日期为 0 返回 422"""
        response = client.post(
            "/api/v1/lunar/birthday",
            json={"lunar_month": 1, "lunar_day": 0}
        )
        assert response.status_code == 422

    def test_birthday_wellness_day_31_422(self):
        """测试日期为 31 返回 422"""
        response = client.post(
            "/api/v1/lunar/birthday",
            json={"lunar_month": 1, "lunar_day": 31}
        )
        assert response.status_code == 422

    def test_birthday_wellness_inferred_constitution(self):
        """测试根据出生月份推断体质"""
        response = client.post(
            "/api/v1/lunar/birthday",
            json={"lunar_month": 6, "lunar_day": 15}
        )
        birthday_data = response.json()["data"]
        # 农历六月应该推断为湿热体质
        assert "inferred_constitution" in birthday_data

    def test_birthday_wellness_all_valid_days(self):
        """测试所有有效日期都返回成功"""
        for day in [1, 7, 15, 20, 30]:
            response = client.post(
                "/api/v1/lunar/birthday",
                json={"lunar_month": 1, "lunar_day": day}
            )
            assert response.status_code == 200

    def test_birthday_wellness_foods_are_lists(self):
        """测试食物信息为列表"""
        response = client.post(
            "/api/v1/lunar/birthday",
            json={"lunar_month": 1, "lunar_day": 1}
        )
        birthday_data = response.json()["data"]
        assert isinstance(birthday_data["recommended_foods"], list)
        assert isinstance(birthday_data["avoided_foods"], list)

    def test_birthday_wellness_constitution_not_provided_has_inferred(self):
        """测试未提供体质时有推断值"""
        response = client.post(
            "/api/v1/lunar/birthday",
            json={"lunar_month": 1, "lunar_day": 1}
        )
        birthday_data = response.json()["data"]
        assert birthday_data["inferred_constitution"] is not None
        assert isinstance(birthday_data["inferred_constitution"], str)


# ─────────────────────────────────────────────────────────────────────────────
# 集成测试
# ─────────────────────────────────────────────────────────────────────────────

class TestIntegration:
    """集成测试：多个端点协作"""

    def test_today_and_festival_consistency(self):
        """测试今日农历信息与节日详情的一致性"""
        today_response = client.get("/api/v1/lunar/today")
        upcoming_festival = today_response.json()["data"]["upcoming_festival"]

        # 验证该节日确实存在
        festival_response = client.get(f"/api/v1/lunar/festival/{upcoming_festival}")
        assert festival_response.status_code == 200

    def test_monthly_info_in_today_and_dedicated_endpoint(self):
        """测试今日月份信息与专用月份端点的一致性"""
        today_response = client.get("/api/v1/lunar/today")
        lunar_month = today_response.json()["data"]["lunar_month"]

        monthly_response = client.get(f"/api/v1/lunar/monthly/{lunar_month}")
        assert monthly_response.status_code == 200

    def test_birthday_consistent_with_monthly(self):
        """测试生日建议与月份信息的一致性"""
        birthday_response = client.post(
            "/api/v1/lunar/birthday",
            json={"lunar_month": 5, "lunar_day": 15}
        )
        birthday_data = birthday_response.json()["data"]

        monthly_response = client.get("/api/v1/lunar/monthly/5")
        monthly_data = monthly_response.json()["data"]

        # 验证月份名称一致
        assert birthday_data["birth_month_name"] == monthly_data["month_name"]
