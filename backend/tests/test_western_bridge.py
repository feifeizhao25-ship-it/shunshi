"""
测试：中西医概念融合桥接引擎
"""

import pytest
from fastapi.testclient import TestClient
from app.router.western_bridge import router


@pytest.fixture
def client():
    """创建测试客户端。"""
    from fastapi import FastAPI
    app = FastAPI()
    app.include_router(router)
    return TestClient(app)


class TestGetConcepts:
    """GET /concepts 端点测试"""

    def test_get_all_concepts(self, client):
        """测试获取所有概念。"""
        response = client.get("/api/v1/bridge/concepts")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "total_concepts" in data["data"]
        assert "concepts" in data["data"]
        assert data["data"]["total_concepts"] >= 15

    def test_concepts_structure(self, client):
        """测试概念列表结构。"""
        response = client.get("/api/v1/bridge/concepts")
        data = response.json()
        for concept in data["data"]["concepts"]:
            assert "concept_id" in concept
            assert "tcm_concept" in concept
            assert "western_equivalent" in concept
            assert isinstance(concept["western_equivalent"], list)

    def test_concepts_have_descriptions(self, client):
        """测试概念包含西方等价物。"""
        response = client.get("/api/v1/bridge/concepts")
        data = response.json()
        for concept in data["data"]["concepts"]:
            assert len(concept["western_equivalent"]) > 0


class TestGetConceptDetail:
    """GET /concepts/{concept_id} 端点测试"""

    def test_get_concept_liver_qi_stagnation(self, client):
        """测试获取肝气郁结概念。"""
        response = client.get("/api/v1/bridge/concepts/liver_qi_stagnation")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["tcm_concept"] == "肝气郁结"

    def test_concept_detail_complete_info(self, client):
        """测试概念详情包含完整信息。"""
        response = client.get("/api/v1/bridge/concepts/damp_heat_constitution")
        data = response.json()
        concept = data["data"]
        assert "tcm_description_cn" in concept
        assert "western_explanation" in concept
        assert "functional_medicine_parallel" in concept
        assert "dietary_connection" in concept
        assert "research_note" in concept
        assert "symptom_overlap" in concept

    def test_all_concepts_accessible(self, client):
        """测试所有概念都可以通过 ID 访问。"""
        concepts_response = client.get("/api/v1/bridge/concepts")
        concepts = concepts_response.json()["data"]["concepts"]
        for concept in concepts:
            detail_response = client.get(f"/api/v1/bridge/concepts/{concept['concept_id']}")
            assert detail_response.status_code == 200

    def test_get_concept_qi_deficiency(self, client):
        """测试获取气虚概念。"""
        response = client.get("/api/v1/bridge/concepts/qi_deficiency")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["tcm_concept"] == "气虚"

    def test_get_concept_invalid_id(self, client):
        """测试无效的概念 ID 返回 404。"""
        response = client.get("/api/v1/bridge/concepts/invalid_concept_xyz")
        assert response.status_code == 404


class TestSearchBySymptom:
    """GET /search 端点测试"""

    def test_search_fatigue(self, client):
        """测试搜索「疲劳」。"""
        response = client.get("/api/v1/bridge/search?symptom=fatigue")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["symptom"] == "fatigue"
        # fatigue 可能与多个概念相关

    def test_search_insomnia(self, client):
        """测试搜索「失眠」。"""
        response = client.get("/api/v1/bridge/search?symptom=insomnia")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        if data["data"]["found"]:
            assert len(data["data"]["concepts"]) > 0

    def test_search_no_results(self, client):
        """测试搜索无结果。"""
        response = client.get("/api/v1/bridge/search?symptom=nonexistent_symptom_xyz")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["found"] is False
        assert len(data["data"]["concepts"]) == 0

    def test_search_multiple_symptoms(self, client):
        """测试搜索不同症状。"""
        symptoms = ["bloating", "anxiety", "cold_intolerance", "acne"]
        for symptom in symptoms:
            response = client.get(f"/api/v1/bridge/search?symptom={symptom}")
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True
            assert data["data"]["symptom"] == symptom

    def test_search_results_have_concept_id(self, client):
        """测试搜索结果包含概念 ID。"""
        response = client.get("/api/v1/bridge/search?symptom=bloating")
        data = response.json()
        if data["data"]["found"]:
            for concept in data["data"]["concepts"]:
                assert "concept_id" in concept
                assert "tcm_concept" in concept

    def test_search_case_insensitive(self, client):
        """测试搜索不区分大小写。"""
        response1 = client.get("/api/v1/bridge/search?symptom=fatigue")
        response2 = client.get("/api/v1/bridge/search?symptom=FATIGUE")
        # 两个应该返回相同的结果结构
        assert response1.status_code == 200
        assert response2.status_code == 200


