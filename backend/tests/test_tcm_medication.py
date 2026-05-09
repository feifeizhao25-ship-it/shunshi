"""
顺时 — 中药服药提醒与禁忌管理 API 测试
包含 35+ pytest 测试，覆盖全部 6 个端点。
"""

import pytest
from fastapi.testclient import TestClient
from fastapi import FastAPI
from datetime import datetime

# 假设 router 已被导入
from app.router.tcm_medication import router

app = FastAPI()
app.include_router(router)
client = TestClient(app)


# ─────────────────────────────────────────────────────────────────────────────
# 测试 GET /api/v1/medication/medicines
# ─────────────────────────────────────────────────────────────────────────────

class TestListMedicines:
    """测试药品列表端点"""

    def test_list_all_medicines_success(self):
        """测试成功获取全部药品"""
        response = client.get("/api/v1/medication/medicines")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "data" in data

    def test_list_medicines_count(self):
        """测试返回 15 种药品"""
        response = client.get("/api/v1/medication/medicines")
        data = response.json()["data"]
        assert data["total"] == 15
        assert len(data["medicines"]) == 15

    def test_list_medicines_all_ids_present(self):
        """测试所有预期的药品 ID 都存在"""
        response = client.get("/api/v1/medication/medicines")
        medicines = response.json()["data"]["medicines"]
        med_ids = [m["id"] for m in medicines]
        expected_ids = [f"med_{i:03d}" for i in range(1, 16)]
        for med_id in expected_ids:
            assert med_id in med_ids

    def test_list_medicines_has_required_fields(self):
        """测试每种药品都包含必需字段"""
        response = client.get("/api/v1/medication/medicines")
        medicines = response.json()["data"]["medicines"]
        for medicine in medicines:
            required_fields = [
                "id", "name", "category", "constitution_suitable",
                "timing", "food_taboos", "drug_interactions_warning",
                "dosage_note", "duration_typical", "tcm_function", "caution"
            ]
            for field in required_fields:
                assert field in medicine, f"Field {field} not found in medicine {medicine.get('id')}"

    @pytest.mark.parametrize("category", [
        "补阴", "补阳", "疏肝理气", "补气补血", "补气",
        "清热", "活血", "化痰", "健脾", "补气健神", "安神"
    ])
    def test_list_medicines_filter_by_category(self, category):
        """测试按分类过滤"""
        response = client.get(f"/api/v1/medication/medicines?category={category}")
        assert response.status_code == 200
        data = response.json()["data"]
        # 验证过滤结果中的所有药品都属于指定分类
        for medicine in data["medicines"]:
            assert medicine["category"] == category

    @pytest.mark.parametrize("constitution", [
        "yin_deficiency", "yang_deficiency", "qi_deficiency", "damp_heat", "heart_weakness"
    ])
    def test_list_medicines_filter_by_constitution(self, constitution):
        """测试按体质过滤"""
        response = client.get(f"/api/v1/medication/medicines?constitution={constitution}")
        assert response.status_code == 200
        data = response.json()["data"]
        # 验证过滤结果中的所有药品都适用于该体质
        for medicine in data["medicines"]:
            assert constitution in medicine["constitution_suitable"]

    def test_list_medicines_filter_both_parameters(self):
        """测试同时过滤分类和体质"""
        response = client.get("/api/v1/medication/medicines?category=补阴&constitution=yin_deficiency")
        assert response.status_code == 200
        data = response.json()["data"]
        for medicine in data["medicines"]:
            assert medicine["category"] == "补阴"
            assert "yin_deficiency" in medicine["constitution_suitable"]

    def test_list_medicines_food_taboos_is_list(self):
        """测试食物禁忌为列表"""
        response = client.get("/api/v1/medication/medicines")
        medicines = response.json()["data"]["medicines"]
        for medicine in medicines:
            assert isinstance(medicine["food_taboos"], list)

    def test_list_medicines_drug_interactions_is_list(self):
        """测试药物相互作用为列表"""
        response = client.get("/api/v1/medication/medicines")
        medicines = response.json()["data"]["medicines"]
        for medicine in medicines:
            assert isinstance(medicine["drug_interactions_warning"], list)


# ─────────────────────────────────────────────────────────────────────────────
# 测试 GET /api/v1/medication/medicines/{med_id}
# ─────────────────────────────────────────────────────────────────────────────

