"""内容还没审核的模块不能挂在线上。

tcm_medication 给出中成药的剂量、服用时间、配伍禁忌，但 15 种药用的是同一套模板文字、没有来源，
这是用药指导，需要执业药师或中医师审核后才能上线。这里保证：名单里的模块确实没被挂载，
名单的原因写清楚，且新增的「用药」类模块不会绕过名单被自动挂载。
"""
import pkgutil
from importlib import import_module

import pytest

from app.main import PENDING_REVIEW_MODULES, app


def _mounted_endpoints(routes) -> list:
    found = []
    for route in routes:
        nested = getattr(route, "effective_candidates", None)
        if callable(nested):
            found.extend(_mounted_endpoints(nested()))
            continue
        endpoint = getattr(route, "endpoint", None)
        if endpoint is not None:
            found.append(endpoint)
    return found


MOUNTED = _mounted_endpoints(app.routes)


def test_the_scan_is_not_vacuous():
    assert len(MOUNTED) > 300


@pytest.mark.parametrize("module_name", sorted(PENDING_REVIEW_MODULES))
def test_pending_module_is_not_mounted(module_name):
    module = import_module(f"app.router.{module_name}")
    declared = [r for r in module.router.routes if getattr(r, "endpoint", None)]
    assert declared, f"{module_name} 没有声明路由——名单里的模块名可能写错了"
    leaked = sorted({fn.__name__ for fn in MOUNTED if getattr(fn, "__module__", "") == module.__name__})
    assert not leaked, f"未审核的模块被挂载了：{leaked}"


@pytest.mark.parametrize("module_name", sorted(PENDING_REVIEW_MODULES))
def test_pending_reason_is_written_down(module_name):
    assert len(PENDING_REVIEW_MODULES[module_name]) >= 10


def test_medication_paths_are_not_served(anonymous_client):
    for path in ("/api/v1/medication/medicines", "/api/v1/medication/taboos/med_001"):
        assert anonymous_client.get(path).status_code in (401, 404)


def test_no_new_medication_module_slips_in():
    """新增名字带 medication / medicine / prescription 的路由模块，要么明确列入待审核名单，要么在这里登记为已审核。"""
    import app.router as pkg

    reviewed: set = set()
    names = {m.name for m in pkgutil.iter_modules(pkg.__path__)}
    risky = {n for n in names if any(k in n for k in ("medication", "medicine", "prescription", "dosage"))}
    assert risky <= set(PENDING_REVIEW_MODULES) | reviewed, sorted(risky - set(PENDING_REVIEW_MODULES) - reviewed)
