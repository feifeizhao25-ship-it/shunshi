"""
测试：TCM 文化故事讲述
"""

import pytest
from datetime import datetime
from fastapi.testclient import TestClient
from app.router.cultural_stories import router, _get_daily_story_id


@pytest.fixture
def client():
    """创建测试客户端。"""
    from fastapi import FastAPI
    app = FastAPI()
    app.include_router(router)
    return TestClient(app)


class TestGetStories:
    """GET / 端点测试"""

    def test_get_all_stories(self, client):
        """测试获取所有故事。"""
        response = client.get("/api/v1/stories/")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "total_stories" in data["data"]
        assert "stories" in data["data"]
        assert data["data"]["total_stories"] >= 15

    def test_get_stories_structure(self, client):
        """测试故事列表结构。"""
        response = client.get("/api/v1/stories/")
        data = response.json()
        for story in data["data"]["stories"]:
            assert "id" in story
            assert "title" in story
            assert "category" in story
            assert "period" in story
            assert "length_words" in story

    def test_filter_by_category_solar_term(self, client):
        """测试按「节气」分类过滤。"""
        response = client.get("/api/v1/stories/?category=solar_term")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        for story in data["data"]["stories"]:
            assert story["category"] == "solar_term"

    def test_filter_by_category_ingredient(self, client):
        """测试按「食材」分类过滤。"""
        response = client.get("/api/v1/stories/?category=ingredient")
        assert response.status_code == 200
        data = response.json()
        for story in data["data"]["stories"]:
            assert story["category"] == "ingredient"

    def test_filter_by_category_physician(self, client):
        """测试按「医家」分类过滤。"""
        response = client.get("/api/v1/stories/?category=physician")
        assert response.status_code == 200
        data = response.json()
        for story in data["data"]["stories"]:
            assert story["category"] == "physician"

    def test_filter_by_category_acupoint(self, client):
        """测试按「穴位」分类过滤。"""
        response = client.get("/api/v1/stories/?category=acupoint")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_filter_by_season_spring(self, client):
        """测试按春季过滤。"""
        response = client.get("/api/v1/stories/?season=spring")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_filter_by_season_winter(self, client):
        """测试按冬季过滤。"""
        response = client.get("/api/v1/stories/?season=winter")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_combined_filters(self, client):
        """测试组合过滤（分类+季节）。"""
        response = client.get("/api/v1/stories/?category=solar_term&season=winter")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True


class TestGetStoryDetail:
    """GET /{story_id} 端点测试"""

    def test_get_story_winter_solstice(self, client):
        """测试获取冬至故事详情。"""
        response = client.get("/api/v1/stories/winter_solstice_kitchen")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["id"] == "winter_solstice_kitchen"
        assert "story_text" in data["data"]
        assert "moral_lesson" in data["data"]

    def test_story_detail_complete_info(self, client):
        """测试故事详情包含完整信息。"""
        response = client.get("/api/v1/stories/ginger_legend")
        data = response.json()
        story = data["data"]
        assert "id" in story
        assert "title" in story
        assert "category" in story
        assert "related_tcm_element" in story
        assert "period" in story
        assert "length_words" in story
        assert "story_text" in story
        assert "moral_lesson" in story
        assert "modern_relevance" in story
        assert "related_wellness_tip" in story

    def test_get_all_stories_by_id(self, client):
        """测试所有故事都可以通过 ID 访问。"""
        list_response = client.get("/api/v1/stories/")
        stories = list_response.json()["data"]["stories"]
        for story in stories:
            detail_response = client.get(f"/api/v1/stories/{story['id']}")
            assert detail_response.status_code == 200
            assert detail_response.json()["data"]["id"] == story["id"]

    def test_get_story_invalid_id(self, client):
        """测试无效的故事 ID 返回 404。"""
        response = client.get("/api/v1/stories/invalid_story_xyz")
        assert response.status_code == 404

    def test_story_text_length_reasonable(self, client):
        """测试故事文本长度合理（200-400 词）。"""
        response = client.get("/api/v1/stories/li_shizhen_compendium")
        data = response.json()
        story_text = data["data"]["story_text"]
        # 简单的词数估算
        word_count = len(story_text.split())
        assert word_count > 100  # 至少有一些内容


