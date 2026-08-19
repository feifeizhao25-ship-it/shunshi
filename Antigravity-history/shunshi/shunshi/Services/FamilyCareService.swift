import Foundation
import Combine

// MARK: - Family Care Service
/// 家庭关怀服务 - 管理家人绑定、关怀互动、异常提醒等功能
@MainActor
final class FamilyCareService: ObservableObject {
    static let shared = FamilyCareService()
    
    // MARK: - 家人列表
    @Published var familyMembers: [FamilyMember] = []
    
    // MARK: - 家人动态
    @Published var familyFeed: [FamilyActivity] = []
    
    // MARK: - 家庭挑战
    @Published var familyChallenges: [FamilyChallenge] = []
    
    // MARK: - 关怀消息
    @Published var careMessages: [CareMessage] = []
    
    // MARK: - 异常提醒
    @Published var anomalyAlerts: [AnomalyAlert] = []
    
    // MARK: - 子女监控数据
    @Published var parentalMonitorData: [String: ParentalData] = [:]  // 家人ID -> 监控数据
    
    // MARK: - 设置
    @Published var settings: FamilySettings = FamilySettings()
    
    private init() {
        loadData()
    }
    
    // MARK: - 数据加载
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: "family_members"),
           let members = try? JSONDecoder().decode([FamilyMember].self, from: data) {
            self.familyMembers = members
        }
        
        if let data = UserDefaults.standard.data(forKey: "family_feed"),
           let feed = try? JSONDecoder().decode([FamilyActivity].self, from: data) {
            self.familyFeed = feed
        }
        
        if let data = UserDefaults.standard.data(forKey: "family_challenges"),
           let challenges = try? JSONDecoder().decode([FamilyChallenge].self, from: data) {
            self.familyChallenges = challenges
        }
        
        if let data = UserDefaults.standard.data(forKey: "family_settings"),
           let savedSettings = try? JSONDecoder().decode(FamilySettings.self, from: data) {
            self.settings = savedSettings
        }
    }
    
    private func saveData() {
        if let data = try? JSONEncoder().encode(familyMembers) {
            UserDefaults.standard.set(data, forKey: "family_members")
        }
        if let data = try? JSONEncoder().encode(familyFeed) {
            UserDefaults.standard.set(data, forKey: "family_feed")
        }
        if let data = try? JSONEncoder().encode(familyChallenges) {
            UserDefaults.standard.set(data, forKey: "family_challenges")
        }
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "family_settings")
        }
    }
    
    // MARK: - 家人绑定
    func inviteMember(relationship: Relationship, permission: FamilyPermission) -> String {
        let inviteCode = generateInviteCode()
        
        // 实际项目中这里会生成邀请链接/二维码
        return inviteCode
    }
    
    func processInvite(code: String, relationship: Relationship) -> Bool {
        // 验证邀请码并绑定
        // 实际项目中需要服务端验证
        return true
    }
    
    func bindMember(_ member: FamilyMember) {
        if !familyMembers.contains(where: { $0.id == member.id }) {
            familyMembers.append(member)
            saveData()
            
            // 创建默认权限
            permissions[member.id] = FamilyPermission.default
        }
    }
    
    func unbindMember(_ memberId: String) {
        familyMembers.removeAll { $0.id == memberId }
        permissions.removeValue(forKey: memberId)
        parentalMonitorData.removeValue(forKey: memberId)
        saveData()
    }
    
    func updateMemberPermission(_ memberId: String, permission: FamilyPermission) {
        permissions[memberId] = permission
        saveData()
    }
    
    // MARK: - 关怀功能
    func sendCareMessage(to memberId: String, type: CareMessageType, content: String) {
        let message = CareMessage(
            id: UUID().uuidString,
            fromUserId: "currentUser",
            toUserId: memberId,
            type: type,
            content: content,
            sentAt: Date()
        )
        
        careMessages.append(message)
        saveData()
        
        // 记录动态
        addActivity(for: memberId, type: .careMessage, content: "发送了\(type.emoji)")
    }
    
    func sendQuickCare(to memberId: String, template: QuickCareTemplate) {
        sendCareMessage(to: memberId, type: template.type, content: template.content)
    }
    
    func sendCareCard(to memberId: String, cardType: CareCardType) {
        let content = getCareCardContent(cardType: cardType)
        sendCareMessage(to: memberId, type: .card, content: content)
    }
    
    func scheduleCare(to memberId: String, template: QuickCareTemplate, time: Date) {
        // 定时关怀功能
    }
    
    // MARK: - 查看家人动态
    func getMemberTodayStatus(_ memberId: String) -> MemberTodayStatus? {
        let activities = familyFeed.filter {
            $0.memberId == memberId &&
            Calendar.current.isDateInToday($0.createdAt)
        }
        
        guard !activities.isEmpty else { return nil }
        
        let lastStatus = activities.first?.memberState ?? "😐"
        let checkIns = activities.filter { $0.type == .checkIn }.count
        let lastActive = activities.first?.createdAt
        
        return MemberTodayStatus(
            memberId: memberId,
            lastState: lastStatus,
            checkInCount: checkIns,
            lastActiveTime: lastActive
        )
    }
    
    // MARK: - 异常检测
    func checkAnomalies() {
        let anomalyAlertsService = AnomalyAlertService.shared
        let alerts = anomalyAlertsService.checkAllAnomalies(members: familyMembers, feed: familyFeed)
        
        // 过滤出需要通知用户的异常
        let notifyAlerts = alerts.filter { settings.enabledAlerts.contains($0.type) }
        self.anomalyAlerts = notifyAlerts
        
        if !notifyAlerts.isEmpty {
            // 发送推送通知
            sendAnomalyNotifications(alerts: notifyAlerts)
        }
    }
    
    private func sendAnomalyNotifications(alerts: [AnomalyAlert]) {
        for alert in alerts {
            // 实际项目中发送本地推送或远程推送
            print("发送异常提醒：\(alert.title)")
        }
    }
    
    // MARK: - 家庭挑战
    func createChallenge(name: String, goal: String, duration: Int, members: [String]) -> FamilyChallenge {
        let challenge = FamilyChallenge(
            id: UUID().uuidString,
            name: name,
            description: goal,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: duration, to: Date())!,
            participants: members,
            dailyGoal: 1,
            progress: [:],
            status: .active
        )
        
        familyChallenges.append(challenge)
        saveData()
        return challenge
    }
    
    func joinChallenge(_ challengeId: String) {
        if let index = familyChallenges.firstIndex(where: { $0.id == challengeId }) {
            familyChallenges[index].participants.append("currentUser")
            saveData()
        }
    }
    
    func checkInChallenge(_ challengeId: String, memberId: String) {
        if let index = familyChallenges.firstIndex(where: { $0.id == challengeId }) {
            let currentCount = familyChallenges[index].progress[memberId] ?? 0
            familyChallenges[index].progress[memberId] = currentCount + 1
            saveData()
            
            // 检查是否完成当日目标
            addActivity(for: memberId, type: .challengeCheckIn, content: "完成了\(familyChallenges[index].name)打卡")
        }
    }
    
    // MARK: - 为父母开通
    func createElderlyAccount(for phone: String, name: String, age: Int, gender: String, city: String) -> ElderlyAccount {
        let account = ElderlyAccount(
            phone: phone,
            name: name,
            age: age,
            gender: gender,
            city: city,
            elderlyModeEnabled: true,
            linkedToUserId: "currentUser",
            createdAt: Date()
        )
        
        // 实际项目中会调用服务端API创建账号
        return account
    }
    
    func enableElderlyMode(for memberId: String) {
        if let index = familyMembers.firstIndex(where: { $0.id == memberId }) {
            familyMembers[index].isElderlyModeEnabled = true
            saveData()
        }
    }
    
    // MARK: - 子女监控
    func getParentalData(for memberId: String) -> ParentalData {
        if let data = parentalMonitorData[memberId] {
            return data
        }
        
        // 聚合家人的使用数据
        let memberActivities = familyFeed.filter { $0.memberId == memberId }
        let todayActivities = memberActivities.filter { Calendar.current.isDateInToday($0.createdAt) }
        
        let data = ParentalData(
            memberId: memberId,
            activeDays: calculateActiveDays(activities: memberActivities),
            avgUsageMinutes: calculateAvgUsage(activities: memberActivities),
            weeklyCheckInRate: calculateCheckInRate(activities: todayActivities),
            lastActiveTime: memberActivities.first?.createdAt,
            commonQuestions: extractCommonQuestions(activities: memberActivities),
            sleepAvg: calculateSleepAvg(activities: memberActivities),
            alerts: anomalyAlerts.filter { $0.memberId == memberId }
        )
        
        parentalMonitorData[memberId] = data
        return data
    }
    
    private func calculateActiveDays(activities: [FamilyActivity]) -> Int {
        let uniqueDays = Set(activities.map { Calendar.current.startOfDay(for: $0.createdAt) })
        return uniqueDays.count
    }
    
    private func calculateAvgUsage(activities: [FamilyActivity]) -> Int {
        return 12 // 模拟值，实际从usage data获取
    }
    
    private func calculateCheckInRate(activities: [FamilyActivity]) -> Double {
        let checkIns = activities.filter { $0.type == .checkIn }.count
        return min(Double(checkIns) / 7.0 * 100, 100)
    }
    
    private func calculateSleepAvg(activities: [FamilyActivity]) -> Double {
        return 6.5 // 模拟值
    }
    
    private func extractCommonQuestions(activities: [FamilyActivity]) -> [String] {
        // 从AI对话记录中提取常见问题
        return ["睡眠问题", "膝盖保养", "煲汤食谱"]
    }
    
    // MARK: - 工具方法
    private func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
    
    private func addActivity(for memberId: String, type: ActivityType, content: String) {
        let activity = FamilyActivity(
            id: UUID().uuidString,
            memberId: memberId,
            type: type,
            content: content,
            createdAt: Date()
        )
        
        familyFeed.insert(activity, at: 0)
        
        // 只保留最近100条
        if familyFeed.count > 100 {
            familyFeed = Array(familyFeed.prefix(100))
        }
        
        saveData()
    }
    
    private func getCareCardContent(cardType: CareCardType) -> String {
        let solarTerm = SolarTermService.shared.currentSolarTerm
        let templates: [CareCardType: String] = [
            .morning: "早安！今天\(solarTerm.name)，\(solarTerm.description)，记得\(getSolarTermTip(solarTerm.name))哦~",
            .weather: "今天\(WeatherService.shared.currentWeather.description)，记得\(getWeatherTip())~",
            .festival: "祝您今天愉快，健康顺遂！",
            .solarTerm: "\(solarTerm.emoji) 今日\(solarTerm.name)，\(solarTerm.message)"
        ]
        return templates[cardType] ?? ""
    }
    
    private func getSolarTermTip(_ solarTerm: String) -> String {
        let tips: [String: String] = [
            "小雪": "早睡晚起、温补养藏",
            "大雪": "保暖防寒、适当进补",
            "冬至": "养肾护阳、饺子汤圆",
            "立春": "养肝护脾、少酸多甘"
        ]
        return tips[solarTerm] ?? "顺应时节"
    }
    
    private func getWeatherTip() -> String {
        let weather = WeatherService.shared.currentWeather
        if weather.code == 0 || weather.code == 1 { return "适合户外活动" }
        if weather.code >= 2 && weather.code <= 3 { return "出门记得带伞" }
        return "注意保暖"
    }
    
    // MARK: - 权限管理
    private var permissions: [String: FamilyPermission] = [:]
    
    func getPermission(for memberId: String) -> FamilyPermission {
        return permissions[memberId] ?? FamilyPermission.default
    }
}

