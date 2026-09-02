from fastapi import APIRouter, HTTPException, Request
from app.services.payment_activation import activate_verified_domestic_payment
from app.services.wechat_pay_service import wechat_pay_service

router = APIRouter(prefix="/api/v1/payments/wechat", tags=["微信支付"])

@router.post("/notify")
async def wechat_pay_notify(request: Request):
    raw = await request.body()
    try:
        tx = wechat_pay_service.verify_and_decrypt_notify(raw, {k.lower(): v for k, v in request.headers.items()})
    except (ValueError, RuntimeError) as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    if tx.get("trade_state") != "SUCCESS": return {"code": "SUCCESS", "message": "成功"}
    amount = tx.get("amount") or {}
    if not tx.get("out_trade_no") or not tx.get("transaction_id") or not isinstance(amount.get("total"), int) or amount.get("currency") != "CNY":
        raise HTTPException(status_code=400, detail="微信支付回调参数不完整")
    activate_verified_domestic_payment(request, order_no=tx["out_trade_no"],
        transaction_id=tx["transaction_id"], amount_cents=amount["total"], provider="wechat")
    return {"code": "SUCCESS", "message": "成功"}

