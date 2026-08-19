import Foundation
import UIKit

// MARK: - Analytics Service
/// 完整的数据埋点服务 - 支持用户生命周期、AI对话、内容消费、打卡、付费等全维度埋点
final class AnalyticsService {
    static let shared = AnalyticsService()
    
    // MARK: - Properties
    private var sessionStartTime: Date?
    private var currentScreen: String?
    private var isEnabled: Bool = true
    private var userId: String?
    private var userProperties: [String: Any] = [:]
    private var eventQueue: [QueuedEvent] = []
    private let maxQueueSize = 500
    private let batchSendInterval: TimeInterval = 60
    private var batchTimer: Timer?
    
    private struct QueuedEvent {
        let name: String
        let parameters: [String: Any]?
        let timestamp: Date
    }
    
    private init() {
        setupBatchTimer()
        #if DEBUG
        isEnabled = false
        #endif
    }
    
    // MARK: - Configuration
    func configure(enabled: Bool) {
        self.isEnabled = enabled
        Logger.info("Analytics \(enabled ? "enabled" : "disabled")")
    }
    
    // MARK: - Batch Timer
    private func setupBatchTimer() {
        batchTimer = Timer.scheduledTimer(withTimeInterval: batchSendInterval, repeats: true) { [weak self] _ in
            self?.flushEvents()
        }
    }
    
    // MARK: - Session Tracking
    func startSession() {
        sessionStartTime = Date()
        trackEvent(.userLogin)
        Logger.info("Analytics session started")
    }
    
    func endSession() {
        guard let startTime = sessionStartTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        trackEvent(.sessionEnd, parameters: ["duration": duration])
        Logger.info("Analytics session ended. Duration: \(String(format: "%.0f", duration))s")
        sessionStartTime = nil
    }
    
    // MARK: - Screen Tracking
    func trackScreen(_ screenName: String, parameters: [String: Any]? = nil) {
        currentScreen = screenName
        var params = parameters ?? [:]
        params["screen_name"] = screenName
        params["timestamp"] = Date().timeIntervalSince1970
        
        if isEnabled {
            queueEvent(name: "screen_view", parameters: params)
        }
        Logger.debug("Screen: \(screenName)")
    }
    
    // MARK: - Event Tracking
    func trackEvent(_ event: AnalyticsEvent, parameters: [String: Any]? = nil) {
        guard isEnabled else { return }
        
        var params = parameters ?? [:]
        params["event"] = event.rawValue
        params["timestamp"] = Date().timeIntervalSince1970
        if let userId = userId {
            params["user_id"] = userId
        }
        
        queueEvent(name: event.rawValue, parameters: params)
        Logger.debug("Event: \(event.rawValue)")
    }
    
    // MARK: - User Properties
    func setUserId(_ userId: String?) {
        self.userId = userId
        queueEvent(name: "user_id_set", parameters: ["user_id": userId ?? ""])
    }
    
    func setUserProperty(_ name: String, value: Any) {
        userProperties[name] = value
        queueEvent(name: "user_property_set", parameters: ["property_name": name, "property_value": value])
    }
    
    func setUserProfile(_ profile: UserProfile) {
        setUserProperty("age_range", value: profile.ageRange ?? "unknown")
        setUserProperty("gender", value: profile.gender ?? "unknown")
        setUserProperty("constitution", value: profile.constitution ?? "unknown")
        setUserProperty("city", value: profile.city ?? "unknown")
        setUserProperty("is_vip", value: profile.isVIP)
        setUserProperty("member_days", value: profile.memberDays)
    }
    
    // MARK: - Event Queue
    private func queueEvent(name: String, parameters: [String: Any]?) {
        let event = QueuedEvent(name: name, parameters: parameters, timestamp: Date())
        eventQueue.append(event)
        
        if eventQueue.count >= maxQueueSize {
            flushEvents()
        }
    }
    
    private func flushEvents() {
        guard !eventQueue.isEmpty else { return }
        
        let eventsToSend = eventQueue
        eventQueue.removeAll()
        
        // TODO: 发送到实际的后端分析服务
        // 示例：AnalyticsAPI.shared.sendEvents(eventsToSend)
        
        Logger.debug("Flushed \(eventsToSend.count) events to analytics backend")
    }
    
    // MARK: - AI对话专用追踪
    func trackChatEvent(_ subEvent: ChatAnalyticsEvent, sessionId: String, parameters: [String: Any]? = nil) {
        var params = parameters ?? [:]
        params["session_id"] = sessionId
        params["sub_event"] = subEvent.rawValue
        trackEvent(.chatMessageSent, parameters: params)
    }
    
    // MARK: - 内容消费追踪
    func trackContentEvent(_ subEvent: ContentAnalyticsEvent, contentId: String, contentType: String, parameters: [String: Any]? = nil) {
        var params = parameters ?? [:]
        params["content_id"] = contentId
        params["content_type"] = contentType
        params["sub_event"] = subEvent.rawValue
        trackEvent(.contentView, parameters: params)
    }
    
    // MARK: - 打卡追踪
    func trackHabitEvent(_ subEvent: HabitAnalyticsEvent, habitId: String, habitName: String, parameters: [String: Any]? = nil) {
        var params = parameters ?? [:]
        params["habit_id"] = habitId
        params["habit_name"] = habitName
        params["sub_event"] = subEvent.rawValue
        trackEvent(.habitCheckin, parameters: params)
    }
    
    // MARK: - 付费追踪
    func trackPaymentEvent(_ subEvent: PaymentAnalyticsEvent, planId: String, price: Double, parameters: [String: Any]? = nil) {
        var params = parameters ?? [:]
        params["plan_id"] = planId
        params["price"] = price
        params["sub_event"] = subEvent.rawValue
        trackEvent(.paymentSuccess, parameters: params)
    }
}

