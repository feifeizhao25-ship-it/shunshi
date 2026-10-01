"""国内版对外文本里不得残留国际版品牌与境外域名/邮箱。

2026-09 查出：医疗免责声明写着「顺时（ShunShi/SEASONS）」；礼品卡说明的客服邮箱是国际版域名 gift@seasons-tcm.com。
扫描范围：已挂载的路由模块（排除国际版名单）与静态页面；注释行不算。
"""

import pathlib
import re

from app.main import INTERNATIONAL_ONLY_MODULES, PENDING_REVIEW_MODULES

APP = pathlib.Path(__file__).resolve().parent.parent / "app"
BRAND = re.compile(r"ShunShi/SEASONS|Welcome to SEASONS|seasons-tcm|seasons\.app|SEASONS 国际|国际版 SEASONS")
EMAIL = re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")
ALLOWED_EMAIL_DOMAINS = ("shunshi.cn",)


def _files():
    files = [p for p in sorted((APP / "router").glob("*.py")) if p.stem not in INTERNATIONAL_ONLY_MODULES | set(PENDING_REVIEW_MODULES)]
    return files + sorted((APP / "static").glob("*.html"))


def _lines(path):
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if path.suffix == ".py" and line.lstrip().startswith("#"):
            continue
        yield number, line


def test_scan_covers_files_and_can_fail():
    assert len(_files()) > 100
    assert BRAND.search("顺时（ShunShi/SEASONS）") and BRAND.search("gift@seasons-tcm.com")


def test_no_international_brand_or_domain_in_domestic_text():
    hits = [f"{p.name}:{n}: {l.strip()[:80]}" for p in _files() for n, l in _lines(p) if BRAND.search(l)]
    assert not hits, "\n".join(hits)


def test_every_email_shown_to_users_is_a_domestic_address():
    hits = []
    for p in _files():
        for n, line in _lines(p):
            for email in EMAIL.findall(line):
                if not email.lower().endswith(ALLOWED_EMAIL_DOMAINS):
                    hits.append(f"{p.name}:{n}: {email}")
    assert not hits, "\n".join(hits)
