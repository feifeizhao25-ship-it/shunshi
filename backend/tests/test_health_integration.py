"""
健康数据集成与 TCM 分析 - 单元测试
覆盖数据同步、TCM 分析规则、体质评分、个性化建议及数据删除功能。
"""

import pytest
from fastapi.testclient import TestClient
from datetime import datetime, timedelta


# 假设 FastAPI app 已正确导入
from app.main import app

client = TestClient(app)


# ─────────────────────────────────────────────────────────────────────────────
# 数据同步端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestHealthDataSync:
    """POST /api/v1/health-data/sync 端点测试"""

    def test_sync_steps_under_3000(self):
        """步数 < 3000 → 重度气虚"""
        payload = {
            "user_id": "user_sync_001",
            "data_type": "steps",
            "value": 2500,
            "unit": "steps",
            "recorded_at": datetime.now().isoformat(),
            "source": "google_fit",
        }
        response = client.post("/api/v1/health-data/sync", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["tcm_analysis"]["constitution"] == "重度气虚"
        assert data["data"]["tcm_analysis"]["score"] == 90

    def test_sync_steps_between_3000_5000(self):
        """步数 3000-5000 → 轻度气虚"""
        payload = {
            "user_id": "user_sync_002",
            "data_type": "steps",
            "value": 4500,
            "unit": "steps",
            "recorded_at": datetime.now().isoformat(),
            "source": "apple_health",
        }
        response = client.post("/api/v1/health-data/sync", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["tcm_analysis"]["constitution"] == "轻度气虚"
        assert data["data"]["tcm_analysis"]["score"] == 65

    def test_sync_steps_8000_12000(self):
        """步数 8000-12000 → 气血均衡"""
        payload = {
            "user_id": "user_sync_003",
            "data_type": "steps",
            "value": 10000,
            "unit": "steps",
            "recorded_at": datetime.now().isoformat(),
            "source": "manual",
        }
        response = client.post("/api/v1/health-data/sync", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["tcm_analysis"]["constitution"] == "气血均衡"
        assert data["data"]["tcm_analysis"]["score"] == 10

    def test_sync_steps_over_12000(self):
        """步数 > 12000 → 气血充足"""
        payload = {
            "user_id": "user_sync_004",
            "data_type": "steps",
            "value": 15000,
            "unit": "steps",
            "recorded_at": datetime.now().isoformat(),
            "source": "apple_health",
        }
        response = client.post("/api/v1/health-data/sync", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["tcm_analysis"]["constitution"] == "气血充足"
        assert data["data"]["tcm_analysis"]["score"] == 5

    def test_sync_sleep_under_5_hours(self):
        """睡眠 < 5 小时 → 重度心神失养"""
        payload = {
            "user_id": "user_sync_005",
            "data_type": "sleep",
            "value": 4.5,
            "unit": "hours",
            "recorded_at": datetime.now().isoformat(),
            "source": "apple_health",
        }
        response = client.post("/api/v1/health-data/sync", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["tcm_analysis"]["constitution"] == "重度心神失养"
        assert data["data"]["tcm_analysis"]["score"] == 95

    def test_sync_sleep_5_6_hours(self):
        """睡眠 5-6 小时 → 轻度心神失养"""
        payload = {
            "user_id": "user_sync_006",
            "data_type": "sleep",
            "value": 5.5,
            "unit": "hours",
            "recorded_at": datetime.now().isoformat(),
            "source": "manual",
        }
        response = client.post("/api/v1/health-data/sync", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["tcm_analysis"]["constitution"] == "轻度心神失养"
        assert data["data"]["tcm_analysis"]["score"] == 60

    def test_sync_sleep_7_8_hours(self):
        """睡眠 7-8 小时 → 心神得养"""
        payload = {
            "user_id": "user_sync_007",
            "data_type": "sleep",
            "value": 7.5,
            "unit": "hours",
            "recorded_at": datetime.now().isoformat(),
            "source": "google_fit",
        }
        response = client.post("/api/v1/health-data/sync", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["tcm_analysis"]["constitution"] == "心神得养"
        assert data["data"]["tcm_analysis"]["score"] == 5

    def test_sync_sleep_over_8_hours(self):
        """睡眠 > 8 小时 → 睡眠过度"""
        payload = {
            "user_id": "user_sync_008",
            "data_type": "sleep",
            "value": 9.0,
            "unit": "hours",
            "recorded_at": datetime.now().isoformat(),
            "source": "apple_health",
        }
        response = client.post("/api/v1/health-data/sync", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["tcm_analysis"]["constitution"] == "睡眠过度"
        assert data["data"]["tcm_analysis"]["score"] == 15

    def test_sync_hrv_under_20(self):
        """HRV < 20 → 重度肝气郁结"""
        payload = {
            "user_id": "user_sync_009",
            "data_type": "hrv",
            "value": 15,
            "unit": "ms",
            "recorded_at": datetime.now().isoformat(),
            "source": "apple_health",
        }
        response = client.post("/api/v1/health-data/sync", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["tcm_analysis"]["constitution"] == "重度肝气郁结"
        assert data["data"]["tcm_analysis"]["score"] == 85

    def test_sync_hrv_20_40(self):
        """HRV 20-40 → 轻度肝气郁结"""
        payload = {
            "user_id": "user_sync_010",
            "data_type": "hrv",
            "value": 35,
            "unit": "ms",
            "recorded_at": datetime.now().isoformat(),
            "source": "google_fit",
        }
        response = client.post("/api/v1/health-data/sync", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["tcm_analysis"]["constitution"] == "轻度肝气郁结"
        assert data["data"]["tcm_analysis"]["score"] == 55

    def test_sync_hrv_60_100(self):
        """HRV 60-100 → 肝气疏泄正常"""
        payload = {
            "user_id": "user_sync_011",
            "data_type": "hrv",
            "value": 80,
            "unit": "ms",
            "recorded_at": datetime.now().isoformat(),
            "source": "apple_health",
        }
        response = client.post("/api/v1/health-data/sync", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["tcm_analysis"]["constitution"] == "肝气疏泄正常"
        assert data["data"]["tcm_analysis"]["score"] == 8

    def test_sync_hr_50_60(self):
        """静息心率 50-60 → 气阴充足"""
        payload = {
            "user_id": "user_sync_012",
            "data_type": "heart_rate",
            "value": 55,
            "unit": "bpm",
            "recorded_at": datetime.now().isoformat(),
            "source": "apple_health",
        }
        response = client.post("/api/v1/health-data/sync", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["tcm_analysis"]["constitution"] == "气阴充足"
        assert data["data"]["tcm_analysis"]["score"] == 8

    def test_sync_hr_over_80(self):
        """静息心率 > 80 → 明显虚热倾向"""
        payload = {
            "user_id": "user_sync_013",
            "data_type": "heart_rate",
            "value": 85,
            "unit": "bpm",
            "recorded_at": datetime.now().isoformat(),
            "source": "google_fit",
        }
        response = client.post("/api/v1/health-data/sync", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["tcm_analysis"]["constitution"] == "明显虚热倾向"
        assert data["data"]["tcm_analysis"]["score"] == 75

    def test_sync_weight_normal(self):
        """体重在合理范围 → 脾胃功能正常"""
        payload = {
            "user_id": "user_sync_014",
            "data_type": "weight",
            "value": 65.0,
            "unit": "kg",
            "recorded_at": datetime.now().isoformat(),
            "source": "manual",
        }
        response = client.post("/api/v1/health-data/sync", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["tcm_analysis"]["constitution"] == "脾胃功能正常"
        assert data["data"]["tcm_analysis"]["score"] == 15


# ─────────────────────────────────────────────────────────────────────────────
# 健康数据摘要测试
# ─────────────────────────────────────────────────────────────────────────────

class TestHealthDataSummary:
    """GET /api/v1/health-data/summary/{user_id} 端点测试"""

    def test_summary_no_data(self):
        """用户无数据时的摘要"""
        response = client.get("/api/v1/health-data/summary/nonexistent_user")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["summary"] == "暂无数据"

    def test_summary_with_data(self):
        """用户有数据时的摘要"""
        # 先同步数据
        client.post("/api/v1/health-data/sync", json={
            "user_id": "user_summary_001",
            "data_type": "steps",
            "value": 8000,
            "unit": "steps",
            "recorded_at": datetime.now().isoformat(),
            "source": "apple_health",
        })

        # 查询摘要
        response = client.get("/api/v1/health-data/summary/user_summary_001")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "latest_values" in data["data"]
        assert "steps" in data["data"]["latest_values"]


# ─────────────────────────────────────────────────────────────────────────────
# TCM 分析端点测试
# ─────────────────────────────────────────────────────────────────────────────

class TestTCMAnalysis:
    """POST /api/v1/health-data/analyze 端点测试"""

    def test_analyze_all_parameters(self):
        """包含所有指标的综合分析"""
        payload = {
            "steps": 3000,
            "sleep_hours": 6.0,
            "resting_hr": 85,
            "hrv": 30,
        }
        response = client.post("/api/v1/health-data/analyze", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert len(data["data"]["analyses"]) == 4
        assert "overall_score" in data["data"]
        assert data["data"]["overall_score"] > 0

    def test_analyze_steps_only(self):
        """仅分析步数"""
        payload = {
            "steps": 10000,
            "sleep_hours": 0,
            "resting_hr": 0,
            "hrv": 0,
        }
        response = client.post("/api/v1/health-data/analyze", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]["analyses"]) == 1
        assert "气血均衡" in data["data"]["analyses"][0]["constitution"]

    def test_analyze_poor_metrics(self):
        """所有指标都不好的综合分析"""
        payload = {
            "steps": 2000,
            "sleep_hours": 4.0,
            "resting_hr": 90,
            "hrv": 20,
        }
        response = client.post("/api/v1/health-data/analyze", json=payload)
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["health_status"] == "需要调理"


# ─────────────────────────────────────────────────────────────────────────────
# TCM 体质评分测试
# ─────────────────────────────────────────────────────────────────────────────

class TestTCMMetrics:
    """GET /api/v1/health-data/tcm-metrics/{user_id} 端点测试"""

    def test_metrics_no_data(self):
        """用户无数据时的体质评分"""
        response = client.get("/api/v1/health-data/tcm-metrics/user_metrics_empty")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["qi_deficiency_score"] == 50

    def test_metrics_with_poor_steps(self):
        """步数低导致气虚评分提升"""
        # 同步低步数数据
        client.post("/api/v1/health-data/sync", json={
            "user_id": "user_metrics_001",
            "data_type": "steps",
            "value": 3000,
            "unit": "steps",
            "recorded_at": datetime.now().isoformat(),
            "source": "apple_health",
        })

        response = client.get("/api/v1/health-data/tcm-metrics/user_metrics_001")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["qi_deficiency_score"] > 50

    def test_metrics_with_poor_sleep(self):
        """睡眠不足导致心阴虚评分提升"""
        client.post("/api/v1/health-data/sync", json={
            "user_id": "user_metrics_002",
            "data_type": "sleep",
            "value": 5.0,
            "unit": "hours",
            "recorded_at": datetime.now().isoformat(),
            "source": "google_fit",
        })

        response = client.get("/api/v1/health-data/tcm-metrics/user_metrics_002")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["heart_yin_deficiency_score"] > 50


# ─────────────────────────────────────────────────────────────────────────────
# 个性化建议测试
# ─────────────────────────────────────────────────────────────────────────────

class TestRecommendations:
    """GET /api/v1/health-data/recommendations/{user_id} 端点测试"""

    def test_recommendations_no_data(self):
        """用户无数据时的建议"""
        response = client.get("/api/v1/health-data/recommendations/user_rec_empty")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "请先同步" in data["data"]["recommendations"][0]

    def test_recommendations_with_low_steps(self):
        """低步数触发运动建议"""
        client.post("/api/v1/health-data/sync", json={
            "user_id": "user_rec_001",
            "data_type": "steps",
            "value": 3000,
            "unit": "steps",
            "recorded_at": datetime.now().isoformat(),
            "source": "apple_health",
        })
        client.post("/api/v1/health-data/sync", json={
            "user_id": "user_rec_001",
            "data_type": "steps",
            "value": 2800,
            "unit": "steps",
            "recorded_at": (datetime.now() - timedelta(days=1)).isoformat(),
            "source": "apple_health",
        })

        response = client.get("/api/v1/health-data/recommendations/user_rec_001")
        assert response.status_code == 200
        data = response.json()
        recommendations_text = str(data["data"]["recommendations"])
        assert "运动" in recommendations_text or "步数" in recommendations_text

    def test_recommendations_with_low_sleep(self):
        """低睡眠触发睡眠建议"""
        client.post("/api/v1/health-data/sync", json={
            "user_id": "user_rec_002",
            "data_type": "sleep",
            "value": 5.5,
            "unit": "hours",
            "recorded_at": datetime.now().isoformat(),
            "source": "google_fit",
        })
        client.post("/api/v1/health-data/sync", json={
            "user_id": "user_rec_002",
            "data_type": "sleep",
            "value": 5.0,
            "unit": "hours",
            "recorded_at": (datetime.now() - timedelta(days=2)).isoformat(),
            "source": "google_fit",
        })

        response = client.get("/api/v1/health-data/recommendations/user_rec_002")
        assert response.status_code == 200
        data = response.json()
        recommendations_text = str(data["data"]["recommendations"])
        assert "睡眠" in recommendations_text

    def test_recommendations_with_low_hrv(self):
        """低 HRV 触发心理建议"""
        client.post("/api/v1/health-data/sync", json={
            "user_id": "user_rec_003",
            "data_type": "hrv",
            "value": 25,
            "unit": "ms",
            "recorded_at": datetime.now().isoformat(),
            "source": "apple_health",
        })

        response = client.get("/api/v1/health-data/recommendations/user_rec_003")
        assert response.status_code == 200
        data = response.json()
        recommendations_text = str(data["data"]["recommendations"])
        assert "心" in recommendations_text or "肝" in recommendations_text

    def test_recommendations_good_metrics(self):
        """良好指标返回保健建议"""
        client.post("/api/v1/health-data/sync", json={
            "user_id": "user_rec_004",
            "data_type": "steps",
            "value": 10000,
            "unit": "steps",
            "recorded_at": datetime.now().isoformat(),
            "source": "apple_health",
        })
        client.post("/api/v1/health-data/sync", json={
            "user_id": "user_rec_004",
            "data_type": "sleep",
            "value": 7.5,
            "unit": "hours",
            "recorded_at": datetime.now().isoformat(),
            "source": "google_fit",
        })

        response = client.get("/api/v1/health-data/recommendations/user_rec_004")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True


# ─────────────────────────────────────────────────────────────────────────────
# 数据删除端点测试 (GDPR)
# ─────────────────────────────────────────────────────────────────────────────

class TestDeleteUserData:
    """DELETE /api/v1/health-data/{user_id} 端点测试"""

    def test_delete_nonexistent_user(self):
        """删除不存在用户的数据"""
        response = client.delete("/api/v1/health-data/delete/nonexistent_user_delete")
        assert response.status_code == 404

    def test_delete_existing_user(self):
        """删除存在用户的数据"""
        user_id = "user_delete_001"

        # 先同步一些数据
        client.post("/api/v1/health-data/sync", json={
            "user_id": user_id,
            "data_type": "steps",
            "value": 5000,
            "unit": "steps",
            "recorded_at": datetime.now().isoformat(),
            "source": "apple_health",
        })

        # 删除用户数据
        response = client.delete(f"/api/v1/health-data/delete/{user_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["deleted"] is True

        # 验证数据已删除
        summary_response = client.get(f"/api/v1/health-data/summary/{user_id}")
        assert summary_response.json()["data"]["summary"] == "暂无数据"

    def test_delete_gdpr_compliance(self):
        """验证删除操作返回 GDPR 合规信息"""
        user_id = "user_delete_gdpr"

        client.post("/api/v1/health-data/sync", json={
            "user_id": user_id,
            "data_type": "weight",
            "value": 70.0,
            "unit": "kg",
            "recorded_at": datetime.now().isoformat(),
            "source": "manual",
        })

        response = client.delete(f"/api/v1/health-data/delete/{user_id}")
        assert response.status_code == 200
        data = response.json()
        assert "GDPR" in data["data"]["message"]


# ─────────────────────────────────────────────────────────────────────────────
# 集成测试
# ─────────────────────────────────────────────────────────────────────────────

class TestIntegration:
    """端点间的集成测试"""

    def test_sync_analyze_recommend_flow(self):
        """完整的数据同步 → 分析 → 建议流程"""
        user_id = "user_integration_001"

        # 1. 同步多个数据点
        client.post("/api/v1/health-data/sync", json={
            "user_id": user_id,
            "data_type": "steps",
            "value": 4000,
            "unit": "steps",
            "recorded_at": datetime.now().isoformat(),
            "source": "apple_health",
        })

        client.post("/api/v1/health-data/sync", json={
            "user_id": user_id,
            "data_type": "sleep",
            "value": 6.0,
            "unit": "hours",
            "recorded_at": datetime.now().isoformat(),
            "source": "google_fit",
        })

        # 2. 获取摘要
        summary = client.get(f"/api/v1/health-data/summary/{user_id}")
        assert summary.status_code == 200

        # 3. 获取建议
        recommendations = client.get(f"/api/v1/health-data/recommendations/{user_id}")
        assert recommendations.status_code == 200
        assert recommendations.json()["success"] is True

        # 4. 获取体质评分
        metrics = client.get(f"/api/v1/health-data/tcm-metrics/{user_id}")
        assert metrics.status_code == 200
        assert metrics.json()["data"]["qi_deficiency_score"] > 50
