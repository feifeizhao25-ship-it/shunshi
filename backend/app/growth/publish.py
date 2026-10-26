"""站外发布的唯一入口。它始终拒绝，确认草稿不会调用它。"""


class ExternalPublishBlocked(RuntimeError):
    """小红书、公众号、视频号、抖音、知乎都不由系统发出。"""


def post_to_platform(*_args, **_kwargs) -> None:
    raise ExternalPublishBlocked("external publishing is human-only")
