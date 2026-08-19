import Foundation
import SwiftUI

// MARK: - Type Aliases to Resolve Ambiguity
// 这个文件用于解决项目中的类型歧义问题
// 统一使用Domain层的类型定义

// 注：以下类型在多个文件中有定义，这里指定使用Domain层的标准定义
// 如需使用服务层的特定实现，请使用完整类型路径

// MARK: - 注释说明
// 1. SolarTerm -> Domain/Entities/SolarTerm.swift
// 2. Season -> Domain/Entities/SolarTerm.swift  
// 3. Recipe -> Domain/Entities/Recipe.swift
// 4. Ingredient -> Domain/Entities/Wellness.swift
// 5. RecipeStep -> Domain/Entities/Recipe.swift
// 6. Acupoint -> Domain/Repositories/WellnessRepositoryProtocol.swift
// 7. Exercise -> Domain/Repositories/WellnessRepositoryProtocol.swift
// 8. User -> Domain/Entities/User.swift
// 9. Constitution -> Domain/Entities/Constitution.swift

// MARK: - 服务层本地类型定义（避免与Domain层冲突）
// 这些类型仅在服务层内部使用

/// 服务层的Daily Task（用于ConstitutionService和SolarTermService）
struct ServiceDailyTask: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let points: Int
    var isCompleted: Bool
    
    init(id: String = UUID().uuidString, title: String, description: String, points: Int = 10, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.points = points
        self.isCompleted = isCompleted
    }
}

/// 服务层的Recipe（简化版，用于WellnessContentService）
struct ServiceRecipe: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let description: String
    let oneLineEffect: String
    let suitableConstitutions: [String]
    let suitableSolarTerms: [String]
    let suitableCrowd: [String]
    let avoidCrowd: [String]
    let difficulty: Difficulty
    let cookTime: Int
    let rating: Double
    let viewCount: Int
    
    init(id: String = UUID().uuidString, name: String, emoji: String = "🍲",
         description: String = "", oneLineEffect: String = "",
         suitableConstitutions: [String] = [], suitableSolarTerms: [String] = [],
         suitableCrowd: [String] = [], avoidCrowd: [String] = [],
         difficulty: Difficulty = .easy, cookTime: Int = 30,
         rating: Double = 4.5, viewCount: Int = 0) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.description = description
        self.oneLineEffect = oneLineEffect
        self.suitableConstitutions = suitableConstitutions
        self.suitableSolarTerms = suitableSolarTerms
        self.suitableCrowd = suitableCrowd
        self.avoidCrowd = avoidCrowd
        self.difficulty = difficulty
        self.cookTime = cookTime
        self.rating = rating
        self.viewCount = viewCount
    }
}

/// 难度等级
enum Difficulty: String, Codable, CaseIterable {
    case easy = "简单"
    case medium = "中等"
    case hard = "困难"
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

/// 茶饮分类
enum ServiceTeaCategory: String, CaseIterable {
    case refresh = "提神醒脑"
    case sleep = "助眠安神"
    case warm = "暖身驱寒"
    case cool = "清热降火"
    case beauty = "美容养颜"

    var emoji: String {
        switch self {
        case .refresh: return "⚡"
        case .sleep: return "🌙"
        case .warm: return "🔥"
        case .cool: return "❄️"
        case .beauty: return "✨"
        }
    }
}

/// 服务层穴位类型
struct ServiceAcupoint: Identifiable {
    let id: String
    let name: String
    let pinyin: String
    let emoji: String
    let oneLineEffect: String
    let effects: [String]
    let locationDescription: String
    let massageMethod: String
    let massageDuration: Int
    let suitableConstitutions: [String]
    let precautions: [String]

    init(id: String = UUID().uuidString, name: String, pinyin: String = "",
         emoji: String = "📍", oneLineEffect: String = "", effects: [String] = [],
         locationDescription: String = "", massageMethod: String = "",
         massageDuration: Int = 180, suitableConstitutions: [String] = [],
         precautions: [String] = []) {
        self.id = id
        self.name = name
        self.pinyin = pinyin
        self.emoji = emoji
        self.oneLineEffect = oneLineEffect
        self.effects = effects
        self.locationDescription = locationDescription
        self.massageMethod = massageMethod
        self.massageDuration = massageDuration
        self.suitableConstitutions = suitableConstitutions
        self.precautions = precautions
    }
}

/// 服务层运动类型
struct ServiceExercise: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let description: String
    let oneLineEffect: String
    let effects: [String]
    let difficulty: Difficulty
    let duration: Int
    let suitableConstitutions: [String]
    let precautions: [String]
    let categories: [String]

    init(id: String = UUID().uuidString, name: String, emoji: String = "🧘",
         description: String = "", oneLineEffect: String = "", effects: [String] = [],
         difficulty: Difficulty = .medium, duration: Int = 15,
         suitableConstitutions: [String] = [], precautions: [String] = [],
         categories: [String] = []) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.description = description
        self.oneLineEffect = oneLineEffect
        self.effects = effects
        self.difficulty = difficulty
        self.duration = duration
        self.suitableConstitutions = suitableConstitutions
        self.precautions = precautions
        self.categories = categories
    }
}

/// 服务层睡眠内容类型
struct ServiceSleepContent: Identifiable {
    let id: String
    let name: String
    let type: SleepContentType
    let description: String
    let duration: Int
    let audioUrl: String?
    let suitableProblems: [String]
    let categories: [String]

    init(id: String = UUID().uuidString, name: String, type: SleepContentType = .meditation,
         description: String = "", duration: Int = 10, audioUrl: String? = nil,
         suitableProblems: [String] = [], categories: [String] = []) {
        self.id = id
        self.name = name
        self.type = type
        self.description = description
        self.duration = duration
        self.audioUrl = audioUrl
        self.suitableProblems = suitableProblems
        self.categories = categories
    }
}

enum SleepContentType: String, Codable {
    case meditation = "冥想"
    case whitenoise = "白噪音"
    case music = "音乐"
    case story = "故事"
}

/// 服务层情绪内容类型
struct ServiceEmotionContent: Identifiable {
    let id: String
    let name: String
    let type: EmotionContentType
    let description: String
    let suitableEmotions: [String]
    let effects: [String]
    let duration: Int?
    let steps: [String]

    init(id: String = UUID().uuidString, name: String, type: EmotionContentType = .breathing,
         description: String = "", suitableEmotions: [String] = [], effects: [String] = [],
         duration: Int? = nil, steps: [String] = []) {
        self.id = id
        self.name = name
        self.type = type
        self.description = description
        self.suitableEmotions = suitableEmotions
        self.effects = effects
        self.duration = duration
        self.steps = steps
    }
}

enum EmotionContentType: String, Codable {
    case breathing = "呼吸法"
    case acupressure = "穴位按摩"
    case meditation = "冥想"
    case exercise = "运动"
}

/// 服务层体质测试记录
struct ServiceConstitutionTestRecord: Identifiable, Codable {
    let id: String
    let date: Date
    let mode: String
    let primaryConstitution: String
    let score: Double

    init(id: String = UUID().uuidString, date: Date = Date(), mode: String = "standard",
         primaryConstitution: String = "", score: Double = 0) {
        self.id = id
        self.date = date
        self.mode = mode
        self.primaryConstitution = primaryConstitution
        self.score = score
    }
}

