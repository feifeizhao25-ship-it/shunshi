# 顺时国内版 · 原创中文冥想音频库

本目录是国内版冥想音频的**目录与来源记录**。音频文件在 `app/static/audio/meditation/`，接口见 `app/router/meditation_cn.py`
（`GET /api/v1/meditation/library`、`GET /api/v1/meditation/library/{id}`）。

## 内容与来源（每一项都可追溯）

| 部分 | 来源 | 版权 / 授权 |
|---|---|---|
| 脚本（`tracks.json` 里的 `text`） | 本项目原创撰写，不摘抄任何书籍、课程、App 或网络文章 | 归艾瑞见时所有 |
| 人声 | MiniMax 开放平台（国内）语音合成 `speech-2.6-hd`，系统音色「温柔学姐」，语速 0.82 | AI 合成语音，需标注「AI 合成语音」；**商用授权以 MiniMax 开放平台服务协议为准，上线前请业主确认** |
| 配乐 | 由 `scripts/build_meditation_audio.py` 用 numpy 现场合成（正弦/泛音叠加、五声音阶、混响、滤波噪声） | 无任何第三方音乐、采样或素材，归艾瑞见时所有 |

生成时间：2026-10-31。重新生成：`MINIMAX_API_KEY=… python3 scripts/build_meditation_audio.py`（密钥只从环境变量读，脚本不打印、不保存）。

## 合规要点

- 响应带 `ai_generated=true`、`ai_label="AI 合成语音"` 和 `X-AI-Generated: true`，客户端播放页常驻显示「AI 合成语音」。
- 内容仅用于放松与作息参考：不含诊断、疗效、用药或「治疗/改善某种病」的表述；每条详情都带免责声明并保留 12356 心理援助热线。
- 审核状态：`review_status = 待审核`。**还没有经过人工试听与内容审核**，上线前需要业主或指定审核人试听全部 10 条、核对脚本后再把状态改为「已审核」。
- 体积：10 条合计约 8 MB（单声道 32kHz 约 40kbps MP3），不打进客户端安装包；可用环境变量
  `SHUNSHI_MEDITATION_AUDIO_BASE_URL` 指向对象存储 / CDN。

## 目录

`tracks.json` 的 `tracks[]`：`id` / `title` / `subtitle` / `category`（breathing 呼吸、sleep 睡前、solar_term 节气、quick 短时）/
`season` / `term` / `best_time` / `tags` / `text`（含 `<#秒#>` 停顿标记）以及生成后回写的 `duration_seconds` / `size_bytes` / `sha256`。
