"""Docs must not contain sk- style API keys, and the scanner must not echo them."""

import importlib.util
import re
from pathlib import Path


def _scanner():
    path = Path(__file__).resolve().parents[2] / "scripts" / "check_docs_for_sk_keys.py"
    spec = importlib.util.spec_from_file_location("check_docs_for_sk_keys", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_repository_docs_have_no_sk_keys():
    scanner = _scanner()
    docs = Path(__file__).resolve().parents[2] / "docs"
    assert scanner.find_sk_keys(docs) == []


def test_scanner_reports_location_without_the_key(tmp_path, capsys):
    scanner = _scanner()
    token = "sk-" + ("ab" * 16)
    target = tmp_path / "notes.md"
    target.write_text("provider\n" + token + "\n", encoding="utf-8")
    found = scanner.find_sk_keys(tmp_path)
    assert found == ["notes.md:2"]
    assert token not in "\n".join(found)
    assert scanner.main([str(tmp_path)]) == 1
    captured = capsys.readouterr()
    assert "notes.md:2" in captured.out
    assert not re.search(r"sk-[A-Za-z0-9]{8,}", captured.out + captured.err)
    placeholder = tmp_path / "placeholder.md"
    placeholder.write_text("OPENAI_API_KEY=sk-your-openai-api-key\n", encoding="utf-8")
    target.unlink()
    assert scanner.find_sk_keys(tmp_path) == []


def test_scanner_reads_gb18030_and_zhipu_shaped_keys(tmp_path, capsys):
    scanner = _scanner()
    sk_token = "sk-" + ("cd" * 16)
    zhipu_token = ("0123456789abcdef" * 2) + ".Abcdefghijklmnop"
    # GB18030 CJK bytes are not valid UTF-8, so the UTF-8 reader used to skip the file.
    prefix = "记录".encode("gb18030")
    raw = prefix + b"\n" + sk_token.encode("ascii") + b"\n" + zhipu_token.encode("ascii") + b"\n"
    try:
        raw.decode("utf-8")
        raise AssertionError("fixture must not be valid UTF-8")
    except UnicodeError:
        pass
    target = tmp_path / "legacy.md"
    target.write_bytes(raw)
    found = scanner.find_sk_keys(tmp_path)
    assert found == ["legacy.md:2", "legacy.md:3"]
    assert sk_token not in "\n".join(found)
    assert zhipu_token not in "\n".join(found)
    assert scanner.main([str(tmp_path)]) == 1
    captured = capsys.readouterr()
    assert "legacy.md:2" in captured.out
    assert "legacy.md:3" in captured.out
    assert sk_token not in captured.out + captured.err
    assert zhipu_token not in captured.out + captured.err
