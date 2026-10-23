"""deploy_ecs.sh 的部署后健康检查要探一个真实存在的路由，并认得后端真实返回的状态词。

原来探 ``/health``（后端没有这条路由，只有 ``/healthz`` 与 ``/api/health``），
又按 ``"status":"healthy"`` 判成功（后端返回的是 ``"ok"``）——结果无论部署成不成功，
脚本都打印「部署可能失败」，真出了问题时这句话也就没有任何信息量。
"""

import pathlib
import re

from fastapi.testclient import TestClient

from app.main import create_app

SCRIPT = pathlib.Path(__file__).resolve().parent.parent / "deploy_ecs.sh"


def _probe_path() -> str:
    match = re.search(r'curl[^\n]*"http://\$ECS_HOST:4000(/[^"]*)"', SCRIPT.read_text(encoding="utf-8"))
    assert match, "没找到部署后健康检查的 curl"
    return match.group(1)


def test_probe_path_exists_and_returns_ok(settings):
    path = _probe_path()
    assert path != "/api/health", "深度检查在 Redis/模型抖动时 503，不适合做部署探针"
    body = TestClient(create_app(settings)).get(path)
    assert body.status_code == 200, f"部署脚本探的 {path} 不是 200"
    success_word = re.search(r'grep -q \'"status":"(\w+)"\'', SCRIPT.read_text(encoding="utf-8")).group(1)
    assert body.json()["status"] == success_word, "脚本判成功的状态词与后端返回的不一致"
