# -*- coding: utf-8 -*-
"""对外 nginx 站点配置与静态页（scripts/check_nginx_site.py）。

2026-09-21：生产 HTTPS 配置 nginx -t 直接失败（引用了未定义的限流区域）；本地配置定义了
限流却没人用；/metrics 反代到公网；管理后台挂在用户主站；混着国际版域名；
隐私政策页 /static/privacy-policy.html 在镜像里却从未挂出来（404）。
"""
from __future__ import annotations

import importlib.util
import os
import pathlib
import shutil
import sys

import pytest

BACKEND = pathlib.Path(__file__).resolve().parent.parent
REPO = BACKEND.parent
sys.path.insert(0, str(BACKEND))
SCRIPT = REPO / "scripts" / "check_nginx_site.py"

SECRET = "s" * 48
os.environ.setdefault("APP_ENV", "testing")
os.environ.setdefault("SHUNSHI_JWT_SECRET", SECRET)
os.environ.setdefault("ADMIN_PASSWORD_HASH", "x")
os.environ.setdefault("ADMIN_JWT_SECRET", SECRET)

if not SCRIPT.exists():  # 只拷了 backend/ 的场景
    pytest.skip("scripts/check_nginx_site.py not present", allow_module_level=True)

spec = importlib.util.spec_from_file_location("check_nginx_site", SCRIPT)
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)

DOMAINS = {
    "SHUNSHI_NGINX_SITE": "shunshi-ssl.conf",
    "SHUNSHI_WEB_DOMAIN": "shunshi.example.cn",
    "SHUNSHI_API_DOMAIN": "api.shunshi.example.cn",
    "SHUNSHI_ADMIN_DOMAIN": "admin.shunshi.example.cn",
    "CN_API_ORIGIN": "https://api.shunshi.example.cn",
}


@pytest.mark.parametrize("site", ["default.conf", "shunshi-ssl.conf"])
def test_repo_sites_pass_static_checks(site):
    assert gate.static_problems(gate.SITES / site) == []


def test_undefined_zone_and_public_metrics_are_detected(tmp_path):
    conf = tmp_path / "x.conf"
    conf.write_text(
        "server { server_name seasons.care;\n"
        "  location /api/ { limit_req zone=api_limit burst=5; proxy_pass http://b; }\n"
        "  location /metrics { proxy_pass http://b/metrics; } }\n"
    )
    problems = "\n".join(gate.static_problems(conf))
    assert "api_limit" in problems and "/metrics" in problems and "seasons.care" in problems


def test_defined_but_unused_zone_is_detected(tmp_path):
    conf = tmp_path / "y.conf"
    conf.write_text("limit_req_zone $binary_remote_addr zone=z:1m rate=1r/s;\nserver { location / { } }\n")
    assert any("没有任何 location 使用" in p for p in gate.static_problems(conf))


def test_ssl_site_requires_domains_consistent_origin_and_certs(tmp_path):
    (tmp_path / "docker/nginx/conf.d").mkdir(parents=True)
    (tmp_path / "docker/nginx/conf.d/shunshi-ssl.conf").write_text("")
    problems = gate.deployment_problems({"SHUNSHI_NGINX_SITE": "shunshi-ssl.conf"}, tmp_path)
    assert sum("未填写" in p for p in problems) == 3

    env = dict(DOMAINS, CN_API_ORIGIN="https://api.shunshi.app")
    problems = gate.deployment_problems(env, tmp_path)
    assert any("CN_API_ORIGIN" in p for p in problems)
    assert any("证书缺失" in p for p in problems)

    (tmp_path / "backend/docker/ssl").mkdir(parents=True)
    for name in ("fullchain.pem", "privkey.pem"):
        (tmp_path / "backend/docker/ssl" / name).write_text("x")
    assert gate.deployment_problems(dict(DOMAINS), tmp_path) == []
    same = dict(DOMAINS, SHUNSHI_ADMIN_DOMAIN="shunshi.example.cn")
    assert any("互不相同" in p for p in gate.deployment_problems(same, tmp_path))


def test_default_site_needs_no_domains():
    assert gate.deployment_problems({}) == []


def test_render_only_replaces_defined_variables():
    out = gate.render("server_name ${SHUNSHI_WEB_DOMAIN}; return 301 https://$host${UNDEFINED};", {"SHUNSHI_WEB_DOMAIN": "a.cn"})
    assert out == "server_name a.cn; return 301 https://$host${UNDEFINED};"


@pytest.mark.skipif(shutil.which("nginx") is None, reason="nginx not installed")
@pytest.mark.parametrize("site,env", [("default.conf", {}), ("shunshi-ssl.conf", DOMAINS)])
def test_nginx_accepts_rendered_site(site, env):
    ok, output = gate.nginx_test(gate.SITES / site, dict(env))
    assert ok, output


@pytest.mark.skipif(shutil.which("nginx") is None, reason="nginx not installed")
def test_nginx_refuses_ssl_site_without_domains():
    ok, _ = gate.nginx_test(gate.SITES / "shunshi-ssl.conf", {"SHUNSHI_WEB_DOMAIN": "", "SHUNSHI_API_DOMAIN": "", "SHUNSHI_ADMIN_DOMAIN": ""})
    assert not ok


def test_privacy_policy_is_served(tmp_path):
    from fastapi.testclient import TestClient

    from app.config import Settings
    from app.main import create_app

    app = create_app(Settings(jwt_secret=SECRET, database_url=f"sqlite:///{tmp_path}/c.db"))
    with TestClient(app) as client:
        response = client.get("/static/privacy-policy.html")
        assert response.status_code == 200
        assert "隐私政策" in response.text
        assert client.get("/static/medical-disclaimer.html").status_code == 200
