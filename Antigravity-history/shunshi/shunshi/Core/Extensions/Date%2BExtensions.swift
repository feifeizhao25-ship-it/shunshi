import Foundation

// MARK: - Date Extensions
extension Date {
    // MARK: - Components
    var year: Int { Calendar.current.component(.year, from: self) }
    var month: Int { Calendar.current.component(.month, from: self) }
    var day: Int { Calendar.current.component(.day, from: self) }
    var hour: Int { Calendar.current.component(.hour, from: self) }
    var minute: Int { Calendar.current.component(.minute, from: self) }
    var weekday: Int { Calendar.current.component(.weekday, from: self) }
    
    var age: Int {
        Calendar.current.dateComponents([.year], from: self, to: Date()).year ?? 0
    }
    
    // MARK: - Start/End of Day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) ?? self
    }
    
    // MARK: - Relative Dates
    static var today: Date { Date().startOfDay }
    static var yesterday: Date { today.addingDays(-1) }
    static var tomorrow: Date { today.addingDays(1) }
    
    // MARK: - Date Manipulation
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    func addingMonths(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
    
    func addingYears(_ years: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: years, to: self) ?? self
    }
    
    // MARK: - Comparison
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
    
    func isSameMonth(as date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.component(.year, from: self) == calendar.component(.year, from: date) &&
               calendar.component(.month, from: self) == calendar.component(.month, from: date)
    }
    
    var isToday: Bool { isSameDay(as: Date()) }
    var isYesterday: Bool { isSameDay(as: Date.yesterday) }
    var isTomorrow: Bool { isSameDay(as: Date.tomorrow) }
    var isPast: Bool { self < Date() }
    var isFuture: Bool { self > Date() }
    
    // MARK: - Days Between
    func daysBetween(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startOfDay, to: date.startOfDay)
        return components.day ?? 0
    }
}

// MARK: - Date Formatters
extension Date {
    private static let formatters: [String: DateFormatter] = {
        var cache = [String: DateFormatter]()
        return cache
    }()
    
    private static func formatter(for format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    func formatted(_ format: String) -> String {
        Self.formatter(for: format).string(from: self)
    }
    
    // MARK: - Common Formats
    var dateString: String { formatted("yyyy-MM-dd") }
    var timeString: String { formatted("HH:mm") }
    var dateTimeString: String { formatted("yyyy-MM-dd HH:mm") }
    var monthDayString: String { formatted("MM月dd日") }
    var yearMonthString: String { formatted("yyyy年MM月") }
    var chineseDateString: String { formatted("yyyy年MM月dd日") }
    var weekdayString: String {
        let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return weekdays[weekday - 1]
    }
    
    // MARK: - Relative Format
    var relativeString: String {
        if isToday {
            return "今天"
        } else if isYesterday {
            return "昨天"
        } else if isTomorrow {
            return "明天"
        } else if isSameMonth(as: Date()) {
            return monthDayString
        } else {
            return chineseDateString
        }
    }
    
    // MARK: - Lunar Calendar
    var lunarDateString: String {
        let chineseCalendar = Calendar(identifier: .chinese)
        let formatter = DateFormatter()
        formatter.calendar = chineseCalendar
        formatter.locale = Locale(identifier: "zh_CN")
        
        let month = chineseCalendar.component(.month, from: self)
        let day = chineseCalendar.component(.day, from: self)
        
        let lunarMonths = ["正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "冬月", "腊月"]
        let lunarDays = [
            "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
            "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
            "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
        ]
        
        let monthName = lunarMonths[month - 1]
        let dayName = lunarDays[day - 1]
        
        return "\(monthName)\(dayName)"
    }
}

// MARK: - ISO8601
extension Date {
    init?(iso8601String: String) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: iso8601String) {
            self = date
        } else {
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: iso8601String) {
                self = date
            } else {
                return nil
            }
        }
    }
    
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: self)
    }
}

