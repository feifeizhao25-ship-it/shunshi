import SwiftUI

// MARK: - Five Dimensions of Health (五维养生)
enum WuWeiType: String, CaseIterable, Identifiable {
    case diet = "diet"           // 食养
    case living = "living"       // 起居
    case exercise = "exercise"   // 动养
    case acupoint = "acupoint"   // 穴位
    case emotion = "emotion"     // 情志
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .diet: return "食养"
        case .living: return "起居"
        case .exercise: return "动养"
        case .acupoint: return "穴位"
        case .emotion: return "情志"
        }
    }
    
    var englishName: String {
        switch self {
        case .diet: return "Diet"
        case .living: return "Living"
        case .exercise: return "Exercise"
        case .acupoint: return "Acupoint"
        case .emotion: return "Emotion"
        }
    }
    
    var icon: String {
        switch self {
        case .diet: return "fork.knife"
        case .living: return "moon.zzz.fill"
        case .exercise: return "figure.walk"
        case .acupoint: return "hand.point.up.fill"
        case .emotion: return "heart.fill"
        }
    }
    
    var description: String {
        switch self {
        case .diet: return "节气饮食，当季食材"
        case .living: return "作息调整，起居养护"
        case .exercise: return "节气运动，强身健体"
        case .acupoint: return "经络养护，穴位保健"
        case .emotion: return "情志调节，心理健康"
        }
    }
    
    var color: Color {
        switch self {
        case .diet: return .orange
        case .living: return .indigo
        case .exercise: return .green
        case .acupoint: return .pink
        case .emotion: return .purple
        }
    }

    var modernAlias: String {
        switch self {
        case .diet: return "饮食营养"
        case .living: return "作息规律"
        case .exercise: return "运动习惯"
        case .acupoint: return "经络调理"
        case .emotion: return "心理平衡"
        }
    }

    var detailedExplanation: String {
        switch self {
        case .diet: return "根据二十四节气推荐当季食材，吃对季节，温和呵护身体。"
        case .living: return "顺应昼夜节律调整作息，在正确的时间做正确的事，恢复精力。"
        case .exercise: return "结合身体状态，推荐舒缓或进阶的运动方案，激发身体活力。"
        case .acupoint: return "通过按压特定的穴位，缓解疲劳，增强脏腑活力，简单有效。"
        case .emotion: return "调节心情压力，保持平和心境，是平衡身心的关键。"
        }
    }
}

// MARK: - Seasonal Ingredient (当季食材)
struct SeasonalIngredient: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let nameEN: String?
    let imageURL: String?
    let nature: String            // 性：寒/凉/平/温/热
    let flavor: [String]          // 味：酸/苦/甘/辛/咸
    let meridians: [String]       // 归经
    let efficacy: [String]        // 功效
    let suitableSolarTerms: [String]
    let contraindications: String? // 禁忌
}

