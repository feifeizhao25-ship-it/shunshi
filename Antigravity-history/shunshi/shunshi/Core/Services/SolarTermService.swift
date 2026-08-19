import Foundation
import Combine

// MARK: - Solar Term Service
/// 节气养生核心服务 - 管理二十四节气日历、内容、提醒等功能
final class SolarTermService: ObservableObject {
    static let shared = SolarTermService()
    
    // MARK: - 节气数据 (使用SimpleSolarTerm避免与Domain/Entities冲突)
    let solarTerms: [SimpleSolarTerm] = [
        SimpleSolarTerm(name: "立春", emoji: "🌱", startMonth: 2, startDay: 4, description: "万物复苏，宜养肝护脾"),
        SimpleSolarTerm(name: "雨水", emoji: "💧", startMonth: 2, startDay: 19, description: "春雨绵绵，宜祛湿健脾"),
        SimpleSolarTerm(name: "惊蛰", emoji: "⚡", startMonth: 3, startDay: 6, description: "春雷惊醒，宜养肝明目"),
        SimpleSolarTerm(name: "春分", emoji: "🌸", startMonth: 3, startDay: 21, description: "昼夜平衡，宜调和阴阳"),
        SimpleSolarTerm(name: "清明", emoji: "🌸", startMonth: 4, startDay: 5, description: "气清景明，宜养肝护肺"),
        SimpleSolarTerm(name: "谷雨", emoji: "🌧️", startMonth: 4, startDay: 20, description: "雨生百谷，宜健脾祛湿"),
        SimpleSolarTerm(name: "立夏", emoji: "☀️", startMonth: 5, startDay: 6, description: "万物生长，宜养心清火"),
        SimpleSolarTerm(name: "小满", emoji: "🌾", startMonth: 5, startDay: 21, description: "小得盈满，宜健脾祛湿"),
        SimpleSolarTerm(name: "芒种", emoji: "🌾", startMonth: 6, startDay: 6, description: "忙种时节，宜养心清暑"),
        SimpleSolarTerm(name: "夏至", emoji: "🌞", startMonth: 6, startDay: 21, description: "阳极阴生，宜养心护阳"),
        SimpleSolarTerm(name: "小暑", emoji: "🔥", startMonth: 7, startDay: 7, description: "暑气渐盛，宜清热祛湿"),
        SimpleSolarTerm(name: "大暑", emoji: "🌡️", startMonth: 7, startDay: 23, description: "大热当令，宜防暑祛湿"),
        SimpleSolarTerm(name: "立秋", emoji: "🍂", startMonth: 8, startDay: 8, description: "秋意初现，宜养肺润燥"),
        SimpleSolarTerm(name: "处暑", emoji: "🍂", startMonth: 8, startDay: 23, description: "暑气渐消，宜滋阴润燥"),
        SimpleSolarTerm(name: "白露", emoji: "💧", startMonth: 9, startDay: 8, description: "露凝而白，宜养肺润燥"),
        SimpleSolarTerm(name: "秋分", emoji: "🍂", startMonth: 9, startDay: 23, description: "昼夜均分，宜调和肺脾"),
        SimpleSolarTerm(name: "寒露", emoji: "🍁", startMonth: 10, startDay: 8, description: "露寒风冷，宜养阴润燥"),
        SimpleSolarTerm(name: "霜降", emoji: "❄️", startMonth: 10, startDay: 24, description: "霜降始肃，宜养肺护肝"),
        SimpleSolarTerm(name: "立冬", emoji: "❄️", startMonth: 11, startDay: 7, description: "万物收藏，宜养肾藏阳"),
        SimpleSolarTerm(name: "小雪", emoji: "🌨️", startMonth: 11, startDay: 22, description: "小雪初降，宜温补养藏"),
        SimpleSolarTerm(name: "大雪", emoji: "⛄", startMonth: 12, startDay: 7, description: "大雪纷飞，宜温补助阳"),
        SimpleSolarTerm(name: "冬至", emoji: "☃️", startMonth: 12, startDay: 22, description: "阴极阳生，宜养肾护阳"),
        SimpleSolarTerm(name: "小寒", emoji: "🥶", startMonth: 1, startDay: 6, description: "寒气渐盛，宜温肾健脾"),
        SimpleSolarTerm(name: "大寒", emoji: "🧊", startMonth: 1, startDay: 20, description: "寒极生热，宜温肾健脾")
    ]
    
    // MARK: - 当前状态
    @Published var currentSolarTerm: SimpleSolarTerm
    @Published var nextSolarTerm: SimpleSolarTerm?
    @Published var daysUntilNext: Int
    @Published var solarTermProgress: Double // 0-1 当前节气进度
    @Published var dailyFocus: String // 每日一重点
    