// MARK: - 核心指标计算
extension AnalyticsService {
    
    /// 计算北极星指标 - 月活跃付费用户数
    func getNorthStarMetric() async -> Int {
        // TODO: 从后端API获取
        return 0
    }
    
    /// 获取日活/月活比
    func getDAU_MAU_Ratio() async -> Double {
        // TODO: 从后端API获取
        return 0.0
    }
    
    /// 获取次日留存率
    func getNextDayRetention() async -> Double {
        // TODO: 从后端API获取
        return 0.0
    }
    
    /// 获取付费转化率
    func getPaymentConversionRate() async -> Double {
        // TODO: 从后端API获取
        return 0.0
    }
}

// MARK: - Analytics Events - 用户生命周期
enum AnalyticsEvent: String {
    // MARK: - 用户生命周期
    case userRegister = "user_register"
    case userLogin = "user_login"
    case userLogout = "user_logout"
    case profileComplete = "profile_complete"
    case onboardingCompleted = "onboarding_completed"
    case constitutionTestStart = "constitution_test_start"
    case constitutionTestComplete = "constitution_test_complete"
    case constitutionTestSkip = "constitution_test_skip"
    
    // MARK: - AI对话
    case chatSessionStarted = "chat_session_started"
    case chatMessageSent = "chat_message_sent"
    case chatMessageReceive = "chat_message_receive"
    case chatSessionEnd = "chat_session_end"
    case chatFeedbackPositive = "chat_feedback_positive"
    case chatFeedbackNegative = "chat_feedback_negative"
    case chatContentClick = "chat_content_click"
    
    // MARK: - 内容消费
    case contentView = "content_view"
    case contentFavorite = "content_favorite"
    case contentShare = "content_share"
    
    // MARK: - 打卡
    case habitAdd = "habit_add"
    case habitRemove = "habit_remove"
    case habitCheckin = "habit_checkin"
    case habitCheckinMiss = "habit_checkin_miss"
    case streakAchieve = "streak_achieve"
    
    // MARK: - 付费
    case paywallView = "paywall_view"
    case subscriptionPageView = "subscription_page_view"
    case paymentStart = "payment_start"
    case paymentSuccess = "payment_success"
    case paymentFail = "payment_fail"
    case subscriptionCancel = "subscription_cancel"
    
    // MARK: - 家庭
    case familyInviteSend = "family_invite_send"
    case familyInviteAccept = "family_invite_accept"
    case familyCareSend = "family_care_send"
    case familyViewStatus = "family_view_status"
    
    // MARK: - 会话
    case sessionStart = "session_start"
    case sessionEnd = "session_end"
    
    // MARK: - App
    case appOpened = "app_opened"
    case pushNotificationReceived = "push_notification_received"
    case pushNotificationClicked = "push_notification_clicked"
}

// MARK: - Chat Analytics Events
enum ChatAnalyticsEvent: String {
    case sessionStart = "chat_session_start"
    case messageSend = "chat_message_send"
    case messageReceive = "chat_message_receive"
    case sessionEnd = "chat_session_end"
    case feedbackPositive = "chat_feedback_positive"
    case feedbackNegative = "chat_feedback_negative"
    case contentClick = "chat_content_click"
    case quickActionClick = "chat_quick_action_click"
    case voiceInputClick = "chat_voice_input_click"
}

// MARK: - Content Analytics Events
enum ContentAnalyticsEvent: String {
    case view = "content_view"
    case scrollDepth = "content_scroll_depth"
    case favorite = "content_favorite"
    case unfavorite = "content_unfavorite"
    case share = "content_share"
    case videoPlay = "content_video_play"
    case videoComplete = "content_video_complete"
    case comment = "content_comment"
}

// MARK: - Habit Analytics Events
enum HabitAnalyticsEvent: String {
    case add = "habit_add"
    case remove = "habit_remove"
    case checkin = "habit_checkin"
    case miss = "habit_checkin_miss"
    case streak = "habit_streak_achieve"
}

// MARK: - Payment Analytics Events
enum PaymentAnalyticsEvent: String {
    case paywallView = "paywall_view"
    case pageView = "payment_page_view"
    case start = "payment_start"
    case success = "payment_success"
    case fail = "payment_fail"
    case cancel = "subscription_cancel"
    case renew = "subscription_renew"
}

// MARK: - User Profile (用于用户画像)
struct UserProfile {
    let userId: String
    let ageRange: String?
    let gender: String?
    let constitution: String?
    let city: String?
    let isVIP: Bool
    let memberDays: Int
    let registerDate: Date
    let lastActiveDate: Date
}

// MARK: - Screen Names
enum ScreenName {
    static let home = "Home"
    static let onboarding = "Onboarding"
    static let constitutionTest = "ConstitutionTest"
    static let constitutionResult = "ConstitutionResult"
    static let consultant = "Consultant"
    static let chatSession = "ChatSession"
    static let wellness = "Wellness"
    static let contentDetail = "ContentDetail"
    static let habit = "Habit"
    static let profile = "Profile"
    static let settings = "Settings"
    static let family = "Family"
    static let subscription = "Subscription"
    static let login = "Login"
    static let register = "Register"
    
    // 内容详情页
    static func contentDetail(_ type: ContentType) -> String {
        return "\(type.rawValue)_Detail"
    }
    
    enum ContentType: String {
        case recipe = "Recipe"
        case tea = "Tea"
        case acupoint = "Acupoint"
        case exercise = "Exercise"
        case solarTerm = "SolarTerm"
        case article = "Article"
    }
}
