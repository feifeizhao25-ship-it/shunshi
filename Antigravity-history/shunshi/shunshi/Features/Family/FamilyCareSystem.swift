import Foundation

// MARK: - 家庭关怀系统
/// 顺时APP家庭关怀核心系统
/// 提供家人绑定、健康关怀、为父母开通会员等功能

final class FamilyCareSystem: ObservableObject {
    static let shared = FamilyCareSystem()
    
    // MARK: - 家庭成员
    struct FamilyMember: Identifiable, Codable {
        let id: String
        var nickname: String
        var relationship: FamilyRelationship
        var avatar: String?
        var phoneNumber: String?
        var birthday: Date?
        var constitution: String?    // 体质类型
        var healthGoals: [String]
        var isLinked: Bool           // 是否已绑定账号
        var linkedUserId: String?    // 绑定的用户ID
        var membershipGifted: Bool   // 是否已赠送会员
        var createdAt: Date
        var lastActiveAt: Date?
    }
    
    enum FamilyRelationship: String, Codable, CaseIterable {
        case father = "father"
        case mother = "mother"
        case spouse = "spouse"
        case child = "child"
        case grandparent = "grandparent"
        case sibling = "sibling"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .father: return "父亲"
            case .mother: return "母亲"
            case .spouse: return "配偶"
            case .child: return "子女"
            case .grandparent: return "祖父母"
            case .sibling: return "兄弟姐妹"
            case .other: return "其他"
            }
        }
        
        var icon: String {
            switch self {
            case .father: return "figure.stand"
            case .mother: return "figure.stand.dress"
            case .spouse: return "heart.fill"
            case .child: return "figure.and.child.holdinghands"
            case .grandparent: return "figure.2.arms.open"
            case .sibling: return "person.2.fill"
            case .other: return "person.fill"
            }
        }
    }
    
    // MARK: - 关怀消息
    struct CareMessage: Identifiable, Codable {
        let id: String
        let type: CareMessageType
        let title: String
        let content: String
        let senderName: String
        let receiverId: String
        let sentAt: Date
        var isRead: Bool
        var readAt: Date?
    }
    
    enum CareMessageType: String, Codable, CaseIterable {
        case greeting = "greeting"       // 问候
        case reminder = "reminder"       // 提醒
        case solarTerm = "solarTerm"     // 节气祝福
        case birthday = "birthday"       // 生日祝福
        case health = "health"           // 健康关怀
        case weather = "weather"         // 天气提醒
        
        var displayName: String {
            switch self {
            case .greeting: return "日常问候"
            case .reminder: return "健康提醒"
            case .solarTerm: return "节气祝福"
            case .birthday: return "生日祝福"
            case .health: return "健康关怀"
            case .weather: return "天气提醒"
            }
        }
    }
    
    // MARK: - 家庭健康报告
    struct FamilyHealthReport: Identifiable, Codable {
        let id: String
        let memberId: String
        let reportDate: Date
        let sleepScore: Int?
        let exerciseMinutes: Int?
        let waterIntake: Int?
        let moodScore: Int?
        let healthTips: [String]
        let concerns: [String]
    }
    
    // MARK: - 会员赠送
    struct MembershipGift: Identifiable, Codable {
        let id: String
        let gifterId: String
        let receiverId: String
        let membershipType: String
        let duration: Int            // 天数
        let giftedAt: Date
        var isActivated: Bool
        var activatedAt: Date?
        var expiresAt: Date?
    }
    
    // MARK: - 绑定邀请
    struct FamilyInvitation: Identifiable, Codable {
        let id: String
        let inviterId: String
        let inviterName: String
        let relationship: FamilyRelationship
        let inviteCode: String
        let createdAt: Date
        let expiresAt: Date
        var status: InvitationStatus
    }
    
    enum InvitationStatus: String, Codable {
        case pending = "pending"
        case accepted = "accepted"
        case declined = "declined"
        case expired = "expired"
    }

    // MARK: - 关怀消息模板
    struct CareMessageTemplate {
        static let greetings = [
            "早安！今天也要好好照顾自己哦 ☀️",
            "天气转凉，记得添衣保暖 🧥",
            "工作再忙也要按时吃饭 🍚",
            "今天辛苦了，早点休息 🌙"
        ]

        static let solarTermGreetings: [String: [String]] = [
            "立春": ["立春到，万物复苏，愿您身体健康，春意盎然！"],
            "雨水": ["雨水时节，注意防潮祛湿，保重身体！"],
            "惊蛰": ["惊蛰至，春雷响，愿您精神焕发！"],
            "春分": ["春分时节，阴阳平衡，愿您身心和谐！"],
            "清明": ["清明时节，踏青养生，愿您心情舒畅！"],
            "谷雨": ["谷雨润万物，愿您健康如意！"]
        ]

        static let healthReminders = [
            "记得多喝水，保持身体水分充足 💧",
            "久坐不好，起来活动活动吧 🧘",
            "今天运动了吗？适量运动有益健康 🏃",
            "睡前泡泡脚，有助于睡眠 🦶"
        ]
    }

    // MARK: - 核心方法

    // MARK: - Properties
    @Published var members: [FamilyMember] = []
    
    // MARK: - Persistence Keys
    private let kFamilyMembersKey = "shunshi_family_members"
    
    private init() {
        loadMembers()
    }
    
    // MARK: - 核心方法

    /// 添加家庭成员
    func addFamilyMember(nickname: String, relationship: FamilyRelationship, constitution: String?, concerns: [String], phoneNumber: String? = nil) -> FamilyMember {
        let member = FamilyMember(
            id: UUID().uuidString,
            nickname: nickname,
            relationship: relationship,
            avatar: nil,
            phoneNumber: phoneNumber,
            birthday: nil,
            constitution: constitution,
            healthGoals: concerns,
            isLinked: false,
            linkedUserId: nil,
            membershipGifted: false,
            createdAt: Date(),
            lastActiveAt: nil
        )
        members.append(member)
        saveMembers()
        return member
    }
    
    /// 删除家庭成员
    func removeMember(_ memberId: String) {
        members.removeAll { $0.id == memberId }
        saveMembers()
    }
    
    /// 更新家庭成员信息
    func updateMember(_ member: FamilyMember) {
        if let index = members.firstIndex(where: { $0.id == member.id }) {
            members[index] = member
            saveMembers()
        }
    }
    
    // MARK: - Persistence
    
    private func saveMembers() {
        if let data = try? JSONEncoder().encode(members) {
            UserDefaults.standard.set(data, forKey: kFamilyMembersKey)
        }
    }
    
    private func loadMembers() {
        guard let data = UserDefaults.standard.data(forKey: kFamilyMembersKey),
              let loaded = try? JSONDecoder().decode([FamilyMember].self, from: data) else {
            return
        }
        self.members = loaded
    }

    /// 生成邀请码
    func generateInviteCode(for relationship: FamilyRelationship) -> FamilyInvitation {
        let code = String(format: "%06d", Int.random(in: 100000...999999))
        let invitation = FamilyInvitation(
            id: UUID().uuidString,
            inviterId: "current_user_id", // 实际实现需要获取当前用户ID
            inviterName: "用户",
            relationship: relationship,
            inviteCode: code,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(7 * 24 * 60 * 60), // 7天有效
            status: .pending
        )
        return invitation
    }

    /// 发送关怀消息
    func sendCareMessage(to memberId: String, type: CareMessageType, customContent: String? = nil) -> CareMessage {
        let content: String
        switch type {
        case .greeting:
            content = customContent ?? CareMessageTemplate.greetings.randomElement() ?? ""
        case .health:
            content = customContent ?? CareMessageTemplate.healthReminders.randomElement() ?? ""
        default:
            content = customContent ?? "关心您的健康 ❤️"
        }

        let message = CareMessage(
            id: UUID().uuidString,
            type: type,
            title: type.displayName,
            content: content,
            senderName: "您的家人",
            receiverId: memberId,
            sentAt: Date(),
            isRead: false,
            readAt: nil
        )
        // 实际实现需要发送推送通知
        return message
    }

    /// 赠送会员
    func giftMembership(to memberId: String, duration: Int) -> MembershipGift {
        let gift = MembershipGift(
            id: UUID().uuidString,
            gifterId: "current_user_id",
            receiverId: memberId,
            membershipType: "premium",
            duration: duration,
            giftedAt: Date(),
            isActivated: false,
            activatedAt: nil,
            expiresAt: nil
        )
        // 实际实现需要处理支付和会员开通逻辑
        return gift
    }

    /// 获取家庭成员列表
    func getFamilyMembers() -> [FamilyMember] {
        return members
    }

    /// 获取家庭成员健康报告
    func getFamilyHealthReport(for memberId: String) -> FamilyHealthReport? {
        // 实际实现需要从服务器获取
        return FamilyHealthReport(
            id: UUID().uuidString,
            memberId: memberId,
            reportDate: Date(),
            sleepScore: 85,
            exerciseMinutes: 30,
            waterIntake: 1500,
            moodScore: 80,
            healthTips: ["今日睡眠质量良好", "建议增加饮水量"],
            concerns: []
        )
    }

    /// 获取待处理的邀请
    func getPendingInvitations() -> [FamilyInvitation] {
        // 实际实现需要从服务器获取
        return []
    }
}

