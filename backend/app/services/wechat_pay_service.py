"""微信支付 API v3：Native/App 下单、平台验签与通知解密。"""
import base64, json, os, secrets, time, uuid
from dataclasses import dataclass
from typing import Mapping

import httpx
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

WECHAT_PAY_MCH_ID = os.getenv("WECHAT_PAY_MCH_ID", "")
WECHAT_PAY_APP_ID = os.getenv("WECHAT_PAY_APP_ID", "")
WECHAT_PAY_SERIAL_NO = os.getenv("WECHAT_PAY_SERIAL_NO", "")
WECHAT_PAY_PRIVATE_KEY = os.getenv("WECHAT_PAY_PRIVATE_KEY", "")
WECHAT_PAY_API_V3_KEY = os.getenv("WECHAT_PAY_API_V3_KEY", "")
WECHAT_PAY_NOTIFY_URL = os.getenv("WECHAT_PAY_NOTIFY_URL", "https://api.shunshi.cn/api/v1/payments/wechat/notify")
WECHAT_PAY_PLATFORM_SERIAL_NO = os.getenv("WECHAT_PAY_PLATFORM_SERIAL_NO", "")
WECHAT_PAY_PLATFORM_PUBLIC_KEY = os.getenv("WECHAT_PAY_PLATFORM_PUBLIC_KEY", "")
WECHAT_PAY_BASE_URL = "https://api.mch.weixin.qq.com"

def _pem(value): return value.replace("\\n", "\n").strip().encode()

@dataclass(frozen=True)
class WeChatOrderResult:
    order_no: str
    payment_scene: str
    pay_url: str | None = None
    app_pay_params: dict | None = None

