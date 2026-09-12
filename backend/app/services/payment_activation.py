"""统一激活已通过支付渠道验签的国内会员订单。"""
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, Request


def activate_verified_domestic_payment(
    request: Request, *, order_no: str, transaction_id: str,
    amount_cents: int, provider: str,
) -> dict:
    """只信任服务端订单中的用户、SKU 与金额，并同步所有权益存储。"""
    from app.database.db import get_db
    from app.router import subscription as sub
    from app.simple_models import Entitlement

    if not order_no or not transaction_id:
        raise HTTPException(status_code=400, detail="支付交易标识缺失")
    db = get_db()
    row = db.execute("SELECT * FROM payment_orders WHERE order_no = ?", (order_no,)).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="支付订单不存在")
    order = dict(row)
    if order["platform"] != provider or order["currency"] != "CNY":
        raise HTTPException(status_code=400, detail="支付渠道或币种与订单不匹配")
    if int(order["amount_cents"]) != int(amount_cents):
        raise HTTPException(status_code=400, detail="支付金额与订单不匹配")
    if order["status"] == "paid":
        if order.get("transaction_id") != transaction_id:
            raise HTTPException(status_code=409, detail="订单支付流水号冲突")
        return order
    if order["status"] != "pending":
        raise HTTPException(status_code=409, detail=f"订单状态 {order['status']} 不允许支付")
    if db.execute(
        "SELECT 1 FROM payment_orders WHERE transaction_id = ? AND order_no <> ?",
        (transaction_id, order_no),
    ).fetchone():
        raise HTTPException(status_code=409, detail="支付流水号已用于其他订单")
    product = next((p for p in sub.SUBSCRIPTION_PRODUCTS
                    if p["product_id"] == order["product_id"] and p["platform"] == provider), None)
    if not product or int(product["price_cents"]) != int(amount_cents):
        raise HTTPException(status_code=400, detail="订单商品或服务端价格无效")

    now_dt = datetime.now(timezone.utc)
    now = now_dt.isoformat()
    subscription_id = f"sub_{provider}_{order_no}"
    # The reads above are advisory: another worker may cancel the order or
    # claim this transaction before we write. Claim and subscription must
    # commit together, and only the winning pending transition may grant.
    try:
        changed = db.execute(
            """UPDATE payment_orders SET status='paid',transaction_id=?,payment_method=?,paid_at=?
            WHERE order_no=? AND status='pending'
            AND NOT EXISTS (SELECT 1 FROM payment_orders
                            WHERE transaction_id=? AND order_no<>?)""",
            (transaction_id, provider, now, order_no, transaction_id, order_no),
        )
        if changed.rowcount != 1:
            raise HTTPException(status_code=409, detail="订单状态或支付流水已变更，请重新核对")
        # Read the remaining term only after acquiring the SQLite write lock.
        # Sequential purchases of the same domestic tier preserve paid days;
        # past subscription rows overlap, so take the latest end, never sum.
        renewal_base = now_dt
        for existing in db.execute(
            """SELECT expires_at FROM subscriptions WHERE user_id=? AND plan=?
            AND status='active' AND platform IN ('alipay','wechat')""",
            (order["user_id"], order["tier"]),
        ).fetchall():
            try:
                previous_end = datetime.fromisoformat(existing["expires_at"])
                if previous_end.tzinfo is None:
                    previous_end = previous_end.replace(tzinfo=timezone.utc)
            except (TypeError, ValueError):
                raise HTTPException(status_code=409, detail="原会员到期时间异常，请核对后重试")
            renewal_base = max(renewal_base, previous_end)
        expires_at = (renewal_base + timedelta(days=int(product["duration_days"]))).isoformat()
        db.execute("INSERT OR IGNORE INTO users (id, name) VALUES (?, ?)", (order["user_id"], "顺时用户"))
        db.execute(
            """INSERT OR REPLACE INTO subscriptions
            (id,user_id,plan,status,started_at,expires_at,auto_renew,platform,subscribed_at)
            VALUES (?,?,?,'active',?,?,0,?,?)""",
            (subscription_id, order["user_id"], order["tier"], now, expires_at, provider, now),
        )
        db.commit()
    except Exception:
        db.rollback()
        raise

    session_factory = getattr(request.app.state, "session_factory", None)
    if session_factory is None:
        db.execute("UPDATE payment_orders SET status='pending',transaction_id=NULL,payment_method=NULL,paid_at=NULL WHERE order_no=?", (order_no,))
        db.execute("DELETE FROM subscriptions WHERE id=?", (subscription_id,))
        db.commit()
        raise HTTPException(status_code=503, detail="会员权益存储不可用")
    try:
        with session_factory() as session:
            entitlement = session.get(Entitlement, order["user_id"])
            expires_ts = int(datetime.fromisoformat(expires_at).timestamp())
            if entitlement:
                entitlement.product_id = order["product_id"]
                entitlement.store = provider
                entitlement.expires_at = expires_ts
                entitlement.original_transaction_id = transaction_id
                entitlement.updated_at = int(now_dt.timestamp())
            else:
                session.add(Entitlement(
                    user_id=order["user_id"], product_id=order["product_id"], store=provider,
                    expires_at=expires_ts, original_transaction_id=transaction_id,
                    updated_at=int(now_dt.timestamp()),
                ))
            session.commit()
    except Exception:
        db.execute("UPDATE payment_orders SET status='pending',transaction_id=NULL,payment_method=NULL,paid_at=NULL WHERE order_no=?", (order_no,))
        db.execute("DELETE FROM subscriptions WHERE id=?", (subscription_id,))
        db.commit()
        raise

    if order["id"] in sub.payment_orders:
        sub.payment_orders[order["id"]].update(
            status="paid", transaction_id=transaction_id, payment_method=provider, paid_at=now
        )
    sub.subscriptions[order["user_id"]] = {
        "plan": order["tier"], "status": "active", "expires_at": expires_at,
        "auto_renew": False, "platform": provider, "order_id": order["id"],
        "order_no": order_no, "activated_at": now, "features": product["features"],
    }
    sub.purchase_history.setdefault(order["user_id"], []).append({
        "plan": order["tier"], "price_cents": amount_cents, "platform": provider,
        "order_id": order["id"], "order_no": order_no, "trade_no": transaction_id,
        "subscribed_at": now,
    })
    sub._init_family_seats(order["user_id"], order["tier"], order["id"])
    sub._write_audit_log("payment_verified", order["user_id"], {
        "order_id": order["id"], "order_no": order_no, "tier": order["tier"],
        "amount_cents": amount_cents, "transaction_id": transaction_id, "provider": provider,
    })
    return {**order, "status": "paid", "transaction_id": transaction_id, "paid_at": now}
