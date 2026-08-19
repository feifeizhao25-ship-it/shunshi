import Foundation
import SwiftUI

// MARK: - Solar Term Static Data
struct SolarTermStaticData {
    static let solarTerms: [SolarTerm] = [
        // 2024 - 2025 Solar Terms
        createSolarTerm(id: "lichun", name: "立春", nameEn: "Start of Spring", month: 2, day: 4, index: 1, season: .spring, description: "立，始建也。春气始而建立也。"),
        createSolarTerm(id: "yushui", name: "雨水", nameEn: "Rain Water", month: 2, day: 19, index: 2, season: .spring, description: "正月中，天一生水。春始属木，然生木者必水也。"),
        createSolarTerm(id: "jingzhe", name: "惊蛰", nameEn: "Awakening of Insects", month: 3, day: 5, index: 3, season: .spring, description: "二月节，万物出乎震，震为雷，故曰惊蛰。"),
        createSolarTerm(id: "chunfen", name: "春分", nameEn: "Spring Equinox", month: 3, day: 20, index: 4, season: .spring, description: "南北半球昼夜均而寒暑平。"),
        createSolarTerm(id: "qingming", name: "清明", nameEn: "Pure Brightness", month: 4, day: 4, index: 5, season: .spring, description: "万物齐洁而清明，气清景明，万物皆显。"),
        createSolarTerm(id: "guyu", name: "谷雨", nameEn: "Grain Rain", month: 4, day: 19, index: 6, season: .spring, description: "雨生百谷，清明断雪，谷雨断霜。"),
        
        createSolarTerm(id: "lixia", name: "立夏", nameEn: "Start of Summer", month: 5, day: 5, index: 7, season: .summer, description: "万物随物化而长。夏季开始，万物生长。"),
        createSolarTerm(id: "xiaoman", name: "小满", nameEn: "Grain Budding", month: 5, day: 20, index: 8, season: .summer, description: "物至于此，毕尽而未盈。"),
        createSolarTerm(id: "mangzhong", name: "芒种", nameEn: "Grain in Ear", month: 6, day: 5, index: 9, season: .summer, description: "有芒之种谷可稼种矣。"),
        createSolarTerm(id: "xiazhi", name: "夏至", nameEn: "Summer Solstice", month: 6, day: 21, index: 10, season: .summer, description: "日北至，日长之至。"),
        createSolarTerm(id: "xiaoshu", name: "小暑", nameEn: "Minor Heat", month: 7, day: 6, index: 11, season: .summer, description: "暑，热也，就极热之中。"),
        createSolarTerm(id: "dashu", name: "大暑", nameEn: "Major Heat", month: 7, day: 22, index: 12, season: .summer, description: "暑气至极。"),
        
        createSolarTerm(id: "liqiu", name: "立秋", nameEn: "Start of Autumn", month: 8, day: 7, index: 13, season: .autumn, description: "秋感于心。始惊三伏，复觉凉意。"),
        createSolarTerm(id: "chushu", name: "处暑", nameEn: "End of Heat", month: 8, day: 23, index: 14, season: .autumn, description: "处，止也。暑气至此而止矣。"),
        createSolarTerm(id: "bailu", name: "白露", nameEn: "White Dew", month: 9, day: 7, index: 15, season: .autumn, description: "阴气渐重，凌而为露。"),
        createSolarTerm(id: "qiufen", name: "秋分", nameEn: "Autumn Equinox", month: 9, day: 22, index: 16, season: .autumn, description: "昼夜相等。秋意渐浓。"),
        createSolarTerm(id: "hanlu", name: "寒露", nameEn: "Cold Dew", month: 10, day: 8, index: 17, season: .autumn, description: "寒露已凝。秋收冬藏之始。"),
        createSolarTerm(id: "shuangjiang", name: "霜降", nameEn: "Frost's Descent", month: 10, day: 23, index: 18, season: .autumn, description: "露结为霜。寒霜初降。"),
        
        createSolarTerm(id: "lidong", name: "立冬", nameEn: "Start of Winter", month: 11, day: 7, index: 19, season: .winter, description: "冬，终也，万物收藏也。"),
        createSolarTerm(id: "xiaoxue", name: "小雪", nameEn: "Minor Snow", month: 11, day: 22, index: 20, season: .winter, description: "气寒而将雪。"),
        createSolarTerm(id: "daxue", name: "大雪", nameEn: "Major Snow", month: 12, day: 7, index: 21, season: .winter, description: "积雪深也。"),
        createSolarTerm(id: "dongzhi", name: "冬至", nameEn: "Winter Solstice", month: 12, day: 21, index: 22, season: .winter, description: "阳生之始。"),
        createSolarTerm(id: "xiaohan", name: "小寒", nameEn: "Minor Cold", month: 1, day: 5, index: 23, season: .winter, description: "寒气尚小。"),
        createSolarTerm(id: "dahan", name: "大寒", nameEn: "Major Cold", month: 1, day: 20, index: 24, season: .winter, description: "寒气之极。")
    ]
    