// MARK: - 家人成员
struct FamilyMember: Identifiable, Codable {
    let id: String
    let name: String
    let relationship: Relationship
    let avatar: String?
    let boundAt: Date
    var lastActiveAt: Date?
    var todayStatus: String?
    var isElderlyModeEnabled: Bool = false
    
    var isActiveToday: Bool {
        guard let lastActive = lastActiveAt else { return false }
        return Calendar.current.isDateInToday(lastActive)
    }
    
    var statusEmoji: String {
        switch todayStatus {
        case "😊": return "😊 良好"
        case "😐": return "😐 一般"
        case "😫": return "😫 需关注"
        default: return "❓ 未记录"
        }
    }
}

enum Relationship: String, Codable, CaseIterable {
    case mother = "我的妈妈"
    case father = "我的爸爸"
    case spouse = "我的配偶"
    case child = "我的子女"
    case sibling = "兄弟姐妹"
    case friend = "朋友"
    case other = "其他"
    
    var emoji: String {
        switch self {
        case .mother: return "👩"
        case .father: return "👨"
        case .spouse: return "👫"
        case .child: return "👧"
        case .sibling: return "👫"
        case .friend: return "👤"
        case .other: return "👥"
        }
    }
}

// MARK: - 家庭权限
struct FamilyPermission: Codable {
    var canSeeCheckIn: Bool = true
    var canSeeDailyState: Bool = true
    var canSeeConstitution: Bool = true
    var canSeeSleepDetail: Bool = false
    var canSeeDiary: Bool = false
    var canSeeLocation: Bool = false
    var canSendCare: Bool = true
    var canSendContent: Bool = true
    var canSeeReport: Bool = false
    var canReceiveAlert: Bool = false
    
