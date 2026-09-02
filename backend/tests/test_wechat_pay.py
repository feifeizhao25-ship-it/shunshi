import base64, json, re, time, uuid

import pytest
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

from app.services import wechat_pay_service as wm
from app.services.wechat_pay_service import WeChatOrderResult, WeChatPayService


@pytest.fixture
def wx(monkeypatch):
    merchant = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    platform = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    values = {
        "WECHAT_PAY_MCH_ID": "1900000109", "WECHAT_PAY_APP_ID": "wx2026000000000000",
        "WECHAT_PAY_SERIAL_NO": "MERCHANTSERIAL",
        "WECHAT_PAY_PRIVATE_KEY": merchant.private_bytes(
            serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
            serialization.NoEncryption()).decode(),
        "WECHAT_PAY_API_V3_KEY": "12345678901234567890123456789012",
        "WECHAT_PAY_NOTIFY_URL": "https://api.example.cn/api/v1/payments/wechat/notify",
        "WECHAT_PAY_PLATFORM_SERIAL_NO": "PLATFORMSERIAL",
        "WECHAT_PAY_PLATFORM_PUBLIC_KEY": platform.public_key().public_bytes(
            serialization.Encoding.PEM, serialization.PublicFormat.SubjectPublicKeyInfo).decode(),
    }
    for key, value in values.items(): monkeypatch.setattr(wm, key, value)
    return merchant, platform, values


@pytest.mark.asyncio
async def test_native_order_uses_server_price_and_valid_rsa_signature(monkeypatch, wx):
    merchant, _, _ = wx
    captured = {}
    class Response:
        status_code = 200
        def json(self): return {"code_url": "weixin://wxpay/bizpayurl?pr=test"}
    class Client:
        def __init__(self, **_): pass
        async def __aenter__(self): return self
        async def __aexit__(self, *_): pass
        async def post(self, url, **kwargs): captured.update(url=url, **kwargs); return Response()
    monkeypatch.setattr(wm.httpx, "AsyncClient", Client)
    result = await WeChatPayService().create_order(
        product={"name": "颐养版·年付", "price_cents": 39900},
        user_id="user-1", payment_scene="native")
    assert result.pay_url.startswith("weixin://")
    fields = dict(re.findall(r'(mchid|nonce_str|signature|timestamp|serial_no)="([^"]+)"',
                             captured["headers"]["Authorization"]))
    body = captured["content"].decode()
    assert json.loads(body)["amount"] == {"total": 39900, "currency": "CNY"}
    merchant.public_key().verify(base64.b64decode(fields["signature"]),
        f"POST\n/v3/pay/transactions/native\n{fields['timestamp']}\n{fields['nonce_str']}\n{body}\n".encode(),
        padding.PKCS1v15(), hashes.SHA256())


def _notify(platform, values, transaction):
    resource_nonce, aad = "notifyNonce1", "transaction"
    ciphertext = AESGCM(values["WECHAT_PAY_API_V3_KEY"].encode()).encrypt(
        resource_nonce.encode(), json.dumps(transaction).encode(), aad.encode())
    raw = json.dumps({"id": f"evt-{uuid.uuid4().hex}", "resource": {
        "algorithm": "AEAD_AES_256_GCM", "ciphertext": base64.b64encode(ciphertext).decode(),
        "nonce": resource_nonce, "associated_data": aad,
    }}, separators=(",", ":")).encode()
    timestamp, nonce = str(int(time.time())), "header-nonce"
    signature = platform.sign(f"{timestamp}\n{nonce}\n{raw.decode()}\n".encode(),
                              padding.PKCS1v15(), hashes.SHA256())
    return raw, {"wechatpay-serial": values["WECHAT_PAY_PLATFORM_SERIAL_NO"],
                 "wechatpay-timestamp": timestamp, "wechatpay-nonce": nonce,
                 "wechatpay-signature": base64.b64encode(signature).decode(),
                 "content-type": "application/json"}


def test_verified_callback_activates_and_is_idempotent(client, auth_headers, monkeypatch, wx):
    _, platform, values = wx
    order_no = f"WX{uuid.uuid4().hex[:20]}"
    async def create_order(**_):
        return WeChatOrderResult(order_no, "app", app_pay_params={"prepayid": "wx-prepay"})
    monkeypatch.setattr(wm.wechat_pay_service, "create_order", create_order)
    created = client.post("/api/v1/subscription/create-order",
        json={"product_id": "yiyang_yearly", "platform": "wechat", "payment_scene": "app"},
        headers=auth_headers)
    assert created.status_code == 200, created.text
    order = created.json()["data"]
    assert order["amount_cents"] == 39900 and order["app_pay_params"]["prepayid"] == "wx-prepay"
    tx = {"mchid": values["WECHAT_PAY_MCH_ID"], "appid": values["WECHAT_PAY_APP_ID"],
          "out_trade_no": order_no, "transaction_id": f"TX{uuid.uuid4().hex}",
          "trade_state": "SUCCESS", "amount": {"total": 39900, "currency": "CNY"}}
    raw, headers = _notify(platform, values, tx)
    assert client.post("/api/v1/payments/wechat/notify", content=raw, headers=headers).status_code == 200
    assert client.post("/api/v1/payments/wechat/notify", content=raw, headers=headers).status_code == 200
    status = client.get(f"/api/v1/subscription/orders/{order['order_id']}", headers=auth_headers)
    assert status.json()["data"]["status"] == "paid"
    assert client.get("/api/v1/subscription/status", headers=auth_headers).json()["data"]["plan"] == "yiyang"


def test_tampered_notify_is_rejected(wx):
    _, platform, values = wx
    tx = {"mchid": values["WECHAT_PAY_MCH_ID"], "appid": values["WECHAT_PAY_APP_ID"],
          "out_trade_no": "WX1", "transaction_id": "TX1", "trade_state": "SUCCESS",
          "amount": {"total": 2900, "currency": "CNY"}}
    raw, headers = _notify(platform, values, tx)
    with pytest.raises(ValueError, match="签名验证失败"):
        WeChatPayService().verify_and_decrypt_notify(raw + b" ", headers)