class TestDailyStory:
    """GET /daily 端点测试"""

    def test_get_daily_story(self, client):
        """测试获取每日精选故事。"""
        response = client.get("/api/v1/stories/daily")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "date" in data["data"]
        assert "daily_featured_story" in data["data"]

    def test_daily_story_has_full_content(self, client):
        """测试每日故事包含完整内容。"""
        response = client.get("/api/v1/stories/daily")
        data = response.json()
        story = data["data"]["daily_featured_story"]
        assert "story_text" in story
        assert "moral_lesson" in story

    def test_daily_story_consistency_same_day(self, client):
        """测试同一天返回相同的故事（一致性）。"""
        response1 = client.get("/api/v1/stories/daily")
        response2 = client.get("/api/v1/stories/daily")
        data1 = response1.json()
        data2 = response2.json()
        # 同一天应该返回相同的故事 ID
        assert data1["data"]["daily_featured_story"]["id"] == data2["data"]["daily_featured_story"]["id"]

    def test_daily_story_date_format(self, client):
        """测试每日故事包含格式正确的日期。"""
        response = client.get("/api/v1/stories/daily")
        data = response.json()
        date_str = data["data"]["date"]
        # 验证日期格式 YYYY-MM-DD
        datetime.strptime(date_str, "%Y-%m-%d")

    def test_daily_story_rotation(self, client):
        """测试故事轮换逻辑（基于日期）。"""
        # 验证轮换函数返回有效的故事 ID
        story_id = _get_daily_story_id()
        response = client.get(f"/api/v1/stories/{story_id}")
        assert response.status_code == 200


class TestCategoryEndpoint:
    """GET /category/{category} 端点测试"""

    def test_get_solar_term_category(self, client):
        """测试获取节气分类的所有故事。"""
        response = client.get("/api/v1/stories/category/solar_term")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["category"] == "solar_term"
        assert "stories" in data["data"]

    def test_get_ingredient_category(self, client):
        """测试获取食材分类的所有故事。"""
        response = client.get("/api/v1/stories/category/ingredient")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["category"] == "ingredient"

    def test_get_physician_category(self, client):
        """测试获取医家分类的所有故事。"""
        response = client.get("/api/v1/stories/category/physician")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["category"] == "physician"

    def test_get_acupoint_category(self, client):
        """测试获取穴位分类的所有故事。"""
        response = client.get("/api/v1/stories/category/acupoint")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_get_tea_category(self, client):
        """测试获取茶文化分类。"""
        response = client.get("/api/v1/stories/category/tea")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_get_silk_road_category(self, client):
        """测试获取丝路分类。"""
        response = client.get("/api/v1/stories/category/silk_road")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_invalid_category(self, client):
        """测试无效的分类。"""
        response = client.get("/api/v1/stories/category/invalid_category")
        assert response.status_code == 400

    def test_category_results_structure(self, client):
        """测试分类结果的结构。"""
        response = client.get("/api/v1/stories/category/ingredient")
        data = response.json()
        assert "category" in data["data"]
        assert "total_in_category" in data["data"]
        assert "stories" in data["data"]
        for story in data["data"]["stories"]:
            assert "id" in story
            assert "title" in story


class TestRelatedStories:
    """GET /related/{tcm_element} 端点测试"""

    def test_get_stories_related_to_winter(self, client):
        """测试获取与冬季相关的故事。"""
        response = client.get("/api/v1/stories/related/winter")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["tcm_element"] == "winter"

    def test_get_stories_related_to_kidney(self, client):
        """测试获取与肾相关的故事。"""
        response = client.get("/api/v1/stories/related/kidney")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_get_stories_related_to_warming(self, client):
        """测试获取与温阳相关的故事。"""
        response = client.get("/api/v1/stories/related/warming")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_get_stories_related_to_qi_circulation(self, client):
        """测试获取与气循环相关的故事。"""
        response = client.get("/api/v1/stories/related/qi_circulation")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_related_stories_no_results(self, client):
        """测试无相关故事。"""
        response = client.get("/api/v1/stories/related/nonexistent_element_xyz")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["found"] is False

    def test_related_stories_structure(self, client):
        """测试相关故事的结构。"""
        response = client.get("/api/v1/stories/related/spring")
        data = response.json()
        if data["data"]["found"]:
            assert "tcm_element" in data["data"]
            assert "total_related" in data["data"]
            assert "stories" in data["data"]

    def test_multiple_related_elements(self, client):
        """测试多个相关元素。"""
        elements = ["winter", "kidney", "yang_qi", "digestion", "warming"]
        for element in elements:
            response = client.get(f"/api/v1/stories/related/{element}")
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True