    static var `default`: FamilyPermission {
        FamilyPermission()
    }
    
    static var forParents: FamilyPermission {
        var perm = FamilyPermission()
        perm.canSeeSleepDetail = true
        perm.canSeeDiary = true
        perm.canSeeLocation = true
        perm.canReceiveAlert = true
        return perm
    }
}

// MARK: - 家庭动态
struct FamilyActivity: Identifiable, Codable {
    let id: String
    let memberId: String
    let type: ActivityType
    let content: String
    let createdAt: Date
    var memberState: String?  // 😊 😐 😫
}

enum ActivityType: String, Codable {
    case checkIn = "checkIn"
    case state = "state"
    case careMessage = "careMessage"
    case challengeCheckIn = "challengeCheckIn"
    case sleep = "sleep"
    case exercise = "exercise"
}

// MARK: - 关怀消息
struct CareMessage: Identifiable, Codable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let type: CareMessageType
    let content: String
    let sentAt: Date
    var isRead: Bool = false
}

enum CareMessageType: String, Codable {
    case text = "text"
    case voice = "voice"
    case card = "card"
    case content = "content"
    case membership = "membership"

    var emoji: String {
        switch self {
        case .text: return "💬"
        case .voice: return "🎤"
        case .card: return "🎴"
        case .content: return "🍵"
        case .membership: return "🎁"
        }
    }
}

