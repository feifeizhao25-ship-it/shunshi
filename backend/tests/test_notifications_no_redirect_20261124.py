"""客户端请求的通知列表地址不带尾斜杠时直接 200，不经 307 重定向（问题 11）。"""
import os

from fastapi import FastAPI
from fastapi.testclient import TestClient


def test_notifications_list_without_trailing_slash_is_not_redirected():
    from app.router import notifications as n
    app = FastAPI(); app.include_router(n.router)
    c = TestClient(app)
    r = c.get("/api/v1/notifications", params={"user_id": "u-test", "limit": 5}, follow_redirects=False)
    assert r.status_code != 307
    r2 = c.get("/api/v1/notifications/", params={"user_id": "u-test", "limit": 5}, follow_redirects=False)
    assert r2.status_code == 307   # 这就是旧客户端走的路
