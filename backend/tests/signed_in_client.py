"""功能测试用的「已登录」客户端，见 SignedInClient 的说明。"""
import re
import uuid

from fastapi.testclient import TestClient


class SignedInClient(TestClient):
    """给「功能测试」用的客户端：每个请求都带一个真实签发的登录令牌。

    ``app/product_access.py`` 已经要求所有写操作、以及带 ``user_id`` 的读操作必须登录，
    且 ``user_id`` 必须是令牌里的本人。功能测试关心的是「打卡/记录/推荐」本身，
    不该每个用例都重复登录；但也**不能**为此放松门禁。所以这里：

    - 用生产的 ``issue_token`` 签令牌、用真实的用户表行通过「账号存在且未注销」的核验；
    - 令牌里的人取自请求里的 ``user_id``/``userId``（路径、查询串、JSON 体），
      都没有就用这个客户端自己的默认用户；
    - ``admin=True`` 时改带管理员令牌（后台接口 /cms、/admin 等）；
    - 用例自己传了 ``Authorization`` / ``X-Admin-Token`` 就原样使用，不覆盖。

    要测「没登录会怎样」「别人的数据能不能碰」的用例不要标 ``signed_in``，
    它们拿到的仍是匿名的 ``TestClient``。
    """

    _templates_cache = None
    _PATH_USER = re.compile(r"/users?/([^/?#]+)")

    def __init__(self, *args, admin: bool = False, **kwargs):
        super().__init__(*args, **kwargs)
        self.admin_token = self._register_admin_token() if admin else None
        self.default_user_id = f"signed-in-{uuid.uuid4().hex[:12]}"
        self._known_users: set[str] = set()

    @staticmethod
    def _register_admin_token() -> str:
        """与 test_product_access_guard 相同：往管理后台的活动令牌表里登记一个。"""
        from app.router import admin_auth

        token = "adm-" + uuid.uuid4().hex
        admin_auth._active_tokens[token] = {"username": "ops", "expires_at": None}
        return token

    def _path_templates(self):
        """从 OpenAPI 取出所有带 {user_id}/{userId} 的路径模板，转成正则（FastAPI 新版的嵌套路由不好直接遍历）。"""
        if SignedInClient._templates_cache is None:
            templates = []
            for path in self.app.openapi().get("paths", {}):
                for name in ("user_id", "userId"):
                    if "{" + name + "}" in path:
                        regex = re.escape(path)
                        regex = re.sub(r"\\\{(\w+)\\\}", lambda m: f"(?P<{m.group(1)}>[^/]+)", regex)
                        templates.append((re.compile(regex), name))
                        break
            SignedInClient._templates_cache = templates  # 各 app 路由相同，只算一次
        return SignedInClient._templates_cache

    def _acting_user(self, url, kwargs) -> str:
        from urllib.parse import parse_qs, urlsplit

        parts = urlsplit(str(url))
        query = parse_qs(parts.query)
        for source in (kwargs.get("params") or {}, {k: v[0] for k, v in query.items()}):
            for key in ("user_id", "userId"):
                if source.get(key):
                    return str(source[key])
        for key in ("json", "data"):
            body = kwargs.get(key)
            if isinstance(body, dict):
                for name in ("user_id", "userId"):
                    if body.get(name):
                        return str(body[name])
        for pattern, name in self._path_templates():
            found = pattern.fullmatch(parts.path)
            if found:
                return found.group(name)
        match = self._PATH_USER.search(parts.path)
        if match and not match.group(1).startswith("{"):
            return match.group(1)
        return self.default_user_id

    def _ensure_user(self, user_id: str) -> None:
        if user_id in self._known_users:
            return
        from app.database.db import get_db

        db = get_db()
        db.execute(
            "INSERT OR IGNORE INTO users (id, name, password_hash, status) VALUES (?, ?, '', 'active')",
            (user_id, "测试用户"),
        )
        db.commit()
        self._known_users.add(user_id)

    def request(self, method, url, **kwargs):
        headers = dict(kwargs.get("headers") or {})
        if self.admin_token and not {k.lower() for k in headers} & {"authorization", "x-admin-token"}:
            headers["X-Admin-Token"] = self.admin_token
            kwargs["headers"] = headers
            return super().request(method, url, **kwargs)
        lowered = {key.lower() for key in headers}
        if "authorization" not in lowered and "x-admin-token" not in lowered:
            from app.security import issue_token

            user_id = self._acting_user(url, kwargs)
            self._ensure_user(user_id)
            token = issue_token(self.app.state.settings, user_id)["access_token"]
            headers["Authorization"] = f"Bearer {token}"
            kwargs["headers"] = headers
        return super().request(method, url, **kwargs)
