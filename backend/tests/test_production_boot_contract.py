# -*- coding: utf-8 -*-
"""按生产配置，后端到底起不起得来。

2026-09-21 按部署文档（docker-compose.yml + backend/.env.example）给的变量，把后端在
「只有 app/ 被拷进镜像」的布局下拉起来，依次撞上四个启动阻断：

1. ``app/db/database.py`` 写死 ``postgresql://shunshi:shunshi2026@localhost``，且该前缀
   选的是没安装的 psycopg2 —— **导入即崩溃**；compose 里的 ``+psycopg2`` 同理；
2. ``router/auth.py`` 读不带前缀的 ``JWT_SECRET``，文档只写了 ``SHUNSHI_JWT_SECRET``
   —— 导入时 ``RuntimeError``；
3. 知识库文稿在仓库根，不在镜像里 —— 启动阶段 ``FileNotFoundError``；
4. compose 的健康检查探 ``/health``，后端没有这条路由 —— 永远 unhealthy，
   admin 与 web-cn 以 service_healthy 依赖它，永远不启动。

另外：即使手工让两套模型连同一个 PostgreSQL，它们都有 ``users`` 表且列不同，
产品模型建外键时 ``DatatypeMismatch``。修复后产品模型进独立 schema
``shunshi_product``；测试使用独立 PostgreSQL 数据库，可通过
``TEST_POSTGRES_ADMIN_URL`` 指定测试服务器，或从 PATH 启动本地 PostgreSQL。
"""
from __future__ import annotations

import os
import pathlib
import shutil
import subprocess
import sys
import textwrap

import pytest

BACKEND = pathlib.Path(__file__).resolve().parent.parent
REPO = BACKEND.parent
sys.path.insert(0, str(BACKEND))

from app.db.url import PRODUCT_SCHEMA, normalize_database_url, resolve_product_database  # noqa: E402

SECRET = "s" * 48
# 在进程内拉起 create_app() 的用例需要它（router/auth.py 在导入时读取）。
os.environ.setdefault("SHUNSHI_JWT_SECRET", SECRET)
os.environ.setdefault("ADMIN_PASSWORD_HASH", "x")
os.environ.setdefault("ADMIN_JWT_SECRET", SECRET)


# ── 一、连接串 ───────────────────────────────────────────────

@pytest.mark.parametrize(
    "raw,expected",
    [
        ("postgresql://u:p@h/db", "postgresql+psycopg://u:p@h/db"),
        ("postgres://u:p@h/db", "postgresql+psycopg://u:p@h/db"),
        ("postgresql+psycopg2://u:p@h/db", "postgresql+psycopg://u:p@h/db"),
        ("postgresql+psycopg://u:p@h/db", "postgresql+psycopg://u:p@h/db"),
        ("sqlite:///./x.db", "sqlite:///./x.db"),
    ],
)
def test_postgres_urls_use_the_installed_psycopg3_driver(raw, expected):
    assert normalize_database_url(raw) == expected


def test_product_models_share_the_core_database_in_their_own_schema():
    url, schema = resolve_product_database(
        {"SHUNSHI_DATABASE_URL": "postgresql+psycopg2://u:p@postgres:5432/shunshi"}
    )
    assert url == "postgresql+psycopg://u:p@postgres:5432/shunshi"
    assert schema == PRODUCT_SCHEMA


def test_explicit_product_database_wins():
    url, schema = resolve_product_database(
        {"SHUNSHI_PRODUCT_DATABASE_URL": "postgresql://u:p@h/other", "SHUNSHI_DATABASE_URL": "postgresql://x"}
    )
    assert (url, schema) == ("postgresql+psycopg://u:p@h/other", None)


def test_legacy_database_url_name_still_accepted():
    assert resolve_product_database({"DATABASE_URL": "postgresql://u:p@h/db"})[0].startswith("postgresql+psycopg://")


def test_production_without_postgres_refuses_to_start():
    with pytest.raises(RuntimeError, match="PostgreSQL"):
        resolve_product_database({"SHUNSHI_ENV": "production"})


def test_no_hardcoded_credentials_left_in_the_product_engine():
    src = (BACKEND / "app" / "db" / "database.py").read_text(encoding="utf-8")
    assert "shunshi2026" not in src and "localhost:5432" not in src


# ── 二、同一把 JWT 密钥 ───────────────────────────────────────

def _run(code: str, env: dict, cwd: pathlib.Path = BACKEND) -> subprocess.CompletedProcess:
    base = {"PATH": os.environ["PATH"], "HOME": os.environ.get("HOME", "/tmp")}
    return subprocess.run(
        [sys.executable, "-c", textwrap.dedent(code)],
        cwd=cwd, env={**base, **env}, capture_output=True, text=True, timeout=180,
    )


def test_login_router_reads_the_documented_prefixed_secret():
    """改之前只配 SHUNSHI_JWT_SECRET 时，router/auth.py 导入即抛 RuntimeError。"""
    r = _run(
        "import app.router.auth as a; print(a.JWT_SECRET_CURRENT == '%s')" % SECRET,
        {"SHUNSHI_JWT_SECRET": SECRET},
    )
    assert r.returncode == 0, r.stderr[-800:]
    assert r.stdout.strip().endswith("True")


