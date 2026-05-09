"""
顺时 - 音频 API v2 测试
test_audio_v2.py
"""

import pytest


class TestAudioLibrary:
    """音频库端点测试"""

    def test_audio_library_returns_200(self, client):
        """测试获取音频库，期望返回 200"""
        response = client.get("/api/v1/audio/library")
        assert response.status_code == 200

    def test_audio_library_response_structure(self, client):
        """测试音频库响应包含预期的键"""
        response = client.get("/api/v1/audio/library")
        assert response.status_code == 200
        data = response.json()

        # 检查预期的键
        assert "breathing" in data
        assert "windDown" in data
        assert "soundscapes" in data
        assert "seasonal" in data
        assert "hemisphere" in data
        assert "season" in data

        # 验证键的值是列表或字符串
        assert isinstance(data["breathing"], list)
        assert isinstance(data["windDown"], list)
        assert isinstance(data["soundscapes"], list)
        assert isinstance(data["seasonal"], list)
        assert isinstance(data["hemisphere"], str)
        assert isinstance(data["season"], str)

    def test_audio_library_with_hemisphere_param(self, client):
        """测试带半球参数的音频库"""
        response = client.get("/api/v1/audio/library?hemisphere=south")
        assert response.status_code == 200
        data = response.json()
        assert data["hemisphere"] == "south"

    def test_audio_library_with_season_param(self, client):
        """测试带季节参数的音频库"""
        response = client.get("/api/v1/audio/library?season=winter")
        assert response.status_code == 200
        data = response.json()
        assert data["season"] == "winter"


class TestAudioRecommended:
    """推荐音频端点测试"""

    def test_audio_recommended_without_user_id(self, client):
        """测试没有 user_id 参数的推荐端点"""
        # user_id 是可选的，所以应该返回 200
        response = client.get("/api/v1/audio/recommended")
        assert response.status_code == 200

    def test_audio_recommended_with_user_id(self, client):
        """测试带有有效 user_id 的推荐端点"""
        response = client.get(
            "/api/v1/audio/recommended?user_id=test-user-001"
        )
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "total" in data
        assert "hemisphere" in data
        assert "season" in data
        assert isinstance(data["items"], list)
        assert isinstance(data["total"], int)

    def test_audio_recommended_with_time_of_day(self, client):
        """测试带时间段过滤的推荐"""
        response = client.get(
            "/api/v1/audio/recommended?time_of_day=morning"
        )
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data["items"], list)

    def test_audio_recommended_with_duration_filter(self, client):
        """测试带时长过滤的推荐"""
        response = client.get(
            "/api/v1/audio/recommended?duration_minutes=10"
        )
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data["items"], list)

    def test_audio_recommended_with_categories(self, client):
        """测试带类别过滤的推荐"""
        response = client.get(
            "/api/v1/audio/recommended?categories=breathing,soundscape"
        )
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data["items"], list)

    def test_audio_recommended_with_limit(self, client):
        """测试带限制参数的推荐"""
        response = client.get(
            "/api/v1/audio/recommended?limit=5"
        )
        assert response.status_code == 200
        data = response.json()
        assert len(data["items"]) <= 5

    def test_audio_recommended_response_has_metadata(self, client):
        """测试推荐响应包含元数据"""
        response = client.get("/api/v1/audio/recommended?limit=10")
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "total" in data
        assert "hemisphere" in data
        assert "season" in data


class TestAudioContents:
    """音频内容端点测试"""

    def test_audio_contents_basic(self, client):
        """测试基本的音频内容端点"""
        response = client.get("/api/v1/audio/contents")
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "total" in data
        assert "hemisphere" in data
        assert "season" in data

    def test_audio_contents_with_duration_filter(self, client):
        """测试带时长过滤的音频内容"""
        response = client.get(
            "/api/v1/audio/contents?duration_minutes=5"
        )
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data["items"], list)

    def test_audio_contents_with_hemisphere(self, client):
        """测试带半球参数的音频内容"""
        response = client.get(
            "/api/v1/audio/contents?hemisphere=south"
        )
        assert response.status_code == 200
        data = response.json()
        assert data["hemisphere"] == "south"

    def test_audio_contents_with_limit(self, client):
        """测试带限制参数的音频内容"""
        response = client.get(
            "/api/v1/audio/contents?limit=10"
        )
        assert response.status_code == 200
        data = response.json()
        assert len(data["items"]) <= 10


class TestAudioPlays:
    """音频播放事件记录测试"""

    def test_audio_plays_post_success(self, client):
        """测试记录音频播放事件"""
        response = client.post(
            "/api/v1/audio/plays",
            json={
                "user_id": "test-user-001",
                "audio_item_id": "audio-001",
                "duration_played_seconds": 120,
                "completed": False,
                "played_at": "2024-11-15T10:00:00Z"
            }
        )
        assert response.status_code in [200, 201]
        data = response.json()
        assert "status" in data

    def test_audio_plays_post_minimal(self, client):
        """测试只提供必需字段的播放事件"""
        response = client.post(
            "/api/v1/audio/plays",
            json={
                "user_id": "test-user-001",
                "audio_item_id": "audio-002",
                "duration_played_seconds": 45,
                "completed": True
            }
        )
        assert response.status_code in [200, 201]

    def test_audio_plays_post_completed(self, client):
        """测试已完成的播放事件"""
        response = client.post(
            "/api/v1/audio/plays",
            json={
                "user_id": "test-user-001",
                "audio_item_id": "audio-003",
                "duration_played_seconds": 300,
                "completed": True,
                "played_at": "2024-11-15T10:30:00Z"
            }
        )
        assert response.status_code in [200, 201]
        data = response.json()
        assert data.get("status") == "ok"

    def test_audio_plays_post_partially_completed(self, client):
        """测试未完成的播放事件"""
        response = client.post(
            "/api/v1/audio/plays",
            json={
                "user_id": "test-user-001",
                "audio_item_id": "audio-004",
                "duration_played_seconds": 60,
                "completed": False
            }
        )
        assert response.status_code in [200, 201]


class TestAudioStream:
    """音频流 URL 端点测试"""

    def test_audio_stream_url_returns_url_or_error(self, client):
        """测试获取音频流 URL"""
        response = client.get("/api/v1/audio/non-existent-id/stream")
        assert response.status_code == 200
        data = response.json()
        # 端点返回 url 或 error 字段
        assert "url" in data or "error" in data
