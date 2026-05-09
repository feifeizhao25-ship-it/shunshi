"""
顺时 - 日记与健康打卡端点测试
test_journal.py
包含 35+ 个测试用例，涵盖：
- 创建日记条目 (happy path, validation)
- 获取日记历史 (pagination, date filtering, empty state)
- 打卡签到记录 (streak calculation, first-time user)
- 周度健康洞察 (trend analysis, pattern recognition)
- 删除条目 (success, not found)
"""

import pytest
from datetime import datetime, date, timedelta
import json


class TestCreateJournalEntry:
    """创建日记条目端点测试 (7 cases)"""

    def test_create_entry_happy_path(self, client):
        """POST /api/v1/journal/entry 创建成功，返回 entry_id 和 wellness_score"""
        payload = {
            "user_id": "test-user-001",
            "mood": 4,
            "energy": 4,
            "sleep_quality": 4,
            "notes": "今天很开心",
            "tags": ["工作", "运动"],
        }
        response = client.post("/api/v1/journal/entry", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "entry_id" in data["data"]
        assert "wellness_score" in data["data"]
        assert data["data"]["mood"] == 4
        assert data["data"]["energy"] == 4
        assert data["data"]["sleep_quality"] == 4
        assert len(data["data"]["entry_id"]) > 0

    def test_create_entry_calculates_wellness_score(self, client):
        """wellness_score 应该是 (mood + energy + sleep_quality) / 3 * 20"""
        payload = {
            "user_id": "test-user-002",
            "mood": 5,
            "energy": 5,
            "sleep_quality": 5,
        }
        response = client.post("/api/v1/journal/entry", json=payload)
        assert response.status_code == 200
        data = response.json()
        # (5 + 5 + 5) / 3 * 20 = 100
        assert data["data"]["wellness_score"] == 100.0

    def test_create_entry_with_date(self, client):
        """指定 date 参数时应被保存"""
        payload = {
            "user_id": "test-user-003",
            "date": "2026-03-15",
            "mood": 3,
            "energy": 3,
            "sleep_quality": 3,
        }
        response = client.post("/api/v1/journal/entry", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["date"] == "2026-03-15"

    def test_create_entry_without_date_defaults_today(self, client):
        """不指定 date 时应默认为今天的日期"""
        payload = {
            "user_id": "test-user-004",
            "mood": 3,
            "energy": 3,
            "sleep_quality": 3,
        }
        response = client.post("/api/v1/journal/entry", json=payload)
        assert response.status_code == 200
        data = response.json()
        today = date.today().isoformat()
        assert data["data"]["date"] == today

    def test_create_entry_with_constitution(self, client):
        """constitution_type 应被保存并包含在 tcm_insight 中"""
        payload = {
            "user_id": "test-user-005",
            "mood": 2,
            "energy": 2,
            "sleep_quality": 2,
            "constitution_type": "qi_deficiency",
        }
        response = client.post("/api/v1/journal/entry", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["constitution_type"] == "qi_deficiency"
        assert "气虚体质" in data["data"]["tcm_insight"]

    def test_create_entry_mood_validation_too_low(self, client):
        """mood < 1 应返回 422 validation error"""
        payload = {
            "user_id": "test-user-006",
            "mood": 0,
            "energy": 3,
            "sleep_quality": 3,
        }
        response = client.post("/api/v1/journal/entry", json=payload)
        assert response.status_code == 422

    def test_create_entry_mood_validation_too_high(self, client):
        """mood > 5 应返回 422 validation error"""
        payload = {
            "user_id": "test-user-007",
            "mood": 6,
            "energy": 3,
            "sleep_quality": 3,
        }
        response = client.post("/api/v1/journal/entry", json=payload)
        assert response.status_code == 422

    def test_create_entry_missing_mood(self, client):
        """缺少 mood 应返回 422"""
        payload = {
            "user_id": "test-user-008",
            "energy": 3,
            "sleep_quality": 3,
        }
        response = client.post("/api/v1/journal/entry", json=payload)
        assert response.status_code == 422

    def test_create_entry_missing_energy(self, client):
        """缺少 energy 应返回 422"""
        payload = {
            "user_id": "test-user-009",
            "mood": 3,
            "sleep_quality": 3,
        }
        response = client.post("/api/v1/journal/entry", json=payload)
        assert response.status_code == 422

    def test_create_entry_missing_sleep_quality(self, client):
        """缺少 sleep_quality 应返回 422"""
        payload = {
            "user_id": "test-user-010",
            "mood": 3,
            "energy": 3,
        }
        response = client.post("/api/v1/journal/entry", json=payload)
        assert response.status_code == 422


class TestGetJournalEntries:
    """获取日记历史端点测试 (9 cases)"""

    def test_get_entries_new_user_empty(self, client):
        """新用户没有条目时返回空列表"""
        response = client.get("/api/v1/journal/entries/new-user-001")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["entries"] == []
        assert data["data"]["total"] == 0

    def test_get_entries_returns_paginated_list(self, client):
        """创建 5 条条目后，GET /entries 返回分页列表"""
        user_id = "test-user-entries-001"
        for i in range(5):
            payload = {
                "user_id": user_id,
                "date": (date.today() - timedelta(days=i)).isoformat(),
                "mood": min(5, 3 + i),
                "energy": 3,
                "sleep_quality": 3,
            }
            client.post("/api/v1/journal/entry", json=payload)

        response = client.get(f"/api/v1/journal/entries/{user_id}")
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]["entries"]) == 5
        assert data["data"]["total"] == 5

    def test_get_entries_limit_parameter(self, client):
        """limit 参数应限制返回条数"""
        user_id = "test-user-entries-002"
        for i in range(10):
            payload = {
                "user_id": user_id,
                "mood": 3,
                "energy": 3,
                "sleep_quality": 3,
            }
            client.post("/api/v1/journal/entry", json=payload)

        response = client.get(f"/api/v1/journal/entries/{user_id}?limit=3")
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]["entries"]) == 3
        assert data["data"]["total"] == 10
        assert data["data"]["limit"] == 3

    def test_get_entries_offset_parameter(self, client):
        """offset 参数应跳过指定数量的条目"""
        user_id = "test-user-entries-003"
        for i in range(5):
            payload = {
                "user_id": user_id,
                "mood": i + 1,
                "energy": 3,
                "sleep_quality": 3,
            }
            client.post("/api/v1/journal/entry", json=payload)

        response = client.get(f"/api/v1/journal/entries/{user_id}?offset=2&limit=2")
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]["entries"]) == 2
        assert data["data"]["offset"] == 2

    def test_get_entries_start_date_filter(self, client):
        """start_date 参数应过滤开始日期前的条目"""
        user_id = "test-user-entries-004"
        dates = [
            "2026-03-10",
            "2026-03-12",
            "2026-03-14",
            "2026-03-16",
        ]
        for date_str in dates:
            payload = {
                "user_id": user_id,
                "date": date_str,
                "mood": 3,
                "energy": 3,
                "sleep_quality": 3,
            }
            client.post("/api/v1/journal/entry", json=payload)

        response = client.get(f"/api/v1/journal/entries/{user_id}?start_date=2026-03-12")
        assert response.status_code == 200
        data = response.json()
        # 应返回 >= 2026-03-12 的条目
        assert len(data["data"]["entries"]) == 3

    def test_get_entries_end_date_filter(self, client):
        """end_date 参数应过滤结束日期后的条目"""
        user_id = "test-user-entries-005"
        dates = [
            "2026-03-10",
            "2026-03-12",
            "2026-03-14",
            "2026-03-16",
        ]
        for date_str in dates:
            payload = {
                "user_id": user_id,
                "date": date_str,
                "mood": 3,
                "energy": 3,
                "sleep_quality": 3,
            }
            client.post("/api/v1/journal/entry", json=payload)

        response = client.get(f"/api/v1/journal/entries/{user_id}?end_date=2026-03-14")
        assert response.status_code == 200
        data = response.json()
        # 应返回 <= 2026-03-14 的条目
        assert len(data["data"]["entries"]) == 3

    def test_get_entries_date_range_filter(self, client):
        """同时使用 start_date 和 end_date 进行日期范围过滤"""
        user_id = "test-user-entries-006"
        dates = [
            "2026-03-10",
            "2026-03-12",
            "2026-03-14",
            "2026-03-16",
        ]
        for date_str in dates:
            payload = {
                "user_id": user_id,
                "date": date_str,
                "mood": 3,
                "energy": 3,
                "sleep_quality": 3,
            }
            client.post("/api/v1/journal/entry", json=payload)

        response = client.get(f"/api/v1/journal/entries/{user_id}?start_date=2026-03-12&end_date=2026-03-14")
        assert response.status_code == 200
        data = response.json()
        # 应返回 2026-03-12 和 2026-03-14 的条目
        assert len(data["data"]["entries"]) == 2

    def test_get_entries_sorted_by_date_descending(self, client):
        """条目应按日期倒序排列（最新在前）"""
        user_id = "test-user-entries-007"
        dates = ["2026-03-10", "2026-03-12", "2026-03-14"]
        for date_str in dates:
            payload = {
                "user_id": user_id,
                "date": date_str,
                "mood": 3,
                "energy": 3,
                "sleep_quality": 3,
            }
            client.post("/api/v1/journal/entry", json=payload)

        response = client.get(f"/api/v1/journal/entries/{user_id}")
        assert response.status_code == 200
        data = response.json()
        returned_dates = [e["date"] for e in data["data"]["entries"]]
        # 应从最新到最旧
        assert returned_dates == ["2026-03-14", "2026-03-12", "2026-03-10"]

    def test_get_entries_default_limit_30(self, client):
        """limit 默认值应为 30"""
        user_id = "test-user-entries-008"
        for i in range(5):
            payload = {
                "user_id": user_id,
                "mood": 3,
                "energy": 3,
                "sleep_quality": 3,
            }
            client.post("/api/v1/journal/entry", json=payload)

        response = client.get(f"/api/v1/journal/entries/{user_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["limit"] == 30


class TestGetCheckinStreak:
    """打卡签到记录端点测试 (7 cases)"""

    def test_get_streak_new_user(self, client):
        """新用户没有条目时，streak 应为 0"""
        response = client.get("/api/v1/journal/streak/new-user-streak-001")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["current_streak"] == 0
        assert data["data"]["longest_streak"] == 0
        assert data["data"]["total_entries"] == 0
        assert data["data"]["last_entry_date"] is None

    def test_get_streak_single_entry(self, client):
        """单条条目应返回 streak = 1"""
        user_id = "test-user-streak-001"
        payload = {
            "user_id": user_id,
            "mood": 3,
            "energy": 3,
            "sleep_quality": 3,
        }
        client.post("/api/v1/journal/entry", json=payload)

        response = client.get(f"/api/v1/journal/streak/{user_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["current_streak"] == 1
        assert data["data"]["longest_streak"] == 1
        assert data["data"]["total_entries"] == 1

    def test_get_streak_consecutive_days(self, client):
        """连续 3 天的条目应返回 streak = 3"""
        user_id = "test-user-streak-002"
        for i in range(3):
            payload = {
                "user_id": user_id,
                "date": (date.today() - timedelta(days=2 - i)).isoformat(),
                "mood": 3,
                "energy": 3,
                "sleep_quality": 3,
            }
            client.post("/api/v1/journal/entry", json=payload)

        response = client.get(f"/api/v1/journal/streak/{user_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["current_streak"] == 3
        assert data["data"]["longest_streak"] == 3

    def test_get_streak_with_gap(self, client):
        """日期有间隔的条目应记录最长 streak"""
        user_id = "test-user-streak-003"
        # 前 3 天连续
        for i in range(3):
            payload = {
                "user_id": user_id,
                "date": (date.today() - timedelta(days=4 - i)).isoformat(),
                "mood": 3,
                "energy": 3,
                "sleep_quality": 3,
            }
            client.post("/api/v1/journal/entry", json=payload)
        # 今天（间隔 1 天）
        payload = {
            "user_id": user_id,
            "date": date.today().isoformat(),
            "mood": 3,
            "energy": 3,
            "sleep_quality": 3,
        }
        client.post("/api/v1/journal/entry", json=payload)

        response = client.get(f"/api/v1/journal/streak/{user_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["current_streak"] == 1
        assert data["data"]["longest_streak"] == 3

    def test_get_streak_last_entry_date(self, client):
        """last_entry_date 应返回最新条目的日期"""
        user_id = "test-user-streak-004"
        last_date = (date.today() - timedelta(days=1)).isoformat()
        payload = {
            "user_id": user_id,
            "date": last_date,
            "mood": 3,
            "energy": 3,
            "sleep_quality": 3,
        }
        client.post("/api/v1/journal/entry", json=payload)

        response = client.get(f"/api/v1/journal/streak/{user_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["last_entry_date"] == last_date

    def test_get_streak_total_entries(self, client):
        """total_entries 应返回所有条目总数"""
        user_id = "test-user-streak-005"
        for i in range(7):
            payload = {
                "user_id": user_id,
                "date": (date.today() - timedelta(days=i)).isoformat(),
                "mood": 3,
                "energy": 3,
                "sleep_quality": 3,
            }
            client.post("/api/v1/journal/entry", json=payload)

        response = client.get(f"/api/v1/journal/streak/{user_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["total_entries"] == 7


class TestGetWellnessInsights:
    """周度健康洞察端点测试 (8 cases)"""

    def test_get_insights_new_user(self, client):
        """新用户没有数据时返回 no_data trend"""
        response = client.get("/api/v1/journal/insights/new-user-insights-001")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["entries_count"] == 0
        assert data["data"]["trend"] == "no_data"

    def test_get_insights_calculates_averages(self, client):
        """应计算过去7天的平均心情、精力、睡眠"""
        user_id = "test-user-insights-001"
        # 创建多条条目
        for i in range(3):
            payload = {
                "user_id": user_id,
                "date": (date.today() - timedelta(days=2 - i)).isoformat(),
                "mood": min(5, 3 + i),
                "energy": min(5, 2 + i),
                "sleep_quality": min(5, 4 + i),
            }
            client.post("/api/v1/journal/entry", json=payload)

        response = client.get(f"/api/v1/journal/insights/{user_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["entries_count"] == 3
        assert "avg_mood" in data["data"]
        assert "avg_energy" in data["data"]
        assert "avg_sleep_quality" in data["data"]
        assert "avg_wellness_score" in data["data"]

    def test_get_insights_trend_improving(self, client):
        """后期条目分数更高时，trend 应为 'improving'"""
        user_id = "test-user-insights-002"
        # 前期低分
        payload = {
            "user_id": user_id,
            "date": (date.today() - timedelta(days=4)).isoformat(),
            "mood": 1,
            "energy": 1,
            "sleep_quality": 1,
        }
        client.post("/api/v1/journal/entry", json=payload)
        # 后期高分
        payload = {
            "user_id": user_id,
            "date": (date.today() - timedelta(days=1)).isoformat(),
            "mood": 5,
            "energy": 5,
            "sleep_quality": 5,
        }
        client.post("/api/v1/journal/entry", json=payload)

        response = client.get(f"/api/v1/journal/insights/{user_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["trend"] == "improving"

    def test_get_insights_trend_declining(self, client):
        """后期条目分数更低时，trend 应为 'declining'"""
        user_id = "test-user-insights-003"
        # 前期高分
        payload = {
            "user_id": user_id,
            "date": (date.today() - timedelta(days=4)).isoformat(),
            "mood": 5,
            "energy": 5,
            "sleep_quality": 5,
        }
        client.post("/api/v1/journal/entry", json=payload)
        # 后期低分
        payload = {
            "user_id": user_id,
            "date": (date.today() - timedelta(days=1)).isoformat(),
            "mood": 1,
            "energy": 1,
            "sleep_quality": 1,
        }
        client.post("/api/v1/journal/entry", json=payload)

        response = client.get(f"/api/v1/journal/insights/{user_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["trend"] == "declining"

    def test_get_insights_tcm_pattern_low_mood(self, client):
        """低心情 avg_mood < 2.5 时应识别为肝气郁结"""
        user_id = "test-user-insights-004"
        for i in range(3):
            payload = {
                "user_id": user_id,
                "mood": 1,
                "energy": 5,
                "sleep_quality": 5,
            }
            client.post("/api/v1/journal/entry", json=payload)

        response = client.get(f"/api/v1/journal/insights/{user_id}")
        assert response.status_code == 200
        data = response.json()
        assert "肝气郁结" in data["data"]["tcm_pattern"]

    def test_get_insights_tcm_pattern_low_energy(self, client):
        """低精力 avg_energy < 2.5 时应识别为气虚"""
        user_id = "test-user-insights-005"
        for i in range(3):
            payload = {
                "user_id": user_id,
                "mood": 5,
                "energy": 1,
                "sleep_quality": 5,
            }
            client.post("/api/v1/journal/entry", json=payload)

        response = client.get(f"/api/v1/journal/insights/{user_id}")
        assert response.status_code == 200
        data = response.json()
        assert "气虚" in data["data"]["tcm_pattern"]

    def test_get_insights_tcm_pattern_low_sleep(self, client):
        """低睡眠 avg_sleep < 2.5 时应识别为心神不安"""
        user_id = "test-user-insights-006"
        for i in range(3):
            payload = {
                "user_id": user_id,
                "mood": 5,
                "energy": 5,
                "sleep_quality": 1,
            }
            client.post("/api/v1/journal/entry", json=payload)

        response = client.get(f"/api/v1/journal/insights/{user_id}")
        assert response.status_code == 200
        data = response.json()
        assert "心神不安" in data["data"]["tcm_pattern"]

    def test_get_insights_tcm_pattern_balanced(self, client):
        """高分数时应识别为气血调和"""
        user_id = "test-user-insights-007"
        for i in range(3):
            payload = {
                "user_id": user_id,
                "mood": 4,
                "energy": 4,
                "sleep_quality": 4,
            }
            client.post("/api/v1/journal/entry", json=payload)

        response = client.get(f"/api/v1/journal/insights/{user_id}")
        assert response.status_code == 200
        data = response.json()
        assert "气血调和" in data["data"]["tcm_pattern"]


class TestDeleteJournalEntry:
    """删除日记条目端点测试 (4 cases)"""

    def test_delete_entry_success(self, client):
        """DELETE /api/v1/journal/entry/{entry_id} 成功删除"""
        user_id = "test-user-delete-001"
        payload = {
            "user_id": user_id,
            "mood": 3,
            "energy": 3,
            "sleep_quality": 3,
        }
        create_response = client.post("/api/v1/journal/entry", json=payload)
        entry_id = create_response.json()["data"]["entry_id"]

        delete_response = client.delete(f"/api/v1/journal/entry/{entry_id}")
        assert delete_response.status_code == 200
        data = delete_response.json()
        assert data["success"] is True
        assert data["data"]["deleted_entry_id"] == entry_id

    def test_delete_entry_not_found(self, client):
        """删除不存在的 entry_id 应返回 404"""
        response = client.delete("/api/v1/journal/entry/nonexistent-id-12345")
        assert response.status_code == 404

    def test_delete_entry_removes_from_history(self, client):
        """删除条目后，GET /entries 应不再返回该条目"""
        user_id = "test-user-delete-002"
        payload = {
            "user_id": user_id,
            "mood": 3,
            "energy": 3,
            "sleep_quality": 3,
        }
        create_response = client.post("/api/v1/journal/entry", json=payload)
        entry_id = create_response.json()["data"]["entry_id"]

        # 删除
        client.delete(f"/api/v1/journal/entry/{entry_id}")

        # 验证已删除
        get_response = client.get(f"/api/v1/journal/entries/{user_id}")
        entries = get_response.json()["data"]["entries"]
        entry_ids = [e["entry_id"] for e in entries]
        assert entry_id not in entry_ids

    def test_delete_entry_updates_streak(self, client):
        """删除条目后，streak 应更新"""
        user_id = "test-user-delete-003"
        # 创建 2 条条目
        entries = []
        for i in range(2):
            payload = {
                "user_id": user_id,
                "date": (date.today() - timedelta(days=1 - i)).isoformat(),
                "mood": 3,
                "energy": 3,
                "sleep_quality": 3,
            }
            response = client.post("/api/v1/journal/entry", json=payload)
            entries.append(response.json()["data"]["entry_id"])

        # 验证删除前的 streak
        streak_before = client.get(f"/api/v1/journal/streak/{user_id}").json()
        assert streak_before["data"]["total_entries"] == 2

        # 删除一条
        client.delete(f"/api/v1/journal/entry/{entries[0]}")

        # 验证删除后的 streak
        streak_after = client.get(f"/api/v1/journal/streak/{user_id}").json()
        assert streak_after["data"]["total_entries"] == 1


class TestTCMInsights:
    """中医洞察与建议测试 (7 cases)"""

    def test_tcm_insight_includes_mood_analysis(self, client):
        """tcm_insight 应包含心情分析"""
        payload = {
            "user_id": "test-user-tcm-001",
            "mood": 1,
            "energy": 5,
            "sleep_quality": 5,
        }
        response = client.post("/api/v1/journal/entry", json=payload)
        data = response.json()
        assert "情绪低落" in data["data"]["tcm_insight"] or "低落" in data["data"]["tcm_insight"]

    def test_tcm_insight_includes_energy_analysis(self, client):
        """tcm_insight 应包含精力分析"""
        payload = {
            "user_id": "test-user-tcm-002",
            "mood": 5,
            "energy": 1,
            "sleep_quality": 5,
        }
        response = client.post("/api/v1/journal/entry", json=payload)
        data = response.json()
        assert "疲劳" in data["data"]["tcm_insight"] or "气虚" in data["data"]["tcm_insight"]

    def test_tcm_insight_includes_sleep_analysis(self, client):
        """tcm_insight 应包含睡眠分析"""
        payload = {
            "user_id": "test-user-tcm-003",
            "mood": 5,
            "energy": 5,
            "sleep_quality": 1,
        }
        response = client.post("/api/v1/journal/entry", json=payload)
        data = response.json()
        assert "睡眠" in data["data"]["tcm_insight"]

    def test_tcm_insight_good_scores(self, client):
        """高分数应返回气血调和的建议"""
        payload = {
            "user_id": "test-user-tcm-004",
            "mood": 5,
            "energy": 5,
            "sleep_quality": 5,
        }
        response = client.post("/api/v1/journal/entry", json=payload)
        data = response.json()
        assert "最佳" in data["data"]["tcm_insight"] or "优质" in data["data"]["tcm_insight"]

    def test_tcm_insight_with_qi_deficiency_constitution(self, client):
        """气虚体质的建议应包含补气信息"""
        payload = {
            "user_id": "test-user-tcm-005",
            "mood": 3,
            "energy": 3,
            "sleep_quality": 3,
            "constitution_type": "qi_deficiency",
        }
        response = client.post("/api/v1/journal/entry", json=payload)
        data = response.json()
        assert "气虚体质" in data["data"]["tcm_insight"]

    def test_tcm_insight_with_yin_deficiency_constitution(self, client):
        """阴虚体质的建议应包含滋阴信息"""
        payload = {
            "user_id": "test-user-tcm-006",
            "mood": 3,
            "energy": 3,
            "sleep_quality": 3,
            "constitution_type": "yin_deficiency",
        }
        response = client.post("/api/v1/journal/entry", json=payload)
        data = response.json()
        assert "阴虚体质" in data["data"]["tcm_insight"]

    def test_wellness_score_formula(self, client):
        """wellness_score 应严格遵循 (mood + energy + sleep) / 3 * 20"""
        test_cases = [
            (1, 1, 1, 20.0),
            (2, 2, 2, 40.0),
            (3, 3, 3, 60.0),
            (4, 4, 4, 80.0),
            (5, 5, 5, 100.0),
            (1, 5, 3, 60.0),  # (1+5+3)/3*20 = 60.0
        ]
        for mood, energy, sleep, expected in test_cases:
            payload = {
                "user_id": f"test-user-score-{mood}-{energy}-{sleep}",
                "mood": mood,
                "energy": energy,
                "sleep_quality": sleep,
            }
            response = client.post("/api/v1/journal/entry", json=payload)
            actual = response.json()["data"]["wellness_score"]
            # 允许小数点偏差
            assert abs(actual - expected) < 0.2
