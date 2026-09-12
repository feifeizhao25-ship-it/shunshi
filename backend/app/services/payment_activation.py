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
    from .payment_recovery import ensure_recovery_jobs, enqueue_recovery

    if not order_no or not transaction_id:
        raise HTTPException(status_code=400, detail="支付交易标识缺失")
    db = get_db()
    ensure_recovery_jobs(db)
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
        try:
            enqueue_recovery(db, order["user_id"])
            db.commit()
        except Exception:
            db.rollback()
            raise
        sub.payment_orders[order["id"]] = order
        _restore_domestic_entitlement(request, db, order["user_id"])
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
        enqueue_recovery(db, order["user_id"])
        db.commit()
    except Exception:
        db.rollback()
        raise

    sub.payment_orders[order["id"]] = {**order, "status": "paid",
        "transaction_id": transaction_id, "paid_at": now, "payment_method": provider}
    _restore_domestic_entitlement(request, db, order["user_id"])
    sub._write_audit_log("payment_verified", order["user_id"], {
        "order_id": order["id"], "order_no": order_no, "tier": order["tier"],
        "amount_cents": amount_cents, "transaction_id": transaction_id, "provider": provider,
    })
    return {**order, "status": "paid", "transaction_id": transaction_id, "paid_at": now}


def _restore_domestic_entitlement(request, db, user_id):
    """Replay the durable paid ledger without extending any subscription term.

    Serialize domestic projections with SQLite writers, including the separate
    entitlement commit. An uncertain commit is retried, never compensated by
    deleting a verified payment. This is recoverability, not a distributed
    transaction: a durable recovery job or verified callback completes an
    interrupted projection.
    """
    from app.router import subscription as sub
    from app.simple_models import Entitlement, User

    session_factory = getattr(request.app.state, "session_factory", None)
    if session_factory is None:
        raise HTTPException(status_code=503, detail="会员权益存储不可用，请稍后重试")
    try:
        db.execute("BEGIN IMMEDIATE")
        row = db.execute(
            """SELECT p.*,s.expires_at AS membership_expires_at FROM subscriptions s
            JOIN payment_orders p ON s.id=('sub_' || p.platform || '_' || p.order_no)
            WHERE p.user_id=? AND s.user_id=p.user_id AND p.status='paid'
            AND p.platform IN ('alipay','wechat') AND s.status='active'
            ORDER BY s.rowid DESC LIMIT 1""", (user_id,),
        ).fetchone()
        if row is None:
            raise HTTPException(status_code=409, detail="已付款订单缺少会员记录，请核对")
        latest = dict(row)
        expiry = latest["membership_expires_at"]
        expires_ts = int(datetime.fromisoformat(expiry).timestamp())
        paid_at = latest["paid_at"]
        paid_ts = int(datetime.fromisoformat(paid_at).timestamp())
        with session_factory() as session:
            if session.get(User, user_id) is None:
                raise HTTPException(status_code=410, detail="账号已不存在，不能恢复会员权益")
            entitlement = session.get(Entitlement, user_id)
            values = dict(product_id=latest["product_id"], store=latest["platform"],
                expires_at=expires_ts, original_transaction_id=latest["transaction_id"],
                updated_at=paid_ts)
            if entitlement:
                # A later non-domestic purchase is outside this ledger. Do not
                # let an old domestic callback overwrite its authority.
                if entitlement.store not in {"alipay", "wechat"}:
                    raise HTTPException(status_code=409, detail="会员支付渠道已变更，请核对权益")
                for key, value in values.items():
                    setattr(entitlement, key, value)
            else:
                session.add(Entitlement(user_id=user_id, **values))
            session.commit()

        # Only hydrate the latest committed purchase, even when an older
        # callback is replayed. Update caches before releasing the writer lock.
        sub.payment_orders[latest["id"]] = {k: v for k, v in latest.items()
                                           if k != "membership_expires_at"}
        sub.subscriptions[user_id] = {
            "plan": latest["tier"], "status": "active", "expires_at": expiry,
            "auto_renew": False, "platform": latest["platform"],
            "order_id": latest["id"], "order_no": latest["order_no"],
            "activated_at": paid_at,
            "features": sub.SUBSCRIPTION_PLANS[latest["tier"]]["features"],
        }
        history = sub.purchase_history.setdefault(user_id, [])
        if not any(item.get("order_id") == latest["id"] for item in history):
            history.append({"plan": latest["tier"], "price_cents": latest["amount_cents"],
                "platform": latest["platform"], "order_id": latest["id"],
                "order_no": latest["order_no"], "trade_no": latest["transaction_id"],
                "subscribed_at": paid_at})
        if latest["tier"] != "jiahe" or user_id not in sub.family_seats:
            sub._init_family_seats(user_id, latest["tier"], latest["id"])
        else:
            sub.family_seats[user_id]["order_id"] = latest["id"]
        db.execute("""UPDATE domestic_payment_recovery SET status='done',
            attempts=0,next_attempt_at=0,last_error=NULL WHERE user_id=?""", (user_id,))
        db.commit()
    except HTTPException:
        db.rollback()
        raise
    except Exception as exc:
        db.rollback()
        raise HTTPException(status_code=503, detail="会员权益同步暂未完成，请稍后重试") from exc
