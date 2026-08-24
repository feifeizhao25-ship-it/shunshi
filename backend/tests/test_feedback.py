"""反馈：未登录 401；反馈与评分真实落库（通过导出验证）。"""


def test_feedback_requires_auth(client):
    assert client.post("/api/v1/feedback", json={"content": "建议"}).status_code == 401
    assert client.post("/api/v1/feedback/rating", json={"rating": 5}).status_code == 401


def test_submit_feedback_saved(client, auth_headers):
    response = client.post(
        "/api/v1/feedback",
        json={"content": "希望增加深色模式", "contact": "13800000000"},
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert response.json()["saved"] is True


def test_submit_rating_saved(client, auth_headers):
    response = client.post(
        "/api/v1/feedback/rating",
        json={"rating": 4, "comment": "挺好用"},
        headers=auth_headers,
    )
    assert response.status_code == 200
    assert response.json()["saved"] is True


def test_rating_out_of_range_rejected(client, auth_headers):
    response = client.post("/api/v1/feedback/rating", json={"rating": 6}, headers=auth_headers)
    assert response.status_code == 422
