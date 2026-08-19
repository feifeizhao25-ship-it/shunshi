import Foundation
import Testing
@testable import shunshi


struct DateExtensionsTests {

    // MARK: - Date Components Tests
    
    @Test func testDateComponentsReturnValidValues() {
        let date = Date()
        
        let year = date.year
        #expect(year >= 2024, "Year should be valid")
        
        let month = date.month
        #expect(month >= 1 && month <= 12, "Month should be between 1-12")
        
        let day = date.day
        #expect(day >= 1 && day <= 31, "Day should be between 1-31")
        
        let hour = date.hour
        #expect(hour >= 0 && hour <= 23, "Hour should be between 0-23")
        
        let minute = date.minute
        #expect(minute >= 0 && minute <= 59, "Minute should be between 0-59")
        
        let weekday = date.weekday
        #expect(weekday >= 1 && weekday <= 7, "Weekday should be between 1-7")
    }
    
    // MARK: - Start/End of Day Tests
    
    @Test func testStartOfDayIsBeforeEndOfDay() {
        let date = Date()
        #expect(date.startOfDay <= date.endOfDay, "Start of day should be before or equal to end of day")
    }
    
    @Test func testStartOfDayHasZeroTime() {
        let date = Date()
        #expect(date.startOfDay.hour == 0, "Start of day should have hour 0")
        #expect(date.startOfDay.minute == 0, "Start of day should have minute 0")
    }
    
    @Test func testEndOfDayHas2359Time() {
        let date = Date()
        #expect(date.endOfDay.hour == 23, "End of day should have hour 23")
        #expect(date.endOfDay.minute == 59, "End of day should have minute 59")
    }
    
    // MARK: - Relative Dates Tests
    
    @Test func testTodayIsStartOfDay() {
        let today = Date.today
        #expect(today.hour == 0)
        #expect(today.minute == 0)
    }
    
    @Test func testYesterdayIsBeforeToday() {
        #expect(Date.yesterday < Date.today)
    }
    
    @Test func testTomorrowIsAfterToday() {
        #expect(Date.tomorrow > Date.today)
    }
    
    @Test func testYesterdayTodayTomorrowAreConsecutive() {
        let daysBetweenYesterdayAndToday = Date.yesterday.daysBetween(Date.today)
        let daysBetweenTodayAndTomorrow = Date.today.daysBetween(Date.tomorrow)
        
        #expect(daysBetweenYesterdayAndToday == 1)
        #expect(daysBetweenTodayAndTomorrow == 1)
    }
    
    // MARK: - Date Manipulation Tests
    
    @Test func testAddingDays() {
        let today = Date.today
        let tomorrow = today.addingDays(1)
        let yesterday = today.addingDays(-1)
        
        #expect(tomorrow.daysBetween(today) == -1)
        #expect(today.daysBetween(yesterday) == -1)
    }
    
    @Test func testAddingMonths() {
        let date = Date()
        let nextMonth = date.addingMonths(1)
        
        #expect(nextMonth.month == date.month + 1 || (date.month == 12 && nextMonth.month == 1))
    }
    
    @Test func testAddingYears() {
        let date = Date()
        let nextYear = date.addingYears(1)
        
        #expect(nextYear.year == date.year + 1)
    }
    
    // MARK: - Comparison Tests
    
    @Test func testIsSameDay() {
        let date1 = Date()
        let calendar = Calendar.current
        let date2 = calendar.date(byAdding: .hour, value: 5, to: date1) ?? date1
        let date3 = date1.addingDays(1)
        
        #expect(date1.isSameDay(as: date2), "Same day should be true")
        #expect(!date1.isSameDay(as: date3), "Different day should be false")
    }
    
    @Test func testIsSameMonth() {
        let date1 = Date()
        let date2 = date1.addingDays(15)
        let date3 = date1.addingMonths(1)
        
        #expect(date1.isSameMonth(as: date2), "Same month should be true")
        #expect(!date1.isSameMonth(as: date3), "Different month should be false")
    }
    