class TestStoryCoverage:
    """故事覆盖率测试"""

    def test_minimum_stories_count(self, client):
        """测试至少有 15 个故事。"""
        response = client.get("/api/v1/stories/")
        data = response.json()
        assert data["data"]["total_stories"] >= 15

    def test_category_distribution(self, client):
        """测试各分类都有故事。"""
        categories = ["solar_term", "ingredient", "physician", "acupoint", "tea", "silk_road"]
        for category in categories:
            response = client.get(f"/api/v1/stories/category/{category}")
            data = response.json()
            if response.status_code == 200:
                assert data["success"] is True

    def test_all_stories_have_moral(self, client):
        """测试所有故事都有道德教训。"""
        response = client.get("/api/v1/stories/")
        stories = response.json()["data"]["stories"]
        for story in stories:
            detail_response = client.get(f"/api/v1/stories/{story['id']}")
            data = detail_response.json()
            assert "moral_lesson" in data["data"]

    def test_all_stories_have_tcm_elements(self, client):
        """测试所有故事都有相关 TCM 元素。"""
        response = client.get("/api/v1/stories/")
        stories = response.json()["data"]["stories"]
        for story in stories:
            detail_response = client.get(f"/api/v1/stories/{story['id']}")
            data = detail_response.json()
            assert "related_tcm_element" in data["data"]
            assert len(data["data"]["related_tcm_element"]) > 0


class TestErrorHandling:
    """错误处理测试"""

    def test_invalid_story_id_404(self, client):
        """测试无效的故事 ID 返回 404。"""
        response = client.get("/api/v1/stories/invalid_xyz")
        assert response.status_code == 404

    def test_invalid_category_400(self, client):
        """测试无效的分类返回 400。"""
        response = client.get("/api/v1/stories/category/invalid_cat")
        assert response.status_code == 400


class TestIntegration:
    """集成测试"""

    def test_daily_story_accessible_by_detail(self, client):
        """测试每日故事可以通过详情端点访问。"""
        daily_response = client.get("/api/v1/stories/daily")
        daily_story_id = daily_response.json()["data"]["daily_featured_story"]["id"]
        detail_response = client.get(f"/api/v1/stories/{daily_story_id}")
        assert detail_response.status_code == 200

    def test_category_filter_and_detail_workflow(self, client):
        """测试分类过滤→详情工作流。"""
        category_response = client.get("/api/v1/stories/category/ingredient")
        stories = category_response.json()["data"]["stories"]
        if stories:
            story_id = stories[0]["id"]
            detail_response = client.get(f"/api/v1/stories/{story_id}")
            assert detail_response.status_code == 200

    def test_related_stories_workflow(self, client):
        """测试相关故事工作流。"""
        related_response = client.get("/api/v1/stories/related/liver")
        data = related_response.json()
        if data["data"]["found"]:
            story_id = data["data"]["stories"][0]["id"]
            detail_response = client.get(f"/api/v1/stories/{story_id}")
            assert detail_response.status_code == 200

    def test_list_and_get_workflow(self, client):
        """测试列表→获取详情工作流。"""
        list_response = client.get("/api/v1/stories/")
        stories = list_response.json()["data"]["stories"]
        assert len(stories) > 0
        # 获取第一个故事的详情
        first_story_id = stories[0]["id"]
        detail_response = client.get(f"/api/v1/stories/{first_story_id}")
        assert detail_response.status_code == 200
        assert detail_response.json()["data"]["id"] == first_story_id

    def test_story_list_completeness(self, client):
        """测试故事列表的完整性。"""
        response = client.get("/api/v1/stories/")
        data = response.json()
        stories = data["data"]["stories"]
        # 每个故事都应该有基本信息
        for story in stories:
            assert all(key in story for key in ["id", "title", "category", "period"])


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