    private static func createSolarTerm(id: String, name: String, nameEn: String, month: Int, day: Int, index: Int, season: Season, description: String) -> SolarTerm {
        // Simple mock for demonstration
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let startDate = calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
        let endDate = calendar.date(byAdding: .day, value: 14, to: startDate) ?? Date()
        
        return SolarTerm(
            id: id,
            name: name,
            nameEn: nameEn,
            namePinyin: "",
            index: index,
            year: year,
            season: season,
            startDate: startDate,
            endDate: endDate,
            exactTime: nil,
            currentDay: 1,
            totalDays: 15,
            daysUntilNext: 15,
            nextSolarTerm: nil,
            themeColor: season.color,
            icon: getIcon(for: id),
            backgroundImage: nil,
            description: description,
            sanHou: id == "daxue" ? [
                SanHou(index: 1, name: "鹖鴠不鸣", description: "寒号鸟不再鸣叫", startDay: 1, endDay: 5, isCurrent: true),
                SanHou(index: 2, name: "虎始交", description: "老虎开始交配", startDay: 6, endDay: 10, isCurrent: false),
                SanHou(index: 3, name: "荔挺出", description: "荔草开始抽出新芽", startDay: 11, endDay: 15, isCurrent: false)
            ] : [],
            healthPrinciple: "大雪时节，阴气最盛，宜温补肾阳，早睡晚起，避寒就温。",
            keywords: ["温补", "早睡", "护腰"],
            yi: ["温补肾阳", "早睡晚起", "温水泡脚", "适量运动"],
            ji: ["大汗淋漓", "过食生冷", "熬夜", "剧烈运动"],
            poem: id == "daxue" ? Poem(title: "大雪", author: "陆游", content: "大雪江南见未曾，今年方始是严凝。劳薪未暖烟先集，短檠无光灯欲凝。", dynasty: "宋") : nil,
            customs: id == "daxue" ? ["吃羊肉", "腌肉", "观赏冰灯", "滑冰"] : ["传统习俗活动"],
            wellnessAdvice: generateDefaultWellnessAdvice(for: id)
        )
    }
    
    private static func generateDefaultWellnessAdvice(for id: String) -> SolarTerm.WellnessAdvice {
        // Sample data that varies slightly by id
        return SolarTerm.WellnessAdvice(
            diet: ["当季时令食材", "清淡易消化"],
            drink: ["温开水", "适合本节气的茶饮"],
            living: ["规律作息", "注意环境通风"],
            exercise: ["适度拉伸", "散步"],
            acupoint: ["足三里", "合谷穴"],
            emotion: ["保持心情舒畅", "适度放松"]
        )
    }
    
    private static func getIcon(for id: String) -> String {
        switch id {
        case "lichun": return "leaf"
        case "yushui": return "cloud.rain"
        case "jingzhe": return "bolt"
        case "chunfen": return "sun.max"
        case "qingming": return "wind"
        case "guyu": return "drop"
        case "lixia": return "sun.and.horizon"
        case "xiaoman": return "cloud.sun"
        case "mangzhong": return "flame"
        case "xiazhi": return "sun.max.fill"
        case "xiaoshu": return "thermometer.sun"
        case "dashu": return "thermometer.high"
        case "liqiu": return "leaf.arrow.triangle.circlepath"
        case "chushu": return "cloud.sun.fill"
        case "bailu": return "sparkles"
        case "qiufen": return "equal"
        case "hanlu": return "thermometer.snowflake"
        case "shuangjiang": return "snowflake"
        case "lidong": return "mountain.2"
        case "xiaoxue": return "cloud.snow"
        case "daxue": return "snowflake"
        case "dongzhi": return "moon.stars"
        case "xiaohan": return "thermometer.low"
        case "dahan": return "thermometer.snowflake"
        default: return "sun.max"
        }
    }
    
    static func getCurrentSolarTerm() -> SolarTerm? {
        let now = Date()
        let calendar = Calendar.current
        
        // Sort by date to find the current one
        let sorted = solarTerms.sorted { $0.startDate < $1.startDate }
        
        // Find the last one that started before now
        for (i, term) in sorted.enumerated() {
            let nextTerm = (i + 1 < sorted.count) ? sorted[i+1] : nil
            
            if now >= term.startDate && (nextTerm == nil || now < nextTerm!.startDate) {
                // Found it!
                // Update dynamic fields
                let currentDay = calendar.dateComponents([.day], from: term.startDate, to: now).day ?? 0
                let totalDays = calendar.dateComponents([.day], from: term.startDate, to: term.endDate).day ?? 15
                let daysUntilNext = nextTerm != nil ? calendar.dateComponents([.day], from: now, to: nextTerm!.startDate).day ?? 0 : 0
                
                return SolarTerm(
                    id: term.id,
                    name: term.name,
                    nameEn: term.nameEn,
                    namePinyin: term.namePinyin,
                    index: term.index,
                    year: term.year,
                    season: term.season,
                    startDate: term.startDate,
                    endDate: term.endDate,
                    exactTime: term.exactTime,
                    currentDay: currentDay + 1,
                    totalDays: totalDays,
                    daysUntilNext: daysUntilNext,
                    nextSolarTerm: nextTerm.map { SolarTermRef(id: $0.id, name: $0.name, startDate: $0.startDate) },
                    themeColor: term.themeColor,
                    icon: term.icon,
                    backgroundImage: term.backgroundImage,
                    description: term.description,
                    sanHou: term.sanHou,
                    healthPrinciple: term.healthPrinciple,
                    keywords: term.keywords,
                    yi: term.yi,
                    ji: term.ji,
                    poem: term.poem,
                    customs: term.customs,
                    wellnessAdvice: term.wellnessAdvice
                )
            }
        }
        
        // If not found (e.g. before Lichun or after Dahan), return the closest one
        return sorted.last
    }
}
