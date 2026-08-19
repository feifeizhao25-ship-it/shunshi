import Foundation

// MARK: - Solar Term DTO
struct SolarTermDTO: Codable {
    let id: String
    let name: String
    let nameEn: String
    let namePinyin: String
    let index: Int
    let year: Int
    let season: String
    let startDate: String
    let endDate: String
    let exactTime: String?
    let currentDay: Int
    let totalDays: Int
    let daysUntilNext: Int
    let nextSolarTerm: SolarTermRefDTO?
    let themeColor: String
    let icon: String
    let backgroundImage: String?
    let description: String
    let sanHou: [SanHouDTO]
    let healthPrinciple: String
    let keywords: [String]
    let yi: [String]
    let ji: [String]
    let poem: PoemDTO?
    let customs: [String]?
    let wellnessAdvice: WellnessAdviceDTO?
    
    enum CodingKeys: String, CodingKey {
        case id, name, index, year, season, icon, description, keywords, yi, ji, poem, customs
        case nameEn = "name_en"
        case namePinyin = "name_pinyin"
        case startDate = "start_date"
        case endDate = "end_date"
        case exactTime = "exact_time"
        case currentDay = "current_day"
        case totalDays = "total_days"
        case daysUntilNext = "days_until_next"
        case nextSolarTerm = "next_solar_term"
        case themeColor = "theme_color"
        case backgroundImage = "background_image"
        case sanHou = "san_hou"
        case healthPrinciple = "health_principle"
        case wellnessAdvice = "wellness_advice"
    }
}

struct WellnessAdviceDTO: Codable {
    let diet: [String]
    let drink: [String]
    let living: [String]
    let exercise: [String]
    let acupoint: [String]
    let emotion: [String]
}

// MARK: - Solar Term Reference DTO
struct SolarTermRefDTO: Codable {
    let id: String
    let name: String
    let startDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case startDate = "start_date"
    }
}

// MARK: - San Hou DTO
struct SanHouDTO: Codable {
    let index: Int
    let name: String
    let description: String
    let startDay: Int
    let endDay: Int
    let isCurrent: Bool
    
    enum CodingKeys: String, CodingKey {
        case index, name, description
        case startDay = "start_day"
        case endDay = "end_day"
        case isCurrent = "is_current"
    }
}

// MARK: - Poem DTO
struct PoemDTO: Codable {
    let title: String
    let author: String
    let content: String
    let dynasty: String
}

// MARK: - Solar Term List Response
struct SolarTermListResponse: Codable {
    let solarTerms: [SolarTermDTO]
    let year: Int
    
    enum CodingKeys: String, CodingKey {
        case solarTerms = "solar_terms"
        case year
    }
}

// MARK: - Current Solar Term Response
struct CurrentSolarTermResponse: Codable {
    let solarTerm: SolarTermDTO

    enum CodingKeys: String, CodingKey {
        case solarTerm = "solar_term"
    }
}

// MARK: - Solar Term List DTO
struct SolarTermListDTO: Codable {
    let year: Int
    let items: [SolarTermSummaryDTO]
}

// MARK: - Solar Term Summary DTO
struct SolarTermSummaryDTO: Codable {
    let id: String
    let name: String
    let nameEn: String
    let index: Int
    let season: String
    let startDate: String
    let isCurrent: Bool
    let isPast: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, index, season
        case nameEn = "name_en"
        case startDate = "start_date"
        case isCurrent = "is_current"
        case isPast = "is_past"
    }
}

// MARK: - Calendar DTO
struct CalendarDTO: Codable {
    let year: Int
    let month: Int
    let days: [CalendarDayDTO]
}

// MARK: - Calendar Day DTO
struct CalendarDayDTO: Codable {
    let date: String
    let lunarDate: String
    let solarTerm: SolarTermRefDTO?
    let isSolarTermStart: Bool
    let dailyTip: String?

    enum CodingKeys: String, CodingKey {
        case date
        case lunarDate = "lunar_date"
        case solarTerm = "solar_term"
        case isSolarTermStart = "is_solar_term_start"
        case dailyTip = "daily_tip"
    }
}

