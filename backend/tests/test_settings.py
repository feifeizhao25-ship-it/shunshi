"""
顺时 - 用户设置 API 路由测试
test_settings.py
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestSettingsGet:
    """获取用户设置端点测试"""

    def test_get_settings_returns_200(self):
        """GET /api/v1/settings 返回 200"""
        response = client.get("/api/v1/settings?user_id=user-001")
        assert response.status_code == 200

    def test_settings_has_data(self):
        """响应包含 data 键"""
        response = client.get("/api/v1/settings?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data

    def test_settings_has_required_fields(self):
        """设置包含所有必要字段"""
        response = client.get("/api/v1/settings?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        settings = data["data"]
        assert "memory_enabled" in settings
        assert "notifications_enabled" in settings
        assert "language" in settings
        assert "theme" in settings

    def test_settings_defaults_for_new_user(self):
        """新用户应该有默认设置"""
        response = client.get("/api/v1/settings?user_id=new-user-12345")
        assert response.status_code == 200
        data = response.json()
        assert "data" in data

    def test_settings_boolean_fields(self):
        """设置的布尔字段应该是 bool 类型"""
        response = client.get("/api/v1/settings?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        settings = data["data"]
        assert isinstance(settings.get("memory_enabled"), bool)
        assert isinstance(settings.get("notifications_enabled"), bool)


class TestSettingsUpdate:
    """更新用户设置端点测试"""

    def test_update_settings_returns_200(self):
        """POST /api/v1/settings 返回 200"""
        response = client.post("/api/v1/settings?user_id=user-001&memory_enabled=false")
        assert response.status_code == 200

    def test_update_settings_success_message(self):
        """更新成功返回成功消息"""
        response = client.post("/api/v1/settings?user_id=user-001&language=en-US")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data

    def test_update_single_setting(self):
        """可以单独更新一个设置"""
        response = client.post("/api/v1/settings?user_id=user-001&theme=dark")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["theme"] == "dark"

    def test_update_multiple_settings(self):
        """可以同时更新多个设置"""
        response = client.post(
            "/api/v1/settings?user_id=user-001&theme=dark&language=en-US&notifications_enabled=false"
        )
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["theme"] == "dark"

    def test_update_quiet_hours_enabled(self):
        """可以启用静默时段"""
        response = client.post("/api/v1/settings?user_id=user-001&quiet_hours_enabled=true")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["quiet_hours_enabled"] is True

    def test_update_quiet_hours_times(self):
        """可以更新静默时段时间"""
        response = client.post(
            "/api/v1/settings?user_id=user-001&quiet_hours_start=23:00&quiet_hours_end=07:00"
        )
        assert response.status_code == 200

    def test_update_notification_preferences(self):
        """可以更新通知偏好"""
        response = client.post(
            "/api/v1/settings?user_id=user-001&solar_term_reminders=true&followup_reminders=false"
        )
        assert response.status_code == 200


class TestMemory:
    """用户记忆端点测试"""

    def test_get_memory_returns_200(self):
        """GET /api/v1/settings/memory 返回 200"""
        response = client.get("/api/v1/settings/memory?user_id=user-001")
        assert response.status_code == 200

    def test_memory_has_items(self):
        """响应包含 items 列表"""
        response = client.get("/api/v1/settings/memory?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "items" in data["data"]
        assert isinstance(data["data"]["items"], list)

    def test_memory_has_total(self):
        """响应包含 total 字段"""
        response = client.get("/api/v1/settings/memory?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "total" in data["data"]

    def test_add_memory(self):
        """POST /api/v1/settings/memory 添加记忆"""
        response = client.post(
            "/api/v1/settings/memory?user_id=user-001&type=preference&content=likes_morning_exercise"
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_memory_has_id(self):
        """新添加的记忆包含 id"""
        response = client.post(
            "/api/v1/settings/memory?user_id=user-001&type=health_note&content=test_memory"
        )
        assert response.status_code == 200
        data = response.json()
        assert "id" in data["data"]

    def test_get_memory_by_type(self):
        """GET /api/v1/settings/memory?type=preference 按类型筛选"""
        response = client.get("/api/v1/settings/memory?user_id=user-001&type=preference")
        assert response.status_code == 200
        data = response.json()
        assert "items" in data["data"]

    def test_memory_limit_parameter(self):
        """GET /api/v1/settings/memory?limit=5 限制数量"""
        response = client.get("/api/v1/settings/memory?user_id=user-001&limit=5")
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]["items"]) <= 5

    def test_delete_memory(self):
        """DELETE /api/v1/settings/memory/{memory_id} 删除单条记忆"""
        # 先添加一条记忆
        add_response = client.post(
            "/api/v1/settings/memory?user_id=user-001&type=test&content=test_content"
        )
        memory_id = add_response.json()["data"]["id"]

        # 删除记忆
        response = client.delete(f"/api/v1/settings/memory/{memory_id}?user_id=user-001")
        assert response.status_code == 200
        assert response.json()["success"] is True

    def test_enable_memory(self):
        """POST /api/v1/settings/memory/enable 启用记忆功能"""
        response = client.post("/api/v1/settings/memory/enable?user_id=user-001&enabled=true")
        assert response.status_code == 200
        assert response.json()["success"] is True

    def test_disable_memory(self):
        """POST /api/v1/settings/memory/enable?enabled=false 关闭记忆功能"""
        response = client.post("/api/v1/settings/memory/enable?user_id=user-001&enabled=false")
        assert response.status_code == 200


class TestQuietHours:
    """静默时段端点测试"""

    def test_get_quiet_hours_returns_200(self):
        """GET /api/v1/settings/quiet-hours 返回 200"""
        response = client.get("/api/v1/settings/quiet-hours?user_id=user-001")
        assert response.status_code == 200

    def test_quiet_hours_has_enabled(self):
        """响应包含 enabled 字段"""
        response = client.get("/api/v1/settings/quiet-hours?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "enabled" in data["data"]
        assert "start" in data["data"]
        assert "end" in data["data"]

    def test_set_quiet_hours(self):
        """POST /api/v1/settings/quiet-hours 设置静默时段"""
        response = client.post(
            "/api/v1/settings/quiet-hours?user_id=user-001&enabled=true&start=22:00&end=08:00"
        )
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_quiet_hours_response(self):
        """设置静默时段的响应包含设置的值"""
        response = client.post(
            "/api/v1/settings/quiet-hours?user_id=user-001&enabled=true&start=23:00&end=07:00"
        )
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["enabled"] is True
        assert data["data"]["start"] == "23:00"
        assert data["data"]["end"] == "07:00"

    def test_disable_quiet_hours(self):
        """可以关闭静默时段"""
        response = client.post(
            "/api/v1/settings/quiet-hours?user_id=user-001&enabled=false"
        )
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["enabled"] is False

    def test_check_quiet_hours(self):
        """GET /api/v1/settings/quiet-hours/check 检查是否在静默时段"""
        response = client.get("/api/v1/settings/quiet-hours/check?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "is_quiet" in data["data"]
        assert "reason" in data["data"]

    def test_check_quiet_hours_when_disabled(self):
        """未启用静默时段时 is_quiet 应为 false"""
        # 先禁用
        client.post("/api/v1/settings/quiet-hours?user_id=user-001&enabled=false")
        # 检查
        response = client.get("/api/v1/settings/quiet-hours/check?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["is_quiet"] is False


class TestExport:
    """设置导出端点测试"""

    def test_export_settings_returns_200(self):
        """GET /api/v1/settings/export 返回 200"""
        response = client.get("/api/v1/settings/export?user_id=user-001")
        assert response.status_code == 200

    def test_export_includes_settings(self):
        """导出数据包含 settings"""
        response = client.get("/api/v1/settings/export?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "settings" in data["data"]

    def test_export_includes_memory(self):
        """导出数据包含 memory"""
        response = client.get("/api/v1/settings/export?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "memory" in data["data"]

    def test_export_includes_exported_at(self):
        """导出数据包含导出时间"""
        response = client.get("/api/v1/settings/export?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert "exported_at" in data["data"]

    def test_export_memory_is_list(self):
        """导出的 memory 应该是列表"""
        response = client.get("/api/v1/settings/export?user_id=user-001")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data["data"]["memory"], list)
