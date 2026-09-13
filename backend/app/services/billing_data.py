"""Owner-scoped export of domestic billing records, without merchant secrets."""
from app.database.db import get_db, close_test_connection


def collect_domestic_billing_data(user_id):
    db = get_db()
    try:
        tables = {row[0] for row in db.execute(
            "SELECT name FROM sqlite_master WHERE type='table'").fetchall()}
        orders, refunds = [], []
        if 'payment_orders' in tables:
            orders = [dict(row) for row in db.execute("""SELECT id,order_no,product_id,
                tier,platform,amount_cents,currency,status,created_at,paid_at
                FROM payment_orders WHERE user_id=? AND currency='CNY'
                AND platform IN ('alipay','wechat') ORDER BY created_at,id""", (user_id,)).fetchall()]
            if 'domestic_refund_requests' in tables:
                refunds = [dict(row) for row in db.execute("""SELECT r.order_no,
                    r.refund_no,r.amount_cents,r.reason,r.status,r.created_at
                    FROM domestic_refund_requests r JOIN payment_orders p ON p.order_no=r.order_no
                    WHERE r.user_id=? AND p.user_id=? AND p.currency='CNY'
                    AND p.platform='alipay' ORDER BY r.created_at,r.refund_no""",
                    (user_id, user_id)).fetchall()]
        return {'payment_orders': orders, 'refund_requests': refunds}
    finally:
        close_test_connection(db)
