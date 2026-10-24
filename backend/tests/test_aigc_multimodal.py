"""AI 生成的图片、视频、语音要带显式的「AI 生成」标识。

对话文字之外，/api/v1/multimodal/* 会生成图片、视频与语音。生成内容的展示在客户端，
但客户端要显示标识就得由后端告诉它；音频没有可见面，用响应头做隐式标识。
另外：这些入口原来不过内容安全，可以直接让模型生成暴力、色情内容。
"""

import pytest

from app.router import multimodal_images, multimodal_speech, multimodal_videos

pytestmark = pytest.mark.signed_in


@pytest.fixture()
def fakes(monkeypatch):
    calls = []

    async def image(prompt, aspect_ratio, model, n):
        calls.append(("image", prompt))
        return {"code": 0, "urls": ["https://cdn.example.cn/a.png"], "model": model, "aspect_ratio": aspect_ratio, "n": 1, "created_at": ""}

    async def video(prompt, subject_image_url, model):
        calls.append(("video", prompt))
        return {"code": 0, "task_id": "t1", "status": "queued"}

    async def status(task_id):
        return {"code": 0, "task_id": task_id, "status": "success", "video_url": "https://cdn.example.cn/v.mp4"}

    async def speech(text, voice, speed, format):
        calls.append(("speech", text))
        return b"ID3\x00\x00"

    monkeypatch.setattr(multimodal_images, "generate_image", image)
    monkeypatch.setattr(multimodal_videos, "generate_video", video)
    monkeypatch.setattr(multimodal_videos, "query_video_status", status)
    monkeypatch.setattr(multimodal_speech, "generate_speech", speech)
    return calls


def test_generated_image_is_labelled(client, fakes):
    r = client.post("/api/v1/multimodal/images", json={"prompt": "一杯枸杞菊花茶"})
    assert r.status_code == 200
    body = r.json()
    assert body["ai_generated"] is True and body["ai_label"] == "AI 生成"
    assert body["urls"]


def test_generated_video_and_its_status_are_labelled(client, fakes):
    r = client.post(
        "/api/v1/multimodal/videos",
        json={"prompt": "八段锦第一式", "subject_image_url": "https://cdn.example.cn/p.png"},
    )
    assert r.status_code == 200, r.text
    assert r.json()["ai_generated"] is True and r.json()["ai_label"] == "AI 生成"
    s = client.get("/api/v1/multimodal/videos/status", params={"task_id": "t1"})
    assert s.json()["ai_generated"] is True and s.json()["ai_label"] == "AI 生成"


def test_generated_audio_carries_an_implicit_label_header(client, fakes):
    r = client.post("/api/v1/multimodal/speech", json={"text": "深呼吸，放松肩膀"})
    assert r.status_code == 200
    assert r.headers["x-ai-generated"] == "true"


@pytest.mark.parametrize("path,body", [
    ("/api/v1/multimodal/images", {"prompt": "色情图片"}),
    ("/api/v1/multimodal/speech", {"text": "怎么杀人"}),
    ("/api/v1/multimodal/videos", {"prompt": "武器教学", "subject_image_url": "https://cdn.example.cn/p.png"}),
])
def test_forbidden_prompts_are_refused_before_calling_the_model(client, fakes, path, body):
    r = client.post(path, json=body)
    assert r.status_code == 400
    assert fakes == []
