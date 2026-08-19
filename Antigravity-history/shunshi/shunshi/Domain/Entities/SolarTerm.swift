import Foundation
import SwiftUI

// MARK: - Solar Term Entity
struct SolarTerm: Identifiable, Equatable {
    let id: String
    let name: String
    let nameEn: String
    let namePinyin: String
    let index: Int
    let year: Int
    let season: Season
    let startDate: Date
    let endDate: Date
    let exactTime: Date?
    let currentDay: Int
    let totalDays: Int
    let daysUntilNext: Int
    let nextSolarTerm: SolarTermRef?
    let themeColor: Color
    let icon: String
    let backgroundImage: URL?
    let description: String
    let sanHou: [SanHou]
    let healthPrinciple: String
    let keywords: [String]
    let yi: [String]
    let ji: [String]
    let poem: Poem?
    let customs: [String]
    let wellnessAdvice: WellnessAdvice?
    
    struct WellnessAdvice: Equatable {
        let diet: [String]
        let drink: [String]
        let living: [String]
        let exercise: [String]
        let acupoint: [String]
        let emotion: [String]
    }
    var progress: Double {
        guard totalDays > 0 else { return 0 }
        return Double(currentDay) / Double(totalDays)
    }
    
    var currentSanHou: SanHou? {
        sanHou.first { $0.isCurrent }
    }
    
    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }
}

// MARK: - Season
enum Season: String, CaseIterable {
    case spring = "spring"
    case summer = "summer"
    case autumn = "autumn"
    case winter = "winter"
    
    var displayName: String {
        switch self {
        case .spring: return "春"
        case .summer: return "夏"
        case .autumn: return "秋"
        case .winter: return "冬"
        }
    }
    
    var color: Color {
        switch self {
        case .spring: return .green
        case .summer: return .red
        case .autumn: return .orange
        case .winter: return .blue
        }
    }
}

// MARK: - Solar Term Reference
struct SolarTermRef: Identifiable, Equatable {
    let id: String
    let name: String
    let startDate: Date?
}

// MARK: - San Hou (三候)
struct SanHou: Identifiable, Equatable {
    var id: Int { index }
    let index: Int
    let name: String
    let description: String
    let startDay: Int
    let endDay: Int
    let isCurrent: Bool
}

// MARK: - Poem
struct Poem: Equatable {
    let title: String
    let author: String
    let content: String
    let dynasty: String
    
    var fullAuthor: String {
        "[\(dynasty)] \(author)"
    }
}

// MARK: - Solar Term Summary
struct SolarTermSummary: Identifiable, Equatable {
    let id: String
    let name: String
    let nameEn: String
    let index: Int
    let season: Season
    let startDate: Date
    let isCurrent: Bool
    let isPast: Bool
}

// MARK: - Solar Term Mapper
extension SolarTerm {
    init(from dto: SolarTermDTO) {
        self.id = dto.id
        self.name = dto.name
        self.nameEn = dto.nameEn
        self.namePinyin = dto.namePinyin
        self.index = dto.index
        self.year = dto.year
        self.season = Season(rawValue: dto.season) ?? .spring
        self.startDate = Date(iso8601String: dto.startDate) ?? Date()
        self.endDate = Date(iso8601String: dto.endDate) ?? Date()
        self.exactTime = dto.exactTime.flatMap { Date(iso8601String: $0) }
        self.currentDay = dto.currentDay
        self.totalDays = dto.totalDays
        self.daysUntilNext = dto.daysUntilNext
        self.nextSolarTerm = dto.nextSolarTerm.map {
            SolarTermRef(id: $0.id, name: $0.name, startDate: $0.startDate.flatMap { Date(iso8601String: $0) })
        }
        self.themeColor = Color(hexCode: dto.themeColor)
        self.icon = dto.icon
        self.backgroundImage = dto.backgroundImage.flatMap { URL(string: $0) }
        self.description = dto.description
        self.sanHou = dto.sanHou.map {
            SanHou(index: $0.index, name: $0.name, description: $0.description, startDay: $0.startDay, endDay: $0.endDay, isCurrent: $0.isCurrent)
        }
        self.healthPrinciple = dto.healthPrinciple
        self.keywords = dto.keywords
        self.yi = dto.yi
        self.ji = dto.ji
        self.poem = dto.poem.map {
            Poem(title: $0.title, author: $0.author, content: $0.content, dynasty: $0.dynasty)
        }
        self.customs = dto.customs ?? []
        self.wellnessAdvice = dto.wellnessAdvice.map {
            WellnessAdvice(
                diet: $0.diet,
                drink: $0.drink,
                living: $0.living,
                exercise: $0.exercise,
                acupoint: $0.acupoint,
                emotion: $0.emotion
            )
        }
    }

    // MARK: - Preview Data
    static let preview = SolarTerm(
        id: "daxue_2024",
        name: "大雪",
        nameEn: "Major Snow",
        namePinyin: "dàxuě",
        index: 21,
        year: 2024,
        season: .winter,
        startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 7)) ?? Date(),
        endDate: Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 21)) ?? Date(),
        exactTime: nil,
        currentDay: 5,
        totalDays: 15,
        daysUntilNext: 10,
        nextSolarTerm: SolarTermRef(id: "dongzhi_2024", name: "冬至", startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 22))),
        themeColor: Color(hexCode: "2196F3"), // Changed from .blue
        icon: "snowflake",
        backgroundImage: nil,
        description: "小雪封地，大雪封河。冬藏之气，宜养肾固精。",
        sanHou: [
            SanHou(index: 1, name: "鹖鴠不鸣", description: "寒号鸟不再鸣叫", startDay: 1, endDay: 5, isCurrent: true),
            SanHou(index: 2, name: "虎始交", description: "老虎开始交配", startDay: 6, endDay: 10, isCurrent: false),
            SanHou(index: 3, name: "荔挺出", description: "荔草开始抽出新芽", startDay: 11, endDay: 15, isCurrent: false)
        ],
        healthPrinciple: "大雪时节，阴气最盛，宜温补肾阳，早睡晚起，避寒就温。",
        keywords: ["温补", "早睡", "护腰"],
        yi: ["温补肾阳", "早睡晚起", "温水泡脚", "适量运动"],
        ji: ["大汗淋漓", "过食生冷", "熬夜", "剧烈运动"],
        poem: Poem(title: "大雪", author: "陆游", content: "大雪江南见未曾，今年方始是严凝。", dynasty: "宋"),
        customs: ["吃羊肉", "腌肉", "观赏冰灯"],
        wellnessAdvice: WellnessAdvice(
            diet: ["食补羊肉、羊肾", "多吃黑色食物如黑豆、黑木耳"],
            drink: ["姜茶暖胃", "熟普洱茶"],
            living: ["早卧晚起", "保护头、背、足部"],
            exercise: ["平缓运动如太极", "室内瑜伽"],
            acupoint: ["涌泉穴（足心）", "关元穴"],
            emotion: ["心境平和", "减少思虑"]
        )
    )
}

// Color(hex:) is defined in Design/Theme/ColorTheme.swift