    // MARK: - 节气内容缓存
    @Published var solarTermContent: [String: SolarTermContent] = [:]
    
    private init() {
        let (current, next, days) = SolarTermService.calculateCurrentSolarTerm(from: solarTerms)
        self.currentSolarTerm = current
        self.nextSolarTerm = next
        self.daysUntilNext = days
        self.solarTermProgress = SolarTermService.calculateProgress(current: current)
        self.dailyFocus = SolarTermService.generateDailyFocus(for: current)
        
        // 预加载内容
        loadSolarTermContent()
    }
    
    // MARK: - 计算当前节气
    static func calculateCurrentSolarTerm(from terms: [SimpleSolarTerm]) -> (current: SimpleSolarTerm, next: SimpleSolarTerm?, days: Int) {
        let calendar = Calendar.current
        let today = Date()
        let month = calendar.component(.month, from: today)
        let day = calendar.component(.day, from: today)
        
        // 找到当前节气
        var currentTerm: SimpleSolarTerm?
        var nextTerm: SimpleSolarTerm?
        
        for (index, term) in terms.enumerated() {
            // 处理跨年情况
            let termMonth = term.startMonth
            let termDay = term.startDay
            
            if termMonth > month || (termMonth == month && termDay <= day) {
                if currentTerm == nil {
                    currentTerm = term
                    let nextIndex = (index + 1) % terms.count
                    nextTerm = terms[nextIndex]
                    
                    // 计算距离下一个节气天数
                    let nextDate = getSolarTermDate(term: nextTerm!)
                    let days = calendar.dateComponents([.day], from: today, to: nextDate).day ?? 15
                    
                    return (term, nextTerm!, days)
                }
            }
        }
        
        // 默认返回立春
        return (terms[0], terms[1], 15)
    }
    
    private static func getSolarTermDate(term: SimpleSolarTerm) -> Date {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        var components = DateComponents()
        components.year = year
        components.month = term.startMonth
        components.day = term.startDay
        return calendar.date(from: components) ?? Date()
    }
    
    private static func calculateProgress(current: SimpleSolarTerm) -> Double {
        // 简化计算：假设每个节气15天
        return 0.5
    }
    
    private static func generateDailyFocus(for term: SimpleSolarTerm) -> String {
        let calendar = Calendar.current
        let dayOfTerm = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        
        let focusPoints: [String: [String]] = [
            "小雪": ["温补肾阳", "适量运动", "早睡晚起", "防寒保暖", "润燥养阴"],
            "立冬": ["养肾藏精", "早睡晚起", "温补为主", "防寒保暖", "静心养神"]
        ]
        
        let focuses = focusPoints[term.name] ?? ["顺应时节", "调整作息", "合理饮食", "适度运动"]
        let index = (dayOfTerm - 1) % focuses.count
        return focuses[index]
    }
    
    // MARK: - 获取节气内容
    func getContent(for term: String) -> SolarTermContent {
        if let cached = solarTermContent[term] {
            return cached
        }
        let content = generateContent(for: term)
        solarTermContent[term] = content
        return content
    }
    
    private func loadSolarTermContent() {
        for term in solarTerms {
            solarTermContent[term.name] = generateContent(for: term.name)
        }
    }
    
    private func generateContent(for termName: String) -> SolarTermContent {
        return SolarTermContent(
            name: termName,
            quickOverview: getQuickOverview(for: termName),
            dietAdvice: getDietAdvice(for: termName),
            teaRecommendation: getTeaRecommendation(for: termName),
            exerciseAdvice: getExerciseAdvice(for: termName),
            acupoint: getAcupoint(for: termName),
            dailyTasks: generateDailyTasks(for: termName),
            poetry: getPoetry(for: termName),
            customs: getCustoms(for: termName)
        )
    }
    
    private func getQuickOverview(for term: String) -> String {
        let overviews: [String: String] = [
            "小雪": "小雪宜藏不宜露，早睡晚起养肾阳，温补为主忌生冷",
            "立冬": "立冬万物收藏日，养肾藏精正当时，温补御寒护阳气",
            "冬至": "冬至一阳生，养肾护阳始，饺子汤圆暖心窝"
        ]
        return overviews[term] ?? "\(term)时节，顺应天时，调整作息，合理饮食"
    }
    
