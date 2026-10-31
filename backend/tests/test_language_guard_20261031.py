"""The CJK-in-international-responses counter (observability, never alters a response)."""
import json

import pytest

from app.services import language_guard as lg

G = {"Accept-Language": "en-US", "X-App-Market": "global"}


@pytest.fixture(autouse=True)
def _reset():
    lg.reset()
    yield
    lg.reset()


def test_record_counts_only_cjk_and_keeps_no_content():
    assert lg.record("/api/x", 200, "all english 123") == 0
    assert lg.record("/api/y", 200, "中文 mixed 内容") == 4
    snap = lg.snapshot()
    assert snap["global_json_responses"] == 2 and snap["with_cjk"] == 1 and snap["rate"] == 0.5
    assert snap["top_paths"] == [{"path": "/api/y", "count": 1}]
    assert "中文" not in json.dumps(snap, ensure_ascii=False)


def test_international_json_is_counted_and_domestic_is_not_inspected(client):
    client.get("/api/v1/entitlements", headers=G)
    assert lg.snapshot()["global_json_responses"] == 1
    lg.reset()
    client.get("/api/v1/entitlements")
    client.get("/api/v1/entitlements", headers={"X-App-Market": "cn"})
    client.get("/api/v1/entitlements", headers={"Accept-Language": "zh-CN"})
    assert lg.snapshot()["global_json_responses"] == 0


def test_chinese_in_an_international_response_is_found_and_the_body_is_unchanged(client):
    # an unauthenticated call's error text is the kind of leak this counter exists to surface
    r = client.get("/api/v1/subscription/status", headers=G)
    snap = lg.snapshot()
    assert snap["global_json_responses"] == 1
    has_cjk = any("\u4e00" <= ch <= "\u9fff" for ch in r.text)
    assert (snap["with_cjk"] == 1) == has_cjk
    if has_cjk:
        assert snap["top_paths"][0]["path"] == "/api/v1/subscription/status"


def test_health_endpoint_exposes_the_counter(client):
    body = client.get("/api/health").json()
    assert set(body["language_guard"]) >= {"global_json_responses", "with_cjk", "rate", "top_paths"}
