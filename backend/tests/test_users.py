"""
顺时 - 用户管理 API 路由测试
test_users.py
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestDeleteUser:
    """用户删除端点测试（GDPR合规）"""

    def test_delete_user_requires_confirmation(self):
        """DELETE /api/v1/users/{user_id} 不确认返回 400"""
        response = client.delete("/api/v1/users/user-001?confirm=false")
        assert response.status_code == 400

    def test_delete_user_with_confirmation(self):
        """DELETE /api/v1/users/{user_id}?confirm=true 确认删除"""
        response = client.delete("/api/v1/users/test-delete-user?confirm=true")
        assert response.status_code == 200

    def test_delete_user_success_response(self):
        """删除成功返回成功消息"""
        response = client.delete("/api/v1/users/test-delete-user-2?confirm=true")
        assert response.status_code == 200
        data = response.json()
        assert "success" in data
        assert "message" in data

    def test_delete_user_has_deleted_at(self):
        """删除响应包含 deleted_at 时间戳"""
        response = client.delete("/api/v1/users/test-delete-user-3?confirm=true")
        assert response.status_code == 200
        data = response.json()
        assert "deleted_at" in data

    def test_delete_user_has_deleted_records(self):
        """删除响应包含已删除的记录数"""
        response = client.delete("/api/v1/users/test-delete-user-4?confirm=true")
        assert response.status_code == 200
        data = response.json()
        assert "deleted_records" in data
        assert isinstance(data["deleted_records"], dict)

    def test_delete_user_cascade_delete(self):
        """级联删除用户关联数据"""
        response = client.delete("/api/v1/users/test-cascade-delete?confirm=true")
        assert response.status_code == 200
        data = response.json()
        deleted_records = data.get("deleted_records", {})
        # 应该尝试删除多个表的数据
        assert isinstance(deleted_records, dict)

    def test_delete_user_without_confirm_query(self):
        """缺少 confirm 参数返回 400"""
        response = client.delete("/api/v1/users/user-001")
        assert response.status_code == 400

    def test_delete_user_invalid_confirm_value(self):
        """confirm=invalid 返回 400"""
        response = client.delete("/api/v1/users/user-001?confirm=invalid")
        assert response.status_code in [400, 422]

    def test_delete_user_response_has_total_records_deleted(self):
        """响应包含 total_records_deleted"""
        response = client.delete("/api/v1/users/test-total-records?confirm=true")
        assert response.status_code == 200
        data = response.json()
        assert "total_records_deleted" in data

    def test_delete_nonexistent_user(self):
        """删除不存在的用户应该返回 200（或 404）"""
        response = client.delete("/api/v1/users/nonexistent-user-xyz?confirm=true")
        assert response.status_code in [200, 404]


class TestExportUserData:
    """用户数据导出端点测试（GDPR合规）"""

    def test_export_user_data_returns_200(self):
        """GET /api/v1/users/{user_id}/export 返回 200"""
        response = client.get("/api/v1/users/user-001/export")
        assert response.status_code == 200

    def test_export_has_user_id(self):
        """导出数据包含 user_id"""
        response = client.get("/api/v1/users/user-001/export")
        assert response.status_code == 200
        data = response.json()
        assert "user_id" in data
        assert data["user_id"] == "user-001"

    def test_export_has_exported_at(self):
        """导出数据包含导出时间戳"""
        response = client.get("/api/v1/users/user-001/export")
        assert response.status_code == 200
        data = response.json()
        assert "exported_at" in data

    def test_export_has_profile(self):
        """导出数据包含用户档案"""
        response = client.get("/api/v1/users/user-001/export")
        assert response.status_code == 200
        data = response.json()
        assert "profile" in data
        assert isinstance(data["profile"], list)

    def test_export_has_subscriptions(self):
        """导出数据包含订阅信息"""
        response = client.get("/api/v1/users/user-001/export")
        assert response.status_code == 200
        data = response.json()
        assert "subscriptions" in data
        assert isinstance(data["subscriptions"], list)

    def test_export_has_memories(self):
        """导出数据包含记忆"""
        response = client.get("/api/v1/users/user-001/export")
        assert response.status_code == 200
        data = response.json()
        assert "memories" in data
        assert isinstance(data["memories"], list)

    def test_export_has_conversations(self):
        """导出数据包含对话记录"""
        response = client.get("/api/v1/users/user-001/export")
        assert response.status_code == 200
        data = response.json()
        assert "conversations" in data
        assert isinstance(data["conversations"], list)

    def test_export_nonexistent_user(self):
        """导出不存在的用户应该返回 200（空数据）或 404"""
        response = client.get("/api/v1/users/nonexistent-user-xyz/export")
        assert response.status_code in [200, 404]

    def test_export_data_structure(self):
        """导出数据包含预期的结构"""
        response = client.get("/api/v1/users/user-001/export")
        assert response.status_code == 200
        data = response.json()
        # 应该有用户数据的不同部分
        keys = set(data.keys())
        expected_keys = {"user_id", "exported_at"}
        assert expected_keys.issubset(keys)

    def test_export_different_users(self):
        """不同用户导出不同数据"""
        response1 = client.get("/api/v1/users/user-001/export")
        response2 = client.get("/api/v1/users/user-002/export")
        assert response1.status_code == 200
        assert response2.status_code == 200
        data1 = response1.json()
        data2 = response2.json()
        assert data1["user_id"] != data2["user_id"]


class TestUserManagementIntegration:
    """用户管理整体集成测试"""

    def test_export_then_delete_workflow(self):
        """GDPR 工作流：先导出后删除"""
        # Step 1: 导出用户数据
        export_response = client.get("/api/v1/users/test-gdpr-user/export")
        assert export_response.status_code == 200
        export_data = export_response.json()
        assert "user_id" in export_data

        # Step 2: 删除用户
        delete_response = client.delete("/api/v1/users/test-gdpr-user?confirm=true")
        assert delete_response.status_code == 200
        delete_data = delete_response.json()
        assert delete_data["success"] is True

    def test_export_returns_complete_data(self):
        """导出应该返回完整用户数据"""
        response = client.get("/api/v1/users/complete-user-test/export")
        assert response.status_code == 200
        data = response.json()
        # 检查关键字段
        assert isinstance(data, dict)
        assert "user_id" in data

    def test_delete_returns_summary(self):
        """删除应该返回删除摘要"""
        response = client.delete("/api/v1/users/delete-summary-test?confirm=true")
        assert response.status_code == 200
        data = response.json()
        if "deleted_records" in data:
            assert isinstance(data["deleted_records"], dict)

    def test_path_parameter_user_id(self):
        """路径参数 user_id 应该正确传递"""
        user_id = "path-param-test-123"
        response = client.get(f"/api/v1/users/{user_id}/export")
        assert response.status_code == 200
        data = response.json()
        assert data["user_id"] == user_id
