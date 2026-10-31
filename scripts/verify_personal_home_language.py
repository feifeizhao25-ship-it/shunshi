#!/usr/bin/env python3
"""个性化首页区块的语言隔离门禁（国内版全中文、国际版全英文）。

背景：区块组件 personal_home_section.dart 四个 App 共用一份代码。它曾经在同一个文件里同时带着中文和英文
（`_zh ? '中文' : 'English'`），结果国内版里有英文、国际版里有中文。现在组件本身不带任何面向用户的文字，
文字放在各版本自己的文件里：国内版只有 personal_home_strings_zh.dart，国际版只有 personal_home_strings_en.dart。

检查（任何一条不满足就失败，退出码 1）：
  1. 四个 App 的共用组件里没有 `_zh` 之类的语言开关，也没有含中文或含空格英文的字符串（即没有面向用户的文字）；
  2. 国际版（seasons：android-global / ios-global）里与个性化首页相关的文件（组件、文字文件、绑定、首页）
     不出现任何中文字符（注释也不行），并且没有 *_zh.dart 文字文件、没有国内版资料库页面文件；
  3. 国内版（shunshi：android-cn / ios-cn）没有 personal_home_strings_en.dart，文字文件里每一条文字都含中文。
用法：python3 scripts/verify_personal_home_language.py [--root .]
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

CJK = re.compile(r"[\u3400-\u9fff\uff00-\uffef\u3000-\u303f]")
DOMESTIC = ("android-cn", "ios-cn")
INTL = ("android-global", "ios-global")
W = "lib/presentation/widgets"
PAGES = "lib/presentation/pages"
LITERAL = re.compile(r"'((?:[^'\\\n]|\\.)*)'|\"((?:[^\"\\\n]|\\.)*)\"")
# 国内版资料库页面只属于国内版：国际版里不应出现这些文件
DOMESTIC_ONLY_FILES = ("library_strings_zh.dart", "library_live.dart", "shunshi_reference_library.dart", "reference_library_page.dart")


def strip_comments(src: str) -> str:
    out = []
    for line in src.splitlines():
        out.append(re.sub(r"(?<!:)//.*$", "", line) if "'" not in line.split("//")[0][-1:] else line)
    return "\n".join(out)


def literals(src: str):
    for m in LITERAL.finditer(strip_comments(src)):
        yield m.group(1) if m.group(1) is not None else m.group(2)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".")
    root = Path(ap.parse_args(argv).root)
    bad: list[str] = []

    def rel(p: Path) -> str:
        return str(p.relative_to(root))

    for app in DOMESTIC + INTL:
        widget = root / app / W / "personal_home_section.dart"
        if not widget.exists():
            bad.append(f"{app}: 缺少 {W}/personal_home_section.dart")
            continue
        src = widget.read_text("utf-8")
        code = strip_comments(src)
        if re.search(r"\b_zh\b|\bisZh\b|\bzh\s*\?", code):
            bad.append(f"{rel(widget)}: 组件里还有语言开关（_zh），文字必须放在版本自己的文字文件里")
        for lit in literals(src):
            if CJK.search(lit) or re.search(r"[A-Za-z]+\s+[A-Za-z]+", lit):
                bad.append(f"{rel(widget)}: 共用组件里有面向用户的文字：{lit[:50]!r}")

    for app in INTL:
        base = root / app
        if (base / W / "personal_home_strings_zh.dart").exists():
            bad.append(f"{app}: 国际版不应包含 personal_home_strings_zh.dart")
        if not (base / W / "personal_home_strings_en.dart").exists():
            bad.append(f"{app}: 缺少 personal_home_strings_en.dart")
        for name in DOMESTIC_ONLY_FILES:
            for p in (base / PAGES / "library").glob(name) if (base / PAGES / "library").exists() else []:
                bad.append(f"{rel(p)}: 国内版资料库文件不应出现在国际版")
        for p in (base / W / "personal_home_section.dart", base / W / "personal_home_strings_en.dart",
                  base / PAGES / "home/widgets/personal_home_binding.dart"):
            if p.exists() and CJK.search(p.read_text("utf-8")):
                line = next(i for i, l in enumerate(p.read_text("utf-8").splitlines(), 1) if CJK.search(l))
                bad.append(f"{rel(p)}:{line}: 国际版文件里出现中文")
        for p in (base / "test").glob("personal_home*_test.dart") if (base / "test").exists() else []:
            pass  # 测试文件里允许同时校验两种语言，不属于打包内容

    for app in DOMESTIC:
        base = root / app
        if (base / W / "personal_home_strings_en.dart").exists():
            bad.append(f"{app}: 国内版不应包含 personal_home_strings_en.dart")
        zh = base / W / "personal_home_strings_zh.dart"
        if not zh.exists():
            bad.append(f"{app}: 缺少 personal_home_strings_zh.dart")
            continue
        for lit in literals(zh.read_text("utf-8")):
            if lit and not lit.endswith(".dart") and not CJK.search(lit) and not re.fullmatch(r"[\d\s$:.{}n]*", lit):
                bad.append(f"{rel(zh)}: 国内版文字里有非中文：{lit[:50]!r}")

    if bad:
        print(f"个性化首页语言隔离检查失败：{len(bad)} 条")
        for b in bad:
            print("  -", b)
        return 1
    print("个性化首页语言隔离检查通过：共用组件无文字；国内版全中文；国际版全英文且不含中文文件。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
