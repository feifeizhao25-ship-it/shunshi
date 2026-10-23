"""5xx / 第三方登录失败时不把原始异常文本（可能含内部地址、密钥名、英文栈信息）放进响应。"""
import pathlib
import re

APP = pathlib.Path(__file__).resolve().parents[1] / "app"
FILES = ["router/multimodal_videos.py", "router/multimodal_speech.py", "router/upload.py", "router/auth.py"]
RAW = re.compile(r"status_code=5\d\d, detail=(str\((e|exc|err)\)|f\"[^\"]*\{(e|exc|err)\}[^\"]*\")")
RAW_AUTH = re.compile(r"detail=f\"[^\"]*(token|verification)[^\"]*\{e\}\"", re.IGNORECASE)


def test_no_raw_exception_text_in_server_errors():
    for rel in FILES:
        src = (APP / rel).read_text(encoding="utf-8")
        assert not RAW.search(src), rel
        assert not RAW_AUTH.search(src), rel
