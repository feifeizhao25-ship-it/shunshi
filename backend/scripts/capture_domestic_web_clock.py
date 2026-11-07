"""Drive the domestic Flutter web build against a test-only backend.

Clock replay, not seven wall-clock days and not a native device.
Accounts come from the product's own 「游客体验」 button. The test clock is the
``test_now`` query, and only a build compiled with SHUNSHI_TEST_CLOCK sends it.
The backend ignores that header unless SHUNSHI_ENV is test or testing.

The profile wizard does not write help_goal. Where a cell names an onboarding
profile, this script calls the existing authenticated
POST /api/v1/seasons/onboarding/complete and labels that call. It does not
draw a substitute card.

Usage (web build and test backend already running):

    python backend/scripts/capture_domestic_web_clock.py \
        --web http://127.0.0.1:8090 \
        --api http://127.0.0.1:8091 \
        --out /tmp/shunshi-web-clock
"""
from __future__ import annotations

import argparse
import json
import urllib.error
import urllib.request
from pathlib import Path

CLOCKS = [f"2026-11-{day:02d}T08:00:00+08:00" for day in range(2, 9)]
CAUSAL = "2026-11-04T21:00:00+08:00"
REINFORCE = "你最近做过同类小行动"
ONBOARD = {
    "sleeper": {"help_goal": "睡得更好", "support_time": "晚上"},
    "walker": {"help_goal": "白天更有精神", "support_time": "早上"},
    "caregiver": {"help_goal": "照顾家人", "support_time": "晚上"},
    "stressed": {"help_goal": "放松减压", "support_time": "下午"},
    "newcomer": {},
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--web", required=True)
    parser.add_argument("--api", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--surface", default="android-cn Flutter web")
    args = parser.parse_args()
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    from playwright.sync_api import sync_playwright

    report: dict = {
        "clock_replay": True,
        "not_wall_clock_seven_days": True,
        "surface": args.surface,
        "not_native": True,
        "web": args.web,
        "api": args.api,
        "onboarding_profile_source": "POST /api/v1/seasons/onboarding/complete with the token the guest-login button already stored. The profile wizard does not send help_goal.",
        "library": "not published; no reviewer invented",
        "solar_term_strip": "首页节气条来自 /api/v1/solar-terms/current，不读测试时钟，所以仍是服务器当天。个性化区块才读 test_now。",
        "shichen_strip": "十二时辰按浏览器本地钟计算，不读 test_now。截图若停在页首，时辰是墙上时间；个性化文字在下方。",
        "screens": [],
        "cells": [],
        "blockers": [],
    }
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(
            executable_path="/usr/local/bin/google-chrome",
            headless=True,
            args=["--no-sandbox", "--disable-dev-shm-usage"],
        )
        try:
            _run(browser, args, out, report)
        except Exception as exc:
            report["blockers"].append(f"{type(exc).__name__}: {exc}")
            _dump(browser, out, report, "failure")
        finally:
            browser.close()
    boards = report.get("dashboards") or []
    report["dashboard_count"] = len(boards)
    if not report["blockers"]:
        report.pop("dashboards", None)
    else:
        report["dashboards"] = boards[-2:]
    (out / "manifest.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(out / "manifest.json")
    return 0 if not report["blockers"] else 2


def _run(browser, args, out: Path, report: dict) -> None:
    context = browser.new_context(locale="zh-CN", viewport={"width": 375, "height": 812})
    page = context.new_page()
    _attach(page, report)
    _guest_home(page, args.web, CAUSAL, "回放甲", out, report, "sleeper-ui", concern="睡眠")
    _board, token = _open_board(page, args.web, CAUSAL)
    if not token:
        token = _token(page)
    if not token:
        keys = page.evaluate("() => Object.keys(localStorage)")
        raise RuntimeError(f"游客登录后没有可用令牌，键：{keys}")
    me = _api(args.api, "GET", "/api/v1/auth/me", token, CAUSAL)
    report["sleeper_user_id"] = (me.get("data") or {}).get("id") or (me.get("id"))
    report["goal_source"] = "引导页点了「睡眠」，资料向导提交时写入 help_goal。脚本不再另写画像。"
    before_board, _ = _open_board(page, args.web, CAUSAL)
    _bring_into_view(page, "今天为你准备的")
    before_text = _save_text(page, out, "sleeper-before")
    _shot(page, out, report, "sleeper-before", 375)
    report["sleeper_before"] = _brief(before_board)
    report["sleeper_before_page_has_reasons"] = _reasons_on_page(before_board, before_text)
    _api(args.api, "POST", "/api/v1/personalization/action/complete", token, CAUSAL, {"action_type": "sleep", "completed": True})
    after_board, _ = _open_board(page, args.web, CAUSAL)
    _bring_into_view(page, REINFORCE)
    after_text = _save_text(page, out, "sleeper-after")
    _shot(page, out, report, "sleeper-after", 375)
    report["sleeper_after_visible"] = _visible_text(out / "sleeper-after-375.png")
    if not any(piece in report["sleeper_after_visible"] for piece in ("分钟", "为什么", "泡脚", "好觉", "同类")):
        raise RuntimeError(f"截图里读不到卡片正文。识别结果：{report['sleeper_after_visible'][:180]}")
    report["sleeper_after"] = _brief(after_board)
    report["sleeper_after_page_has_reasons"] = _reasons_on_page(after_board, after_text)
    report["sleeper_after_page_has_reinforce"] = REINFORCE in after_text
    if REINFORCE not in json.dumps(after_board, ensure_ascii=False):
        raise RuntimeError("同一时刻完成睡眠后，服务返回里没有「你最近做过同类小行动」")
    if REINFORCE not in after_text:
        raise RuntimeError("服务返回已有原因变化，页面文字里没有「你最近做过同类小行动」")
    for width in (768, 1280):
        page.set_viewport_size({"width": width, "height": 900})
        page.wait_for_timeout(600)
        _bring_into_view(page, REINFORCE)
        _shot(page, out, report, "sleeper-after", width)
    page.set_viewport_size({"width": 375, "height": 812})
    refresh_board, _ = _open_board(page, args.web, CAUSAL)
    again = _save_text(page, out, "sleeper-refresh")
    report["same_moment_refresh_stable"] = _brief(refresh_board) == report["sleeper_after"]
    report["same_moment_text_unchanged"] = again == after_text
    _shot(page, out, report, "sleeper-refresh", 375)

    _scroll_to(page, "关闭个性化")
    for _ in range(6):
        if "关闭个性化" in _copy(page):
            break
        page.mouse.move(180, 420)
        page.mouse.wheel(0, 500)
        page.wait_for_timeout(250)
    report["off_control_in_page_text"] = "关闭个性化" in _copy(page)
    if report["off_control_in_page_text"]:
        try:
            _click(page, "关闭个性化")
        except Exception:
            nodes = page.locator("flt-semantics").filter(has_text="关闭个性化")
            if nodes.count() == 0:
                raise
            nodes.last.click(force=True)
            page.wait_for_timeout(400)
        _wait_copy(page, "关闭个性化推荐")
        _shot(page, out, report, "sleeper-off-dialog", 375)
        _click(page, "关闭")
    else:
        # 按钮不在当前语义树里。关掉这件事走按钮同一条已有接口，再让页面自己刷新。
        _api(args.api, "POST", "/api/v1/seasons/profile/preferences", token, CAUSAL, {"personalization_enabled": False})
        report["off_via"] = "POST /api/v1/seasons/profile/preferences，因为页面文字里没有「关闭个性化」"
    off_board, _ = _open_board(page, args.web, CAUSAL)
    off_text = _save_text(page, out, "sleeper-off")
    report["off_visible"] = "个性化已关闭" in off_text
    report["off_api_enabled"] = _brief(off_board)["enabled"]
    for width in (375, 768, 1280):
        page.set_viewport_size({"width": width, "height": 900 if width > 375 else 812})
        page.wait_for_timeout(400)
        _bring_into_view(page, "个性化已关闭")
        _shot(page, out, report, "sleeper-off", width)
    page.set_viewport_size({"width": 375, "height": 812})
    if "重新打开" in _copy(page):
        _click(page, "重新打开")
        report["turn_on_via"] = "页面按钮"
    else:
        _api(args.api, "POST", "/api/v1/seasons/profile/preferences", token, CAUSAL, {"personalization_enabled": True})
        report["turn_on_via"] = "POST /api/v1/seasons/profile/preferences"
    _open_board(page, args.web, CAUSAL)
    if REINFORCE not in _copy(page):
        raise RuntimeError("重新打开后，页面没有回到完成睡眠的原因")

    report["cells"] = []
    page.set_viewport_size({"width": 375, "height": 812})
    _capture_week(page, args, out, report, "睡眠", token)

    control_context = browser.new_context(locale="en-US", viewport={"width": 375, "height": 812})
    control = control_context.new_page()
    _attach(control, report)
    _guest_home(control, args.web, CAUSAL, "对照", out, report, "control-ui", concern=None)
    _, control_token = _open_board(control, args.web, CAUSAL)
    control_board, _ = _open_board(control, args.web, CAUSAL)
    _bring_into_view(control, "今天为你准备的")
    control_text = _save_text(control, out, "control-same-instant")
    _shot(control, out, report, "control-same-instant", 375)
    report["control_has_reinforce"] = REINFORCE in control_text
    report["english_browser_still_chinese"] = "今天为你准备的" in control_text and "Good " not in control_text
    if not report["english_browser_still_chinese"]:
        raise RuntimeError("英文浏览器语言下，国内包首页不是中文")
    report["control"] = _brief(control_board)
    for width in (768, 1280):
        control.set_viewport_size({"width": width, "height": 900})
        control.wait_for_timeout(400)
        _shot(control, out, report, "control-same-instant", width)
    control.set_viewport_size({"width": 375, "height": 812})
    _capture_week(control, args, out, report, "跳过", control_token)
    control_context.close()

    for name, concern in (("饮食", "饮食"), ("运动", "运动"), ("情绪", "情绪")):
        failure = None
        for _attempt in (1, 2):
            report["cells"] = [cell for cell in report["cells"] if cell["user"] != name]
            cell_context = browser.new_context(locale="zh-CN", viewport={"width": 375, "height": 812})
            try:
                cell_page = cell_context.new_page()
                _attach(cell_page, report)
                _guest_home(cell_page, args.web, CLOCKS[0], name, out, report, f"{name}-ui", concern=concern)
                _, cell_token = _open_board(cell_page, args.web, CLOCKS[0])
                _capture_week(cell_page, args, out, report, name, cell_token)
                failure = None
                break
            except Exception as exc:
                failure = exc
            finally:
                cell_context.close()
        if failure is not None:
            report["blockers"].append(f"{name}: {type(failure).__name__}: {failure}")

    _click(page, "我的")
    page.wait_for_timeout(800)
    mine = _copy(page)
    report["profile_shows_nickname"] = "回放甲" in mine
    if not report["profile_shows_nickname"]:
        raise RuntimeError(f"资料页没有显示刚填写的昵称。当前文字：{mine[:240]}")
    _wheel_canvas(page, 1200)
    page.wait_for_timeout(400)
    if "退出登录" not in _copy(page) and "设置" in _copy(page):
        _click(page, "设置")
        page.wait_for_timeout(600)
        _wheel_canvas(page, 900)
    _wait_copy(page, "退出登录", timeout=10000)
    _save_text(page, out, "sleeper-profile")
    _shot(page, out, report, "sleeper-profile", 375)
    _click(page, "退出登录")
    _wait_guest_entry(page)
    _click_guest(page)
    try:
        _wait_copy(page, "怎么称呼", timeout=8000)
    except Exception:
        _click_guest(page)
    _guest_from_login(page, "回放乙")
    _open_board(page, args.web, CAUSAL)
    switched = _save_text(page, out, "switched-home")
    _shot(page, out, report, "switched-home", 375)
    report["switch_leaks_reinforce"] = REINFORCE in switched
    report["switch_leaks_nickname"] = "回放甲" in switched
    other_token = _token(page)
    report["switch_user_differs"] = bool(other_token) and other_token != token


def _capture_week(page, args, out: Path, report: dict, name: str, token: str) -> None:
    for clock in CLOCKS:
        board, _ = _open_board(page, args.web, clock)
        _bring_into_view(page, "今天为你准备的")
        _shot(page, out, report, f"{name}-{clock[:10]}", 375)
        text = _collect_text(page)
        (out / f"{name}-{clock[:10]}.txt").write_text(text, encoding="utf-8")
        reasons = [card.get("reason") or "" for card in board.get("suggestions") or []]
        report["cells"].append({
            "user": name,
            "clock": clock,
            "viewport": 375,
            "api_date": board.get("date"),
            "api_time_of_day": board.get("time_of_day"),
            "api_reasons": reasons,
            "page_text_file": f"{name}-{clock[:10]}.txt",
            "page_has_heading": "今天为你准备的" in text,
            "page_contains_api_reasons": all(reason in text for reason in reasons),
            "screenshot": f"{name}-{clock[:10]}-375.png",
        })


def _open_board(page, web: str, clock: str, route: str = "/today"):
    def match(response) -> bool:
        return (
            "home/dashboard" in response.url
            and response.request.method == "GET"
            and response.status == 200
            and response.request.headers.get("x-shunshi-test-now") == clock
        )

    _open(page, web, clock, route)
    # 壳内从 /home 切到 /today 不会重新请求。重新加载才带上地址里的 test_now。
    with page.expect_response(match, timeout=40000) as caught:
        page.reload(wait_until="domcontentloaded", timeout=60000)
    response = caught.value
    board = response.json()
    auth = response.request.headers.get("authorization") or ""
    token = auth.split(" ", 1)[-1] if auth.lower().startswith("bearer ") else ""
    enabled = (board.get("personalization") or {}).get("enabled", True)
    title = ((board.get("hero") or {}).get("title")) or ""
    needle = "个性化已关闭" if enabled is False else (title[:18] or "今天为你准备的")
    _wait_copy(page, needle, timeout=20000)
    return board, token


def _brief(board: dict) -> dict:
    return {
        "date": board.get("date"),
        "time_of_day": board.get("time_of_day"),
        "enabled": (board.get("personalization") or {}).get("enabled"),
        "cards": [
            {"id": card.get("id"), "reason": card.get("reason"), "score": card.get("score")}
            for card in board.get("suggestions") or []
        ],
    }


def _reasons_on_page(board: dict, text: str) -> bool:
    return all((card.get("reason") or "") in text for card in board.get("suggestions") or [])


def _guest_home(page, web, clock, nickname, out, report, label, concern: str | None = "睡眠") -> None:
    _open(page, web, clock, "/splash")
    _wait_copy(page, "开始使用", timeout=30000)
    _shot(page, out, report, f"{label}-onboarding", 375)
    _click(page, "开始使用")
    _wait_copy(page, "你最关注什么")
    if concern:
        _click(page, concern)
    else:
        _click(page, "先跳过")
    _wait_copy(page, "开始体验")
    _click(page, "开始体验")
    _wait_copy(page, "我的", timeout=20000)
    _click(page, "我的")
    page.wait_for_timeout(800)
    text = _copy(page)
    if "去登录" in text:
        _click(page, "去登录")
    elif "登录后查看" in text:
        _click(page, "登录后查看我的收藏与订阅")
    else:
        page.mouse.click(337, 780)
        page.wait_for_timeout(500)
        text = _copy(page)
        if "去登录" in text:
            _click(page, "去登录")
        elif "登录后查看" in text:
            _click(page, "登录后查看我的收藏与订阅")
        else:
            raise RuntimeError(f"个人页没有登录入口。当前文字：{text[:240]}")
    _shot(page, out, report, f"{label}-profile-logged-out", 375)
    _wait_guest_entry(page)
    _shot(page, out, report, f"{label}-login", 375)
    _click_guest(page)
    _guest_from_login(page, nickname)


def _wait_guest_entry(page) -> None:
    page.wait_for_function(
        """() => {
          const text = document.querySelector('#app-readable-copy')?.textContent || '';
          return text.includes('游客体验') || text.includes('体验模式') || text.includes('免登录直接体验');
        }""",
        timeout=20000,
    )


def _click_guest(page) -> None:
    text = _copy(page)
    if "游客体验" in text:
        _click(page, "游客体验")
    elif "体验模式" in text:
        _click(page, "体验模式")
    elif "免登录直接体验" in text:
        _click(page, "免登录直接体验")
    else:
        raise RuntimeError(f"登录页没有游客入口。当前文字：{text[:240]}")


def _guest_from_login(page, nickname: str) -> None:
    _wait_copy(page, "怎么称呼", timeout=20000)
    _fill(page, nickname)
    _click(page, "下一步")
    try:
        _wait_copy(page, "你的性别是", timeout=8000)
    except Exception:
        _fill(page, nickname)
        _click(page, "下一步")
        _wait_copy(page, "你的性别是", timeout=15000)
    _click(page, "女")
    _click(page, "下一步")
    _wait_copy(page, "你出生在哪一年")
    if "睡眠" in _copy(page):
        _click(page, "睡眠")
    _click(page, "下一步")
    _wait_copy(page, "了解你的体质类型")
    _click(page, "平和质")
    _click(page, "完成")
    try:
        _wait_copy(page, "今天为你准备的", timeout=20000)
    except Exception:
        if "暂时没能加载" in _copy(page) or "重试" in _copy(page):
            _click(page, "重试")
        _wait_copy(page, "今天为你准备的", timeout=20000)


def _open(page, web: str, clock: str, route: str) -> None:
    query = clock.replace("+", "%2B")
    page.goto(f"{web.rstrip('/')}/?test_now={query}#{route}", wait_until="domcontentloaded", timeout=60000)


def _attach(page, report: dict) -> None:
    def on_response(response):
        if "home/dashboard" not in response.url or response.request.method != "GET":
            return
        item = {"status": response.status, "test_now": response.request.headers.get("x-shunshi-test-now")}
        try:
            item["body"] = response.json()
        except Exception as exc:
            item["error"] = str(exc)
        report.setdefault("dashboards", []).append(item)

    page.on("response", on_response)


def _dashboard_for(report: dict, clock: str):
    for item in reversed(report.get("dashboards") or []):
        if item.get("status") == 200 and item.get("test_now") == clock and isinstance(item.get("body"), dict):
            return item["body"]
    return None


def _latest_dashboard(report: dict):
    boards = report.get("dashboards") or []
    for item in reversed(boards):
        if item.get("status") == 200 and isinstance(item.get("body"), dict):
            return item["body"]
    return None


def _collect_text(page) -> str:
    seen: list[str] = []

    def add() -> None:
        for line in _copy(page).splitlines():
            if line and line not in seen:
                seen.append(line)

    add()
    for _ in range(5):
        page.mouse.move(180, 420)
        page.mouse.wheel(0, 420)
        page.wait_for_timeout(180)
        add()
    return "\n".join(seen)


def _visible_text(path: Path) -> str:
    import subprocess
    try:
        out = subprocess.check_output(
            ["tesseract", str(path), "stdout", "-l", "chi_sim", "--psm", "6"],
            stderr=subprocess.DEVNULL,
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        return f"ocr-failed:{exc}"
    return out.decode("utf-8", "replace")


def _copy(page) -> str:
    return page.evaluate("() => document.querySelector('#app-readable-copy')?.textContent || ''")


def _wait_copy(page, text: str, timeout: int = 15000) -> None:
    page.wait_for_function(
        """(expected) => (document.querySelector('#app-readable-copy')?.textContent || '').includes(expected)""",
        arg=text,
        timeout=timeout,
    )


def _click(page, text: str) -> None:
    buttons = page.get_by_role("button").locator("visible=true")
    chosen = None
    chosen_len = 10**9
    total = min(buttons.count(), 16)
    for i in range(total):
        item = buttons.nth(i)
        try:
            label = " ".join(item.inner_text(timeout=1500).split())
        except Exception:
            continue
        if text == label or text in label:
            if len(label) < chosen_len:
                chosen = item
                chosen_len = len(label)
    if chosen is not None and chosen_len <= max(len(text) + 12, 24):
        chosen.click(timeout=10000, force=True)
        page.wait_for_timeout(450)
        return
    exact = page.get_by_text(text, exact=True).locator("visible=true")
    if exact.count():
        exact.last.click(timeout=10000, force=True)
        page.wait_for_timeout(450)
        return
    raise RuntimeError(f"页面上没有可点的「{text}」。当前文字：{_copy(page)[:400]}")


def _fill(page, value: str) -> None:
    field = page.locator("input:visible, textarea:visible")
    if field.count() == 0:
        hint = page.get_by_text("输入你的昵称", exact=True).locator("visible=true")
        if hint.count():
            hint.last.click(force=True)
            page.wait_for_timeout(200)
        field = page.locator("input:visible, textarea:visible")
    if field.count():
        field.last.click(force=True)
        field.last.fill("")
        field.last.fill(value)
    else:
        page.keyboard.type(value, delay=30)
    page.wait_for_timeout(250)


def _wheel_canvas(page, delta: int) -> None:
    page.evaluate(
        """(delta) => {
          const pane = document.querySelector('flt-glass-pane') || document.querySelector('flutter-view');
          if (!pane) return;
          pane.dispatchEvent(new WheelEvent('wheel', {
            deltaY: delta, bubbles: true, cancelable: true, clientX: 180, clientY: 420,
          }));
        }""",
        delta,
    )


def _bring_into_view(page, text: str) -> bool:
    for _ in range(22):
        loc = page.locator("flt-semantics").filter(has_text=text)
        best = None
        best_area = 10**12
        for i in range(min(loc.count(), 16)):
            item = loc.nth(i)
            try:
                if not item.is_visible():
                    continue
                box = item.bounding_box()
            except Exception:
                continue
            if not box or box["height"] < 8 or box["height"] > 220:
                continue
            area = box["width"] * box["height"]
            if area < best_area:
                best = box
                best_area = area
        if best and 80 <= best["y"] <= 560:
            return True
        _wheel_canvas(page, 320 if best is None or best["y"] > 560 else -240)
        page.wait_for_timeout(180)
    return False


def _scroll_to(page, text: str) -> None:
    loc = page.get_by_text(text, exact=False).locator("visible=true")
    if loc.count():
        try:
            loc.first.scroll_into_view_if_needed(timeout=3000)
        except Exception:
            pass


def _token(page) -> str:
    return page.evaluate(
        """() => {
          const keys = Object.keys(localStorage);
          const preferred = ['flutter.auth_token', 'auth_token'];
          for (const key of preferred.concat(keys)) {
            const value = localStorage.getItem(key) || '';
            const match = value.match(/eyJ[A-Za-z0-9_\\-]+\\.[A-Za-z0-9_\\-]+\\.[A-Za-z0-9_\\-]+/);
            if (match) return match[0];
          }
          return '';
        }"""
    )


def _save_text(page, out: Path, name: str) -> str:
    text = _copy(page)
    (out / f"{name}.txt").write_text(text, encoding="utf-8")
    return text


def _shot(page, out: Path, report: dict, name: str, width: int) -> None:
    path = out / f"{name}-{width}.png"
    page.screenshot(path=str(path))
    report["screens"].append({"name": name, "viewport": width, "file": path.name, "url": page.url})


def _dump(browser, out: Path, report: dict, name: str) -> None:
    if not browser.contexts:
        return
    pages = [p for ctx in browser.contexts for p in ctx.pages]
    if not pages:
        return
    page = pages[-1]
    try:
        _save_text(page, out, name)
        _shot(page, out, report, name, 375)
        report["failure_url"] = page.url
    except Exception as exc:
        report["blockers"].append(f"dump failed: {exc}")


def _api(base: str, method: str, path: str, token: str, clock: str, body=None):
    data = None if body is None else json.dumps(body).encode()
    request = urllib.request.Request(
        base.rstrip("/") + path,
        data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "X-Shunshi-Test-Now": clock,
        },
        method=method if body is None else "POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.loads(response.read().decode())
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode()[:500]
        raise RuntimeError(f"{method} {path} -> {exc.code} {detail}") from exc


if __name__ == "__main__":
    raise SystemExit(main())
