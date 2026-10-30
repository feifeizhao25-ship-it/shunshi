#!/usr/bin/env python3
"""国内版 Flutter 应用「界面全中文」门禁。

做什么：从 lib/main.dart 出发，顺着 import 找出真正会被打包进应用的 Dart 文件，
扫描其中的字符串字面量；凡是含英文单词、又不在白名单里的，视为「可能显示给用户的英文」，失败。

不扫描什么（都是刻意的，不是漏洞）：
  * 没有被 main.dart 间接引用的文件（死代码，不会出现在应用里）；
  * 日志 / 请求头 / 异常里给开发者看的内部文字（见下面 TECH_CTX 里的写法）。
    这类文字如果以后被直接显示给用户，请改成中文，不要往白名单里加；
  * `// zh-gate:allow 原因` 标记过的那一行，以及 `// zh-gate:allow-begin 原因` 到
    `// zh-gate:allow-end` 之间的区域（例如用来识别用户输入的英文关键词，不会显示）。

用法：
  python3 scripts/verify_zh_ui_dart.py --app android-cn --app ios-cn [--allow scripts/zh_ui_allow.json] [--list]
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

LATIN = re.compile(r"[A-Za-z]{2,}")
DEFAULT_TOKENS = {
    # 品牌 / 平台 / 通用缩写（界面上本来就只有这种写法）
    "AI", "AIGC", "iOS", "iPhone", "iPad", "Android", "App", "App Store", "Apple", "HTTPS", "ID", "VIP", "QQ", "ICP", "PDF", "PNG",
    # 计量单位
    "kW", "kWp", "kWh", "MW", "MWp", "MWh", "GW", "GWh", "kV", "kVA", "MB", "GB", "KB", "Hz", "W", "Wh", "V", "A",
    "kg", "g", "mg", "ml", "kcal", "cm", "mm", "km", "min", "px", "ms", "m", "h", "s",
}
# 出现这些词的行，里面的英文是给程序/开发者看的，不是界面文字
LINE_CTX = ("debugPrint", "print(", "throw ", "Exception(", "StateError(", "UnimplementedError(", "kDebugMode", "assert(")
TECH_CTX = (
    "Authorization", "Bearer", "debugPrint", "print(", "log(", "Logger", "logger", "throw ", "Exception(", "StateError(",
    "UnimplementedError(", "Error(", "headers", "Content-Type", "Accept", "assert(", "RegExp(", "jsonDecode",
    "SharedPreferences", "prefs.", "getString", "setString", "MethodChannel", "queryParameters", "_request(", "Uri.parse",
    "Locale(", "RestoreResult(", "CacheStats(", "CacheResult(", "toString()", "DateFormat(", "pattern:", "key:", "Key(",
    "case '", "== '", "!= '", "contains('", "startsWith('", "endsWith('", "split('", "replaceAll(", "kDebugMode",
)


UI_CTX = ("Text(", "title:", "label:", "subtitle:", "hintText", "labelText", "tooltip", "content:", "text:", "_heroTag(", "Chip(")


def literals(src: str):
    i, n, line = 0, len(src), 1
    while i < n:
        c = src[i]
        if c == "\n":
            line += 1; i += 1; continue
        if src.startswith("//", i):
            j = src.find("\n", i); i = n if j < 0 else j; continue
        if src.startswith("/*", i):
            j = src.find("*/", i + 2); j = n if j < 0 else j + 2
            line += src.count("\n", i, j); i = j; continue
        if c in "'\"":
            raw = i > 0 and src[i - 1] == "r" and (i < 2 or not src[i - 2].isalnum())
            q = c
            if src.startswith(q * 3, i):
                q3 = q * 3; j = i + 3
                while j < n and not src.startswith(q3, j):
                    if src[j] == "\\" and not raw: j += 1
                    j += 1
                body, end = src[i + 3:j], j + 3
            else:
                j, depth = i + 1, 0
                while j < n:
                    ch = src[j]
                    if ch == "\\" and not raw: j += 2; continue
                    if not raw and ch == "$" and src.startswith("${", j): depth += 1; j += 2; continue
                    if depth and ch == "}": depth -= 1
                    elif depth == 0 and ch == q: break
                    elif ch == "\n" and depth == 0: break
                    j += 1
                body, end = src[i + 1:j], j + 1
            yield line, body, src[max(src.rfind('\n', 0, i) + 1, i - 40):i]
            line += src.count("\n", i, end); i = end; continue
        i += 1


def reachable(app: Path) -> set[Path]:
    lib = (app / "lib").resolve()
    pat = re.compile(r"""^\s*(?:import|export|part)\s+['"]([^'"]+)['"]""", re.M)
    seen: set[Path] = set(); stack = [lib / "main.dart"]
    while stack:
        f = stack.pop()
        if f in seen or not f.exists(): continue
        seen.add(f)
        for m in pat.findall(f.read_text(encoding="utf-8", errors="ignore")):
            if m.startswith("dart:"): continue
            c = (lib / m.split("/", 1)[1]) if m.startswith("package:") and "/" in m else (f.parent / m).resolve()
            if c.exists(): stack.append(c)
    return seen


def english_words(text: str, tokens: list[str]) -> list[str]:
    t = re.sub(r"\$\{[^}]*\}|\$[A-Za-z_]\w*", " ", text)
    t = re.sub(r"\\[nrt'\"$\\]", " ", t)
    t = re.sub(r"https?://\S+", " ", t)
    for tok in sorted(tokens, key=len, reverse=True):
        t = re.sub(r"(?<![A-Za-z])" + re.escape(tok) + r"(?![A-Za-z])", " ", t)
    return LATIN.findall(t)


def scan_app(app: Path, tokens: list[str], literal_allow: list[dict]):
    out = []
    root = app.resolve()
    for p in sorted(reachable(app)):
        rel = str(p.relative_to(root))
        if p.name.startswith("._") or p.name.endswith((".g.dart", ".freezed.dart")): continue
        src = p.read_text(encoding="utf-8", errors="ignore")
        lines = src.splitlines()
        region = False
        in_region = set()
        for idx, l in enumerate(lines, 1):
            if "zh-gate:allow-begin" in l: region = True
            if region: in_region.add(idx)
            if "zh-gate:allow-end" in l: region = False
        for ln, body, pre in literals(src):
            ctx = lines[ln - 1] if ln - 1 < len(lines) else ""
            cs = ctx.strip()
            if cs.startswith(("import ", "export ", "part ", "library ", "@")): continue
            if ln in in_region or "zh-gate:allow" in ctx: continue
            if any(k in pre for k in TECH_CTX) or any(k in ctx for k in LINE_CTX): continue
            words = english_words(body, tokens)
            if not words: continue
            b = re.sub(r"\$\{[^}]*\}|\$[A-Za-z_]\w*", "", body).strip()
            # 不含空白的当作键 / 路径 / 标识符；只有首字母大写的单词（Text('Nourish')）、
            # 或出现在界面控件里的全大写缩写（Text('SVIP')）才算界面文字
            if " " not in b:
                if re.fullmatch(r"[A-Z][a-z]{2,}", b): pass
                elif re.fullmatch(r"[A-Z]{2,}", b) and any(k in ctx for k in UI_CTX): pass
                else: continue
            if re.fullmatch(r"[yMdHhmsSaEZ:\-/ .,]+", b): continue
            if any(a["file"] == rel and a["text"] in body for a in literal_allow): continue
            out.append((rel, ln, body[:100], sorted(set(words))[:4]))
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--app", action="append", required=True)
    ap.add_argument("--allow", default=None)
    ap.add_argument("--list", action="store_true")
    a = ap.parse_args()
    base = Path(__file__).resolve().parents[1]
    cfg = json.loads(Path(a.allow).read_text(encoding="utf-8")) if a.allow and Path(a.allow).exists() else {}
    tokens = sorted(DEFAULT_TOKENS | set(cfg.get("tokens", [])))
    lit = cfg.get("literals", [])
    for e in lit:
        if not e.get("why"): print("白名单条目必须写明原因 why:", e); return 2
    bad = []
    for app in a.app:
        d = base / app
        if not (d / "lib" / "main.dart").exists():
            print(f"找不到 {app}/lib/main.dart，门禁没有检查任何东西"); return 2
        bad += [(app,) + x for x in scan_app(d, tokens, lit)]
    if bad:
        print(f"界面里可能有英文（国内版必须全中文），共 {len(bad)} 处：")
        for app, rel, ln, text, words in bad: print(f"  {app}/{rel}:{ln}: {text!r}  → {', '.join(words)}")
        print("处理办法：改成中文；确实不是显示给用户的，在那一行加 `// zh-gate:allow 原因`。")
        return 1
    print("国内版 Flutter 界面全中文检查通过")
    return 0


if __name__ == "__main__":
    sys.exit(main())