// MARK: - 快捷关怀模板
struct QuickCareTemplate: Identifiable {
    let id = UUID().uuidString
    let name: String
    let emoji: String
    let content: String
    let type: CareMessageType
}

enum CareCardType: String, CaseIterable {
    case morning = "morning"
    case weather = "weather"
    case festival = "festival"
    case solarTerm = "solarTerm"

    var emoji: String {
        switch self {
        case .morning: return "☀️"
        case .weather: return "🌤️"
        case .festival: return "🎊"
        case .solarTerm: return "❄️"
        }
    }

    var name: String {
        switch self {
        case .morning: return "早安问候"
        case .weather: return "天气关怀"
        case .festival: return "节日祝福"
        case .solarTerm: return "节气卡片"
        }
    }
}

// MARK: - 家庭挑战
struct FamilyChallenge: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let startDate: Date
    let endDate: Date
    var participants: [String]
    var dailyGoal: Int
    var progress: [String: Int]  // memberId -> completedDays
    var status: ChallengeStatus

    enum ChallengeStatus: String, Codable {
        case active = "active"
        case completed = "completed"
        case expired = "expired"
    }

    var completedDays: Int {
        guard let myProgress = progress["currentUser"] else { return 0 }
        return myProgress
    }

    var totalDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 21
    }
}

// MARK: - 异常提醒
struct AnomalyAlert: Identifiable {
    let id = UUID().uuidString
    let memberId: String
    let memberName: String
    let type: AnomalyType
    let title: String
    let description: String
    let createdAt: Date
    var isRead: Bool = false
}

enum AnomalyType: String, CaseIterable, Codable {
    case inactive = "inactive"         // 连续N天未使用
    case badState = "badState"          // 连续N天状态不好
    case poorSleep = "poorSleep"        // 睡眠时长异常
    case noCheckIn = "noCheckIn"        // 连续N天未打卡
    
    var emoji: String {
        switch self {
        case .inactive: return "⚠️"
        case .badState: return "😟"
        case .poorSleep: return "😴"
        case .noCheckIn: return "❌"
        }
    }
    
