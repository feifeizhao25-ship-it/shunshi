import Foundation
@testable import shunshi

class MockSolarTermRepository: SolarTermRepositoryProtocol {
    var getCurrentSolarTermResult: SolarTerm?
    var getSolarTermListResult: [SolarTermSummary] = []
    var getSolarTermDetailResult: SolarTerm?
    var getCalendarResult: [CalendarDay] = []
    var cachedCurrentSolarTermValue: SolarTerm?
    
    var errorToThrow: Error?

    func getCurrentSolarTerm(location: String?) async throws -> SolarTerm {
        if let error = errorToThrow { throw error }
        guard let result = getCurrentSolarTermResult else {
            throw AppError.operationFailed("Mock get current solar term failed")
        }
        return result
    }

    func getSolarTermList(year: Int, season: Season?) async throws -> [SolarTermSummary] {
        if let error = errorToThrow { throw error }
        return getSolarTermListResult
    }

    func getSolarTermDetail(id: String) async throws -> SolarTerm {
        if let error = errorToThrow { throw error }
        guard let result = getSolarTermDetailResult else {
            throw AppError.operationFailed("Mock get solar term detail failed")
        }
        return result
    }

    func getCalendar(year: Int, month: Int) async throws -> [CalendarDay] {
        if let error = errorToThrow { throw error }
        return getCalendarResult
    }

    var cachedCurrentSolarTerm: SolarTerm? {
        return cachedCurrentSolarTermValue
    }
}
