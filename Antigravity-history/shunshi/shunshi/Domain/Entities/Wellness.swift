import Foundation
import SwiftUI

// MARK: - Wellness Dimension
enum WellnessDimension: String, CaseIterable, Identifiable {
    case diet = "diet"
    case living = "living"
    case exercise = "exercise"
    case emotion = "emotion"
    case acupoint = "acupoint"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .diet: return "饮食养生"
        case .living: return "起居调摄"
        case .exercise: return "运动保健"
        case .emotion: return "情志调养"
        case .acupoint: return "穴位按摩"
        }
    }
    
    var shortName: String {
        switch self {
        case .diet: return "食"
        case .living: return "息"
        case .exercise: return "动"
        case .emotion: return "情"
        case .acupoint: return "穴"
        }
    }
    
    var icon: String {
        switch self {
        case .diet: return "leaf.fill"
        case .living: return "bed.double.fill"
        case .exercise: return "figure.walk"
        case .emotion: return "heart.fill"
        case .acupoint: return "hand.point.up.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .diet: return .green
        case .living: return .blue
        case .exercise: return .orange
        case .emotion: return .pink
        case .acupoint: return .purple
        }
    }
}

// MARK: - Wellness Overview
struct WellnessOverview: Equatable {
    let solarTerm: SolarTermRef
    let constitution: ConstitutionType?
    let summary: String
    let dimensions: [WellnessDimensionInfo]
    let todayTips: [TodayTip]
}

// MARK: - Wellness Dimension Info
struct WellnessDimensionInfo: Identifiable, Equatable {
    var id: String { dimension.rawValue }
    let dimension: WellnessDimension
    let summary: String
    let recommendationCount: Int
}

// MARK: - Today Tip
struct TodayTip: Identifiable, Equatable {
    let id = UUID()
    let type: WellnessDimension
    let title: String
    let content: String
    let time: String?
}

// MARK: - Ingredient
struct Ingredient: Identifiable, Equatable {
    let id: String
    let name: String
    let nameEn: String?
    let category: IngredientCategory
    let nature: FoodNature
    let flavor: [FoodFlavor]
    let meridians: [Meridian]
    let effects: [String]
    let suitableFor: [ConstitutionType]
    let unsuitableFor: [ConstitutionType]
    let description: String
    let imageUrl: URL?
    let cookingTips: [String]
    let isRecommended: Bool
    let recommendationReason: String?
}

// MARK: - Ingredient Category
enum IngredientCategory: String, CaseIterable {
    case vegetable = "vegetable"
    case fruit = "fruit"
    case meat = "meat"
    case seafood = "seafood"
    case grain = "grain"
    case legume = "legume"
    case herb = "herb"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .vegetable: return "蔬菜"
        case .fruit: return "水果"
        case .meat: return "肉类"
        case .seafood: return "海鲜"
        case .grain: return "谷物"
        case .legume: return "豆类"
        case .herb: return "药材"
        case .other: return "其他"
        }
    }
}

// MARK: - Food Nature (食物性味)
enum FoodNature: String, CaseIterable {
    case cold = "cold"
    case cool = "cool"
    case neutral = "neutral"
    case warm = "warm"
    case hot = "hot"
    
    var displayName: String {
        switch self {
        case .cold: return "寒"
        case .cool: return "凉"
        case .neutral: return "平"
        case .warm: return "温"
        case .hot: return "热"
        }
    }
    
    var color: Color {
        switch self {
        case .cold: return .blue
        case .cool: return .cyan
        case .neutral: return .gray
        case .warm: return .orange
        case .hot: return .red
        }
    }
}

// MARK: - Food Flavor (食物味道)
enum FoodFlavor: String, CaseIterable {
    case sweet = "sweet"
    case sour = "sour"
    case bitter = "bitter"
    case pungent = "pungent"
    case salty = "salty"
    case bland = "bland"
    
    var displayName: String {
        switch self {
        case .sweet: return "甘"
        case .sour: return "酸"
        case .bitter: return "苦"
        case .pungent: return "辛"
        case .salty: return "咸"
        case .bland: return "淡"
        }
    }
}

// MARK: - Meridian (经络)
enum Meridian: String, CaseIterable {
    case lung = "lung"
    case largeIntestine = "large_intestine"
    case stomach = "stomach"
    case spleen = "spleen"
    case heart = "heart"
    case smallIntestine = "small_intestine"
    case bladder = "bladder"
    case kidney = "kidney"
    case pericardium = "pericardium"
    case tripleWarmer = "triple_warmer"
    case gallbladder = "gallbladder"
    case liver = "liver"
    
    var displayName: String {
        switch self {
        case .lung: return "肺经"
        case .largeIntestine: return "大肠经"
        case .stomach: return "胃经"
        case .spleen: return "脾经"
        case .heart: return "心经"
        case .smallIntestine: return "小肠经"
        case .bladder: return "膀胱经"
        case .kidney: return "肾经"
        case .pericardium: return "心包经"
        case .tripleWarmer: return "三焦经"
        case .gallbladder: return "胆经"
        case .liver: return "肝经"
        }
    }
}