def test_login_tokens_are_accepted_by_core_routes():
    """登录接口签的 access token，核心接口（deps.current_user）要认。"""
    r = _run(
        """
        from app.router.auth import create_access_token
        from app.config import Settings
        from app.security import verify_token
        token = create_access_token("user-42", "u", "u@example.com")
        print(verify_token(Settings(jwt_secret="%s"), token))
        """ % SECRET,
        {"SHUNSHI_JWT_SECRET": SECRET},
    )
    assert r.returncode == 0, r.stderr[-800:]
    assert r.stdout.strip().endswith("user-42")


def test_refresh_tokens_cannot_be_used_as_access_tokens():
    r = _run(
        """
        from fastapi import HTTPException
        from app.router.auth import create_refresh_token
        from app.config import Settings
        from app.security import verify_token
        try:
            verify_token(Settings(jwt_secret="%s"), create_refresh_token("user-42"))
            print("ACCEPTED")
        except HTTPException as e:
            print("REJECTED", e.status_code)
        """ % SECRET,
        {"SHUNSHI_JWT_SECRET": SECRET},
    )
    assert r.returncode == 0, r.stderr[-800:]
    assert r.stdout.strip().endswith("REJECTED 401")


def test_conflicting_secrets_refuse_to_start():
    from app.config import Settings
    from app.main import create_app

    os.environ["JWT_SECRET"] = "d" * 48
    try:
        with pytest.raises(RuntimeError, match="不一致"):
            create_app(Settings(jwt_secret=SECRET, env="test"))
    finally:
        os.environ.pop("JWT_SECRET", None)


# ── 三、知识库目录 ────────────────────────────────────────────

def test_knowledge_dir_can_be_mounted_outside_the_repo(tmp_path):
    src_dir = REPO / "参考文档，知识库"
    if not src_dir.is_dir():
        pytest.skip("仓库根上没有知识库目录")
    mounted = tmp_path / "knowledge"
    mounted.mkdir()
    for f in src_dir.glob("*.md"):
        shutil.copy(f, mounted / f.name)
    r = _run(
        "from app.rag.knowledge_base import load_knowledge_bases, cn_kb, gl_kb; "
        "load_knowledge_bases(force=True); print(len(cn_kb.chunks) > 0, len(gl_kb.chunks) > 0)",
        {"SHUNSHI_KNOWLEDGE_DIR": str(mounted)},
    )
    assert r.returncode == 0, r.stderr[-800:]
    assert r.stdout.strip().endswith("True True")


# ── 四、compose 与路由对得上 ─────────────────────────────────

def _backend_service():
    yaml = pytest.importorskip("yaml")
    compose = yaml.safe_load((REPO / "docker-compose.yml").read_text(encoding="utf-8"))
    return compose["services"]["backend"]


def test_healthcheck_probes_a_route_that_exists():
    from app.main import create_app
    from app.config import Settings

    test = " ".join(_backend_service()["healthcheck"]["test"])
    path = test.split("localhost:4000", 1)[1].split("'", 1)[0]
    from fastapi.testclient import TestClient

    app = create_app(Settings(jwt_secret=SECRET, env="test"))
    assert path != "/api/health", "深度检查在 Redis/模型抖动时 503，不适合做存活探针"
    # 不启动 lifespan（不连库、不加载知识库）：存活探针本来就不该依赖这些。
    assert TestClient(app).get(path).status_code == 200, f"健康检查探的 {path} 不是 200"


def test_compose_uses_psycopg3_and_mounts_the_knowledge_base():
    backend = _backend_service()
    env = backend["environment"]
    assert "+psycopg2" not in env["SHUNSHI_DATABASE_URL"]
    assert env["SHUNSHI_DATABASE_URL"].startswith("postgresql+psycopg://")
    assert env.get("SHUNSHI_KNOWLEDGE_DIR") == "/app/knowledge"
    assert any(str(v).endswith(":/app/knowledge:ro") for v in backend["volumes"])


# ── 五、真实 PostgreSQL（每次运行独立测试数据库）────────────────

def test_boots_on_postgres_with_documented_variables_only(tmp_path, postgres_database_url):
    image = tmp_path / "image"
    shutil.copytree(BACKEND / "app", image / "app", ignore=shutil.ignore_patterns("__pycache__"))
    kb = tmp_path / "knowledge"
    shutil.copytree(REPO / "参考文档，知识库", kb, ignore=shutil.ignore_patterns("*.pdf"))
    r = _run(
        """
        import app.main as m
        from fastapi.testclient import TestClient
        with TestClient(m.app) as c:
            print("BOOT", c.get("/healthz").status_code)
        """,
        {
            "SHUNSHI_ENV": "production",
            "SHUNSHI_DATABASE_URL": postgres_database_url,
            "SHUNSHI_KNOWLEDGE_DIR": str(kb),
            "SHUNSHI_JWT_SECRET": SECRET,
            "SHUNSHI_CORS_ORIGINS": "https://shunshi.example",
            "ADMIN_PASSWORD_HASH": "x",
            "ADMIN_JWT_SECRET": SECRET,
        },
        cwd=image,
    )
    assert "BOOT 200" in r.stdout, (r.stdout + r.stderr)[-1500:]


def test_explicit_product_url_equal_to_core_still_gets_its_own_schema():
    core = "postgresql://u:p@db:5432/shunshi"
    url, schema = resolve_product_database({"SHUNSHI_DATABASE_URL": core, "SHUNSHI_PRODUCT_DATABASE_URL": core})
    assert schema == PRODUCT_SCHEMA
    other = resolve_product_database({"SHUNSHI_DATABASE_URL": core, "SHUNSHI_PRODUCT_DATABASE_URL": "postgresql://u:p@db:5432/product"})
    assert other[1] is None
