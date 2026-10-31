"""Language gates for the four 顺时 / SEASONS apps.

* international apps (ios-global, android-global): no Chinese characters in any
  code reachable from main.dart, apart from comments and the 24 solar-term
  names, which are lookup keys shared with the calendar table and never shown.
* domestic apps (ios-cn, android-cn): no English sentences as UI strings in code
  reachable from main.dart (3+ words, starts with a capital letter).

Both gates read the Dart sources only; they need no Flutter toolchain.
"""
import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
LIT = re.compile(r"""'((?:[^'\\\n]|\\.)*)'|"((?:[^"\\\n]|\\.)*)\"""")
HAN = re.compile(r"[\u3400-\u9fff]")
IMPORT = re.compile(r"""(?:import|export|part)\s+['"]([^'"]+)['"]""")
SOLAR_TERM_KEYS = {
    "小寒", "大寒", "立春", "雨水", "惊蛰", "春分", "清明", "谷雨", "立夏", "小满", "芒种", "夏至",
    "小暑", "大暑", "立秋", "处暑", "白露", "秋分", "寒露", "霜降", "立冬", "小雪", "大雪", "冬至",
}
# English text the domestic apps may show verbatim: brand names and technical labels.
DOMESTIC_ENGLISH_OK = {"Terms of Service"}


def _package(app: str) -> str:
    for line in (ROOT / app / "pubspec.yaml").read_text(encoding="utf-8").splitlines():
        m = re.match(r"name:\s*(\S+)", line)
        if m:
            return m.group(1)
    raise AssertionError(f"no package name in {app}/pubspec.yaml")


def reachable(app: str):
    pkg, base = _package(app), ROOT / app / "lib"
    seen, stack = set(), ["main.dart"]
    while stack:
        rel = stack.pop()
        if rel in seen or not (base / rel).exists():
            continue
        seen.add(rel)
        for m in IMPORT.finditer((base / rel).read_text(encoding="utf-8")):
            target = m.group(1)
            if target.startswith(f"package:{pkg}/"):
                target = target[len(f"package:{pkg}/"):]
            elif target.startswith(("package:", "dart:")):
                continue
            else:
                target = str((Path(rel).parent / target).as_posix())
                parts = []
                for p in target.split("/"):
                    if p == "..":
                        parts and parts.pop()
                    elif p != ".":
                        parts.append(p)
                target = "/".join(parts)
            stack.append(target)
    return sorted(seen)


def _strip_trailing_comment(line: str) -> str:
    """Cut a trailing // comment (ignoring // inside string literals)."""
    spans = [m.span() for m in LIT.finditer(line)]
    i = line.find("//")
    while i != -1:
        if not any(a <= i < b for a, b in spans):
            return line[:i]
        i = line.find("//", i + 2)
    return line


def _code_lines(app: str):
    base = ROOT / app / "lib"
    for rel in reachable(app):
        for no, line in enumerate((base / rel).read_text(encoding="utf-8").splitlines(), 1):
            s = line.strip()
            if s.startswith(("//", "*", "/*")):
                continue
            yield rel, no, _strip_trailing_comment(line)


def _literals(line: str):
    for m in LIT.finditer(line):
        yield m.group(1) if m.group(1) is not None else m.group(2)


@pytest.mark.parametrize("app", ["ios-global", "android-global"])
def test_international_app_has_no_chinese_text(app):
    bad = []
    for rel, no, line in _code_lines(app):
        if not HAN.search(line):
            continue
        rest = line
        for lit in _literals(line):
            if lit in SOLAR_TERM_KEYS:
                rest = rest.replace(lit, "")
        if HAN.search(rest):
            bad.append(f"{app}/lib/{rel}:{no}: {line.strip()[:100]}")
    assert not bad, "Chinese text in the international app:\n" + "\n".join(bad[:40])


@pytest.mark.parametrize("app", ["ios-global", "android-global"])
def test_international_app_does_not_ship_other_locales(app):
    main = (ROOT / app / "lib" / "main.dart").read_text(encoding="utf-8")
    m = re.search(r"supportedLocales:\s*const\s*\[([^\]]*)\]", main)
    if m:
        assert re.findall(r"Locale\('(\w+)'", m.group(1)) == ["en"]


@pytest.mark.parametrize("app", ["ios-cn", "android-cn"])
def test_domestic_app_has_no_english_ui_sentences(app):
    pat = re.compile(r"[A-Z][A-Za-z0-9 ,.'!?\-:]{14,}")
    skip = re.compile(r"\b(print|debugPrint|log|Exception|throw|assert|Logger|developer)\b")
    bad = []
    for rel, no, line in _code_lines(app):
        s = line.lstrip()
        if skip.search(line) or s.startswith(("import", "export", "part")):
            continue
        for lit in _literals(line):
            if pat.fullmatch(lit) and len(lit.split()) >= 3 and lit not in DOMESTIC_ENGLISH_OK:
                bad.append(f"{app}/lib/{rel}:{no}: {lit[:80]}")
    assert not bad, "English UI sentence in the domestic app:\n" + "\n".join(bad[:40])
