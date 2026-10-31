"""Counts international-edition JSON responses that contain Chinese characters.

The international apps must show English only. Unit tests catch known cases; this counter catches the rest in
production: it reads JSON responses sent to clients the API treats as international (same rule as
``resolve_locale``: X-App-Market, else a non-Chinese Accept-Language) and counts the ones holding CJK characters, per path. It never stores or logs response
content, only the path, the status and how many CJK characters were seen. Streaming and large responses are
passed through untouched."""
from __future__ import annotations

import json
import logging
import re
import threading
from collections import Counter
from typing import Any, Dict

logger = logging.getLogger("language_guard")

CJK = re.compile(r"[\u3400-\u9fff\uf900-\ufaff\u3000-\u303f\uff00-\uffef]")
MAX_BYTES = 1_000_000
_lock = threading.Lock()
_stats: Dict[str, Any] = {"global_json_responses": 0, "with_cjk": 0, "cjk_chars": 0, "by_path": Counter()}
_WARN_EVERY = 25


def reset() -> None:
    with _lock:
        _stats.update(global_json_responses=0, with_cjk=0, cjk_chars=0, by_path=Counter())


def snapshot(top: int = 20) -> Dict[str, Any]:
    with _lock:
        total = _stats["global_json_responses"]
        bad = _stats["with_cjk"]
        return {
            "global_json_responses": total,
            "with_cjk": bad,
            "cjk_chars": _stats["cjk_chars"],
            "rate": round(bad / total, 4) if total else 0.0,
            "top_paths": [{"path": p, "count": n} for p, n in _stats["by_path"].most_common(top)],
        }


def record(path: str, status: int, text: str) -> int:
    """Count one international JSON response. Returns the number of CJK characters found."""
    found = len(CJK.findall(text))
    with _lock:
        _stats["global_json_responses"] += 1
        if found:
            _stats["with_cjk"] += 1
            _stats["cjk_chars"] += found
            _stats["by_path"][path] += 1
            n = _stats["by_path"][path]
        else:
            n = 0
    if found and (n == 1 or n % _WARN_EVERY == 0):
        logger.warning("CJK in international response: path=%s status=%s cjk_chars=%s occurrences=%s", path, status, found, n)
    return found


def _is_global(scope) -> bool:
    from ..locale_context import resolve_locale

    h = {k.decode("latin-1").lower(): v.decode("latin-1") for k, v in scope.get("headers") or []}
    return resolve_locale(h.get("accept-language"), h.get("x-app-market"), h.get("x-region")).is_global


class LanguageGuardMiddleware:
    """Pure ASGI wrapper: forwards every message unchanged and inspects small JSON bodies afterwards."""

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http" or not _is_global(scope):
            return await self.app(scope, receive, send)
        state = {"inspect": False, "status": 0, "buf": bytearray(), "over": False}

        async def wrapped(message):
            if message["type"] == "http.response.start":
                headers = {k.lower(): v for k, v in message.get("headers") or []}
                ctype = headers.get(b"content-type", b"").decode("latin-1").lower()
                length = headers.get(b"content-length")
                state["status"] = message.get("status", 0)
                state["inspect"] = "application/json" in ctype and (length is None or int(length) <= MAX_BYTES)
            elif message["type"] == "http.response.body" and state["inspect"] and not state["over"]:
                state["buf"] += message.get("body", b"")
                if len(state["buf"]) > MAX_BYTES:
                    state["over"] = True
                    state["buf"] = bytearray()
                if not message.get("more_body") and not state["over"]:
                    try:
                        raw = bytes(state["buf"]).decode("utf-8", "replace")
                        try:  # decode \\uXXXX escapes so escaped Chinese is counted too
                            text = json.dumps(json.loads(raw), ensure_ascii=False)
                        except ValueError:
                            text = raw
                        record(scope.get("path", "?"), state["status"], text)
                    except Exception:
                        logger.debug("language guard could not inspect a response", exc_info=True)
            await send(message)

        await self.app(scope, receive, wrapped)