    private func getDietAdvice(for term: String) -> [DietAdvice] {
        let dietMap: [String: [DietAdvice]] = [
            "小雪": [
                DietAdvice(type: .recommend, title: "羊肉萝卜汤", description: "温补肾阳，暖身驱寒"),
                DietAdvice(type: .recommend, title: "黑芝麻核桃粥", description: "补肾益精，乌发养颜"),
                DietAdvice(type: .avoid, title: "生冷寒凉", description: "如冰饮、生鱼片等")
            ],
            "立冬": [
                DietAdvice(type: .recommend, title: "当归生姜羊肉汤", description: "经典温补方"),
                DietAdvice(type: .recommend, title: "桂圆红枣茶", description: "补气养血")
            ]
        ]
        return dietMap[term] ?? [
            DietAdvice(type: .recommend, title: "温补食物", description: "如羊肉、桂圆、红枣"),
            DietAdvice(type: .avoid, title: "生冷食物", description: "避免寒凉伤胃")
        ]
    }
    
    private func getTeaRecommendation(for term: String) -> TeaAdvice {
        let teaMap: [String: TeaAdvice] = [
            "小雪": TeaAdvice(
                name: "红枣桂圆茶",
                ingredients: ["红枣5颗", "桂圆10颗", "枸杞少量"],
                benefits: "补气养血，温暖身心",
                suitableFor: ["气虚质", "阳虚质", "平和质"]
            ),
            "立冬": TeaAdvice(
                name: "桂圆红枣茶",
                ingredients: ["桂圆5颗", "红枣3颗", "生姜2片"],
                benefits: "温补气血，驱散寒意",
                suitableFor: ["气虚质", "阳虚质"]
            )
        ]
        return teaMap[term] ?? TeaAdvice(
            name: "养生茶饮",
            ingredients: ["根据体质选择"],
            benefits: "调理身体",
            suitableFor: ["平和质"]
        )
    }
    
    private func getExerciseAdvice(for term: String) -> ExerciseAdvice {
        return ExerciseAdvice(
            name: "八段锦",
            duration: "15-20分钟",
            frequency: "每天1-2次",
            benefits: "调理气血，疏通经络",
            contraindications: ["饭后1小时内不宜剧烈运动"]
        )
    }
    
    private func getAcupoint(for term: String) -> AcupointAdvice {
        let acupointMap: [String: AcupointAdvice] = [
            "小雪": AcupointAdvice(
                name: "涌泉穴",
                location: "足底前部凹陷处",
                method: "睡前用温水泡脚后，按揉5分钟",
                benefits: "补肾益精，温阳助眠"
            ),
            "立冬": AcupointAdvice(
                name: "肾俞穴",
                location: "第二腰椎棘突下旁开1.5寸",
                method: "双手搓热后按揉，或艾灸",
                benefits: "温补肾阳，强腰健肾"
            )
        ]
        return acupointMap[term] ?? AcupointAdvice(
            name: "足三里",
            location: "外膝眼下3寸，胫骨外侧",
            method: "每日按揉3-5分钟",
            benefits: "调理脾胃，增强体质"
        )
    }
    
    private func generateDailyTasks(for term: String) -> [ServiceDailyTask] {
        return [
            ServiceDailyTask(id: "1", title: "早睡打卡", description: "21:30前入睡", points: 10, isCompleted: false),
            ServiceDailyTask(id: "2", title: "温补餐", description: "吃一顿温补的饭菜", points: 10, isCompleted: false),
            ServiceDailyTask(id: "3", title: "穴位按摩", description: "按摩今日推荐穴位", points: 5, isCompleted: false),
            ServiceDailyTask(id: "4", title: "养生茶", description: "喝一杯节气养生茶", points: 5, isCompleted: false),
            ServiceDailyTask(id: "5", title: "运动", description: "完成15分钟养生运动", points: 10, isCompleted: false)
        ]
    }
    
    private func getPoetry(for term: String) -> [Poetry] {
        let poetryMap: [String: [Poetry]] = [
            "小雪": [
                Poetry(title: "小雪", author: "戴叔伦", content: "花雪随风不厌看，更多还肯失林峦。", dynasty: "唐")
            ],
            "冬至": [
                Poetry(title: "冬至", author: "杜甫", content: "天时人事日相催，冬至阳生春又来。", dynasty: "唐")
            ]
        ]
        return poetryMap[term] ?? [
            Poetry(title: "\(term)", author: "养生古语", content: "顺应四时，养生之道也。", dynasty: "现代")
        ]
    }
    
    private func getCustoms(for term: String) -> [Custom] {
        let customsMap: [String: [Custom]] = [
            "小雪": [
                Custom(title: "腌腊肉", description: "民间有小雪腌菜、大雪腌肉的习俗"),
                Custom(title: "吃糍粑", description: "南方地区有小雪吃糍粑的习俗")
            ],
            "冬至": [
                Custom(title: "吃饺子", description: "北方地区有冬至吃饺子的习俗"),
                Custom(title: "吃汤圆", description: "南方地区有冬至吃汤圆的习俗")
            ]
        ]
        return customsMap[term] ?? [Custom(title: "顺时养生", description: "顺应节气变化，调整生活方式")]
    }
    