    var title: String {
        switch self {
        case .inactive: return "活跃异常"
        case .badState: return "状态提醒"
        case .poorSleep: return "睡眠异常"
        case .noCheckIn: return "打卡异常"
        }
    }
}

// MARK: - 异常检测服务
class AnomalyAlertService {
    static let shared = AnomalyAlertService()
    
    func checkAllAnomalies(members: [FamilyMember], feed: [FamilyActivity]) -> [AnomalyAlert] {
        var alerts: [AnomalyAlert] = []
        let thresholdDays = 3
        
        for member in members {
            // 检查活跃异常
            if let lastActive = member.lastActiveAt {
                let daysSinceActive = Calendar.current.dateComponents([.day], from: lastActive, to: Date()).day ?? 0
                if daysSinceActive >= thresholdDays {
                    alerts.append(AnomalyAlert(
                        memberId: member.id,
                        memberName: member.name,
                        type: .inactive,
                        title: "活跃异常",
                        description: "\(member.name)已经\(daysSinceActive)天没有使用App了",
                        createdAt: Date()
                    ))
                }
            }
            
            // 检查状态异常
            let recentStates = feed.filter {
                $0.memberId == member.id &&
                Calendar.current.dateComponents([.day], from: $0.createdAt, to: Date()).day! < 3
            }
            let badStates = recentStates.filter { $0.memberState == "😫" }
            if badStates.count >= 3 {
                alerts.append(AnomalyAlert(
                    memberId: member.id,
                    memberName: member.name,
                    type: .badState,
                    title: "状态提醒",
                    description: "\(member.name)最近状态不太好，建议关心一下",
                    createdAt: Date()
                ))
            }
        }
        
        return alerts
    }
}

// MARK: - 家人今日状态
struct MemberTodayStatus {
    let memberId: String
    let lastState: String
    let checkInCount: Int
    let lastActiveTime: Date?
    
    var hasCheckIn: Bool { checkInCount > 0 }
    var isGoodState: Bool { lastState == "😊" || lastState == "😄" }
    var isBadState: Bool { lastState == "😫" || lastState == "😞" }
}

// MARK: - 子女监控数据
struct ParentalData {
    let memberId: String
    let activeDays: Int
    let avgUsageMinutes: Int
    let weeklyCheckInRate: Double
    let lastActiveTime: Date?
    let commonQuestions: [String]
    let sleepAvg: Double
    let alerts: [AnomalyAlert]
    
    var activeRate: Double {
        min(Double(activeDays) / 30.0 * 100, 100)
    }
    
    var sleepStatus: String {
        if sleepAvg >= 7 { return "良好" }
        if sleepAvg >= 6 { return "一般" }
        return "偏少"
    }
}

// MARK: - 为父母开通
struct ElderlyAccount {
    let phone: String
    let name: String
    let age: Int
    let gender: String
    let city: String
    var elderlyModeEnabled: Bool
    var linkedToUserId: String
    let createdAt: Date
}

// MARK: - 家庭设置
struct FamilySettings: Codable {
    var globalEnabled: Bool = true
    var enabledAlerts: Set<AnomalyType> = Set(AnomalyType.allCases)
    var dailySummaryEnabled: Bool = true
    var dailySummaryTime: Int = 18  // 18:00
    var quietHoursStart: Int = 22
    var quietHoursEnd: Int = 7
}

// MARK: - 快捷关怀库
struct QuickCareLibrary {
    static let templates: [QuickCareTemplate] = [
        QuickCareTemplate(name: "早安", emoji: "☀️", content: "早上好！今天也要元气满满~", type: .text),
        QuickCareTemplate(name: "多喝水", emoji: "💧", content: "记得多喝水哦~", type: .text),
        QuickCareTemplate(name: "天冷加衣", emoji: "🧥", content: "今天降温了，记得多穿一件~", type: .text),
        QuickCareTemplate(name: "早点休息", emoji: "😴", content: "早点休息，晚安~", type: .text),
        QuickCareTemplate(name: "想你了", emoji: "❤️", content: "想你了，最近怎么样？", type: .text),
        QuickCareTemplate(name: "语音问候", emoji: "🎤", content: "点击录制语音问候", type: .voice),
        QuickCareTemplate(name: "早安卡", emoji: "☀️", content: "", type: .card),
        QuickCareTemplate(name: "节气卡", emoji: "❄️", content: "", type: .card)
    ]
}
