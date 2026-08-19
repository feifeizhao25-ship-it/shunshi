import Foundation
import Combine

// MARK: - Calendar View Model
@MainActor
final class CalendarViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedDate: Date = Date()
    @Published var currentMonth: Date = Date()
    @Published var solarTerms: [SolarTerm] = []
    @Published var selectedSolarTerm: SolarTerm?
    @Published var isLoading: Bool = false
    @Published var error: AppError?
    
    // MARK: - Dependencies
    private let appStateService: AppStateService
    
    private var cancellables = Set<AnyCancellable>()
    
    init(appStateService: AppStateService? = nil) {
        self.appStateService = appStateService ?? .shared
    }
    
    // MARK: - Computed Properties
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: currentMonth)
    }
    
    var daysInMonth: [Date] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
    }
    
    var firstWeekdayOfMonth: Int {
        let calendar = Calendar.current
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        return calendar.component(.weekday, from: firstDay) - 1
    }
    
    // MARK: - Load Data
    func loadData() async {
        isLoading = true
        error = nil
        
        // Load solar terms for the year
        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentMonth)
        
        // TODO: Fetch from API
        // For now, generate mock data
        solarTerms = generateMockSolarTerms(for: year)
        
        isLoading = false
    }
    
    // MARK: - Navigation
    func previousMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    func nextMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    func goToToday() {
        currentMonth = Date()
        selectedDate = Date()
    }
    
    // MARK: - Selection
    func selectDate(_ date: Date) {
        selectedDate = date
        selectedSolarTerm = solarTermForDate(date)
    }
    
    func solarTermForDate(_ date: Date) -> SolarTerm? {
        let calendar = Calendar.current
        return solarTerms.first { term in
            calendar.isDate(term.startDate, inSameDayAs: date)
        }
    }
    
    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    func isSelected(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    func isSolarTermDate(_ date: Date) -> Bool {
        solarTermForDate(date) != nil
    }
    
    // MARK: - Mock Data
    private func generateMockSolarTerms(for year: Int) -> [SolarTerm] {
        // Generate 24 solar terms for the year
        let solarTermNames = [
            "立春", "雨水", "惊蛰", "春分", "清明", "谷雨",
            "立夏", "小满", "芒种", "夏至", "小暑", "大暑",
            "立秋", "处暑", "白露", "秋分", "寒露", "霜降",
            "立冬", "小雪", "大雪", "冬至", "小寒", "大寒"
        ]
        
        let calendar = Calendar.current
        var terms: [SolarTerm] = []
        
        // Determine season based on index
        let seasons: [Season] = [
            .spring, .spring, .spring, .spring, .spring, .spring,
            .summer, .summer, .summer, .summer, .summer, .summer,
            .autumn, .autumn, .autumn, .autumn, .autumn, .autumn,
            .winter, .winter, .winter, .winter, .winter, .winter
        ]

        for (index, name) in solarTermNames.enumerated() {
            // Approximate dates (every ~15 days starting from Feb 4)
            let dayOffset = index * 15 + 35 // Start from Feb 4
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: calendar.date(from: DateComponents(year: year, month: 1, day: 1))!) {
                let endDate = calendar.date(byAdding: .day, value: 14, to: date)!
                let term = SolarTerm(
                    id: "term_\(year)_\(index)",
                    name: name,
                    nameEn: name,
                    namePinyin: name,
                    index: index + 1,
                    year: year,
                    season: seasons[index],
                    startDate: date,
                    endDate: endDate,
                    exactTime: nil,
                    currentDay: 1,
                    totalDays: 15,
                    daysUntilNext: 15,
                    nextSolarTerm: nil,
                    themeColor: seasons[index].color,
                    icon: "leaf",
                    backgroundImage: nil,
                    description: "\(name)是二十四节气之一",
                    sanHou: [],
                    healthPrinciple: "养生建议",
                    keywords: [],
                    yi: [],
                    ji: [],
                    poem: nil
                )
                terms.append(term)
            }
        }
        
        return terms
    }
}

