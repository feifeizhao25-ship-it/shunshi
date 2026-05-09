"""顺时 - 社区测试"""
import pytest


class TestCommunityPosts:
    def test_list_posts_returns_200(self, client):
        response = client.get("/api/v1/community/posts")
        assert response.status_code == 200

    def test_list_posts_has_posts(self, client):
        data = client.get("/api/v1/community/posts").json()
        assert "posts" in data["data"]
        assert data["success"] is True


class TestCommunityCreatePost:
    def test_create_post_returns_200(self, client):
        payload = {
            "user_id": "test_user",
            "content": "分享一个补气养生小技巧！",
            "category": "constitution",
            "tags": ["补气", "养生"]
        }
        response = client.post("/api/v1/community/posts", json=payload)
        assert response.status_code == 200

    def test_create_post_has_id(self, client):
        payload = {"user_id": "test_user", "content": "测试帖子内容", "category": "food"}
        data = client.post("/api/v1/community/posts", json=payload).json()
        assert data["success"] is True
        assert "post_id" in data["data"]


class TestCommunityPostDetail:
    def test_post_detail_returns_200(self, client):
        # Create post first
        create_data = client.post("/api/v1/community/posts",
                                  json={"user_id": "test_user", "content": "Detail test", "category": "general"}).json()
        post_id = create_data["data"]["post_id"]
        response = client.get(f"/api/v1/community/posts/{post_id}")
        assert response.status_code == 200

    def test_nonexistent_post_returns_404(self, client):
        assert client.get("/api/v1/community/posts/nonexistent_post").status_code == 404


class TestCommunityLikePost:
    def test_like_post_returns_200(self, client):
        create_data = client.post("/api/v1/community/posts",
                                  json={"user_id": "test_user", "content": "Like test", "category": "exercise"}).json()
        post_id = create_data["data"]["post_id"]
        response = client.post(f"/api/v1/community/posts/{post_id}/like",
                               json={"user_id": "liker_user"})
        assert response.status_code == 200


class TestCommunityComments:
    def test_get_comments_returns_200(self, client):
        create_data = client.post("/api/v1/community/posts",
                                  json={"user_id": "test_user", "content": "Comment test", "category": "general"}).json()
        post_id = create_data["data"]["post_id"]
        response = client.get(f"/api/v1/community/posts/{post_id}/comments")
        assert response.status_code == 200

    def test_add_comment_returns_200(self, client):
        create_data = client.post("/api/v1/community/posts",
                                  json={"user_id": "test_user", "content": "Comment test 2", "category": "general"}).json()
        post_id = create_data["data"]["post_id"]
        response = client.post(f"/api/v1/community/posts/{post_id}/comments",
                               json={"user_id": "commenter", "content": "很有帮助！"})
        assert response.status_code == 200


class TestCommunityCategories:
    def test_categories_returns_200(self, client):
        response = client.get("/api/v1/community/categories")
        assert response.status_code == 200


class TestCommunityFeatured:
    def test_featured_returns_200(self, client):
        response = client.get("/api/v1/community/featured")
        assert response.status_code == 200
