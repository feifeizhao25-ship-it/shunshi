"""顺时 - 健康礼品测试"""
import pytest


class TestGiftingProducts:
    def test_products_returns_200(self, client):
        response = client.get("/api/v1/gifting/products")
        assert response.status_code == 200

    def test_products_has_list(self, client):
        data = client.get("/api/v1/gifting/products").json()
        assert "products" in data["data"]
        assert len(data["data"]["products"]) > 0


class TestGiftingProductDetail:
    def test_valid_product_returns_200(self, client):
        response = client.get("/api/v1/gifting/products/tcm_tea_set")
        assert response.status_code == 200

    def test_invalid_product_returns_404(self, client):
        assert client.get("/api/v1/gifting/products/nonexistent_product").status_code == 404


class TestGiftingOrders:
    def test_create_order_returns_200(self, client):
        payload = {
            "buyer_id": "test_user",
            "recipient_id": "friend_user",
            "product_id": "tcm_tea_set",
            "message": "送你好茶！"
        }
        response = client.post("/api/v1/gifting/orders", json=payload)
        assert response.status_code == 200

    def test_create_order_has_id(self, client):
        payload = {"buyer_id": "test_user", "product_id": "herbal_kit"}
        data = client.post("/api/v1/gifting/orders", json=payload).json()
        assert data["success"] is True
        assert "order_id" in data["data"]


class TestGiftingOrderDetail:
    def test_order_detail_returns_200(self, client):
        payload = {"buyer_id": "test_user", "product_id": "tcm_tea_set"}
        create_data = client.post("/api/v1/gifting/orders", json=payload).json()
        order_id = create_data["data"]["order_id"]
        response = client.get(f"/api/v1/gifting/orders/{order_id}")
        assert response.status_code == 200

    def test_nonexistent_order_returns_404(self, client):
        assert client.get("/api/v1/gifting/orders/nonexistent_order").status_code == 404


class TestGiftCards:
    def test_create_gift_card_returns_200(self, client):
        payload = {"buyer_id": "test_user", "denomination": 100, "message": "健康礼物"}
        response = client.post("/api/v1/gifting/gift-cards/create", json=payload)
        assert response.status_code == 200

    def test_create_gift_card_has_code(self, client):
        payload = {"buyer_id": "test_user", "denomination": 50}
        data = client.post("/api/v1/gifting/gift-cards/create", json=payload).json()
        assert data["success"] is True
        assert "card_code" in data["data"]


class TestGiftCardRedeem:
    def test_redeem_valid_card(self, client):
        payload = {"buyer_id": "test_user", "denomination": 100}
        create_data = client.post("/api/v1/gifting/gift-cards/create", json=payload).json()
        code = create_data["data"]["card_code"]
        response = client.post(f"/api/v1/gifting/gift-cards/{code}/redeem",
                               json={"user_id": "recipient_user"})
        assert response.status_code == 200

    def test_redeem_invalid_card_returns_404(self, client):
        response = client.post("/api/v1/gifting/gift-cards/INVALID_CODE/redeem",
                               json={"user_id": "user"})
        assert response.status_code == 404


class TestGiftingDenominations:
    def test_denominations_returns_200(self, client):
        response = client.get("/api/v1/gifting/denominations")
        assert response.status_code == 200
