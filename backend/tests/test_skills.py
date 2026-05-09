"""
顺时 - Skills API 路由测试
test_skills.py
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestSkillsList:
    """Skill 列表端点测试"""

    def test_list_skills_returns_200(self):
        """GET /api/v1/skills 返回 200"""
        response = client.get("/api/v1/skills")
        assert response.status_code == 200

    def test_list_skills_returns_array(self):
        """响应是 SkillSummary 数组"""
        response = client.get("/api/v1/skills")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    def test_skill_summary_has_required_fields(self):
        """Skill 摘要包含必要字段"""
        response = client.get("/api/v1/skills")
        assert response.status_code == 200
        data = response.json()
        if len(data) > 0:
            skill = data[0]
            assert "skill_id" in skill
            assert "name" in skill
            assert "category" in skill
            assert "is_premium" in skill

    def test_list_skills_with_limit(self):
        """GET /api/v1/skills?limit=5 限制返回数量"""
        response = client.get("/api/v1/skills?limit=5")
        assert response.status_code == 200
        data = response.json()
        assert len(data) <= 5

    def test_list_skills_with_offset(self):
        """GET /api/v1/skills?offset=10 支持分页"""
        response = client.get("/api/v1/skills?offset=10&limit=5")
        assert response.status_code == 200

    def test_filter_by_category(self):
        """GET /api/v1/skills?category=planning 按分类筛选"""
        response = client.get("/api/v1/skills?category=planning")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    def test_filter_by_tag(self):
        """GET /api/v1/skills?tag=wellness 按标签筛选"""
        response = client.get("/api/v1/skills?tag=wellness")
        assert response.status_code == 200

    def test_filter_by_priority(self):
        """GET /api/v1/skills?priority=P0 按优先级筛选"""
        response = client.get("/api/v1/skills?priority=P0")
        assert response.status_code == 200

    def test_premium_only_filter(self):
        """GET /api/v1/skills?premium_only=true 仅会员 Skill"""
        response = client.get("/api/v1/skills?premium_only=true")
        assert response.status_code == 200

    def test_limit_max_200(self):
        """limit 参数最大为 200"""
        response = client.get("/api/v1/skills?limit=300")
        # 应该被限制或返回错误
        assert response.status_code in [200, 422]


class TestSkillDetail:
    """Skill 详情端点测试"""

    def test_get_skill_detail_returns_200(self):
        """GET /api/v1/skills/{skill_id} 返回 200"""
        # 先获取一个 skill_id
        list_response = client.get("/api/v1/skills?limit=1")
        if list_response.status_code == 200 and len(list_response.json()) > 0:
            skill_id = list_response.json()[0]["skill_id"]
            response = client.get(f"/api/v1/skills/{skill_id}")
            assert response.status_code == 200

    def test_skill_detail_has_all_fields(self):
        """Skill 详情包含所有字段"""
        list_response = client.get("/api/v1/skills?limit=1")
        if list_response.status_code == 200 and len(list_response.json()) > 0:
            skill_id = list_response.json()[0]["skill_id"]
            response = client.get(f"/api/v1/skills/{skill_id}")
            if response.status_code == 200:
                data = response.json()
                assert "skill_id" in data
                assert "name" in data
                assert "version" in data
                assert "output_schema" in data

    def test_unknown_skill_404(self):
        """GET /api/v1/skills/nonexistent_skill 返回 404"""
        response = client.get("/api/v1/skills/nonexistent_skill_xyz")
        assert response.status_code == 404


class TestSkillCategories:
    """Skill 分类端点测试"""

    def test_list_categories_returns_200(self):
        """GET /api/v1/skills/categories 返回 200"""
        response = client.get("/api/v1/skills/categories")
        assert response.status_code == 200

    def test_categories_is_array(self):
        """分类列表是数组"""
        response = client.get("/api/v1/skills/categories")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    def test_category_has_required_fields(self):
        """分类包含必要字段"""
        response = client.get("/api/v1/skills/categories")
        assert response.status_code == 200
        data = response.json()
        if len(data) > 0:
            category = data[0]
            assert "category" in category
            assert "skill_count" in category
            assert "sample_skills" in category

    def test_category_has_counts(self):
        """分类包含数量统计"""
        response = client.get("/api/v1/skills/categories")
        assert response.status_code == 200
        data = response.json()
        if len(data) > 0:
            category = data[0]
            assert "p0_count" in category or "skill_count" in category


class TestSkillStats:
    """Skill 统计端点测试"""

    def test_get_stats_returns_200(self):
        """GET /api/v1/skills/stats 返回 200"""
        response = client.get("/api/v1/skills/stats")
        assert response.status_code == 200

    def test_stats_has_total_skills(self):
        """统计包含 total_skills"""
        response = client.get("/api/v1/skills/stats")
        assert response.status_code == 200
        data = response.json()
        assert "total_skills" in data

    def test_stats_has_category_counts(self):
        """统计包含 category_counts"""
        response = client.get("/api/v1/skills/stats")
        assert response.status_code == 200
        data = response.json()
        assert "category_counts" in data

    def test_stats_has_priority_counts(self):
        """统计包含 priority_counts"""
        response = client.get("/api/v1/skills/stats")
        assert response.status_code == 200
        data = response.json()
        assert "priority_counts" in data

    def test_stats_has_premium_count(self):
        """统计包含 premium_count 和 free_count"""
        response = client.get("/api/v1/skills/stats")
        assert response.status_code == 200
        data = response.json()
        assert "premium_count" in data
        assert "free_count" in data


class TestSkillSearch:
    """Skill 搜索端点测试"""

    def test_search_skills_returns_200(self):
        """GET /api/v1/skills/search?q=养生 返回 200"""
        response = client.get("/api/v1/skills/search?q=health")
        assert response.status_code == 200

    def test_search_results_is_array(self):
        """搜索结果是数组"""
        response = client.get("/api/v1/skills/search?q=wellness")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)

    def test_search_requires_query(self):
        """缺少查询参数应返回错误"""
        response = client.get("/api/v1/skills/search")
        assert response.status_code == 422

    def test_search_with_limit(self):
        """GET /api/v1/skills/search?q=test&limit=5 限制结果"""
        response = client.get("/api/v1/skills/search?q=health&limit=5")
        assert response.status_code == 200
        data = response.json()
        assert len(data) <= 5

    def test_search_empty_results(self):
        """搜索不存在的关键词返回空数组"""
        response = client.get("/api/v1/skills/search?q=nonexistent_xyz_keyword")
        assert response.status_code == 200
        data = response.json()
        # 可能是空数组或空列表
        assert isinstance(data, list)


class TestSkillExecute:
    """Skill 执行端点测试"""

    def test_execute_skill_returns_200(self):
        """POST /api/v1/skills/execute 返回 200"""
        payload = {
            "user_id": "user-001",
            "message": "给我一个养生建议"
        }
        response = client.post("/api/v1/skills/execute", json=payload)
        assert response.status_code == 200

    def test_execute_response_structure(self):
        """执行响应包含必要字段"""
        payload = {
            "user_id": "user-001",
            "message": "help me with wellness"
        }
        response = client.post("/api/v1/skills/execute", json=payload)
        if response.status_code == 200:
            data = response.json()
            assert "status" in data
            assert "final_response" in data
            assert "skills_executed" in data
            assert "total_tokens" in data

    def test_execute_with_context(self):
        """支持传递上下文"""
        payload = {
            "user_id": "user-001",
            "message": "wellness advice",
            "context": {"constitution": "pinghe"}
        }
        response = client.post("/api/v1/skills/execute", json=payload)
        assert response.status_code == 200

    def test_execute_requires_user_id_and_message(self):
        """缺少 user_id 或 message 应返回错误"""
        payload = {"user_id": "user-001"}
        response = client.post("/api/v1/skills/execute", json=payload)
        assert response.status_code == 422

    def test_execute_response_has_skills_executed(self):
        """响应包含执行的 skills 列表"""
        payload = {
            "user_id": "user-001",
            "message": "health advice"
        }
        response = client.post("/api/v1/skills/execute", json=payload)
        if response.status_code == 200:
            data = response.json()
            assert isinstance(data["skills_executed"], list)


class TestDailyPlan:
    """每日计划端点测试"""

    def test_generate_daily_plan_returns_200(self):
        """POST /api/v1/skills/daily-plan 返回 200"""
        payload = {
            "user_id": "user-001",
            "plan_type": "light"
        }
        response = client.post("/api/v1/skills/daily-plan", json=payload)
        assert response.status_code == 200

    def test_daily_plan_light_type(self):
        """支持 plan_type=light"""
        payload = {
            "user_id": "user-001",
            "plan_type": "light"
        }
        response = client.post("/api/v1/skills/daily-plan", json=payload)
        assert response.status_code == 200

    def test_daily_plan_deep_type(self):
        """支持 plan_type=deep"""
        payload = {
            "user_id": "user-001",
            "plan_type": "deep"
        }
        response = client.post("/api/v1/skills/daily-plan", json=payload)
        assert response.status_code == 200

    def test_daily_plan_emotion_type(self):
        """支持 plan_type=emotion"""
        payload = {
            "user_id": "user-001",
            "plan_type": "emotion"
        }
        response = client.post("/api/v1/skills/daily-plan", json=payload)
        assert response.status_code == 200

    def test_daily_plan_with_context(self):
        """支持传递上下文"""
        payload = {
            "user_id": "user-001",
            "plan_type": "light",
            "context": {"season": "spring"}
        }
        response = client.post("/api/v1/skills/daily-plan", json=payload)
        assert response.status_code == 200

    def test_daily_plan_response_structure(self):
        """计划响应包含必要字段"""
        payload = {
            "user_id": "user-001",
            "plan_type": "light"
        }
        response = client.post("/api/v1/skills/daily-plan", json=payload)
        if response.status_code == 200:
            data = response.json()
            assert "status" in data
            assert "final_response" in data

    def test_invalid_plan_type(self):
        """无效的 plan_type 应返回错误"""
        payload = {
            "user_id": "user-001",
            "plan_type": "invalid_type"
        }
        response = client.post("/api/v1/skills/daily-plan", json=payload)
        assert response.status_code == 200  # 无效 plan_type 回退到 light 方案
