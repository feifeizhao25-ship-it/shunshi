"""资料库「自动更新 + 展示规则」公共内核（四个产品共用同一份逻辑，各产品只写一层很薄的适配）。

只依赖标准库。抓取函数由调用方注入（顺时/新能源/见己用各自 SIL 的 fetch_page 白名单抓取），所以本包本身
不联网、不改任何条目、不让任何内容上线：
  * freshness.check_entries   —— 重新抓取每条的官方来源，比对内容摘要，发现修订/废止/失效链接，写入「状态文件」；
  * freshness.discover        —— 从权威来源的列表页暂存新候选（只有标题/链接/日期，来源与读取范围写明，永远待核实）；
  * display.decide            —— 给用户看的唯一规则：什么算「现行」、什么必须挂提示、什么必须不显示；
  * review.*                  —— 人工审核后写回（必须有审核人姓名，写审计日志）。
"""

from .display import Decision, decide, effective_verified  # noqa: F401
from .freshness import FetchError, check_entries, discover, render_report  # noqa: F401

SCHEMA = 1
