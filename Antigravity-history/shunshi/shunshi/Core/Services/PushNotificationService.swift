import Foundation
import UIKit
import UserNotifications

// MARK: - Push Notification Service
/// 推送服务 - 主：极光推送 备：友盟 + 本地通知
@MainActor
final class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()
    
    @Published private(set) var isRegistered = false
    @Published private(set) var deviceToken: String?
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    // MARK: - Request Permission
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                await registerForRemotePush()
            }
            return granted
        } catch {
            Logger.error("Push permission request failed: \(error)")
            return false
        }
    }
    
    // MARK: - Register for Remote Push
    private func registerForRemotePush() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - Handle Device Token
    func handleDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = tokenString
        isRegistered = true
        
        // 注册到极光推送
        if !ThirdPartyAPI.Push.JPush.appKey.isEmpty {
            registerWithJPush(token: tokenString)
        }
        
        // 备用：注册到友盟
        if !ThirdPartyAPI.Push.UMeng.appKey.isEmpty {
            registerWithUMeng(token: tokenString)
        }
        
        Logger.info("Device token registered: \(tokenString.prefix(20))...")
    }
    
    // MARK: - Schedule Local Notification
    func scheduleLocalNotification(
        id: String,
        title: String,
        body: String,
        date: Date,
        repeats: Bool = false,
        sound: UNNotificationSound = .default
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try await notificationCenter.add(request)
        
        Logger.info("Scheduled notification: \(id) at \(date)")
    }
    
    // MARK: - Schedule Wellness Reminders
    func scheduleWellnessReminders() async {
        // 早起提醒 (6:30)
        try? await scheduleLocalNotification(
            id: "morning_wellness",
            title: "🌅 早安，开启养生的一天",
            body: "查看今日节气养生建议，顺应天时",
            date: Calendar.current.date(from: DateComponents(hour: 6, minute: 30)) ?? Date(),
            repeats: true
        )
        
        // 午休提醒 (12:30)
        try? await scheduleLocalNotification(
            id: "noon_rest",
            title: "☀️ 午时养心",
            body: "子午觉养生，适当休息15-30分钟",
            date: Calendar.current.date(from: DateComponents(hour: 12, minute: 30)) ?? Date(),
            repeats: true
        )
        
        // 晚间提醒 (21:30)
        try? await scheduleLocalNotification(
            id: "evening_wellness",
            title: "🌙 夜间养生时刻",
            body: "放松身心，准备入眠，明日再续养生之路",
            date: Calendar.current.date(from: DateComponents(hour: 21, minute: 30)) ?? Date(),
            repeats: true
        )

    }
    
    // MARK: - Schedule AI Follow-Up (Phase B)
    func scheduleFollowUp(intent: AIAgentService.FollowUpIntent) async {
        guard intent.inDays > 0 else { return }
        
        let targetDate = Calendar.current.date(byAdding: .day, value: intent.inDays, to: Date()) ?? Date()
        // 默认在上午 10:00 跟进，比较自然
        let triggerDate = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: targetDate) ?? targetDate
        
        // 构造温和的文案
        let title = "来自顺时小师的关心"
        let body: String
        switch intent.intent {
        case "sleep_check":
            body = "想问问您这两天睡得还好吗？关于\(intent.topic)的调整有没有帮助呢？"
        case "mood_check":
            body = "希望今天你的心情是晴朗的。之前的\(intent.topic)还有在困扰你吗？"
        case "general_check":
            body = "过了几天了，关于\(intent.topic)的调理，感觉身体有什么变化吗？"
        default:
            body = "记得留意一下\(intent.topic)的情况哦，有需要随时找我。"
        }
        
        try? await scheduleLocalNotification(
            id: "ai_follow_up_\(Int(Date().timeIntervalSince1970))", // 唯一ID
            title: title,
            body: body,
            date: triggerDate,
            repeats: false
        )
        
        Logger.info("Scheduled AI FollowUp for \(intent.topic) in \(intent.inDays) days")
    }
    
    // MARK: - Cancel Notification
    func cancelNotification(id: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // MARK: - JPush Integration
    private func registerWithJPush(token: String) {
        // TODO: 集成极光推送SDK
        // JPUSHService.registerDeviceToken(token)
        // JPUSHService.setAlias("user_\(userId)")
        Logger.info("JPush registration prepared")
    }
    
    // MARK: - UMeng Integration
    private func registerWithUMeng(token: String) {
        // TODO: 集成友盟推送SDK
        Logger.info("UMeng registration prepared")
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension PushNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let id = response.notification.request.identifier
        Logger.info("Notification tapped: \(id)")
        // TODO: 处理通知点击事件
    }
}

