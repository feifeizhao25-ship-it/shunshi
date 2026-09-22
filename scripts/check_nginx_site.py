#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""门禁：对外 nginx 站点配置能启动、限流真的生效、域名与前端构建一致。

## 为什么要有这个文件

2026-09-21 用 nginx 1.24 对仓库里的两份站点配置做 ``nginx -t``：

- ``shunshi-ssl.conf``（生产 HTTPS）**起不来**：``limit_req zone=api_limit`` 引用的区域只在
  ``default.conf`` 里定义，而两份配置同一时间只挂一份 —— ``zero size shared memory zone``。
- ``default.conf`` 定义了限流区域却**没有任何 location 使用**：限流从未生效。
- 生产配置把管理后台挂在用户主站 ``/`` 上、没有用户 Web；证书路径是宿主机的
  ``/etc/letsencrypt``，compose 没挂进容器；还混着国际版域名 ``seasons.care``。
- 三处写着三个不同的域名：nginx 用 ``shunshi.cn``，Web 构建默认 ``api.shunshi.app``，
  部署脚本用 ``shunshiapp.com``。

## 检查内容

1. 静态：每份站点配置里用到的 ``limit_req zone=X``（含 include 的片段）都在同一份配置里定义；
   ``/metrics`` 不对外反代；不出现国际版域名。
2. 选用 ``shunshi-ssl.conf`` 时：三个域名都已填写且互不相同；``CN_API_ORIGIN`` 等于
   ``https://<SHUNSHI_API_DOMAIN>``；证书文件存在。
3. 本机有 nginx 时（``--nginx-test``）：按 nginx 镜像的方式渲染模板后跑 ``nginx -t``。

## 用法

    python3 scripts/check_nginx_site.py                 # 读仓库根目录 .env
    python3 scripts/check_nginx_site.py --nginx-test    # 额外跑 nginx -t
