import Foundation
import UserNotifications

// MARK: - Proactive Care Service
/// 主动关怀服务 - 「顺时」2.0的核心特色
actor ProactiveCareService {
    static let shared = ProactiveCareService()
    
    // 关怀类型
    enum CareType: String, Codable {
        case morningGreeting     // 早安问候
        case noonCare          // 午间关怀
        case eveningCare       // 晚安叮嘱
        case solarTermGreeting // 节气问候
        case birthdayBlessing  // 生日祝福
        case holidayGreeting   // 节日问候
        case emotionCare       // 情绪关怀
        case weatherCare       // 天气养生提醒
        case habitReminder     // 习惯提醒
        case constitutionCare  // 体质关怀
    }
    
    // 关怀配置
    struct CareConfig {
        let type: CareType
        let title: String
        let content: String
        let icon: String
        let scheduleTime: String?  // HH:mm格式
        let isEnabled: Bool
        let priority: Int
        let category: String
    }
    
    // 关怀历史记录
    struct CareRecord: Identifiable, Codable {
        let id: String
        let type: CareType
        let title: String
        let content: String
        let scheduledTime: Date
        let sentTime: Date?
        let isRead: Bool
        let isClicked: Bool
        let userResponse: String?
    }
    
    // 关怀上下文
    struct CareContext {
        let userProfile: UserProfile
        let constitution: String?
        let currentSolarTerm: String?
        let weatherInfo: WeatherInfo?
        let recentMood: String?
        let lastActiveTime: Date?
        let birthday: Date?
        let preferences: CarePreferences
    }
    
    // 用户偏好
    struct CarePreferences {
        var enableMorningCare: Bool = true
        var enableNoonCare: Bool = true
        var enableEveningCare: Bool = true
        var enableSolarTermCare: Bool = true
        var enableBirthdayCare: Bool = true
        var enableEmotionCare: Bool = true
        var enableWeatherCare: Bool = true
        var morningTime: String = "07:30"
        var noonTime: String = "12:30"
        var eveningTime: String = "21:00"
        var communicationStyle: String = "warm" // warm, casual, professional
        var isQuietHoursEnabled: Bool = true
        var quietStartTime: String = "22:00"
        var quietEndTime: String = "07:00"
    }
    
    // 天气信息
    struct WeatherInfo {
        let temperature: Double
        let condition: String
        let humidity: Double
        let windSpeed: Double
        let isCold: Bool
        let isHot: Bool
        let isRainy: Bool
        let isHumid: Bool
        let airQuality: String
    }
    
    // 用户档案
    struct UserProfile {
        let userId: String
        let nickname: String
        let age: Int?
        let gender: String?
        let city: String
        let timezone: String
        let registrationDate: Date
        let lastLoginDate: Date
    }
    
    private init() {}
    
    // MARK: - 主动关怀调度
    
    /// 启动主动关怀系统
    func startProactiveCare() async {
        // 检查是否需要发送关怀消息
        await checkAndSendCareMessages()
        
        // 设置定时检查
        setupPeriodicCheck()
    }
    
    /// 停止主动关怀系统
    func stopProactiveCare() async {
        // 取消所有定时任务
        // TODO: 实现定时任务取消
    }
    
    /// 检查并发送关怀消息
    private func checkAndSendCareMessages() async {
        let currentTime = Date()
        let userPreferences = getUserPreferences()
        
        // 检查各种关怀类型
        await checkMorningCare(currentTime: currentTime, preferences: userPreferences)
        await checkNoonCare(currentTime: currentTime, preferences: userPreferences)
        await checkEveningCare(currentTime: currentTime, preferences: userPreferences)
        await checkSolarTermCare(preferences: userPreferences)
        await checkBirthdayCare(preferences: userPreferences)
        await checkEmotionCare(preferences: userPreferences)
        await checkWeatherCare(preferences: userPreferences)
    }
    
    // MARK: - 各类关怀检查
    
    /// 检查早安问候
    private func checkMorningCare(currentTime: Date, preferences: CarePreferences) async {
        guard preferences.enableMorningCare else { return }
        guard !isInQuietHours(currentTime, preferences: preferences) else { return }
        
        let morningTime = parseTime(preferences.morningTime)
        let shouldSend = isTimeToSend(currentTime, targetTime: morningTime, tolerance: 30) // 30分钟容错
        
        let hasSent = await hasSentCareToday(.morningGreeting)
        if shouldSend && !hasSent {
            let context = await buildCareContext()
            let careMessage = await generateMorningGreeting(context: context)
            await sendCareMessage(.morningGreeting, message: careMessage)
        }
    }
    
    /// 检查午间关怀
    private func checkNoonCare(currentTime: Date, preferences: CarePreferences) async {
        guard preferences.enableNoonCare else { return }
        guard !isInQuietHours(currentTime, preferences: preferences) else { return }
        
        let noonTime = parseTime(preferences.noonTime)
        let shouldSend = isTimeToSend(currentTime, targetTime: noonTime, tolerance: 30)
        
        let hasSentNoon = await hasSentCareToday(.noonCare)
        if shouldSend && !hasSentNoon {
            let context = await buildCareContext()
            let careMessage = await generateNoonCare(context: context)
            await sendCareMessage(.noonCare, message: careMessage)
        }
    }
    
    /// 检查晚安叮嘱
    private func checkEveningCare(currentTime: Date, preferences: CarePreferences) async {
        guard preferences.enableEveningCare else { return }
        guard !isInQuietHours(currentTime, preferences: preferences) else { return }
        
        let eveningTime = parseTime(preferences.eveningTime)
        let shouldSend = isTimeToSend(currentTime, targetTime: eveningTime, tolerance: 30)
        
        let hasSentEvening = await hasSentCareToday(.eveningCare)
        if shouldSend && !hasSentEvening {
            let context = await buildCareContext()
            let careMessage = await generateEveningCare(context: context)
            await sendCareMessage(.eveningCare, message: careMessage)
        }
    }
    
    /// 检查节气问候
    private func checkSolarTermCare(preferences: CarePreferences) async {
        guard preferences.enableSolarTermCare else { return }

        // 检查是否是新节气的第一天
        let currentSolarTerm = await getCurrentSolarTerm()
        let shouldSend = await isNewSolarTermDay(currentSolarTerm)
        let hasSentSolarTerm = await hasSentSolarTermCareToday(currentSolarTerm)

        if shouldSend && !hasSentSolarTerm {
            let context = await buildCareContext()
            let careMessage = await generateSolarTermGreeting(context: context, solarTerm: currentSolarTerm)
            await sendCareMessage(.solarTermGreeting, message: careMessage)
        }
    }

    /// 检查生日祝福
    private func checkBirthdayCare(preferences: CarePreferences) async {
        guard preferences.enableBirthdayCare else { return }

        let context = await buildCareContext()
        guard let birthday = context.birthday else { return }

        let today = Calendar.current.component(.day, from: Date())
        let birthdayDay = Calendar.current.component(.day, from: birthday)
        let todayMonth = Calendar.current.component(.month, from: Date())
        let birthdayMonth = Calendar.current.component(.month, from: birthday)

        let hasSentBirthday = await hasSentBirthdayCare()
        if today == birthdayDay && todayMonth == birthdayMonth && !hasSentBirthday {
            let careMessage = await generateBirthdayBlessing(context: context)
            await sendCareMessage(.birthdayBlessing, message: careMessage)
        }
    }
    
    /// 检查情绪关怀
    private func checkEmotionCare(preferences: CarePreferences) async {
        guard preferences.enableEmotionCare else { return }

        let context = await buildCareContext()
        guard let recentMood = context.recentMood else { return }

        // 如果检测到负面情绪，及时关怀
        let hasSentEmotion = await hasSentEmotionCareRecently()
        if isNegativeEmotion(recentMood) && !hasSentEmotion {
            let careMessage = await generateEmotionCare(context: context, mood: recentMood)
            await sendCareMessage(.emotionCare, message: careMessage)
        }
    }

    /// 检查天气养生提醒
    private func checkWeatherCare(preferences: CarePreferences) async {
        guard preferences.enableWeatherCare else { return }

        let context = await buildCareContext()
        guard let weatherInfo = context.weatherInfo else { return }

        // 根据天气变化发送相应提醒
        let hasSentCold = await hasSentWeatherCareToday("cold")
        let hasSentHot = await hasSentWeatherCareToday("hot")
        let hasSentRainy = await hasSentWeatherCareToday("rainy")

        if weatherInfo.isCold && !hasSentCold {
            let careMessage = await generateWeatherCare(context: context, weatherType: "cold")
            await sendCareMessage(.weatherCare, message: careMessage)
        } else if weatherInfo.isHot && !hasSentHot {
            let careMessage = await generateWeatherCare(context: context, weatherType: "hot")
            await sendCareMessage(.weatherCare, message: careMessage)
        } else if weatherInfo.isRainy && !hasSentRainy {
            let careMessage = await generateWeatherCare(context: context, weatherType: "rainy")
            await sendCareMessage(.weatherCare, message: careMessage)
        }
    }
    
    // MARK: - 关怀内容生成
    
    /// 生成早安问候
    private func generateMorningGreeting(context: CareContext) async -> CareConfig {
        let currentSolarTerm = context.currentSolarTerm ?? "大雪"
        
        let morningGreetings = [
            "早呀，天有点凉了。要不要喝点热的？不急，慢慢来。",
            "早上好。今天\(currentSolarTerm)，适合温柔地开始一天。",
            "早安。昨晚睡得怎么样？",
            "早。新的一天，不用着急，一步步来就好。"
        ]
        
        let selectedGreeting = morningGreetings.randomElement() ?? morningGreetings[0]
        
        return CareConfig(
            type: .morningGreeting,
            title: "早安",
            content: selectedGreeting,
            icon: "sun.max.fill",
            scheduleTime: context.preferences.morningTime,
            isEnabled: true,
            priority: 1,
            category: "daily_care"
        )
    }
    
    /// 生成午间关怀
    private func generateNoonCare(context: CareContext) async -> CareConfig {
        let noonCares = [
            "这两天你好像有点辛苦。要不要休息一下？不用立刻回我。",
            "中午了，吃点什么好呢？随意就好。",
            "午安。忙的话就先忙，我等你有空再聊。",
            "中午好。记得喝点水，慢慢来。"
        ]
        
        let selectedCare = noonCares.randomElement() ?? noonCares[0]
        
        return CareConfig(
            type: .noonCare,
            title: "午间问候",
            content: selectedCare,
            icon: "sun.horizon.fill",
            scheduleTime: context.preferences.noonTime,
            isEnabled: true,
            priority: 1,
            category: "daily_care"
        )
    }
    
    /// 生成晚安叮嘱
    private func generateEveningCare(context: CareContext) async -> CareConfig {
        let eveningCares = [
            "晚了，今天过得怎么样？不管怎样，早点休息。我明天再来。",
            "晚安。累了就睡吧，别想太多。",
            "夜深了。放下手机，好好睡一觉吧。",
            "晚安。今天辛苦了，明天继续。"
        ]
        
        let selectedCare = eveningCares.randomElement() ?? eveningCares[0]
        
        return CareConfig(
            type: .eveningCare,
            title: "晚安",
            content: selectedCare,
            icon: "moon.stars.fill",
            scheduleTime: context.preferences.eveningTime,
            isEnabled: true,
            priority: 1,
            category: "daily_care"
        )
    }
    
    /// 生成节气问候
    private func generateSolarTermGreeting(context: CareContext, solarTerm: String) async -> CareConfig {
        let solarTermMessages = [
            "\(solarTerm)到了。天气变了，注意保暖。",
            "今天\(solarTerm)。我们一起慢慢适应这个节气吧。",
            "\(solarTerm)了，感觉到了吗？身体会告诉你的。"
        ]
        
        let selectedMessage = solarTermMessages.randomElement() ?? solarTermMessages[0]
        
        return CareConfig(
            type: .solarTermGreeting,
            title: "节气",
            content: selectedMessage,
            icon: "leaf.fill",
            scheduleTime: nil,
            isEnabled: true,
            priority: 2,
            category: "seasonal_care"
        )
    }
    
    /// 生成生日祝福
    private func generateBirthdayBlessing(context: CareContext) async -> CareConfig {
        let birthdayBlessings = [
            "生日快乐。又长大一岁了，希望你一切都好。",
            "今天是你的生日呢。祝你平安健康，慢慢变好。",
            "生日快乐。这一年，我会一直陪着你。"
        ]
        
        let selectedBlessing = birthdayBlessings.randomElement() ?? birthdayBlessings[0]
        
        return CareConfig(
            type: .birthdayBlessing,
            title: "生日",
            content: selectedBlessing,
            icon: "gift.fill",
            scheduleTime: nil,
            isEnabled: true,
            priority: 3,
            category: "special_care"
        )
    }
    
    /// 生成情绪关怀
    private func generateEmotionCare(context: CareContext, mood: String) async -> CareConfig {
        let emotionCares = [
            "嗯，我注意到了。不用说什么，我在这儿。",
            "最近好像有点累？想聊聊吗？不聊也行。",
            "我懂。有时候就是会这样的。"
        ]
        
        let selectedCare = emotionCares.randomElement() ?? emotionCares[0]
        
        return CareConfig(
            type: .emotionCare,
            title: "关心",
            content: selectedCare,
            icon: "heart.fill",
            scheduleTime: nil,
            isEnabled: true,
            priority: 2,
            category: "emotional_care"
        )
    }
    
    /// 生成天气养生提醒
    private func generateWeatherCare(context: CareContext, weatherType: String) async -> CareConfig {
        let weatherMessages: [String: String] = [
            "cold": "今天降温了，记得多穿点。别着凉。",
            "hot": "今天有点热，多喝点水吧。",
            "rainy": "今天下雨，出门记得带伞。"
        ]
        
        let message = weatherMessages[weatherType] ?? "天气还不错，出去走走也好。"
        
        return CareConfig(
            type: .weatherCare,
            title: "天气",
            content: message,
            icon: "cloud.sun.fill",
            scheduleTime: nil,
            isEnabled: true,
            priority: 2,
            category: "weather_care"
        )
    }
    
    // MARK: - 发送关怀消息
    
    /// 发送关怀消息
    private func sendCareMessage(_ type: CareType, message: CareConfig) async {
        // 保存关怀记录
        let record = CareRecord(
            id: UUID().uuidString,
            type: type,
            title: message.title,
            content: message.content,
            scheduledTime: Date(),
            sentTime: Date(),
            isRead: false,
            isClicked: false,
            userResponse: nil
        )
        await saveCareRecord(record)
        
        // 发送推送通知
        await sendNotification(title: message.title, body: message.content, category: message.category)
        
        // 发送到AI对话界面
        await notifyAIAgent(message: message.content, type: type)
    }
    
    /// 发送推送通知
    private func sendNotification(title: String, body: String, category: String) async {
        // 这里实现推送通知逻辑
        // TODO: 集成推送通知服务
    }
    
    /// 通知AI Agent
    private func notifyAIAgent(message: String, type: CareType) async {
        // 获取当前活跃的会话ID (或者创建一个专门的主动关怀会话)
        let sessionId = "current_main_session" // 实际应从 ChatPersistenceService 获取
        
        // 映射 CareType 到 IntentType
        let intent = mapCareTypeToIntent(type)
        
        await AIAgentService.shared.handleProactiveMessage(
            content: message,
            type: intent,
            sessionId: sessionId
        )
    }
    
    private func mapCareTypeToIntent(_ type: CareType) -> AIAgentService.IntentType {
        switch type {
        case .morningGreeting, .noonCare, .eveningCare:
            return .dailyCare
        case .solarTermGreeting:
            return .solarTermAdvice
        case .emotionCare:
            return .emotionalCompanion
        case .weatherCare:
            return .wellnessConsultation // 天气养生归为养生咨询
        case .constitutionCare:
            return .constitutionGuidance
        default:
            return .casualChat
        }
    }
    
    // MARK: - 工具方法
    
    /// 构建关怀上下文
    private func buildCareContext() async -> CareContext {
        // 获取用户信息
        let userProfile = await getUserProfile()
        let constitution = await getUserConstitution()
        let currentSolarTerm = await getCurrentSolarTerm()
        let weatherInfo = await getWeatherInfo()
        let recentMood = await getRecentMood()
        let lastActiveTime = await getLastActiveTime()
        let birthday = await getUserBirthday()
        let preferences = getUserPreferences()
        
        return CareContext(
            userProfile: userProfile,
            constitution: constitution,
            currentSolarTerm: currentSolarTerm,
            weatherInfo: weatherInfo,
            recentMood: recentMood,
            lastActiveTime: lastActiveTime,
            birthday: birthday,
            preferences: preferences
        )
    }
    
    /// 解析时间
    private func parseTime(_ timeString: String) -> Date {
        let components = timeString.components(separatedBy: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return Date()
        }
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        return Calendar.current.date(from: dateComponents) ?? Date()
    }
    
    /// 判断是否到发送时间
    private func isTimeToSend(_ currentTime: Date, targetTime: Date, tolerance: Int) -> Bool {
        let currentMinutes = Calendar.current.component(.hour, from: currentTime) * 60 + Calendar.current.component(.minute, from: currentTime)
        let targetMinutes = Calendar.current.component(.hour, from: targetTime) * 60 + Calendar.current.component(.minute, from: targetTime)
        
        return abs(currentMinutes - targetMinutes) <= tolerance
    }
    
    /// 判断是否在免打扰时间
    private func isInQuietHours(_ currentTime: Date, preferences: CarePreferences) -> Bool {
        guard preferences.isQuietHoursEnabled else { return false }
        
        let currentHour = Calendar.current.component(.hour, from: currentTime)
        let quietStart = Int(preferences.quietStartTime.split(separator: ":")[0]) ?? 22
        let quietEnd = Int(preferences.quietEndTime.split(separator: ":")[0]) ?? 7
        
        if quietStart > quietEnd {
            // 跨越午夜的情况 (如 22:00 - 07:00)
            return currentHour >= quietStart || currentHour < quietEnd
        } else {
            // 普通情况
            return currentHour >= quietStart && currentHour < quietEnd
        }
    }
    
    // MARK: - 数据查询方法（待实现）
    private func getUserPreferences() -> CarePreferences {
        // TODO: 从本地存储获取用户偏好
        return CarePreferences()
    }
    
    private func getUserProfile() async -> UserProfile {
        // TODO: 从数据库获取用户信息
        return UserProfile(
            userId: "user123",
            nickname: "养生达人",
            age: 30,
            gender: "女",
            city: "北京",
            timezone: "Asia/Shanghai",
            registrationDate: Date(),
            lastLoginDate: Date()
        )
    }
    
    private func getUserConstitution() async -> String? {
        // TODO: 从数据库获取用户体质信息
        return "气虚质"
    }
    
    private func getCurrentSolarTerm() async -> String {
        // TODO: 获取当前节气
        return "大雪"
    }
    
    private func getWeatherInfo() async -> WeatherInfo? {
        // TODO: 获取天气信息
        return WeatherInfo(
            temperature: 15.0,
            condition: "多云",
            humidity: 60.0,
            windSpeed: 3.0,
            isCold: false,
            isHot: false,
            isRainy: false,
            isHumid: false,
            airQuality: "良"
        )
    }
    
    private func getRecentMood() async -> String? {
        // TODO: 获取用户最近情绪状态
        return nil
    }
    
    private func getLastActiveTime() async -> Date? {
        // TODO: 获取用户最后活跃时间
        return Date()
    }
    
    private func getUserBirthday() async -> Date? {
        // TODO: 获取用户生日
        return nil
    }
    
    // 检查方法
    private func hasSentCareToday(_ type: CareType) async -> Bool {
        // TODO: 检查今天是否已发送过该类型关怀
        return false
    }
    
    private func hasSentSolarTermCareToday(_ solarTerm: String) async -> Bool {
        // TODO: 检查今天是否已发送过该节气关怀
        return false
    }
    
    private func hasSentBirthdayCare() async -> Bool {
        // TODO: 检查是否已发送生日祝福
        return false
    }
    
    private func hasSentEmotionCareRecently() async -> Bool {
        // TODO: 检查最近是否已发送情绪关怀
        return false
    }
    
    private func hasSentWeatherCareToday(_ weatherType: String) async -> Bool {
        // TODO: 检查今天是否已发送过该天气关怀
        return false
    }
    
    private func isNewSolarTermDay(_ solarTerm: String) async -> Bool {
        // TODO: 检查是否是新节气第一天
        return false
    }
    
    private func isNegativeEmotion(_ mood: String) -> Bool {
        return ["难过", "沮丧", "焦虑", "烦躁", "疲惫"].contains(mood)
    }
    
    // 保存方法
    private func saveCareRecord(_ record: CareRecord) async {
        // TODO: 保存关怀记录到数据库
    }
    
    // 定时检查设置
    private func setupPeriodicCheck() {
        // TODO: 设置定时检查任务，每30分钟检查一次
    }
}
