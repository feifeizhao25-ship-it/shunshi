# Router modules
from . import auth
from . import chat
from . import constitution
from . import content_cms
from . import contents
from . import family
from . import followup
from . import lifecycle
from . import memory
from . import notifications
from . import solar_terms
from . import subscription
from . import today_plan
from . import records
from . import settings


"""
顺时 AI 路由索引
按业务域分组，便于维护和查找
"""

# === 认证与用户 ===
# auth          — 用户注册/登录/Token
# admin_auth    — 管理员认证
# admin         — 管理后台接口
# oauth_wechat  — 微信 OAuth 登录
# users         — 用户信息查询
# onboarding    — 新用户引导流程
# settings      — 用户偏好设置
# user_data     — 用户数据导出

# === 聊天与 AI ===
# chat                  — 主聊天接口（含 RAG 注入）
# seasons_chat          — 季节养生聊天
# core_skills           — AI 核心技能路由
# ai_companion          — AI 陪伴对话
# ai_content            — AI 内容生成
# ai_dream              — AI 解梦
# ai_ingredient_scan    — AI 食材扫描
# ai_wellness_plan      — AI 养生计划
# followup              — 聊天追问
# skills                — AI 技能调用
# multimodal_images     — 多模态图片
# multimodal_speech     — 多模态语音
# multimodal_videos     — 多模态视频

# === 养生内容 ===
# contents          — 通用内容推荐
# constitution      — 体质辨识与评估
# solar_terms       — 节气养生
# solar_wellness    — 节气调理方案
# seasons_home      — 季节首页
# seasons_api       — 季节 API
# seasons_audio     — 季节音频
# cards             — 养生卡片
# recommendations   — 个性化推荐
# wisdom            — 中医智慧
# cultural_stories  — 文化故事
# tcm_culture       — 中医文化
# lunar_calendar    — 农历相关
# shichen           — 时辰养生

# === 脏腑与专项调理 ===
# liver_care        — 养肝
# lung_care         — 养肺
# kidney_care       — 养肾
# stomach_care      — 养胃
# meridian          — 经络
# acupoint          — 穴位
# moxibustion       — 艾灸
# baduanjin         — 八段锦
# herbal_knowledge  — 中草药知识
# tcm_medication    — 中药用药指导
# tcm_food_safety   — 食材安全与相克

# === 饮食与运动 ===
# food_therapy        — 食疗方案
# food_compatibility  — 食物搭配
# recipe              — 菜谱
# tea                 — 茶饮
# calorie_tracker     — 热量追踪
# water_tracker       — 饮水追踪
# sports_recovery     — 运动恢复
# exercise            — 运动指导

# === 健康与生活 ===
# health             — 健康检查
# health_integration — 健康数据集成
# sleep              — 睡眠管理
# emotion            — 情绪管理
# mental_wellness    — 心理健康
# skin_care          — 护肤
# hair_care          — 护发
# eye_care           — 护眼
# allergy_wellness   — 过敏调理
# chronic_care       — 慢性病管理

# === 特定人群 ===
# maternity         — 孕期养生
# postpartum        — 产后调理
# menstrual         — 经期管理
# child_wellness    — 儿童养生
# senior_wellness   — 老年养生
# youth_wellness    — 青少年养生
# couple_wellness   — 夫妻养生
# pet_wellness      — 宠物健康
# workplace_wellness — 职场养生
# regional_wellness  — 地域养生
# timezone_wellness  — 时区养生

# === 支付与订阅 ===
# alipay               — 支付宝支付
# stripe               — Stripe 支付
# subscription         — 订阅管理
# subscription_local   — 本地订阅
# seasons_subscription — 季节订阅
# membership           — 会员系统
# gamification         — 积分游戏化
# coupon               — 优惠券
# gifting              — 礼物/赠送

# === 社区与互动 ===
# community         — 社区互动
# share             — 分享
# family            — 家庭成员
# seasons_family    — 季节家庭
# wechat_social     — 微信社交
# notifications     — 通知
# push              — 推送消息
# push_notifications — 推送通知
# push_intelligence  — 智能推送
# crowd             — 众包数据
# expert_qa         — 专家问答
# feedback          — 用户反馈
# gratitude         — 感恩日记
# journal           — 日记
# diary             — 日记（替代）
# favorites         — 收藏

# === 工具与系统 ===
# health           — 健康检查/心率等
# speech           — 语音合成
# audio_v2         — 音频 V2
# localization     — 国际化/本地化
# weather          — 天气养生 (weather_wellness)
# search           — 搜索
# upload           — 文件上传
# widget           — 桌面小组件
# smart_alarm      — 智能闹钟
# live_class       — 直播课
# first_insight    — 初诊
# data_analytics   — 数据分析
# accessibility    — 无障碍
# theme            — 主题
# banner           — 轮播图
# client_metrics   — 客户端指标
# weight_manage    — 体重管理
# habit_builder    — 习惯养成
# western_bridge   — 中西医桥接
# wellness_myth    — 养生辟谣

# === 管理后台 ===
# admin           — 管理员接口
# admin_auth      — 管理员认证
# content_cms     — 内容管理系统
# audit           — 审计日志
