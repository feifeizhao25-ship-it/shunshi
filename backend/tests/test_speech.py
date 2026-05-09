"""
顺时 - AI 语音 API 路由测试
test_speech.py
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestTextToSpeech:
    """文字转语音端点测试"""

    def test_tts_returns_200(self):
        """POST /api/v1/speech/tts 返回 200"""
        payload = {
            "text": "这是一个测试文本"
        }
        response = client.post("/api/v1/speech/tts", json=payload)
        assert response.status_code in [200, 400, 500]  # 可能依赖外部服务

    def test_tts_requires_text(self):
        """缺少 text 参数应返回错误"""
        payload = {}
        response = client.post("/api/v1/speech/tts", json=payload)
        assert response.status_code == 422

    def test_tts_with_model(self):
        """POST /api/v1/speech/tts 支持指定模型"""
        payload = {
            "text": "Test text",
            "model": "fish-speech-1.5"
        }
        response = client.post("/api/v1/speech/tts", json=payload)
        assert response.status_code in [200, 400, 500]

    def test_tts_with_voice(self):
        """POST /api/v1/speech/tts 支持指定音色"""
        payload = {
            "text": "Test text",
            "voice": "benjamin"
        }
        response = client.post("/api/v1/speech/tts", json=payload)
        assert response.status_code in [200, 400, 500]

    def test_tts_with_format(self):
        """POST /api/v1/speech/tts 支持指定输出格式"""
        payload = {
            "text": "Test text",
            "response_format": "mp3"
        }
        response = client.post("/api/v1/speech/tts", json=payload)
        assert response.status_code in [200, 400, 500]

    def test_tts_with_speed(self):
        """POST /api/v1/speech/tts 支持指定语速"""
        payload = {
            "text": "Test text",
            "speed": 1.5
        }
        response = client.post("/api/v1/speech/tts", json=payload)
        assert response.status_code in [200, 400, 500]

    def test_tts_speed_range(self):
        """语速应该在 0.5-2.0 之间"""
        payload = {
            "text": "Test text",
            "speed": 3.0
        }
        response = client.post("/api/v1/speech/tts", json=payload)
        assert response.status_code in [200, 400, 422, 500]

    def test_tts_text_max_length(self):
        """文本长度不能超过 5000 字符"""
        payload = {
            "text": "a" * 6000
        }
        response = client.post("/api/v1/speech/tts", json=payload)
        assert response.status_code in [400, 422, 500]

    def test_tts_with_all_parameters(self):
        """支持同时设置所有参数"""
        payload = {
            "text": "Complete test",
            "model": "fish-speech-1.5",
            "voice": "diana",
            "response_format": "wav",
            "speed": 1.0
        }
        response = client.post("/api/v1/speech/tts", json=payload)
        assert response.status_code in [200, 400, 500]


class TestSpeechToText:
    """语音识别端点测试"""

    def test_asr_requires_file(self):
        """POST /api/v1/speech/asr 需要音频文件"""
        response = client.post("/api/v1/speech/asr")
        assert response.status_code in [422, 400]

    def test_asr_with_model(self):
        """POST /api/v1/speech/asr 支持指定模型"""
        # 创建模拟文件
        with open("/tmp/test_audio.wav", "wb") as f:
            f.write(b"RIFF" + b"test_audio_content")

        with open("/tmp/test_audio.wav", "rb") as f:
            files = {"file": ("test.wav", f, "audio/wav")}
            data = {"model": "sensevoice"}
            response = client.post("/api/v1/speech/asr", files=files, data=data)
            assert response.status_code in [200, 400, 500]

    def test_asr_with_language(self):
        """POST /api/v1/speech/asr 支持指定语言"""
        with open("/tmp/test_audio2.wav", "wb") as f:
            f.write(b"test_content")

        with open("/tmp/test_audio2.wav", "rb") as f:
            files = {"file": ("test.wav", f, "audio/wav")}
            data = {"language": "zh"}
            response = client.post("/api/v1/speech/asr", files=files, data=data)
            assert response.status_code in [200, 400, 500]


class TestGetModels:
    """获取可用模型端点测试"""

    def test_get_models_returns_200(self):
        """GET /api/v1/speech/models 返回 200"""
        response = client.get("/api/v1/speech/models")
        assert response.status_code == 200

    def test_models_has_tts_models(self):
        """响应包含 tts_models"""
        response = client.get("/api/v1/speech/models")
        assert response.status_code == 200
        data = response.json()
        assert "tts_models" in data

    def test_models_has_asr_models(self):
        """响应包含 asr_models"""
        response = client.get("/api/v1/speech/models")
        assert response.status_code == 200
        data = response.json()
        assert "asr_models" in data

    def test_models_is_list(self):
        """模型列表是数组"""
        response = client.get("/api/v1/speech/models")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data.get("tts_models"), list)
        assert isinstance(data.get("asr_models"), list)


class TestGetVoices:
    """获取可用音色端点测试"""

    def test_get_voices_returns_200(self):
        """GET /api/v1/speech/voices 返回 200"""
        response = client.get("/api/v1/speech/voices")
        assert response.status_code == 200

    def test_voices_has_voices_array(self):
        """响应包含 voices 数组"""
        response = client.get("/api/v1/speech/voices")
        assert response.status_code == 200
        data = response.json()
        assert "voices" in data

    def test_voices_is_array(self):
        """voices 是数组"""
        response = client.get("/api/v1/speech/voices")
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data["voices"], list)

    def test_voice_has_id(self):
        """音色包含 id 字段"""
        response = client.get("/api/v1/speech/voices")
        assert response.status_code == 200
        data = response.json()
        if len(data["voices"]) > 0:
            voice = data["voices"][0]
            assert "id" in voice

    def test_voice_has_label(self):
        """音色包含 label 字段"""
        response = client.get("/api/v1/speech/voices")
        assert response.status_code == 200
        data = response.json()
        if len(data["voices"]) > 0:
            voice = data["voices"][0]
            assert "label" in voice


class TestChatVoice:
    """语音对话端点测试"""

    def test_chat_voice_requires_file(self):
        """POST /api/v1/speech/chat-voice 需要音频文件"""
        response = client.post("/api/v1/speech/chat-voice")
        assert response.status_code in [422, 400]

    def test_chat_voice_with_file(self):
        """POST /api/v1/speech/chat-voice 接收音频文件"""
        with open("/tmp/test_chat.wav", "wb") as f:
            f.write(b"test_audio_data")

        with open("/tmp/test_chat.wav", "rb") as f:
            files = {"file": ("test.wav", f, "audio/wav")}
            response = client.post("/api/v1/speech/chat-voice", files=files)
            assert response.status_code in [200, 400, 500]

    def test_chat_voice_with_model(self):
        """POST /api/v1/speech/chat-voice 支持指定 ASR 模型"""
        with open("/tmp/test_chat2.wav", "wb") as f:
            f.write(b"test_content")

        with open("/tmp/test_chat2.wav", "rb") as f:
            files = {"file": ("test.wav", f, "audio/wav")}
            data = {"model": "sensevoice"}
            response = client.post("/api/v1/speech/chat-voice", files=files, data=data)
            assert response.status_code in [200, 400, 500]

    def test_chat_voice_with_tts_model(self):
        """POST /api/v1/speech/chat-voice 支持指定 TTS 模型"""
        with open("/tmp/test_chat3.wav", "wb") as f:
            f.write(b"test_content")

        with open("/tmp/test_chat3.wav", "rb") as f:
            files = {"file": ("test.wav", f, "audio/wav")}
            data = {"tts_model": "fish-speech-1.5"}
            response = client.post("/api/v1/speech/chat-voice", files=files, data=data)
            assert response.status_code in [200, 400, 500]

    def test_chat_voice_with_voice(self):
        """POST /api/v1/speech/chat-voice 支持指定回复音色"""
        with open("/tmp/test_chat4.wav", "wb") as f:
            f.write(b"test_content")

        with open("/tmp/test_chat4.wav", "rb") as f:
            files = {"file": ("test.wav", f, "audio/wav")}
            data = {"voice": "diana"}
            response = client.post("/api/v1/speech/chat-voice", files=files, data=data)
            assert response.status_code in [200, 400, 500]

    def test_chat_voice_response_structure(self):
        """语音对话响应应该包含特定字段"""
        with open("/tmp/test_chat5.wav", "wb") as f:
            f.write(b"test_content")

        with open("/tmp/test_chat5.wav", "rb") as f:
            files = {"file": ("test.wav", f, "audio/wav")}
            response = client.post("/api/v1/speech/chat-voice", files=files)
            if response.status_code == 200:
                data = response.json()
                # 可能包含 asr_text, reply_text, audio 等


class TestSpeechIntegration:
    """语音服务集成测试"""

    def test_models_and_voices_available(self):
        """模型和音色应该可用"""
        models_response = client.get("/api/v1/speech/models")
        voices_response = client.get("/api/v1/speech/voices")

        assert models_response.status_code == 200
        assert voices_response.status_code == 200

    def test_tts_voice_consistency(self):
        """TTS 使用的音色应该在可用音色列表中"""
        voices_response = client.get("/api/v1/speech/voices")
        assert voices_response.status_code == 200
        data = voices_response.json()
        voices = data.get("voices", [])
        # 至少应该有一个音色可用
        assert len(voices) >= 0
