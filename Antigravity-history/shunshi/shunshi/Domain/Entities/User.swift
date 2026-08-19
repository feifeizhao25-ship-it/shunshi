import Foundation

// MARK: - User Entity
struct User: Identifiable, Equatable {
    let id: String
    let phone: String?
    var nickname: String?
    var avatarUrl: URL?
    var gender: Gender?
    var birthDate: Date?
    var birthTime: Date?
    var location: Location?
    var constitution: UserConstitution?
    var preferences: UserPreferences
    var stats: UserStats
    var membership: Membership
    var likedContents: [String] = []
    var concerns: [String] = []
    var sleepHabit: String?
    var foodPreference: String?
    var exerciseHabit: String?
    let createdAt: Date
    
    var displayName: String {
        nickname ?? phone?.maskedPhone ?? "用户"
    }
    
    var hasCompletedProfile: Bool {
        nickname != nil && gender != nil && birthDate != nil
    }
    
    var hasTestedConstitution: Bool {
        constitution?.primary != nil
    }
    
    var profileSummary: String {
        var summary = "用户: \(displayName)"
        if let gender = gender { summary += ", 性别: \(gender.displayName)" }
        if let age = birthDate?.age { summary += ", 年龄: \(age)" }
        if !concerns.isEmpty {
            summary += ", 关注: \(concerns.joined(separator: ", "))"
        }
        if let constitution = constitution?.primary?.type.displayName {
            summary += ", 体质: \(constitution)"
        }
        return summary
    }
}

// MARK: - Gender
enum Gender: String, CaseIterable, Codable {
    case male = "male"
    case female = "female"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .male: return "男"
        case .female: return "女"
        case .other: return "其他"
        }
    }
}

// MARK: - Location
struct Location: Equatable {
    let province: String
    let city: String
    
    var displayName: String {
        "\(province) \(city)"
    }
}

// MARK: - User Constitution
struct UserConstitution: Equatable {
    let primary: UserConstitutionResult?
    let secondary: UserConstitutionResult?
    let testedAt: Date?
}

// MARK: - Constitution Result
struct UserConstitutionResult: Equatable {
    let type: ConstitutionType
    let score: Int
}

// MARK: - User Preferences
struct UserPreferences: Equatable {
    var notificationEnabled: Bool
    var morningReminder: Date?
    var eveningReminder: Date?
    var solarTermReminder: Bool
    var dietReminder: Bool
    
    static let `default` = UserPreferences(
        notificationEnabled: true,
        morningReminder: nil,
        eveningReminder: nil,
        solarTermReminder: true,
        dietReminder: true
    )
}

// MARK: - User Stats
struct UserStats: Equatable {
    let checkInDays: Int
    let favoritesCount: Int
    let wellnessScore: Int?
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var zenGrowthStage: Int = 0 // 0: Seed, 1: Sprout, 2: Sapling, 3: Tree, 4: Flower, 5: Fruit
    
    static let empty = UserStats(checkInDays: 0, favoritesCount: 0, wellnessScore: nil, currentStreak: 0, bestStreak: 0, zenGrowthStage: 0)
}

// MARK: - Membership
struct Membership: Equatable {
    let type: MembershipType
    let expiresAt: Date?
    
    var isActive: Bool {
        switch type {
        case .free:
            return true
        case .premium, .vip:
            guard let expiresAt = expiresAt else { return false }
            return expiresAt > Date()
        }
    }
    
    static let free = Membership(type: .free, expiresAt: nil)
}

// MARK: - Membership Type
enum MembershipType: String, Codable {
    case free = "free"
    case premium = "premium"
    case vip = "vip"
    
    var displayName: String {
        switch self {
        case .free: return "普通会员"
        case .premium: return "高级会员"
        case .vip: return "VIP会员"
        }
    }
}

// MARK: - User Mapper
extension User {
    init(from dto: UserProfileDTO) {
        self.id = dto.id
        self.phone = dto.phone
        self.nickname = dto.nickname
        self.avatarUrl = dto.avatarUrl.flatMap { URL(string: $0) }
        self.gender = dto.gender.flatMap { Gender(rawValue: $0) }
        self.birthDate = dto.birthDate.flatMap { Date(iso8601String: $0) }
        self.birthTime = dto.birthTime.flatMap { Date(iso8601String: $0) }
        self.location = dto.location.map { Location(province: $0.province, city: $0.city) }
        self.constitution = dto.constitution.map { constitution in
            UserConstitution(
                primary: constitution.primary.map { UserConstitutionResult(type: ConstitutionType(rawValue: $0.type) ?? .balanced, score: $0.score) },
                secondary: constitution.secondary.map { UserConstitutionResult(type: ConstitutionType(rawValue: $0.type) ?? .balanced, score: $0.score) },
                testedAt: constitution.testedAt.flatMap { Date(iso8601String: $0) }
            )
        }
        self.preferences = dto.preferences.map { prefs in
            UserPreferences(
                notificationEnabled: prefs.notificationEnabled ?? true,
                morningReminder: prefs.morningReminder.flatMap { Date(iso8601String: $0) },
                eveningReminder: prefs.eveningReminder.flatMap { Date(iso8601String: $0) },
                solarTermReminder: true,
                dietReminder: true
            )
        } ?? .default
        self.stats = dto.stats.map { UserStats(checkInDays: $0.checkInDays, favoritesCount: $0.favoritesCount, wellnessScore: $0.wellnessScore) } ?? .empty
        self.membership = dto.membership.map { Membership(type: MembershipType(rawValue: $0.type) ?? .free, expiresAt: $0.expiresAt.flatMap { Date(iso8601String: $0) }) } ?? .free
        self.createdAt = Date(iso8601String: dto.createdAt) ?? Date()
    }
}