"""
from __future__ import annotations

import argparse
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
SITES = REPO / "docker" / "nginx" / "conf.d"
SNIPPETS = REPO / "docker" / "nginx" / "snippets"
NGINX_CONF = REPO / "backend" / "docker" / "nginx" / "nginx.conf"
FOREIGN_DOMAINS = ("seasons.care", "shunshiapp.com")
SSL_SITE = "shunshi-ssl.conf"
DOMAIN_VARS = ("SHUNSHI_WEB_DOMAIN", "SHUNSHI_API_DOMAIN", "SHUNSHI_ADMIN_DOMAIN")
HOSTNAME = re.compile(r"^(?=.{1,253}$)([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$")


def _strip_comments(text: str) -> str:
    return "\n".join(line.split("#", 1)[0] for line in text.splitlines())


def expand_includes(text: str, snippets: pathlib.Path = SNIPPETS) -> str:
    def repl(match: re.Match[str]) -> str:
        name = pathlib.PurePosixPath(match.group(1)).name
        path = snippets / name
        return expand_includes(_strip_comments(path.read_text(encoding="utf-8")), snippets) if path.exists() else ""

    return re.sub(r"include\s+/etc/nginx/snippets/([^;\s]+)\s*;", repl, text)


def static_problems(path: pathlib.Path, snippets: pathlib.Path = SNIPPETS) -> list[str]:
    raw = path.read_text(encoding="utf-8")
    text = expand_includes(_strip_comments(raw), snippets)
    problems: list[str] = []
    defined = set(re.findall(r"limit_req_zone\s+\S+\s+zone=([\w-]+):", text))
    used = set(re.findall(r"limit_req\s+zone=([\w-]+)", text))
    for zone in sorted(used - defined):
        problems.append(f"{path.name}: 用到了限流区域 {zone}，但本配置里没有 limit_req_zone 定义它（nginx 起不来）")
    for zone in sorted(defined - used):
        problems.append(f"{path.name}: 定义了限流区域 {zone} 却没有任何 location 使用（限流不生效）")
    if re.search(r"location\s+[^{]*/metrics[^{]*\{[^}]*proxy_pass", text):
        problems.append(f"{path.name}: /metrics 被反代到公网；Prometheus 应在内网直接抓 backend:4000")
    for domain in FOREIGN_DOMAINS:
        if domain in text:
            problems.append(f"{path.name}: 出现了不属于国内版的域名 {domain}")
    return problems


def read_env(path: pathlib.Path) -> dict[str, str]:
    env: dict[str, str] = {}
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, value = line.split("=", 1)
                env[key.strip()] = value.strip().strip('"').strip("'")
    for key in ("SHUNSHI_NGINX_SITE", "CN_API_ORIGIN", *DOMAIN_VARS):
        if os.environ.get(key):
            env[key] = os.environ[key]
    return env


def deployment_problems(env: dict[str, str], repo: pathlib.Path = REPO) -> list[str]:
    site = env.get("SHUNSHI_NGINX_SITE") or "default.conf"
    if not (repo / "docker" / "nginx" / "conf.d" / site).exists():
        return [f"SHUNSHI_NGINX_SITE={site}：docker/nginx/conf.d/ 下没有这个文件"]
    if site != SSL_SITE:
        return []
    problems: list[str] = []
    domains = [env.get(name, "").lower() for name in DOMAIN_VARS]
    for name, value in zip(DOMAIN_VARS, domains):
        if not value:
            problems.append(f"{name} 未填写")
        elif not HOSTNAME.match(value):
            problems.append(f"{name}={value} 不是合法域名")
    filled = [d for d in domains if d]
    if len(set(filled)) != len(filled):
        problems.append("三个域名必须互不相同（管理后台不能和用户站点共用一个域名）")
    api = env.get("SHUNSHI_API_DOMAIN", "").lower()
    origin = env.get("CN_API_ORIGIN", "").rstrip("/").lower()
    if api and origin != f"https://{api}":
        problems.append(
            f"CN_API_ORIGIN={origin or '(未填)'} 与 SHUNSHI_API_DOMAIN 不一致；应为 https://{api}"
            "（Web 构建会把它写死进前端）"
        )
    for name in ("fullchain.pem", "privkey.pem"):
        if not (repo / "backend" / "docker" / "ssl" / name).exists():
            problems.append(f"证书缺失：backend/docker/ssl/{name}")
    return problems


def render(template: str, env: dict[str, str]) -> str:
    """与 nginx 镜像的 envsubst 相同：只替换已定义的变量。"""
    return re.sub(r"\$\{(\w+)\}", lambda m: env[m.group(1)] if m.group(1) in env else m.group(0), template)


def nginx_test(site: pathlib.Path, env: dict[str, str]) -> tuple[bool, str]:
    nginx = shutil.which("nginx")
    if not nginx:
        return True, "本机没有 nginx，跳过 nginx -t"
    with tempfile.TemporaryDirectory() as tmp:
        prefix = pathlib.Path(tmp)
        (prefix / "conf.d").mkdir()
        (prefix / "snippets").mkdir()
        (prefix / "log").mkdir()
        (prefix / "ssl").mkdir()
        subprocess.run(
            ["openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "1", "-subj", "/CN=test",
             "-keyout", str(prefix / "ssl/privkey.pem"), "-out", str(prefix / "ssl/fullchain.pem")],
            check=True, capture_output=True,
        )
        mime = pathlib.Path("/etc/nginx/mime.types")
        (prefix / "mime.types").write_text(mime.read_text() if mime.exists() else "types {}\n")

        def localize(text: str) -> str:
            return (
                text.replace("/etc/nginx/", f"{prefix}/")
                .replace("/var/log/nginx", f"{prefix}/log")
                .replace("/var/run/nginx.pid", f"{prefix}/nginx.pid")
                .replace("/usr/share/nginx/html", str(prefix))
                .replace("/var/www/certbot", str(prefix))
                .replace("user nginx;", "")
            )

        for snippet in SNIPPETS.glob("*.conf"):
            (prefix / "snippets" / snippet.name).write_text(localize(snippet.read_text(encoding="utf-8")))
        (prefix / "nginx.conf").write_text(localize(NGINX_CONF.read_text(encoding="utf-8")))
        (prefix / "conf.d" / "default.conf").write_text(localize(render(site.read_text(encoding="utf-8"), env)))
        result = subprocess.run([nginx, "-t", "-c", str(prefix / "nginx.conf"), "-p", str(prefix)],
                                capture_output=True, text=True)
        return result.returncode == 0, (result.stderr or result.stdout).strip()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--env-file", default=str(REPO / ".env"))
    parser.add_argument("--nginx-test", action="store_true")
    args = parser.parse_args()

    problems: list[str] = []
    for site in sorted(SITES.glob("*.conf")):
        problems += static_problems(site)
    env = read_env(pathlib.Path(args.env_file))
    problems += deployment_problems(env)
    if args.nginx_test:
        site = SITES / (env.get("SHUNSHI_NGINX_SITE") or "default.conf")
        if site.exists():
            ok, output = nginx_test(site, env)
            if output:
                print(output)
            if not ok:
                problems.append(f"nginx -t 失败（{site.name}）：\n{output}")
    if problems:
        print(f"✗ {len(problems)} 处问题：\n")
        for problem in problems:
            print("  - " + problem)
        return 1
    print("✓ nginx 站点配置：限流区域定义与使用一致，/metrics 不对外，域名与前端构建一致")
    return 0


if __name__ == "__main__":
    sys.exit(main())
