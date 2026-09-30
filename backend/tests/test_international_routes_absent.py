"""国际版专用模块的任何一个接口函数都不能挂在国内版上。

以前这里是 test_stripe.py / test_seasons_subscription_truth.py，测的是 Stripe 收银台
与 SEASONS 订阅——这些是国际版的境外支付，国内版按设计不挂载（见 main.INTERNATIONAL_ONLY_MODULES），
两个文件因此全部 404，一直是红的。国内版要保证的是「它们确实不在」，不是「它们能用」。

为什么按「接口函数属于哪个模块」查、而不是按路径：国内版自己也有 ``/ai/chat``、
``/api/v1/seasons/audio/...`` 这些同名路径（routers/chat.py、content.py、seasons.py），
按路径比对会把它们误判成泄漏；按函数所在模块比对才是「国际版那份代码有没有被挂上」。
"""
from importlib import import_module

import pytest

from app.main import INTERNATIONAL_ONLY_MODULES, app


def _mounted_endpoints(routes) -> list:
    """所有已挂载接口的函数。兼容新旧 FastAPI：新版把 include_router 的路由包成嵌套结构。"""
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


def test_the_scan_actually_sees_the_domestic_routes():
    """防止这个检查空转：至少能看到几百个接口，且能看到国内版自己的对话接口。"""
    assert len(MOUNTED) > 300
    assert any(getattr(fn, "__module__", "") == "app.routers.chat" for fn in MOUNTED)


@pytest.mark.parametrize("module_name", sorted(INTERNATIONAL_ONLY_MODULES))
def test_international_only_module_is_not_mounted(module_name):
    module = import_module(f"app.router.{module_name}")
    declared = [r for r in getattr(module, "router").routes if getattr(r, "endpoint", None)]
    assert declared, f"{module_name} 没有声明任何路由——名单里的模块名可能写错了"
    leaked = sorted({fn.__name__ for fn in MOUNTED if getattr(fn, "__module__", "") == module.__name__})
    assert not leaked, f"国内版挂载了国际版接口：{leaked[:5]}"


def test_every_stripe_or_seasons_module_is_on_the_exclusion_list():
    """新加一个 stripe_* / seasons_* 模块却忘了写进名单，它会被自动挂载——在这里拦住。"""
    import pkgutil

    import app.router as product_router_package

    names = {m.name for m in pkgutil.iter_modules(product_router_package.__path__)}
    suspicious = {n for n in names if n.startswith(("stripe", "seasons_"))}
    assert suspicious <= INTERNATIONAL_ONLY_MODULES, sorted(suspicious - INTERNATIONAL_ONLY_MODULES)