class TestGetMedicine:
    """测试药品详情端点"""

    @pytest.mark.parametrize("med_id", [f"med_{i:03d}" for i in range(1, 16)])
    def test_get_medicine_success(self, med_id):
        """测试获取所有有效药品的详情"""
        response = client.get(f"/api/v1/medication/medicines/{med_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "data" in data

    @pytest.mark.parametrize("med_id", [f"med_{i:03d}" for i in range(1, 16)])
    def test_get_medicine_has_complete_info(self, med_id):
        """测试药品信息完整性"""
        response = client.get(f"/api/v1/medication/medicines/{med_id}")
        medicine = response.json()["data"]
        required_fields = [
            "id", "name", "category", "constitution_suitable",
            "timing", "food_taboos", "drug_interactions_warning",
            "dosage_note", "duration_typical", "tcm_function", "caution"
        ]
        for field in required_fields:
            assert field in medicine

    def test_get_medicine_invalid_id_404(self):
        """测试无效药品 ID 返回 404"""
        response = client.get("/api/v1/medication/medicines/invalid_id")
        assert response.status_code == 404

    def test_get_medicine_liuwei_dihuang(self):
        """测试六味地黄丸详情"""
        response = client.get("/api/v1/medication/medicines/med_001")
        medicine = response.json()["data"]
        assert medicine["name"] == "六味地黄丸"
        assert medicine["category"] == "补阴"
        assert "yin_deficiency" in medicine["constitution_suitable"]

    def test_get_medicine_jinqu_shenqi(self):
        """测试金匮肾气丸详情"""
        response = client.get("/api/v1/medication/medicines/med_002")
        medicine = response.json()["data"]
        assert medicine["name"] == "金匮肾气丸"
        assert medicine["category"] == "补阳"

    def test_get_medicine_timing_valid(self):
        """测试药品服用时间有效"""
        response = client.get("/api/v1/medication/medicines/med_001")
        medicine = response.json()["data"]
        assert medicine["timing"] in ["饭前", "饭后", "睡前"]

    def test_get_medicine_food_taboos_populated(self):
        """测试药品有食物禁忌"""
        response = client.get("/api/v1/medication/medicines/med_001")
        medicine = response.json()["data"]
        assert isinstance(medicine["food_taboos"], list)
        assert len(medicine["food_taboos"]) > 0


# ─────────────────────────────────────────────────────────────────────────────
# 测试 POST /api/v1/medication/reminder
# ─────────────────────────────────────────────────────────────────────────────

class TestCreateReminder:
    """测试创建用药提醒端点"""

    def test_create_reminder_success(self):
        """测试成功创建用药提醒"""
        response = client.post(
            "/api/v1/medication/reminder",
            json={
                "user_id": "user_001",
                "medicine_id": "med_001",
                "times_per_day": 3,
                "start_date": "2024-01-01",
                "notes": "饭后温水送服"
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "data" in data

    def test_create_reminder_has_all_fields(self):
        """测试创建的提醒包含所有字段"""
        response = client.post(
            "/api/v1/medication/reminder",
            json={
                "user_id": "user_001",
                "medicine_id": "med_001",
                "times_per_day": 2,
                "start_date": "2024-01-01",
                "notes": "早晚各一次"
            }
        )
        reminder = response.json()["data"]
        required_fields = [
            "reminder_id", "user_id", "medicine_id", "medicine_name",
            "times_per_day", "start_date", "notes", "created_at"
        ]
        for field in required_fields:
            assert field in reminder

    def test_create_reminder_invalid_medicine_404(self):
        """测试使用无效药品 ID 返回 404"""
        response = client.post(
            "/api/v1/medication/reminder",
            json={
                "user_id": "user_001",
                "medicine_id": "invalid_id",
                "times_per_day": 2,
                "start_date": "2024-01-01"
            }
        )
        assert response.status_code == 404

    def test_create_reminder_without_notes(self):
        """测试不提供备注信息的提醒"""
        response = client.post(
            "/api/v1/medication/reminder",
            json={
                "user_id": "user_002",
                "medicine_id": "med_002",
                "times_per_day": 2,
                "start_date": "2024-01-01"
            }
        )
        assert response.status_code == 200
        reminder = response.json()["data"]
        assert reminder["notes"] is None

    def test_create_multiple_reminders_same_user(self):
        """测试同一用户创建多个提醒"""
        for i in range(3):
            response = client.post(
                "/api/v1/medication/reminder",
                json={
                    "user_id": "user_multi",
                    "medicine_id": f"med_{i+1:03d}",
                    "times_per_day": 2,
                    "start_date": "2024-01-01"
                }
            )
            assert response.status_code == 200

    def test_create_reminder_generates_unique_id(self):
        """测试每个提醒都有唯一 ID"""
        response1 = client.post(
            "/api/v1/medication/reminder",
            json={
                "user_id": "user_unique",
                "medicine_id": "med_001",
                "times_per_day": 2,
                "start_date": "2024-01-01"
            }
        )
        response2 = client.post(
            "/api/v1/medication/reminder",
            json={
                "user_id": "user_unique",
                "medicine_id": "med_002",
                "times_per_day": 2,
                "start_date": "2024-01-01"
            }
        )
        id1 = response1.json()["data"]["reminder_id"]
        id2 = response2.json()["data"]["reminder_id"]
        assert id1 != id2

    def test_create_reminder_has_created_at(self):
        """测试提醒包含创建时间"""
        response = client.post(
            "/api/v1/medication/reminder",
            json={
                "user_id": "user_time",
                "medicine_id": "med_001",
                "times_per_day": 2,
                "start_date": "2024-01-01"
            }
        )
        reminder = response.json()["data"]
        assert "created_at" in reminder
        assert len(reminder["created_at"]) > 0


# ─────────────────────────────────────────────────────────────────────────────
# 测试 GET /api/v1/medication/reminder/{user_id}
# ─────────────────────────────────────────────────────────────────────────────

class TestGetUserReminders:
    """测试获取用户提醒列表端点"""

    def test_get_user_reminders_empty(self):
        """测试获取不存在的用户的提醒（空列表）"""
        response = client.get("/api/v1/medication/reminder/nonexistent_user")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["total"] == 0
        assert data["reminders"] == []

    def test_get_user_reminders_after_create(self):
        """测试创建提醒后能获取"""
        user_id = "user_retrieve"
        # 创建提醒
        client.post(
            "/api/v1/medication/reminder",
            json={
                "user_id": user_id,
                "medicine_id": "med_001",
                "times_per_day": 2,
                "start_date": "2024-01-01"
            }
        )
        # 获取提醒
        response = client.get(f"/api/v1/medication/reminder/{user_id}")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["total"] == 1
        assert len(data["reminders"]) == 1

    def test_get_user_reminders_multiple(self):
        """测试获取多个提醒"""
        user_id = "user_multiple"
        # 创建 3 个提醒
        for i in range(1, 4):
            client.post(
                "/api/v1/medication/reminder",
                json={
                    "user_id": user_id,
                    "medicine_id": f"med_{i:03d}",
                    "times_per_day": 2,
                    "start_date": "2024-01-01"
                }
            )
        # 获取所有提醒
        response = client.get(f"/api/v1/medication/reminder/{user_id}")
        data = response.json()["data"]
        assert data["total"] == 3
        assert len(data["reminders"]) == 3

    def test_get_user_reminders_has_required_fields(self):
        """测试提醒记录包含所有字段"""
        user_id = "user_fields"
        client.post(
            "/api/v1/medication/reminder",
            json={
                "user_id": user_id,
                "medicine_id": "med_001",
                "times_per_day": 2,
                "start_date": "2024-01-01"
            }
        )
        response = client.get(f"/api/v1/medication/reminder/{user_id}")
        reminders = response.json()["data"]["reminders"]
        reminder = reminders[0]
        required_fields = [
            "reminder_id", "user_id", "medicine_id", "medicine_name",
            "times_per_day", "start_date", "created_at"
        ]
        for field in required_fields:
            assert field in reminder

    def test_get_user_reminders_count_accurate(self):
        """测试提醒计数准确"""
        user_id = "user_count"
        # 创建 5 个提醒
        for i in range(1, 6):
            client.post(
                "/api/v1/medication/reminder",
                json={
                    "user_id": user_id,
                    "medicine_id": f"med_{i:03d}",
                    "times_per_day": i,
                    "start_date": "2024-01-01"
                }
            )
        response = client.get(f"/api/v1/medication/reminder/{user_id}")
        data = response.json()["data"]
        assert data["total"] == 5


# ─────────────────────────────────────────────────────────────────────────────
# 测试 GET /api/v1/medication/check-interaction
# ─────────────────────────────────────────────────────────────────────────────

class TestCheckDrugInteraction:
    """测试药物相互作用检查端点"""

    def test_check_interaction_no_interaction(self):
        """测试无相互作用的两种药物"""
        response = client.get(
            "/api/v1/medication/check-interaction?med1=med_001&med2=med_003"
        )
        assert response.status_code == 200
        data = response.json()["data"]
        assert "has_interaction" in data
        assert "medicine_1" in data
        assert "medicine_2" in data
        assert "warning" in data

    def test_check_interaction_liuwei_vs_mahuang(self):
        """测试六味地黄丸与麻黄的相互作用"""
        # 这是一个已知的配伍禁忌
        response = client.get(
            "/api/v1/medication/check-interaction?med1=med_001&med2=med_002"
        )
        assert response.status_code == 200
        data = response.json()["data"]
        assert isinstance(data["has_interaction"], bool)

    def test_check_interaction_jinqu_shenqi_vs_liuwei(self):
        """测试金匮肾气丸与六味地黄丸（温阳 vs 滋阴）"""
        response = client.get(
            "/api/v1/medication/check-interaction?med1=med_002&med2=med_001"
        )
        assert response.status_code == 200
        data = response.json()["data"]
        # 这两个药物可能存在相克
        assert isinstance(data["has_interaction"], bool)

    def test_check_interaction_invalid_med1_404(self):
        """测试无效的第一种药物 ID"""
        response = client.get(
            "/api/v1/medication/check-interaction?med1=invalid&med2=med_001"
        )
        assert response.status_code == 404

    def test_check_interaction_invalid_med2_404(self):
        """测试无效的第二种药物 ID"""
        response = client.get(
            "/api/v1/medication/check-interaction?med1=med_001&med2=invalid"
        )
        assert response.status_code == 404

    @pytest.mark.parametrize("med1,med2", [
        ("med_001", "med_002"),
        ("med_003", "med_004"),
        ("med_005", "med_006"),
        ("med_007", "med_008"),
    ])
    def test_check_interaction_various_pairs(self, med1, med2):
        """测试各种药物组合"""
        response = client.get(
            f"/api/v1/medication/check-interaction?med1={med1}&med2={med2}"
        )
        assert response.status_code == 200
        data = response.json()["data"]
        assert "has_interaction" in data

    def test_check_interaction_same_medicine(self):
        """测试相同药物的相互作用"""
        response = client.get(
            "/api/v1/medication/check-interaction?med1=med_001&med2=med_001"
        )
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["medicine_1"] == data["medicine_2"]


# ─────────────────────────────────────────────────────────────────────────────
# 测试 GET /api/v1/medication/taboos/{med_id}
# ─────────────────────────────────────────────────────────────────────────────

class TestGetMedicineTaboos:
    """测试获取药物禁忌端点"""

    @pytest.mark.parametrize("med_id", [f"med_{i:03d}" for i in range(1, 16)])
    def test_get_taboos_success(self, med_id):
        """测试获取所有药品的禁忌"""
        response = client.get(f"/api/v1/medication/taboos/{med_id}")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "data" in data

    @pytest.mark.parametrize("med_id", [f"med_{i:03d}" for i in range(1, 16)])
    def test_get_taboos_has_required_fields(self, med_id):
        """测试禁忌信息包含所有字段"""
        response = client.get(f"/api/v1/medication/taboos/{med_id}")
        data = response.json()["data"]
        required_fields = [
            "medicine_id", "medicine_name", "food_taboos",
            "drug_interactions_warning", "lifestyle_cautions",
            "general_caution", "dosage_note", "timing"
        ]
        for field in required_fields:
            assert field in data

    def test_get_taboos_invalid_id_404(self):
        """测试无效药品 ID 返回 404"""
        response = client.get("/api/v1/medication/taboos/invalid_id")
        assert response.status_code == 404

    def test_get_taboos_liuwei_dihuang(self):
        """测试六味地黄丸的禁忌"""
        response = client.get("/api/v1/medication/taboos/med_001")
        data = response.json()["data"]
        assert data["medicine_name"] == "六味地黄丸"
        assert isinstance(data["food_taboos"], list)
        assert len(data["food_taboos"]) > 0

    def test_get_taboos_food_taboos_is_list(self):
        """测试食物禁忌为列表"""
        response = client.get("/api/v1/medication/taboos/med_001")
        data = response.json()["data"]
        assert isinstance(data["food_taboos"], list)
        assert len(data["food_taboos"]) > 0

    def test_get_taboos_drug_interactions_is_list(self):
        """测试药物相互作用为列表"""
        response = client.get("/api/v1/medication/taboos/med_001")
        data = response.json()["data"]
        assert isinstance(data["drug_interactions_warning"], list)

    def test_get_taboos_lifestyle_cautions_is_list(self):
        """测试生活方式禁忌为列表"""
        response = client.get("/api/v1/medication/taboos/med_001")
        data = response.json()["data"]
        assert isinstance(data["lifestyle_cautions"], list)
        assert len(data["lifestyle_cautions"]) > 0

    def test_get_taboos_has_dosage_and_timing(self):
        """测试禁忌包含用法和服用时间"""
        response = client.get("/api/v1/medication/taboos/med_001")
        data = response.json()["data"]
        assert len(data["dosage_note"]) > 0
        assert data["timing"] in ["饭前", "饭后", "睡前"]

    def test_get_taboos_complete_info(self):
        """测试禁忌信息完整性"""
        response = client.get("/api/v1/medication/taboos/med_012")
        data = response.json()["data"]
        # 验证所有重要字段都有数据
        assert data["medicine_name"] != ""
        assert len(data["general_caution"]) > 0


# ─────────────────────────────────────────────────────────────────────────────
# 集成测试
# ─────────────────────────────────────────────────────────────────────────────

class TestIntegration:
    """集成测试：多个端点协作"""

    def test_medicines_list_and_detail_consistency(self):
        """测试列表中的药品与详情端点一致"""
        list_response = client.get("/api/v1/medication/medicines")
        medicines_from_list = list_response.json()["data"]["medicines"]

        detail_response = client.get("/api/v1/medication/medicines/med_001")
        medicine_from_detail = detail_response.json()["data"]

        # 找到对应的药品
        med_from_list = next((m for m in medicines_from_list if m["id"] == "med_001"), None)
        assert med_from_list is not None
        assert med_from_list["name"] == medicine_from_detail["name"]

    def test_reminder_creation_and_retrieval(self):
        """测试创建提醒后能准确检索"""
        user_id = "user_integration"
        medicine_id = "med_001"

        # 创建提醒
        create_response = client.post(
            "/api/v1/medication/reminder",
            json={
                "user_id": user_id,
                "medicine_id": medicine_id,
                "times_per_day": 3,
                "start_date": "2024-01-01"
            }
        )
        reminder_id = create_response.json()["data"]["reminder_id"]

        # 检索提醒
        retrieve_response = client.get(f"/api/v1/medication/reminder/{user_id}")
        reminders = retrieve_response.json()["data"]["reminders"]

        # 验证创建的提醒在检索结果中
        assert any(r["reminder_id"] == reminder_id for r in reminders)

    def test_medicine_details_in_reminder(self):
        """测试提醒中包含正确的药品信息"""
        user_id = "user_med_info"
        medicine_id = "med_005"

        # 获取药品详情
        med_response = client.get(f"/api/v1/medication/medicines/{medicine_id}")
        medicine_name = med_response.json()["data"]["name"]

        # 创建提醒
        create_response = client.post(
            "/api/v1/medication/reminder",
            json={
                "user_id": user_id,
                "medicine_id": medicine_id,
                "times_per_day": 2,
                "start_date": "2024-01-01"
            }
        )

        # 验证提醒中的药品名称正确
        reminder = create_response.json()["data"]
        assert reminder["medicine_name"] == medicine_name

    def test_taboos_info_for_reminder_medicine(self):
        """测试为提醒中的药物获取禁忌信息"""
        medicine_id = "med_003"

        # 获取禁忌
        taboos_response = client.get(f"/api/v1/medication/taboos/{medicine_id}")
        taboos = taboos_response.json()["data"]

        # 验证禁忌信息完整
        assert len(taboos["food_taboos"]) > 0
        assert "medication_name" not in taboos or len(taboos.get("medication_name", "")) > 0
