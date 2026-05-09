# 顺时 ShunShi 前端目录结构

## 项目信息

- **项目名称**：shunshi_app
- **技术栈**：Flutter 3.x + Riverpod + GoRouter
- **目标平台**：iOS + Android
- **最低版本**：iOS 12.0 / Android API 21

---

## 目录结构

```
shunshi_app/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/                          # 核心层
│   │   ├── constants/
│   │   │   ├── app_colors.dart        # Color Tokens
│   │   │   ├── app_typography.dart     # Typography
│   │   │   ├── app_spacing.dart       # Spacing
│   │   │   ├── app_radius.dart        # Radius
│   │   │   └── app_strings.dart       # 静态文案
│   │   │
│   │   ├── theme/
│   │   │   ├── app_theme.dart         # ThemeData
│   │   │   └── theme_extension.dart
│   │   │
│   │   ├── utils/
│   │   │   ├── date_utils.dart
│   │   │   ├── string_utils.dart
│   │   │   └── validators.dart
│   │   │
│   │   ├── extensions/
│   │   │   ├── context_extensions.dart
│   │   │   └── string_extensions.dart
│   │   │
│   │   └── errors/
│   │       ├── exceptions.dart
│   │       └── error_handler.dart
│   │
│   ├── data/                          # 数据层
│   │   ├── repositories/             # Repository 实现
│   │   │   ├── auth_repository.dart
│   │   │   ├── user_repository.dart
│   │   │   ├── chat_repository.dart
│   │   │   ├── habit_repository.dart
│   │   │   ├── family_repository.dart
│   │   │   └── subscription_repository.dart
│   │   │
│   │   ├── datasources/               # 数据源
│   │   │   ├── local/
│   │   │   │   ├── local_storage.dart
│   │   │   │   └── hive_boxes.dart
│   │   │   └── remote/
│   │   │       ├── api_client.dart
│   │   │       ├── api_endpoints.dart
│   │   │       └── interceptors.dart
│   │   │
│   │   ├── models/                   # 数据模型 (Freezed)
│   │   │   ├── user/
│   │   │   │   ├── user_model.dart
│   │   │   │   ├── user_profile.dart
│   │   │   │   └── user_settings.dart
│   │   │   │
│   │   │   ├── chat/
│   │   │   │   ├── message_model.dart
│   │   │   │   ├── conversation_model.dart
│   │   │   │   └── ai_response_model.dart
│   │   │   │
│   │   │   ├── wellness/
│   │   │   │   ├── daily_plan_model.dart
│   │   │   │   ├── habit_model.dart
│   │   │   │   ├── habit_log_model.dart
│   │   │   │   └── wellness_journal_model.dart
│   │   │   │
│   │   │   ├── content/
│   │   │   │   ├── solar_term_model.dart
│   │   │   │   ├── constitution_model.dart
│   │   │   │   ├── food_model.dart
│   │   │   │   ├── tea_model.dart
│   │   │   │   └── acupoint_model.dart
│   │   │   │
│   │   │   ├── family/
│   │   │   │   ├── family_group_model.dart
│   │   │   │   ├── family_member_model.dart
│   │   │   │   └── family_digest_model.dart
│   │   │   │
│   │   │   └── subscription/
│   │   │       ├── subscription_model.dart
│   │   │       └── product_model.dart
│   │   │
│   │   └── mappers/                  # 数据映射
│   │       ├── user_mapper.dart
│   │       └── chat_mapper.dart
│   │
│   ├── domain/                       # 领域层
│   │   ├── entities/                # 实体 (纯 Dart)
│   │   │   ├── user_entity.dart
│   │   │   ├── message_entity.dart
│   │   │   └── ...
│   │   │
│   │   ├── repositories/            # Repository 接口
│   │   │   ├── i_auth_repository.dart
│   │   │   ├── i_user_repository.dart
│   │   │   └── ...
│   │   │
│   │   └── usecases/                # 用例
│   │       ├── auth/
│   │       │   ├── login_usecase.dart
│   │       │   └── register_usecase.dart
│   │       ├── chat/
│   │       │   ├── send_message_usecase.dart
│   │       │   └── get_conversation_usecase.dart
│   │       └── ...
│   │
│   ├── presentation/                 # 展示层
│   │   ├── providers/               # Riverpod Providers
│   │   │   ├── auth_provider.dart
│   │   │   ├── user_provider.dart
│   │   │   ├── chat_provider.dart
│   │   │   ├── home_provider.dart
│   │   │   ├── wellness_provider.dart
│   │   │   ├── family_provider.dart
│   │   │   ├── subscription_provider.dart
│   │   │   └── settings_provider.dart
│   │   │
│   │   ├── widgets/                 # 通用组件
│   │   │   ├── common/
│   │   │   │   ├── app_button.dart
│   │   │   │   ├── app_card.dart
│   │   │   │   ├── app_text_field.dart
│   │   │   │   ├── app_loading.dart
│   │   │   │   ├── app_empty_state.dart
│   │   │   │   ├── app_error_state.dart
│   │   │   │   └── app_network_image.dart
│   │   │   │
│   │   │   ├── chat/
│   │   │   │   ├── chat_bubble.dart
│   │   │   │   ├── ai_response_card.dart
│   │   │   │   ├── quick_reply_chips.dart
│   │   │   │   ├── safe_mode_card.dart
│   │   │   │   └── voice_input_button.dart
│   │   │   │
│   │   │   ├── home/
│   │   │   │   ├── greeting_card.dart
│   │   │   │   ├── solar_term_card.dart
│   │   │   │   ├── today_insight_card.dart
│   │   │   │   ├── three_things_card.dart
│   │   │   │   └── habit_checklist.dart
│   │   │   │
│   │   │   ├── wellness/
│   │   │   │   ├── solar_term_detail_card.dart
│   │   │   │   ├── constitution_result_card.dart
│   │   │   │   ├── food_card.dart
│   │   │   │   ├── tea_card.dart
│   │   │   │   ├── acupoint_card.dart
│   │   │   │   └── habit_item.dart
│   │   │   │
│   │   │   ├── family/
│   │   │   │   ├── family_member_card.dart
│   │   │   │   ├── family_digest_card.dart
│   │   │   │   └── care_send_card.dart
│   │   │   │
│   │   │   └── profile/
│   │   │       ├── subscription_badge.dart
│   │   │       ├── memory_settings_tile.dart
│   │   │       └── notification_settings_tile.dart
│   │   │
│   │   └── pages/                   # 页面
│   │       ├── splash/
│   │       │   └── splash_page.dart
│   │       │
│   │       ├── auth/
│   │       │   ├── login_page.dart
│   │       │   ├── register_page.dart
│   │       │   └── forgot_password_page.dart
│   │       │
│   │       ├── main/
│   │       │   └── main_page.dart    # 5 Tab 入口
│   │       │
│   │       ├── home/
│   │       │   ├── home_page.dart
│   │       │   ├── home_tab.dart
│   │       │   └── widgets/
│   │       │
│   │       ├── chat/
│   │       │   ├── chat_page.dart
│   │       │   ├── chat_list_page.dart
│   │       │   ├── voice_chat_page.dart
│   │       │   └── widgets/
│   │       │
│   │       ├── wellness/
│   │       │   ├── wellness_page.dart
│   │       │   ├── solar_term/
│   │       │   │   ├── solar_term_page.dart
│   │       │   │   ├── solar_term_calendar.dart
│   │       │   │   └── solar_term_detail_page.dart
│   │       │   ├── constitution/
│   │       │   │   ├── constitution_test_page.dart
│   │       │   │   └── constitution_result_page.dart
│   │       │   ├── content/
│   │       │   │   ├── food_list_page.dart
│   │       │   │   ├── tea_list_page.dart
│   │       │   │   └── acupoint_list_page.dart
│   │       │   └── habits/
│   │       │       ├── habits_page.dart
│   │       │       └── habit_detail_page.dart
│   │       │
│   │       ├── family/
│   │       │   ├── family_page.dart
│   │       │   ├── family_group_page.dart
│   │       │   ├── family_invite_page.dart
│   │       │   ├── family_digest_page.dart
│   │       │   └── care_message_page.dart
│   │       │
│   │       └── profile/
│   │           ├── profile_page.dart
│   │           ├── settings/
│   │           │   ├── settings_page.dart
│   │           │   ├── notification_settings_page.dart
│   │           │   ├── memory_settings_page.dart
│   │           │   ├── privacy_settings_page.dart
│   │           │   └── appearance_settings_page.dart
│   │           ├── subscription/
│   │           │   ├── subscription_page.dart
│   │           │   └── subscription_detail_page.dart
│   │           └── auth/
│   │               ├── change_password_page.dart
│   │               └── logout_confirm_page.dart
│   │
│   ├── router/                      # 路由
│   │   ├── app_router.dart
│   │   ├── routes.dart
│   │   └── guards/
│   │       ├── auth_guard.dart
│   │       └── subscription_guard.dart
│   │
│   └── services/                    # 服务
│       ├── notification_service.dart
│       ├── voice_service.dart
│       ├── audio_player_service.dart
│       ├── in_app_purchase_service.dart
│       └── local_notification_service.dart
│
├── assets/
│   ├── images/
│   │   ├── logo.png
│   │   ├── splash/
│   │   └── illustrations/
│   │
│   ├── icons/
│   │   ├── home.svg
│   │   ├── chat.svg
│   │   ├── wellness.svg
│   │   ├── family.svg
│   │   └── profile.svg
│   │
│   ├── animations/
│   │   └── loading.json
│   │
│   └── fonts/
│       └── noto_sans_sc/
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── ios/
├── android/
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 页面清单 (60+)

### 首页模块 (Home)
1. splash_page - 启动页
2. home_page - 首页
3. home_tab - 首页Tab内容
4. greeting_card - 问候卡片
5. solar_term_card - 节气卡片
6. today_insight_card - 今日洞察
7. three_things_card - 今日三件事
8. habit_checklist - 习惯打卡
9. family_entry_card - 家庭入口卡片
10. ai_care_card - AI关怀卡片

### 对话模块 (Chat)
11. chat_page - AI对话页
12. chat_list_page - 对话列表
13. voice_chat_page - 语音对话页
14. chat_bubble - 对话气泡
15. quick_reply_chips - 快捷回复
16. safe_mode_card - 安全模式提示
17. content_card - 内容卡片
18. system_notice_card - 系统通知卡片

### 养生模块 (Wellness)
19. wellness_page - 养生主页
20. solar_term_page - 节气页
21. solar_term_calendar - 节气日历
22. solar_term_detail_page - 节气详情
23. solar_term_share - 节气分享海报
24. constitution_test_page - 体质测试
25. constitution_result_page - 体质结果
26. food_list_page - 食疗列表
27. food_detail_page - 食疗详情
28. tea_list_page - 茶饮列表
29. tea_detail_page - 茶饮详情
30. acupoint_list_page - 穴位列表
31. acupoint_detail_page - 穴位详情
32. habits_page - 习惯页面
33. habit_detail_page - 习惯详情
34. habit_create_page - 创建习惯

### 家庭模块 (Family)
35. family_page - 家庭主页
36. family_group_page - 家庭组页
37. family_invite_page - 邀请家人
38. family_digest_page - 家庭动态
39. care_message_page - 关怀消息
40. family_member_card - 家庭成员卡片
41. family_settings_page - 家庭设置

### 我的模块 (Profile)
42. profile_page - 个人主页
43. settings_page - 设置页
44. notification_settings_page - 通知设置
45. memory_settings_page - 记忆设置
46. privacy_settings_page - 隐私设置
47. appearance_settings_page - 外观设置
48. subscription_page - 订阅页
49. subscription_detail_page - 订阅详情
50. change_password_page - 修改密码
51. logout_confirm_page - 登出确认
52. about_page - 关于顺时
53. help_page - 帮助中心
54. feedback_page - 反馈建议

### 认证模块 (Auth)
55. login_page - 登录页
56. register_page - 注册页
57. forgot_password_page - 忘记密码
58. verify_code_page - 验证码页

### 通用
59. empty_state_page - 空状态页
60. error_state_page - 错误状态页
61. loading_overlay - 加载遮罩
62. bottom_sheet_template - 底部弹窗模板