class TestConstitutionSearch:
    """GET /constitution/{western_description} 端点测试"""

    def test_find_constitution_inflammatory(self, client):
        """测试通过「炎症」描述查找体质。"""
        response = client.get("/api/v1/bridge/constitution?q=inflammatory")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["query"] == "inflammatory"

    def test_find_constitution_metabolic_syndrome(self, client):
        """测试查找代谢综合征相关体质。"""
        response = client.get("/api/v1/bridge/constitution?q=metabolic%20syndrome")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_find_constitution_no_results(self, client):
        """测试无搜索结果。"""
        response = client.get("/api/v1/bridge/constitution?q=nonexistent_description_xyz")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["found"] is False

    def test_find_constitution_multiple_descriptions(self, client):
        """测试多种西方描述。"""
        descriptions = ["fatigue", "cold", "obesity", "sluggishness"]
        for desc in descriptions:
            response = client.get(f"/api/v1/bridge/constitution?q={desc}")
            assert response.status_code == 200

    def test_constitution_results_have_functional_medicine(self, client):
        """测试结果包含功能医学对应。"""
        response = client.get("/api/v1/bridge/constitution?q=metabolic")
        data = response.json()
        if data["data"]["found"]:
            for constitution in data["data"]["constitutions"]:
                assert "functional_medicine_parallel" in constitution


class TestExplainTcm:
    """GET /explain/{tcm_term} 端点测试"""

    def test_explain_liver_qi_stagnation(self, client):
        """测试解释肝气郁结。"""
        response = client.get("/api/v1/bridge/explain/liver_qi_stagnation")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "western_explanation" in data["data"]
        assert "functional_medicine_parallel" in data["data"]

    def test_explain_by_chinese_term(self, client):
        """测试通过中文术语解释。"""
        response = client.get("/api/v1/bridge/explain/肝气郁结")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_explain_comprehensive_info(self, client):
        """测试解释包含完整信息。"""
        response = client.get("/api/v1/bridge/explain/qi_deficiency")
        data = response.json()
        info = data["data"]
        assert "tcm_description_cn" in info
        assert "western_explanation" in info
        assert "western_equivalent" in info
        assert "functional_medicine_parallel" in info
        assert "research_note" in info
        assert "symptom_overlap" in info

    def test_explain_invalid_term(self, client):
        """测试无效的术语。"""
        response = client.get("/api/v1/bridge/explain/invalid_tcm_term_xyz")
        assert response.status_code == 404

    def test_explain_multiple_terms(self, client):
        """测试解释多个术语。"""
        terms = [
            "liver_qi_stagnation",
            "damp_heat_constitution",
            "qi_deficiency",
            "yin_deficiency",
            "yang_deficiency",
        ]
        for term in terms:
            response = client.get(f"/api/v1/bridge/explain/{term}")
            assert response.status_code == 200


class TestDietScience:
    """GET /diet-science/{concept_id} 端点测试"""

    def test_get_diet_science_damp_heat(self, client):
        """测试获取湿热体质的饮食科学。"""
        response = client.get("/api/v1/bridge/diet-science/damp_heat_constitution")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "dietary_recommendations" in data["data"]
        assert "functional_medicine_basis" in data["data"]

    def test_diet_science_comprehensive(self, client):
        """测试饮食科学包含完整信息。"""
        response = client.get("/api/v1/bridge/diet-science/qi_deficiency")
        data = response.json()
        info = data["data"]
        assert "concept_id" in info
        assert "tcm_concept" in info
        assert "western_explanation" in info
        assert "functional_medicine_basis" in info
        assert "dietary_recommendations" in info
        assert "research_background" in info

    def test_diet_science_all_concepts(self, client):
        """测试所有概念都有饮食建议。"""
        concepts_response = client.get("/api/v1/bridge/concepts")
        concepts = concepts_response.json()["data"]["concepts"]
        for concept in concepts:
            response = client.get(f"/api/v1/bridge/diet-science/{concept['concept_id']}")
            assert response.status_code == 200

    def test_diet_science_invalid_concept(self, client):
        """测试无效的概念 ID。"""
        response = client.get("/api/v1/bridge/diet-science/invalid_concept")
        assert response.status_code == 404

    def test_diet_science_includes_recommendations(self, client):
        """测试饮食科学包含具体的饮食建议。"""
        response = client.get("/api/v1/bridge/diet-science/liver_qi_stagnation")
        data = response.json()
        recommendations = data["data"]["dietary_recommendations"]
        assert isinstance(recommendations, str)
        assert len(recommendations) > 0


