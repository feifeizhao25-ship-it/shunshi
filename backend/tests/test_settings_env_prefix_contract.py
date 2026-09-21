# -*- coding: utf-8 -*-
"""钉住"compose 写的变量名，后端真的读得到"这件事。

## 背景

`app/config.py` 的 Settings 用的是 `env_prefix="SHUNSHI_"`，
而 `docker-compose.yml` 里写的是不带前缀的：

    environment:
      DATABASE_URL: postgresql+psycopg://...@postgres:5432/shunshi
      REDIS_URL: redis://redis:6379/0

pydantic-settings **不读**这两个名字。于是 `database_url` 一路用了缺省值
`sqlite:///./shunshi_dev.db`，文件落在容器 WORKDIR `/app` 下，
而 compose 只把 `/app/data`、`/app/logs` 做成了 volume。

结果是：postgres 容器健康地空跑，用户数据全在容器可写层里，
**下一次 `docker compose up --build` 就清零**。

JWT 与 CORS 都是 fail-closed 的，唯独"数据存在哪"不是——
而它恰恰是唯一一个配错了不报错、只在重新部署那天才暴露的配置。

这一组从两头钉：
  1. Settings 确实只认带前缀的名字（不带前缀的必须被忽略）；
  2. compose 里给 backend 的每个变量名都带前缀。
"""
from __future__ import annotations

import pathlib
import sys

import pytest

BACKEND = pathlib.Path(__file__).resolve().parent.parent
REPO = BACKEND.parent
sys.path.insert(0, str(BACKEND))

from app.config import Settings  # noqa: E402


# ── 一、Settings 只认带前缀的名字 ────────────────────────────────

def test_unprefixed_database_url_is_ignored(monkeypatch):
    """这条是"反直觉行为"的存档：不带前缀的 DATABASE_URL 确实无效。

    如果哪天有人把 env_prefix 去掉、让它生效了，这条会红——
    那时要一并检查 compose 和 .env.example，而不是直接改这条用例。
    """
    monkeypatch.delenv("SHUNSHI_DATABASE_URL", raising=False)
    monkeypatch.setenv("DATABASE_URL", "postgresql+psycopg://u:p@postgres:5432/shunshi")
    assert Settings(_env_file=None).database_url.startswith("sqlite"), (
        "不带前缀的 DATABASE_URL 被读进来了；compose 与 .env.example 需要同步复查"
    )


def test_prefixed_database_url_is_read(monkeypatch):
    monkeypatch.setenv("SHUNSHI_DATABASE_URL", "postgresql+psycopg://u:p@postgres:5432/shunshi")
    assert Settings(_env_file=None).database_url.startswith("postgresql")


def test_prefixed_redis_url_is_read(monkeypatch):
    monkeypatch.setenv("SHUNSHI_REDIS_URL", "redis://:pw@redis:6379/0")
    assert Settings(_env_file=None).redis_url == "redis://:pw@redis:6379/0"


# ── 二、compose 给 backend 的变量名必须带前缀 ────────────────────

COMPOSE = REPO / "docker-compose.yml"

# 这些是给容器/镜像本身看的，不走 Settings，不要求前缀
NOT_APP_SETTINGS = {"PATH", "TZ", "PYTHONUNBUFFERED", "PYTHONDONTWRITEBYTECODE"}


def _backend_environment() -> dict:
    yaml = pytest.importorskip("yaml")
    doc = yaml.safe_load(COMPOSE.read_text(encoding="utf-8"))
    env = doc["services"]["backend"].get("environment") or {}
    if isinstance(env, list):
        out = {}
        for item in env:
            k, _, v = str(item).partition("=")
            out[k] = v
        return out
    return dict(env)


@pytest.mark.skipif(not COMPOSE.exists(), reason="仓库里没有 docker-compose.yml")
def test_compose_backend_env_names_all_carry_the_prefix():
    env = _backend_environment()
    assert env, "backend 服务没有 environment 段，本条用例失去意义"
    wrong = [k for k in env if k not in NOT_APP_SETTINGS and not k.startswith("SHUNSHI_")]
    assert not wrong, (
        f"compose 给 backend 的这些变量名没有 SHUNSHI_ 前缀，后端读不到：{wrong}。"
        f"app/config.py 的 Settings 用的是 env_prefix='SHUNSHI_'。"
    )


@pytest.mark.skipif(not COMPOSE.exists(), reason="仓库里没有 docker-compose.yml")
def test_compose_points_the_backend_at_postgres_not_sqlite():
    env = _backend_environment()
    dsn = env.get("SHUNSHI_DATABASE_URL", "")
    assert dsn, "compose 没有给 backend 配 SHUNSHI_DATABASE_URL"
    assert not dsn.startswith("sqlite"), "生产 compose 不应指向 SQLite"
    assert "postgres" in dsn, f"期望 PostgreSQL DSN，实际是 {dsn!r}"
