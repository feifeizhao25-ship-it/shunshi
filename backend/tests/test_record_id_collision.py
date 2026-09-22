"""The CI failure was a real collision in the old 9,000-ID/second space."""
import random
from datetime import datetime

from app.router import records
from app.database.db import close_test_connection, get_db


def test_back_to_back_records_survive_same_clock_and_legacy_random(client, monkeypatch, auth_headers, settings):
    from app.security import verify_token
    user_id = verify_token(settings, auth_headers["Authorization"].removeprefix("Bearer "))
    class FrozenDateTime(datetime):
        @classmethod
        def now(cls, tz=None):
            return cls(2026, 9, 9, 12, 0, 0, tzinfo=tz)

    monkeypatch.setattr(records, "datetime", FrozenDateTime)
    monkeypatch.setattr(random, "randint", lambda *args: 1000)
    responses = [client.post("/api/v1/records/care", headers=auth_headers, params={
        "user_id": user_id, "date": "2026-09-09", "notes": note,
    }) for note in ("第一次记录", "第二次记录")]
    assert all(response.status_code == 200 for response in responses)
    assert len({response.json()["data"]["id"] for response in responses}) == 2
    items = client.get("/api/v1/records/care", headers=auth_headers, params={"user_id": user_id}).json()["data"]["items"]
    assert {item["notes"] for item in items} == {"第一次记录", "第二次记录"}
