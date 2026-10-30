"""国内版（android-cn / ios-cn）界面全中文门禁。

规则见 scripts/verify_zh_ui_dart.py：从 main.dart 可达的 Dart 文件里，字符串字面量不得含英文单词
（品牌 / 单位白名单见 scripts/zh_ui_allow.json，其余必须逐行写明原因）。
"""
import importlib.util
import json
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "verify_zh_ui_dart.py"
ALLOW = ROOT / "scripts" / "zh_ui_allow.json"


def _gate():
    spec = importlib.util.spec_from_file_location("verify_zh_ui_dart", SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _tokens():
    cfg = json.loads(ALLOW.read_text(encoding="utf-8"))
    return sorted(_gate().DEFAULT_TOKENS | set(cfg.get("tokens", []))), cfg.get("literals", [])


@pytest.mark.parametrize("app", ["android-cn", "ios-cn"])
def test_cn_app_ui_has_no_english(app):
    gate = _gate()
    tokens, literals = _tokens()
    bad = gate.scan_app(ROOT / app, tokens, literals)
    assert not bad, "界面里可能有英文：\n" + "\n".join(f"{app}/{r}:{n}: {t!r}" for r, n, t, _ in bad[:30])


def test_gate_catches_english_and_respects_markers(tmp_path):
    lib = tmp_path / "lib"
    lib.mkdir()
    (lib / "main.dart").write_text(
        "import 'package:x/page.dart';\nvoid main() {}\n", encoding="utf-8"
    )
    (lib / "page.dart").write_text(
        "var a = Text('Hello World');\n"
        "var b = Text('你好，顺时');\n"
        "var c = Text('Welcome back'); // zh-gate:allow 测试\n"
        "// zh-gate:allow-begin 测试\nconst k = ['heart attack'];\n// zh-gate:allow-end\n",
        encoding="utf-8",
    )
    (lib / "dead.dart").write_text("var d = Text('Dead code English');\n", encoding="utf-8")
    gate = _gate()
    tokens, _ = _tokens()
    bad = gate.scan_app(tmp_path, tokens, [])
    assert [(r, t) for r, _, t, _ in bad] == [("lib/page.dart", "Hello World")]
