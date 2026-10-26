"""把某个用户的历史消息拨回到两小时前，用来在本地界面里看到连续使用提醒。

连续使用的口径是：相邻两条用户消息间隔不超过 30 分钟，并且从最早一条到现在满 2 小时。
只改本地 SQLite，不提供线上接口。
"""
from __future__ import annotations

import sqlite3
import sys
import time
import uuid

MINUTES_AGO = (125, 105, 85, 65, 45, 25, 5)


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: seed_continuous_session.py USER_ID DATABASE")
    user_id, database = sys.argv[1], sys.argv[2]
    now = int(time.time())
    connection = sqlite3.connect(database)
    try:
        for ago in MINUTES_AGO:
            connection.execute(
                "INSERT INTO messages (id, user_id, role, content, created_at) VALUES (?, ?, 'user', ?, ?)",
                (uuid.uuid4().hex, user_id, "起来看看远处", now - ago * 60),
            )
        connection.commit()
    finally:
        connection.close()


if __name__ == "__main__":
    main()