class WeChatPayService:
    def _require(self, callback=False):
        required = {
            "WECHAT_PAY_MCH_ID": WECHAT_PAY_MCH_ID, "WECHAT_PAY_APP_ID": WECHAT_PAY_APP_ID,
            "WECHAT_PAY_SERIAL_NO": WECHAT_PAY_SERIAL_NO, "WECHAT_PAY_PRIVATE_KEY": WECHAT_PAY_PRIVATE_KEY,
            "WECHAT_PAY_API_V3_KEY": WECHAT_PAY_API_V3_KEY, "WECHAT_PAY_NOTIFY_URL": WECHAT_PAY_NOTIFY_URL,
        }
        if callback:
            required.update(WECHAT_PAY_PLATFORM_SERIAL_NO=WECHAT_PAY_PLATFORM_SERIAL_NO,
                            WECHAT_PAY_PLATFORM_PUBLIC_KEY=WECHAT_PAY_PLATFORM_PUBLIC_KEY)
        missing = [k for k, v in required.items() if not v]
        if missing: raise RuntimeError(f"微信支付商户配置缺失：{', '.join(missing)}")
        if len(WECHAT_PAY_API_V3_KEY.encode()) != 32: raise RuntimeError("微信支付 API v3 密钥必须为 32 字节")
        if not WECHAT_PAY_NOTIFY_URL.startswith("https://"): raise RuntimeError("微信支付回调地址必须使用 HTTPS")

    def _sign(self, message):
        key = serialization.load_pem_private_key(_pem(WECHAT_PAY_PRIVATE_KEY), password=None)
        return base64.b64encode(key.sign(message.encode(), padding.PKCS1v15(), hashes.SHA256())).decode()

    def _auth(self, method, path, body):
        timestamp, nonce = str(int(time.time())), secrets.token_hex(16)
        signature = self._sign(f"{method}\n{path}\n{timestamp}\n{nonce}\n{body}\n")
        return ('WECHATPAY2-SHA256-RSA2048 '
                f'mchid="{WECHAT_PAY_MCH_ID}",nonce_str="{nonce}",signature="{signature}",'
                f'timestamp="{timestamp}",serial_no="{WECHAT_PAY_SERIAL_NO}"')

    async def create_order(self, *, product, user_id, payment_scene):
        del user_id
        self._require()
        if payment_scene not in {"native", "app"}: raise ValueError("payment_scene 只支持 native 或 app")
        order_no = f"WX{time.strftime('%Y%m%d%H%M%S')}{uuid.uuid4().hex[:8]}"
        path = f"/v3/pay/transactions/{payment_scene}"
        body = json.dumps({
            "appid": WECHAT_PAY_APP_ID, "mchid": WECHAT_PAY_MCH_ID,
            "description": str(product["name"])[:127], "out_trade_no": order_no,
            "notify_url": WECHAT_PAY_NOTIFY_URL,
            "amount": {"total": int(product["price_cents"]), "currency": "CNY"},
        }, ensure_ascii=False, separators=(",", ":"))
        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.post(f"{WECHAT_PAY_BASE_URL}{path}", content=body.encode(), headers={
                "Authorization": self._auth("POST", path, body), "Accept": "application/json",
                "Content-Type": "application/json", "User-Agent": "ShunShi/1.0",
            })
        try: result = response.json()
        except ValueError as exc: raise RuntimeError("微信支付下单返回无效响应") from exc
        if response.status_code not in {200, 201}: raise RuntimeError(f"微信支付下单失败：{result.get('code', response.status_code)}")
        if payment_scene == "native":
            if not result.get("code_url"): raise RuntimeError("微信支付下单未返回二维码地址")
            return WeChatOrderResult(order_no, payment_scene, pay_url=result["code_url"])
        prepay = result.get("prepay_id")
        if not prepay: raise RuntimeError("微信支付下单未返回 prepay_id")
        timestamp, nonce = str(int(time.time())), secrets.token_hex(16)
        return WeChatOrderResult(order_no, payment_scene, app_pay_params={
            "appid": WECHAT_PAY_APP_ID, "partnerid": WECHAT_PAY_MCH_ID, "prepayid": prepay,
            "package": "Sign=WXPay", "noncestr": nonce, "timestamp": timestamp,
            "sign": self._sign(f"{WECHAT_PAY_APP_ID}\n{timestamp}\n{nonce}\n{prepay}\n"),
        })

    def verify_and_decrypt_notify(self, raw_body: bytes, headers: Mapping[str, str]):
        self._require(callback=True)
        serial, timestamp = headers.get("wechatpay-serial", ""), headers.get("wechatpay-timestamp", "")
        nonce, signature = headers.get("wechatpay-nonce", ""), headers.get("wechatpay-signature", "")
        if serial != WECHAT_PAY_PLATFORM_SERIAL_NO or not timestamp or not nonce or not signature:
            raise ValueError("微信支付回调签名头无效")
        try: epoch = int(timestamp)
        except ValueError as exc: raise ValueError("微信支付回调时间戳无效") from exc
        if abs(int(time.time()) - epoch) > 300: raise ValueError("微信支付回调已过期")
        key = serialization.load_pem_public_key(_pem(WECHAT_PAY_PLATFORM_PUBLIC_KEY))
        try:
            key.verify(base64.b64decode(signature, validate=True),
                       f"{timestamp}\n{nonce}\n{raw_body.decode()}\n".encode(),
                       padding.PKCS1v15(), hashes.SHA256())
        except Exception as exc: raise ValueError("微信支付回调签名验证失败") from exc
        resource = (json.loads(raw_body).get("resource") or {})
        if resource.get("algorithm") != "AEAD_AES_256_GCM": raise ValueError("微信支付回调加密算法无效")
        plaintext = AESGCM(WECHAT_PAY_API_V3_KEY.encode()).decrypt(
            resource.get("nonce", "").encode(), base64.b64decode(resource.get("ciphertext", ""), validate=True),
            resource.get("associated_data", "").encode())
        transaction = json.loads(plaintext)
        if transaction.get("mchid") != WECHAT_PAY_MCH_ID or transaction.get("appid") != WECHAT_PAY_APP_ID:
            raise ValueError("微信支付商户或应用不匹配")
        return transaction

wechat_pay_service = WeChatPayService()