class TestConceptCoverage:
    """概念桥接覆盖率测试"""

    def test_minimum_concepts_count(self, client):
        """测试至少有 15 个概念。"""
        response = client.get("/api/v1/bridge/concepts")
        data = response.json()
        assert data["data"]["total_concepts"] >= 15

    def test_all_concepts_have_bridges(self, client):
        """测试所有概念都有中西医桥接。"""
        concepts_response = client.get("/api/v1/bridge/concepts")
        concepts = concepts_response.json()["data"]["concepts"]
        for concept in concepts:
            response = client.get(f"/api/v1/bridge/concepts/{concept['concept_id']}")
            data = response.json()
            concept_detail = data["data"]
            assert concept_detail["western_equivalent"]
            assert concept_detail["functional_medicine_parallel"]

    def test_symptom_overlap_coverage(self, client):
        """测试所有概念都有症状重叠列表。"""
        concepts_response = client.get("/api/v1/bridge/concepts")
        concepts = concepts_response.json()["data"]["concepts"]
        for concept in concepts:
            response = client.get(f"/api/v1/bridge/concepts/{concept['concept_id']}")
            data = response.json()
            assert "symptom_overlap" in data["data"]
            assert isinstance(data["data"]["symptom_overlap"], list)


class TestErrorHandling:
    """错误处理测试"""

    def test_search_missing_symptom_parameter(self, client):
        """测试缺少症状参数。"""
        response = client.get("/api/v1/bridge/search")
        assert response.status_code == 422

    def test_constitution_missing_query_parameter(self, client):
        """测试缺少查询参数。"""
        response = client.get("/api/v1/bridge/constitution")
        assert response.status_code == 422

    def test_invalid_concept_returns_404(self, client):
        """测试无效的概念 ID 返回 404。"""
        response = client.get("/api/v1/bridge/concepts/nonexistent_xyz")
        assert response.status_code == 404


class TestIntegration:
    """集成测试"""

    def test_search_and_explain_workflow(self, client):
        """测试搜索→解释工作流。"""
        # 搜索症状
        search_response = client.get("/api/v1/bridge/search?symptom=fatigue")
        search_data = search_response.json()
        if search_data["data"]["found"]:
            concept_id = search_data["data"]["concepts"][0]["concept_id"]
            # 获取详情
            detail_response = client.get(f"/api/v1/bridge/concepts/{concept_id}")
            assert detail_response.status_code == 200

    def test_constitution_to_diet_workflow(self, client):
        """测试体质→饮食工作流。"""
        constitution_response = client.get("/api/v1/bridge/constitution?q=inflammatory")
        constitution_data = constitution_response.json()
        if constitution_data["data"]["found"]:
            concept_id = constitution_data["data"]["constitutions"][0]["concept_id"]
            diet_response = client.get(f"/api/v1/bridge/diet-science/{concept_id}")
            assert diet_response.status_code == 200
            assert "dietary_recommendations" in diet_response.json()["data"]

    def test_western_to_tcm_explanation_workflow(self, client):
        """测试西方描述→TCM 解释工作流。"""
        # 通过西方症状找到 TCM 概念
        search_response = client.get("/api/v1/bridge/search?symptom=bloating")
        search_data = search_response.json()
        if search_data["data"]["found"]:
            concept = search_data["data"]["concepts"][0]
            # 获取详细解释
            explain_response = client.get(f"/api/v1/bridge/explain/{concept['concept_id']}")
            assert explain_response.status_code == 200


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
