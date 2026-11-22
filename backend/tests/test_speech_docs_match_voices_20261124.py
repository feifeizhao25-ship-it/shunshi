"""/speech 接口文档和 /voices 实际返回的模型、音色一致（问题 59）。"""
from app.router import speech
from app.services import speech_service as ss


def test_tts_doc_lists_every_tts_model_and_voice():
    doc = speech.text_to_speech.__doc__
    for key, cfg in ss.TTS_MODELS.items():
        assert key in doc, key
        for v in cfg["voices"]:
            assert v in doc, (key, v)


def test_request_field_mentions_cosyvoice2():
    desc = speech.TTSRequest.model_fields["model"].description
    assert "cosyvoice2" in desc and "fish-speech-1.5" in desc
