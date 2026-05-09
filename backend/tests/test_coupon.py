"""顺时 - 优惠券测试"""
import pytest


class TestCouponIssue:
    def test_issue_returns_200(self, client):
        payload = {"user_id": "test_user", "coupon_type": "discount_10"}
        response = client.post("/api/v1/coupon/issue", json=payload)
        assert response.status_code == 200

    def test_issue_has_coupon_code(self, client):
        payload = {"user_id": "test_user", "coupon_type": "free_month"}
        data = client.post("/api/v1/coupon/issue", json=payload).json()
        assert data["success"] is True
        assert "coupon_code" in data["data"]


class TestCouponMy:
    def test_my_coupons_returns_200(self, client):
        response = client.get("/api/v1/coupon/my?user_id=test_user")
        assert response.status_code == 200

    def test_my_coupons_has_list(self, client):
        data = client.get("/api/v1/coupon/my?user_id=test_user").json()
        assert "coupons" in data["data"]


class TestCouponRedeem:
    def test_redeem_valid_coupon(self, client):
        # Issue first
        issue_payload = {"user_id": "test_user", "coupon_type": "discount_10"}
        issue_data = client.post("/api/v1/coupon/issue", json=issue_payload).json()
        code = issue_data["data"]["coupon_code"]
        # Redeem
        redeem_payload = {"user_id": "test_user", "coupon_code": code}
        response = client.post("/api/v1/coupon/redeem", json=redeem_payload)
        assert response.status_code == 200

    def test_redeem_invalid_code(self, client):
        payload = {"user_id": "test_user", "coupon_code": "INVALID000"}
        response = client.post("/api/v1/coupon/redeem", json=payload)
        assert response.status_code in [400, 404]


class TestCouponValidate:
    def test_validate_returns_200(self, client):
        # Issue a coupon first
        issue_data = client.post("/api/v1/coupon/issue",
                                 json={"user_id": "test_user", "coupon_type": "discount_10"}).json()
        code = issue_data["data"]["coupon_code"]
        response = client.get(f"/api/v1/coupon/validate/{code}")
        assert response.status_code == 200


class TestCouponTypes:
    def test_types_returns_200(self, client):
        response = client.get("/api/v1/coupon/types")
        assert response.status_code == 200

    def test_types_has_list(self, client):
        data = client.get("/api/v1/coupon/types").json()
        assert "coupon_types" in data["data"]