    func getHistoricalReview() -> [HistoricalRecord] {
        return [
            HistoricalRecord(term: "立冬", date: "2024-11-07", completedTasks: 15, streakDays: 7),
            HistoricalRecord(term: "霜降", date: "2024-10-23", completedTasks: 18, streakDays: 14)
        ]
    }
    
    func shouldSendReminder(for term: String, daysBefore: Int, settings: SolarTermReminderSettings) -> Bool {
        switch daysBefore {
        case 3: return settings.preheat3Days
        case 1: return settings.preheat1Day
        case 0: return settings.onDay
        default: return false
        }
    }
}

// MARK: - Simplified Solar Term Model (internal use only - avoids conflict with Domain/Entities.SolarTerm)
struct SimpleSolarTerm {
    let name: String
    let emoji: String
    let startMonth: Int
    let startDay: Int
    let description: String
    
    var message: String { description }
}

// MARK: - Solar Term Content
struct SolarTermContent {
    let name: String
    let quickOverview: String
    let dietAdvice: [DietAdvice]
    let teaRecommendation: TeaAdvice
    let exerciseAdvice: ExerciseAdvice
    let acupoint: AcupointAdvice
    let dailyTasks: [ServiceDailyTask]
    let poetry: [Poetry]
    let customs: [Custom]
    var isPremium: Bool = false
}

// MARK: - Supporting Types
struct DietAdvice: Identifiable {
    let id = UUID()
    let type: AdviceType
    let title: String
    let description: String
    
    enum AdviceType {
        case recommend, avoid, caution
    }
}

struct TeaAdvice: Identifiable {
    let id = UUID()
    let name: String
    let ingredients: [String]
    let benefits: String
    let suitableFor: [String]
}

struct ExerciseAdvice {
    let name: String
    let duration: String
    let frequency: String
    let benefits: String
    let contraindications: [String]
}

struct AcupointAdvice {
    let name: String
    let location: String
    let method: String
    let benefits: String
}

// DailyTask 定义在 Core/TypeAliases.swift 中作为 ServiceDailyTask

struct Poetry: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let content: String
    let dynasty: String
}

struct Custom: Identifiable {
    let id = UUID()
    let title: String
    let description: String
}

struct HistoricalRecord {
    let term: String
    let date: String
    let completedTasks: Int
    let streakDays: Int
}

struct SolarTermReminderSettings {
    var preheat3Days: Bool = true
    var preheat1Day: Bool = true
    var onDay: Bool = true
    var dailyTip: Bool = true
    var summary: Bool = true
    
    var reminderTime: DateComponents {
        DateComponents(hour: 8, minute: 0)
    }
}

// MARK: - Additional Services
class SolarTermPosterService {
    static let shared = SolarTermPosterService()
    
    func generatePoster(term: String, emoji: String, userName: String, blessing: String) -> PosterData {
        return PosterData(
            backgroundColor: "#FBF9F7",
            emoji: emoji,
            term: term,
            userName: userName,
            blessing: blessing
        )
    }
}

struct PosterData {
    let backgroundColor: String
    let emoji: String
    let term: String
    let userName: String
    let blessing: String
}

class SolarTermGreetingService {
    static let shared = SolarTermGreetingService()
    
    let templates: [GreetingTemplate] = [
        GreetingTemplate(id: "1", name: "温暖关怀", text: "小雪至，寒意浓，记得添衣保暖哦~"),
        GreetingTemplate(id: "2", name: "养生提醒", text: "立冬养藏，记得早睡晚起~"),
        GreetingTemplate(id: "3", name: "温馨问候", text: "冬至大如年，愿您温暖过冬~")
    ]
    
    func generateGreeting(term: String, templateId: String) -> String? {
        templates.first { $0.id == templateId }?.text
    }
}

struct GreetingTemplate {
    let id: String
    let name: String
    let text: String
}

struct SolarTermTopic {
    let id: String
    let term: String
    let question: String
    let replyCount: Int
}

class SolarTermCommunityService {
    static let shared = SolarTermCommunityService()
    
    func getTopics(for term: String) -> [SolarTermTopic] {
        return [
            SolarTermTopic(id: "1", term: term, question: "今日\(term)，你那里是什么天气？", replyCount: 128),
            SolarTermTopic(id: "2", term: term, question: "\(term)时节，你有什么养生小妙招？", replyCount: 89),
            SolarTermTopic(id: "3", term: term, question: "\(term)吃什么？分享你的节气美食~", replyCount: 256)
        ]
    }
}
    
