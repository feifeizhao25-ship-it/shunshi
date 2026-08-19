import Foundation
import SwiftUI

// MARK: - Constitution Type
enum ConstitutionType: String, CaseIterable, Identifiable {
    case balanced = "balanced"           // 平和质
    case qiDeficiency = "qi_deficiency" // 气虚质
    case yangDeficiency = "yang_deficiency" // 阳虚质
    case yinDeficiency = "yin_deficiency" // 阴虚质
    case phlegmDampness = "phlegm_dampness" // 痰湿质
    case dampHeat = "damp_heat"         // 湿热质
    case bloodStasis = "blood_stasis"   // 血瘀质
    case qiStagnation = "qi_stagnation" // 气郁质
    case inherited = "inherited"         // 特禀质
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .balanced: return "平和质"
        case .qiDeficiency: return "气虚质"
        case .yangDeficiency: return "阳虚质"
        case .yinDeficiency: return "阴虚质"
        case .phlegmDampness: return "痰湿质"
        case .dampHeat: return "湿热质"
        case .bloodStasis: return "血瘀质"
        case .qiStagnation: return "气郁质"
        case .inherited: return "特禀质"
        }
    }
    
    var shortDescription: String {
        switch self {
        case .balanced: return "身心健康，精力充沛"
        case .qiDeficiency: return "容易疲劳，气短懒言"
        case .yangDeficiency: return "畏寒怕冷，手脚冰凉"
        case .yinDeficiency: return "口干咽燥，手足心热"
        case .phlegmDampness: return "体型偏胖，痰多黏腻"
        case .dampHeat: return "面部油腻，口苦口干"
        case .bloodStasis: return "面色晦暗，易生色斑"
        case .qiStagnation: return "情绪低落，胸闷不舒"
        case .inherited: return "容易过敏，适应力差"
        }
    }
    
    var themeColor: Color {
        switch self {
        case .balanced: return .green
        case .qiDeficiency: return .orange
        case .yangDeficiency: return .blue
        case .yinDeficiency: return .red
        case .phlegmDampness: return .brown
        case .dampHeat: return .yellow
        case .bloodStasis: return .purple
        case .qiStagnation: return .indigo
        case .inherited: return .pink
        }
    }
    
    var icon: String {
        switch self {
        case .balanced: return "leaf.fill"
        case .qiDeficiency: return "wind"
        case .yangDeficiency: return "snowflake"
        case .yinDeficiency: return "flame.fill"
        case .phlegmDampness: return "drop.fill"
        case .dampHeat: return "sun.max.fill"
        case .bloodStasis: return "heart.fill"
        case .qiStagnation: return "cloud.fill"
        case .inherited: return "allergens"
        }
    }
    
    var emoji: String {
        switch self {
        case .balanced: return "🌿"
        case .qiDeficiency: return "💨"
        case .yangDeficiency: return "❄️"
        case .yinDeficiency: return "🔥"
        case .phlegmDampness: return "☁️"
        case .dampHeat: return "☀️"
        case .bloodStasis: return "🩸"
        case .qiStagnation: return "🥀"
        case .inherited: return "🧬"
        }
    }
}

// MARK: - Constitution Test Result
struct ConstitutionTestResult: Identifiable, Equatable {
    let id: String
    let primaryConstitution: ConstitutionDetail
    let secondaryConstitution: ConstitutionDetail?
    let allScores: [ConstitutionScore]
    let recommendations: ConstitutionRecommendations
    let testedAt: Date
    
    var isBalanced: Bool {
        primaryConstitution.type == .balanced
    }
}

// MARK: - Constitution Detail
struct ConstitutionDetail: Identifiable, Equatable {
    var id: String { type.rawValue }
    let type: ConstitutionType
    let score: Int
    let description: String
    let characteristics: [String]
    let causes: [String]
    let healthRisks: [String]
}

// MARK: - Constitution Score
struct ConstitutionScore: Identifiable, Equatable {
    var id: String { type.rawValue }
    let type: ConstitutionType
    let score: Int
    
    var percentage: Double {
        Double(score) / 100.0
    }
}

// MARK: - Constitution Recommendations
struct ConstitutionRecommendations: Equatable {
    let diet: [String]
    let living: [String]
    let exercise: [String]
    let emotion: [String]
}

// MARK: - Questionnaire
struct Questionnaire: Identifiable {
    var id: String { version }
    let version: String
    let totalQuestions: Int
    let sections: [QuestionnaireSection]
}

// MARK: - Questionnaire Section
struct QuestionnaireSection: Identifiable {
    var id: String { type.rawValue }
    let type: ConstitutionType
    let questions: [Question]
}

// MARK: - Question
struct Question: Identifiable {
    let id: String
    let text: String
    let options: [QuestionOption]
}

// MARK: - Question Option
struct QuestionOption: Identifiable {
    var id: Int { value }
    let value: Int
    let text: String
}

// MARK: - Mappers
extension ConstitutionTestResult {
    init(from dto: ConstitutionTestResultDTO) {
        self.id = dto.resultId
        self.primaryConstitution = ConstitutionDetail(from: dto.primaryConstitution)
        self.secondaryConstitution = dto.secondaryConstitution.map { ConstitutionDetail(from: $0) }
        self.allScores = dto.allScores.map { ConstitutionScore(type: ConstitutionType(rawValue: $0.type) ?? .balanced, score: $0.score) }
        self.recommendations = ConstitutionRecommendations(
            diet: dto.recommendations.diet,
            living: dto.recommendations.living,
            exercise: dto.recommendations.exercise,
            emotion: dto.recommendations.emotion
        )
        self.testedAt = Date(iso8601String: dto.testedAt) ?? Date()
    }
}

extension ConstitutionDetail {
    init(from dto: ConstitutionDetailDTO) {
        self.type = ConstitutionType(rawValue: dto.type) ?? .balanced
        self.score = dto.score
        self.description = dto.description
        self.characteristics = dto.characteristics
        self.causes = dto.causes
        self.healthRisks = dto.healthRisks
    }
}

