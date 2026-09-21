#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""门禁：compose 里不许再出现"公网直连"的端口和"裸奔"的数据服务。

## 为什么要有这个文件

2026-09-20 复查 `docker-compose.yml` 时发现，除 nginx 外的**每一个**服务
都把端口写成裸端口号：

    postgres   "5432:5432"     → 公网可直连数据库
    redis      "6379:6379"     → 公网可直连，且**没有设密码**
    backend    "4000:4000"     → 绕过 nginx（也就绕过 TLS、限流、安全响应头）
    admin      "3001:3000"     → 管理后台直接挂在公网上
    grafana    "3000:3000"     → 而 GF_SECURITY_ADMIN_PASSWORD 没设时
                                  Grafana 回落到内置的 admin/admin
    prometheus "9090:9090"     → Prometheus 自身没有任何鉴权

Docker 把裸端口号解释成 `0.0.0.0`，而且 docker-proxy 的转发走 DOCKER 链、
**不经过 iptables 的 INPUT 链** —— 在宿主机上配的 ufw / firewalld 规则
对它不起作用。也就是说"我装了防火墙"并不能挡住这些端口。

其中开放且无密码的 Redis 是一条成熟的 RCE 路径：
`CONFIG SET dir /root/.ssh` + `dbfilename authorized_keys`，
写进攻击者的公钥就拿到宿主机。

一次改完不够——下一个人加服务时会照着上面几行抄。所以做成门禁。

## 规则

1. 端口必须绑 `127.0.0.1`（或 `::1`）。唯一的例外是 ALLOWED_PUBLIC 里
   列出的网关服务的 80 / 443。
2. `redis` 镜像必须带 `--requirepass`。
3. 口令类变量必须用 `${VAR:?...}` 而不是 `${VAR}` —— 后者在变量缺失时
   展开成空串，故障会以"密码为空"的形式静默发生。

## 用法

    python3 scripts/check_compose_exposure.py            # 检查
    python3 scripts/check_compose_exposure.py --list     # 只列出，不判定
"""
from __future__ import annotations

import argparse
import pathlib
import re
import sys

try:
    import yaml
except ImportError:  # pragma: no cover
    sys.exit("需要 PyYAML：pip install pyyaml")

REPO = pathlib.Path(__file__).resolve().parent.parent

# 允许对公网监听的服务 → 允许的容器端口
ALLOWED_PUBLIC = {
    "nginx": {"80", "443"},
    "caddy": {"80", "443"},
    "gateway": {"80", "443"},
    "traefik": {"80", "443"},
}

# 这些变量一旦为空就意味着"没有口令"，必须用 :? 让 compose 直接拒绝启动
SECRET_VAR_HINT = re.compile(r"(PASSWORD|SECRET|TOKEN|PRIVATE_KEY|API_KEY)$")

LOOPBACK = ("127.0.0.1:", "::1:", "[::1]:")


def compose_files() -> list[pathlib.Path]:
    out = []
    for p in REPO.rglob("docker-compose*.y*ml"):
        if any(part in {"node_modules", ".git", "vendor-refs"} for part in p.parts):
            continue
        out.append(p)
    return sorted(out)


def port_entries(spec) -> list[str]:
    """把 ports 的三种写法统一成字符串。"""
    out = []
    for item in spec or []:
        if isinstance(item, dict):  # 长语法
            host_ip = item.get("host_ip", "")
            published = item.get("published", "")
            target = item.get("target", "")
            out.append(f"{host_ip + ':' if host_ip else ''}{published}:{target}")
        else:
            out.append(str(item))
    return out


def check_file(path: pathlib.Path, listing: bool) -> list[str]:
    problems: list[str] = []
    rel = path.relative_to(REPO)
    try:
        doc = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    except yaml.YAMLError as exc:
        return [f"{rel}: YAML 解析失败：{exc}"]

    for name, svc in (doc.get("services") or {}).items():
        if not isinstance(svc, dict):
            continue

        # ── 1. 端口绑定 ────────────────────────────────────────────
        for entry in port_entries(svc.get("ports")):
            if listing:
                print(f"  {rel}  {name:<16} {entry}")
                continue
            if entry.startswith(LOOPBACK):
                continue
            container_port = entry.rsplit(":", 1)[-1].split("/")[0]
            if container_port in ALLOWED_PUBLIC.get(name, set()):
                continue
            problems.append(
                f"{rel}: 服务 {name} 的端口 {entry!r} 对公网监听。"
                f"写成 '127.0.0.1:<host>:<container>'；确实要对外就经网关进。"
            )

        # ── 2. Redis 必须要口令 ────────────────────────────────────
        image = str(svc.get("image") or "")
        if "redis" in image.split(":")[0].lower():
            command = svc.get("command")
            flat = " ".join(command) if isinstance(command, list) else str(command or "")
            if "--requirepass" not in flat:
                problems.append(
                    f"{rel}: 服务 {name} 用的是 Redis 镜像但 command 里没有 "
                    f"--requirepass。开放且无口令的 Redis 可被写入 SSH 公钥拿到宿主机。"
                )

        # ── 3. 口令变量必须 fail-closed ────────────────────────────
        env = svc.get("environment")
        pairs: list[tuple[str, str]] = []
        if isinstance(env, dict):
            pairs = [(k, str(v)) for k, v in env.items()]
        elif isinstance(env, list):
            for item in env:
                k, _, v = str(item).partition("=")
                pairs.append((k, v))
        for key, value in pairs:
            if not SECRET_VAR_HINT.search(key):
                continue
            for var in re.findall(r"\$\{([A-Za-z_][A-Za-z0-9_]*)([^}]*)\}", value):
                var_name, modifier = var
                if not SECRET_VAR_HINT.search(var_name):
                    continue
                if modifier.startswith(":?") or modifier.startswith("?"):
                    continue
                problems.append(
                    f"{rel}: 服务 {name} 的 {key} 用了 ${{{var_name}{modifier}}}。"
                    f"口令类变量要写 ${{{var_name}:?{var_name} is required}}，"
                    f"缺失时直接拒绝启动，而不是展开成空口令。"
                )

    return problems


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true", help="只列出端口，不判定")
    args = ap.parse_args()

    files = compose_files()
    if not files:
        print("没有找到 docker-compose 文件")
        return 0

    all_problems: list[str] = []
    for path in files:
        all_problems += check_file(path, args.list)

    if args.list:
        return 0

    if all_problems:
        print(f"✗ {len(all_problems)} 处问题：\n")
        for p in all_problems:
            print(f"  - {p}")
        print(f"\n（扫描了 {len(files)} 个 compose 文件）")
        return 1

    print(f"✓ {len(files)} 个 compose 文件：端口均绑回环，Redis 有口令，口令变量 fail-closed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
