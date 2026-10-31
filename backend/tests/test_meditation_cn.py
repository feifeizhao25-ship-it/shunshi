"""国内版冥想音频库：目录与音频文件一致、原创中文脚本不含医疗表述、AI 标识齐全、空状态不编造。"""

import hashlib
import json
import re

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.router import meditation_cn as med

FORBIDDEN = re.compile(r"治疗|治愈|疗效|诊断|处方|药物|服药|根治|痊愈|抑郁症|失眠症|焦虑症|保证|一定能|包治")
ENGLISH_WORD = re.compile(r"[A-Za-z]{2,}")


@pytest.fixture()
def client():
    med.reload_catalog()
    app = FastAPI()
    app.include_router(med.router)
    return TestClient(app)


def _tracks():
    return json.loads(med.CATALOG_PATH.read_text(encoding="utf-8"))["tracks"]


def test_catalog_matches_audio_files():
    tracks = _tracks()
    assert len(tracks) >= 8
    ids = [t["id"] for t in tracks]
    assert len(ids) == len(set(ids))
    for t in tracks:
        f = med.AUDIO_DIR / f"{t['id']}.mp3"
        assert f.is_file(), t["id"]
        data = f.read_bytes()
        assert t["size_bytes"] == len(data)
        assert t["sha256"] == hashlib.sha256(data).hexdigest()
        assert 60 <= t["duration_seconds"] <= 600
    # 总体积受控：客户端不内置，服务端静态目录合计 < 20MB
    assert sum(t["size_bytes"] for t in tracks) < 20 * 1024 * 1024


def test_scripts_are_chinese_and_make_no_medical_claims():
    for t in _tracks():
        script = "".join(t["text"])
        visible = re.sub(r"<#[\d.]+#>", "", script)
        assert re.search(r"[\u4e00-\u9fff]", visible)
        assert not FORBIDDEN.search(visible + t["title"] + t["subtitle"]), t["id"]
        for field in (t["title"], t["subtitle"], t["category_label"], *t["tags"]):
            assert not ENGLISH_WORD.search(field), (t["id"], field)
        assert not ENGLISH_WORD.search(visible), t["id"]


def test_library_lists_tracks_with_ai_label(client):
    r = client.get("/api/v1/meditation/library")
    assert r.status_code == 200
    assert r.headers["X-AI-Generated"] == "true"
    data = r.json()["data"]
    assert data["total"] == len(_tracks())
    assert data["ai_label"] == "AI 合成语音"
    assert "12356" in data["disclaimer"]
    for item in data["items"]:
        assert item["ai_generated"] is True and item["ai_label"] == "AI 合成语音"
        assert item["audio_url"].endswith(f"{item['id']}.mp3")


def test_library_filters_and_season_order(client):
    r = client.get("/api/v1/meditation/library?category=solar_term&season=autumn").json()["data"]
    assert [i["term"] for i in r["items"]] == ["霜降"]
    assert r["items"][0]["recommended"] is True
    sleep = client.get("/api/v1/meditation/library?category=sleep").json()["data"]["items"]
    assert sleep and all(i["category"] == "sleep" for i in sleep)


def test_track_detail_has_transcript_without_pause_markers(client):
    r = client.get("/api/v1/meditation/library/med_cn_sleep_01")
    assert r.status_code == 200
    d = r.json()["data"]
    assert "<#" not in d["transcript"] and len(d["transcript"]) > 100
    assert "12356" in d["disclaimer"]
    assert client.get("/api/v1/meditation/library/not-exist").status_code == 404


def test_cdn_base_url_override(client, monkeypatch):
    monkeypatch.setenv("SHUNSHI_MEDITATION_AUDIO_BASE_URL", "https://cdn.example.cn/med/")
    item = client.get("/api/v1/meditation/library").json()["data"]["items"][0]
    assert item["audio_url"] == f"https://cdn.example.cn/med/{item['id']}.mp3"


def test_missing_audio_files_give_empty_list_not_fake_items(client, monkeypatch, tmp_path):
    monkeypatch.setattr(med, "AUDIO_DIR", tmp_path)
    data = client.get("/api/v1/meditation/library").json()["data"]
    assert data["items"] == [] and data["total"] == 0
    assert client.get("/api/v1/meditation/library/med_cn_sleep_01").status_code == 404
