# 国内版网页：emoji 回退字体（2026-11-22）

数据档：**桩**（后端 SHUNSHI_LLM_STUB=1；本页不涉及 AI 回答）。环境：盒子上 Chrome 无头，手机视口 360×740 @2x，网页构建 `APP_VARIANT=web-cn`，不是真机、不是模拟器。

| 图 | 构建 | 节气页 #/solar |
|---|---|---|
| before-main-solar.png | main c4eac2e | 节气 emoji 是方框；浏览器对 `assets/fallback_fonts/notocoloremoji/v32/…woff2` 请求 108 次全是 404，另有 1 次 `roboto/v32/…woff2` 404 |
| after-branch-solar.png | 本分支 | 🌨️ ⛄ 正常显示；只请求 1 次 emoji 分片，200；不再请求 Roboto |

页面上的日期是 2026-11-22（真实日期）。节气页不读测试时钟，这是另一个已知问题，和本改动无关。
