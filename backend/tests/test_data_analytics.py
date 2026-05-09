"""
测试数据分析模块
"""

import pytest
from fastapi.testclient import TestClient
from fastapi import FastAPI
from datetime import datetime, timedelta

# 模拟导入
from app.router import data_analytics

app = FastAPI()
app.include_router(data_analytics.router)
client = TestClient(app)


class TestEventRecord:
    """测试事件记录"""

    def test_record_valid_event(self):
        """记录有效事件"""
        payload = {
            "user_id": "user_001",
            "event_type": "checkin",
            "metadata": {"location": "home"},
        }
        resp = client.post("/api/v1/analytics/event", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert "event_id" in data["data"]
        assert data["data"]["recorded"] is True

    def test_record_all_event_types(self):
        """记录所有事件类型"""
        event_types = ["checkin", "food_log", "exercise", "meditation", "mood_log", "content_view"]
        for et in event_types:
            payload = {
                "user_id": "user_types",
                "event_type": et,
                "metadata": {},
            }
            resp = client.post("/api/v1/analytics/event", json=payload)
            assert resp.status_code == 200
            assert resp.json()["success"] is True

    def test_record_event_with_custom_timestamp(self):
        """用自定义时间戳记录事件"""
        ts = (datetime.now() - timedelta(hours=2)).isoformat()
        payload = {
            "user_id": "user_ts",
            "event_type": "exercise",
            "metadata": {"duration": 30},
            "timestamp": ts,
        }
        resp = client.post("/api/v1/analytics/event", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["data"]["timestamp"] == ts

    def test_record_event_invalid_type(self):
        """无效事件类型返回错误"""
        payload = {
            "user_id": "user_invalid",
            "event_type": "invalid_type",
            "metadata": {},
        }
        resp = client.post("/api/v1/analytics/event", json=payload)
        assert resp.status_code == 400

    def test_record_event_with_metadata(self):
        """记录包含元数据的事件"""
        payload = {
            "user_id": "user_meta",
            "event_type": "food_log",
            "metadata": {
                "food_name": "红枣粥",
                "constitution_benefit": "健脾益气",
                "season": "spring",
            },
        }
        resp = client.post("/api/v1/analytics/event", json=payload)
        assert resp.status_code == 200
        assert resp.json()["success"] is True

    def test_record_multiple_events_same_user(self):
        """同一用户记录多个事件"""
        user_id = "user_multi"
        for i in range(5):
            payload = {
                "user_id": user_id,
                "event_type": "checkin",
                "metadata": {"day": i},
            }
            resp = client.post("/api/v1/analytics/event", json=payload)
            assert resp.status_code == 200


class TestSummary:
    """测试摘要"""

    def test_get_summary_with_data(self):
        """获取有数据的摘要"""
        user_id = "user_summary_1"
        # 先记录一些事件
        for _ in range(3):
            client.post("/api/v1/analytics/event", json={
                "user_id": user_id,
                "event_type": "checkin",
                "metadata": {},
            })

        resp = client.get(f"/api/v1/analytics/summary/{user_id}")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert "period" in data["data"]
        assert data["data"]["period"] == "7_days"
        assert "event_counts" in data["data"]
        assert "checkin_streak" in data["data"]

    def test_get_summary_new_user(self):
        """获取新用户（无数据）的摘要"""
        resp = client.get("/api/v1/analytics/summary/user_new_summary")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        # 新用户也应该返回结构
        assert "event_counts" in data["data"]

    def test_summary_contains_required_fields(self):
        """摘要包含必填字段"""
        user_id = "user_summary_fields"
        client.post("/api/v1/analytics/event", json={
            "user_id": user_id,
            "event_type": "exercise",
            "metadata": {},
        })

        resp = client.get(f"/api/v1/analytics/summary/{user_id}")
        data = resp.json()["data"]
        assert "user_id" in data
        assert "period" in data
        assert "start_date" in data
        assert "end_date" in data
        assert "event_counts" in data
        assert "most_active_hours" in data
        assert "checkin_streak" in data


class TestWeeklyReport:
    """测试周报"""

    def test_weekly_report_with_data(self):
        """获取有数据的周报"""
        user_id = "user_weekly_1"
        for _ in range(5):
            client.post("/api/v1/analytics/event", json={
                "user_id": user_id,
                "event_type": "checkin",
                "metadata": {},
            })

        resp = client.get(f"/api/v1/analytics/weekly-report/{user_id}")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert "dimensions" in data["data"]
        assert "average_score" in data["data"]
        assert "trend" in data["data"]
        assert "best_performance" in data["data"]
        assert "improvement_suggestions" in data["data"]

    def test_weekly_report_new_user_empty_state(self):
        """新用户周报返回空状态指引"""
        resp = client.get("/api/v1/analytics/weekly-report/user_new_weekly")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert data["data"]["is_new_user"] is True
        assert "message" in data["data"]
        assert "next_week_suggestion" in data["data"]

    def test_weekly_report_dimensions_score(self):
        """周报维度评分在0-100范围"""
        user_id = "user_weekly_score"
        for _ in range(7):
            client.post("/api/v1/analytics/event", json={
                "user_id": user_id,
                "event_type": "checkin",
                "metadata": {},
            })

        resp = client.get(f"/api/v1/analytics/weekly-report/{user_id}")
        data = resp.json()["data"]
        for score in data["dimensions"].values():
            assert 0 <= score <= 100
        assert 0 <= data["average_score"] <= 100

    def test_weekly_report_trend_values(self):
        """周报趋势值有效"""
        user_id = "user_weekly_trend"
        client.post("/api/v1/analytics/event", json={
            "user_id": user_id,
            "event_type": "checkin",
            "metadata": {},
        })

        resp = client.get(f"/api/v1/analytics/weekly-report/{user_id}")
        data = resp.json()["data"]
        assert data["trend"] in ["up", "down", "stable"]

    def test_weekly_report_contains_tcm_insights(self):
        """周报包含TCM洞察"""
        user_id = "user_weekly_tcm"
        for _ in range(3):
            client.post("/api/v1/analytics/event", json={
                "user_id": user_id,
                "event_type": "exercise",
                "metadata": {},
            })

        resp = client.get(f"/api/v1/analytics/weekly-report/{user_id}")
        data = resp.json()["data"]
        assert "tcm_insights" in data
        assert len(data["tcm_insights"]) > 0

    def test_weekly_report_next_goals(self):
        """周报包含下周目标"""
        user_id = "user_weekly_goals"
        client.post("/api/v1/analytics/event", json={
            "user_id": user_id,
            "event_type": "meditation",
            "metadata": {},
        })

        resp = client.get(f"/api/v1/analytics/weekly-report/{user_id}")
        data = resp.json()["data"]
        assert "next_week_goals" in data
        assert isinstance(data["next_week_goals"], list)
        assert len(data["next_week_goals"]) > 0


class TestMonthlyReport:
    """测试月报"""

    def test_monthly_report_with_data(self):
        """获取有数据的月报"""
        user_id = "user_monthly_1"
        for _ in range(10):
            client.post("/api/v1/analytics/event", json={
                "user_id": user_id,
                "event_type": "checkin",
                "metadata": {},
            })

        resp = client.get(f"/api/v1/analytics/monthly-report/{user_id}")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert "checkin_count" in data["data"]
        assert "wellness_score" in data["data"]

    def test_monthly_report_new_user_empty_state(self):
        """新用户月报返回空状态指引"""
        resp = client.get("/api/v1/analytics/monthly-report/user_new_monthly")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert data["data"]["is_new_user"] is True
        assert "message" in data["data"]

    def test_monthly_report_wellness_score_range(self):
        """月报健康评分在0-100范围"""
        user_id = "user_monthly_score"
        for _ in range(20):
            client.post("/api/v1/analytics/event", json={
                "user_id": user_id,
                "event_type": "checkin",
                "metadata": {},
            })

        resp = client.get(f"/api/v1/analytics/monthly-report/{user_id}")
        data = resp.json()["data"]
        assert 0 <= data["wellness_score"] <= 100

    def test_monthly_report_three_highlights(self):
        """月报包含三个亮点"""
        user_id = "user_monthly_highlights"
        for _ in range(25):
            client.post("/api/v1/analytics/event", json={
                "user_id": user_id,
                "event_type": "checkin",
                "metadata": {},
            })

        resp = client.get(f"/api/v1/analytics/monthly-report/{user_id}")
        data = resp.json()["data"]
        assert "three_highlights" in data
        assert len(data["three_highlights"]) >= 1

    def test_monthly_report_wellness_level(self):
        """月报健康等级有效"""
        user_id = "user_monthly_level"
        for _ in range(15):
            client.post("/api/v1/analytics/event", json={
                "user_id": user_id,
                "event_type": "checkin",
                "metadata": {},
            })

        resp = client.get(f"/api/v1/analytics/monthly-report/{user_id}")
        data = resp.json()["data"]
        assert data["wellness_level"] in ["improving", "declining", "stable"]

    def test_monthly_report_checkin_dates(self):
        """月报包含打卡日期列表"""
        user_id = "user_monthly_dates"
        for _ in range(5):
            client.post("/api/v1/analytics/event", json={
                "user_id": user_id,
                "event_type": "checkin",
                "metadata": {},
            })

        resp = client.get(f"/api/v1/analytics/monthly-report/{user_id}")
        data = resp.json()["data"]
        assert "checkin_dates" in data
        assert isinstance(data["checkin_dates"], list)


class TestInsights:
    """测试洞察生成"""

    def test_insights_with_data(self):
        """获取有数据的洞察"""
        user_id = "user_insights_1"
        for _ in range(3):
            client.post("/api/v1/analytics/event", json={
                "user_id": user_id,
                "event_type": "checkin",
                "metadata": {},
            })

        resp = client.get(f"/api/v1/analytics/insights/{user_id}")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert "insights" in data["data"]
        assert isinstance(data["data"]["insights"], list)
        assert len(data["data"]["insights"]) > 0

    def test_insights_new_user(self):
        """新用户洞察返回引导"""
        resp = client.get("/api/v1/analytics/insights/user_new_insights")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert len(data["data"]["insights"]) >= 1

    def test_insights_at_least_one(self):
        """洞察至少返回一条"""
        user_id = "user_insights_min"
        client.post("/api/v1/analytics/event", json={
            "user_id": user_id,
            "event_type": "meditation",
            "metadata": {},
        })

        resp = client.get(f"/api/v1/analytics/insights/{user_id}")
        data = resp.json()
        assert data["data"]["count"] >= 1
        assert len(data["data"]["insights"]) >= 1

    def test_insights_max_five(self):
        """洞察最多返回5条"""
        user_id = "user_insights_max"
        for _ in range(50):
            client.post("/api/v1/analytics/event", json={
                "user_id": user_id,
                "event_type": "checkin",
                "metadata": {},
            })

        resp = client.get(f"/api/v1/analytics/insights/{user_id}")
        data = resp.json()
        assert len(data["data"]["insights"]) <= 5

    def test_insights_generated_at_timestamp(self):
        """洞察包含生成时间戳"""
        user_id = "user_insights_ts"
        client.post("/api/v1/analytics/event", json={
            "user_id": user_id,
            "event_type": "food_log",
            "metadata": {},
        })

        resp = client.get(f"/api/v1/analytics/insights/{user_id}")
        data = resp.json()
        assert "generated_at" in data["data"]


class TestAppStats:
    """测试应用统计"""

    def test_app_stats_no_auth(self):
        """应用统计无需认证"""
        resp = client.get("/api/v1/analytics/app-stats")
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True

    def test_app_stats_contains_fields(self):
        """应用统计包含必填字段"""
        resp = client.get("/api/v1/analytics/app-stats")
        data = resp.json()["data"]
        assert "total_users" in data
        assert "daily_active_users" in data
        assert "dau_ratio" in data
        assert "most_popular_content" in data
        assert "season_distribution" in data
        assert "last_updated" in data

    def test_app_stats_reasonable_values(self):
        """应用统计数值合理"""
        resp = client.get("/api/v1/analytics/app-stats")
        data = resp.json()["data"]
        assert data["total_users"] > 0
        assert data["daily_active_users"] > 0
        assert 0 <= data["dau_ratio"] <= 100
        assert isinstance(data["most_popular_content"], list)
        assert len(data["most_popular_content"]) > 0

    def test_app_stats_season_distribution_sum(self):
        """应用统计季节分布总和为1"""
        resp = client.get("/api/v1/analytics/app-stats")
        data = resp.json()["data"]
        total = sum(data["season_distribution"].values())
        assert abs(total - 1.0) < 0.01


class TestEventCounting:
    """测试事件计数"""

    def test_multiple_event_types_counted(self):
        """多种事件类型正确计数"""
        user_id = "user_event_count"
        events = ["checkin", "exercise", "food_log"]
        for et in events:
            for _ in range(2):
                client.post("/api/v1/analytics/event", json={
                    "user_id": user_id,
                    "event_type": et,
                    "metadata": {},
                })

        resp = client.get(f"/api/v1/analytics/summary/{user_id}")
        counts = resp.json()["data"]["event_counts"]
        for et in events:
            assert counts.get(et, 0) >= 2


class TestDataPersistence:
    """测试数据持久性"""

    def test_events_persist_across_requests(self):
        """事件在多个请求间持久存在"""
        user_id = "user_persist"
        client.post("/api/v1/analytics/event", json={
            "user_id": user_id,
            "event_type": "checkin",
            "metadata": {"id": 1},
        })

        resp1 = client.get(f"/api/v1/analytics/summary/{user_id}")
        count1 = resp1.json()["data"]["event_counts"].get("checkin", 0)

        client.post("/api/v1/analytics/event", json={
            "user_id": user_id,
            "event_type": "checkin",
            "metadata": {"id": 2},
        })

        resp2 = client.get(f"/api/v1/analytics/summary/{user_id}")
        count2 = resp2.json()["data"]["event_counts"].get("checkin", 0)

        assert count2 >= count1 + 1