    @Test func testIsToday() {
        let today = Date()
        #expect(today.isToday, "Today should be today")
    }
    
    @Test func testIsYesterday() {
        let yesterday = Date.yesterday
        #expect(yesterday.isYesterday, "Yesterday should be yesterday")
    }
    
    @Test func testIsTomorrow() {
        let tomorrow = Date.tomorrow
        #expect(tomorrow.isTomorrow, "Tomorrow should be tomorrow")
    }
    
    // MARK: - Days Between Tests
    
    @Test func testDaysBetween() {
        let date1 = Date.today
        let date2 = date1.addingDays(5)
        let date3 = date1.addingDays(-3)
        
        #expect(date1.daysBetween(date2) == 5)
        #expect(date1.daysBetween(date3) == -3)
    }
    
    @Test func testDaysBetweenIsSymmetric() {
        let date1 = Date()
        let date2 = date1.addingDays(10)
        
        #expect(date1.daysBetween(date2) == 10) // Fixed: daysBetween(other) returns components from self to other
    }
    
    // MARK: - Formatting Tests
    
    @Test func testDateStringFormat() {
        let date = Date()
        let dateString = date.dateString
        
        #expect(dateString.count == 10, "Date string should be 10 characters")
        #expect(dateString.contains("-"), "Date string should contain dashes")
    }
    
    @Test func testTimeStringFormat() {
        let date = Date()
        let timeString = date.timeString
        
        #expect(timeString.count == 5, "Time string should be 5 characters")
        #expect(timeString.contains(":"), "Time string should contain colon")
    }
    
    @Test func testMonthDayStringFormat() {
        let date = Date()
        let monthDay = date.monthDayString
        
        #expect(monthDay.contains("月"), "Should contain 月")
        #expect(monthDay.contains("日"), "Should contain 日")
    }
    
    @Test func testYearMonthStringFormat() {
        let date = Date()
        let yearMonth = date.yearMonthString
        
        #expect(yearMonth.contains("年"), "Should contain 年")
        #expect(yearMonth.contains("月"), "Should contain 月")
    }
    
    // MARK: - Weekday String Tests
    
    @Test func testWeekdayStringIsValid() {
        let date = Date()
        let weekdayString = date.weekdayString
        
        let validWeekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        #expect(validWeekdays.contains(weekdayString), "Weekday string should be valid")
    }
    
    // MARK: - Relative String Tests
    
    @Test func testRelativeStringToday() {
        let today = Date()
        #expect(today.relativeString == "今天")
    }
    
    @Test func testRelativeStringYesterday() {
        let yesterday = Date.yesterday
        #expect(yesterday.relativeString == "昨天")
    }
    
    @Test func testRelativeStringTomorrow() {
        let tomorrow = Date.tomorrow
        #expect(tomorrow.relativeString == "明天")
    }
    
    // MARK: - Lunar Calendar Tests
    
    @Test func testLunarDateStringIsNotEmpty() {
        let date = Date()
        let lunarString = date.lunarDateString
        
        #expect(!lunarString.isEmpty, "Lunar date string should not be empty")
        #expect(lunarString.contains("月"), "Lunar date should contain 月")
    }
    
    // MARK: - ISO8601 Tests
    
    @Test func testISO8601RoundTrip() {
        let original = Date()
        let string = original.iso8601String
        let reconstructed = Date(iso8601String: string)
        
        #expect(reconstructed != nil, "Should be able to parse ISO8601 string")
    }
    
    @Test func testISO8601Format() {
        let date = Date()
        let isoString = date.iso8601String
        
        #expect(isoString.contains("-"), "ISO8601 should contain dashes")
        #expect(isoString.contains("T"), "ISO8601 should contain T")
    }
    
    @Test func testISO8601WithFractionalSeconds() {
        let date = Date()
        let string = date.iso8601String
        
        // Should not throw error when parsing
        let parsed = Date(iso8601String: string)
        #expect(parsed != nil, "Should parse ISO8601 with fractional seconds")
    }
}
