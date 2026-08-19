import Foundation
import SwiftUI

// MARK: - Living (起居养生)
struct LivingTip: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let timeOfDay: TimeOfDay
    let category: LivingCategory
    let benefits: [String]
    let imagePrompt: String
    var imageURL: URL?
    
    enum TimeOfDay: String, Codable, CaseIterable {
        case morning, afternoon, evening, night
        
        var displayName: String {
            switch self {
            case .morning: return "晨起"
            case .afternoon: return "午后"
            case .evening: return "傍晚"
            case .night: return "夜间"
            }
        }
        
        var icon: String {
            switch self {
            case .morning: return "sunrise.fill"
            case .afternoon: return "sun.max.fill"
            case .evening: return "sunset.fill"
            case .night: return "moon.stars.fill"
            }
        }
    }
    
    enum LivingCategory: String, Codable, CaseIterable {
        case sleep, hygiene, routine, environment
        
        var displayName: String {
            switch self {
            case .sleep: return "睡眠"
            case .hygiene: return "卫生"
            case .routine: return "作息"
            case .environment: return "环境"
            }
        }
    }
}

// MARK: - Exercise (动养)
struct ExerciseTip: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let duration: Int
    let difficulty: Difficulty
    let category: ExerciseCategory
    let steps: [String]
    let benefits: [String]
    let imagePrompt: String
    var imageURL: URL?
    
    enum Difficulty: String, Codable, CaseIterable {
        case easy, medium, hard
        
        var displayName: String {
            switch self {
            case .easy: return "简单"
            case .medium: return "中等"
            case .hard: return "进阶"
            }
        }
        
        var color: Color {
            switch self {
            case .easy: return .green
            case .medium: return .orange
            case .hard: return .red
            }
        }
    }
    
    enum ExerciseCategory: String, Codable, CaseIterable {
        case qigong, taichi, yoga, stretch, walk
        
        var displayName: String {
            switch self {
            case .qigong: return "气功"
            case .taichi: return "太极"
            case .yoga: return "瑜伽"
            case .stretch: return "拉伸"
            case .walk: return "散步"
            }
        }
        
        var icon: String {
            switch self {
            case .qigong: return "figure.mind.and.body"
            case .taichi: return "figure.cooldown"
            case .yoga: return "figure.yoga"
            case .stretch: return "figure.flexibility"
            case .walk: return "figure.walk"
            }
        }
    }
}

// Note: Acupoint is defined in WellnessRepositoryProtocol.swift
// We extend it here to add AI image prompt support
extension Acupoint {
    var imagePrompt: String {
        "Professional artistic illustration of the '\(name)' (\(pinyin)) acupoint on the '\(meridian.displayName)', traditional Chinese medical art style combined with clean modern minimalist design, ethereal ink wash elements, soft gold and turquoise highlights, clear anatomical reference, Chinese calligraphy accents, 8k resolution, high quality"
    }
}

// MARK: - Emotion (情志养生)
struct EmotionTip: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let emotion: EmotionType
    let techniques: [String]
    let affirmation: String
    let imagePrompt: String
    var imageURL: URL?
    
    enum EmotionType: String, Codable, CaseIterable {
        case joy, anger, worry, sadness, fear, calm
        
        var displayName: String {
            switch self {
            case .joy: return "喜"
            case .anger: return "怒"
            case .worry: return "思"
            case .sadness: return "悲"
            case .fear: return "恐"
            case .calm: return "平和"
            }
        }
        
        var icon: String {
            switch self {
            case .joy: return "face.smiling"
            case .anger: return "flame.fill"
            case .worry: return "brain.head.profile"
            case .sadness: return "cloud.rain.fill"
            case .fear: return "exclamationmark.triangle.fill"
            case .calm: return "leaf.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .joy: return .yellow
            case .anger: return .red
            case .worry: return .orange
            case .sadness: return .blue
            case .fear: return .purple
            case .calm: return .green
            }
        }
    }
}
