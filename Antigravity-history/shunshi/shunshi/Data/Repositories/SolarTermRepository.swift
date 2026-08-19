import Foundation

// MARK: - Solar Term Repository
final class SolarTermRepository: SolarTermRepositoryProtocol {
    static let shared = SolarTermRepository()
    
    private let apiClient: APIClientProtocol
    private let cache: CacheManager
    
    private var _cachedCurrentSolarTerm: SolarTerm?
    private var lastFetchTime: Date?
    
    init(
        apiClient: APIClientProtocol = APIClient.shared,
        cache: CacheManager = .shared
    ) {
        self.apiClient = apiClient
        self.cache = cache
    }
    
    // MARK: - Get Current Solar Term
    func getCurrentSolarTerm(location: String?) async throws -> SolarTerm {
        // Check cache
        if let cached = _cachedCurrentSolarTerm,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < AppConstants.Cache.solarTermCacheDuration {
            Logger.debug("Returning cached solar term")
            return cached
        }
        
        do {
            let endpoint = SolarTermEndpoint.current(location: location)
            let dto: SolarTermDTO = try await apiClient.request(endpoint)
            let solarTerm = SolarTerm(from: dto)
            
            // Update cache
            _cachedCurrentSolarTerm = solarTerm
            lastFetchTime = Date()
            
            return solarTerm
        } catch {
            Logger.error("Failed to fetch current solar term, using static data", error: error)
            if let staticTerm = SolarTermStaticData.getCurrentSolarTerm() {
                _cachedCurrentSolarTerm = staticTerm
                return staticTerm
            }
            throw error
        }
    }
    
    // MARK: - Get Solar Term List
    func getSolarTermList(year: Int, season: Season?) async throws -> [SolarTermSummary] {
        let cacheKey = "solar_terms_\(year)_\(season?.rawValue ?? "all")"

        // Check cache (cache DTO for Codable compatibility)
        if let cachedDTO: SolarTermListDTO = cache.get(forKey: cacheKey) {
            return cachedDTO.items.map { mapSolarTermSummary(from: $0) }
        }

        let endpoint = SolarTermEndpoint.list(year: year, season: season?.rawValue)
        let dto: SolarTermListDTO = try await apiClient.request(endpoint)

        // Save DTO to cache
        cache.set(dto, forKey: cacheKey, expiration: AppConstants.Cache.solarTermCacheDuration)

        return dto.items.map { mapSolarTermSummary(from: $0) }
    }

    private func mapSolarTermSummary(from item: SolarTermSummaryDTO) -> SolarTermSummary {
        SolarTermSummary(
            id: item.id,
            name: item.name,
            nameEn: item.nameEn,
            index: item.index,
            season: Season(rawValue: item.season) ?? .spring,
            startDate: Date(iso8601String: item.startDate) ?? Date(),
            isCurrent: item.isCurrent,
            isPast: item.isPast
        )
    }
    
    // MARK: - Get Solar Term Detail
    func getSolarTermDetail(id: String) async throws -> SolarTerm {
        let cacheKey = "solar_term_\(id)"

        // Check cache (cache DTO for Codable compatibility)
        if let cachedDTO: SolarTermDTO = cache.get(forKey: cacheKey) {
            return SolarTerm(from: cachedDTO)
        }

        let endpoint = SolarTermEndpoint.detail(id: id)
        let dto: SolarTermDTO = try await apiClient.request(endpoint)

        // Save DTO to cache
        cache.set(dto, forKey: cacheKey, expiration: AppConstants.Cache.solarTermCacheDuration)

        return SolarTerm(from: dto)
    }

    // MARK: - Get Calendar
    func getCalendar(year: Int, month: Int) async throws -> [CalendarDay] {
        let cacheKey = "calendar_\(year)_\(month)"

        // Check cache (cache DTO for Codable compatibility)
        if let cachedDTO: CalendarDTO = cache.get(forKey: cacheKey) {
            return cachedDTO.days.map { mapCalendarDay(from: $0) }
        }

        let endpoint = SolarTermEndpoint.calendar(year: year, month: month)
        let dto: CalendarDTO = try await apiClient.request(endpoint)

        // Save DTO to cache
        cache.set(dto, forKey: cacheKey, expiration: AppConstants.Cache.solarTermCacheDuration)

        return dto.days.map { mapCalendarDay(from: $0) }
    }

    private func mapCalendarDay(from day: CalendarDayDTO) -> CalendarDay {
        CalendarDay(
            date: Date(iso8601String: day.date) ?? Date(),
            lunarDate: day.lunarDate,
            solarTerm: day.solarTerm.map { SolarTermRef(id: $0.id, name: $0.name, startDate: nil) },
            isSolarTermStart: day.isSolarTermStart,
            dailyTip: day.dailyTip
        )
    }
    
    // MARK: - Cached Solar Term
    var cachedCurrentSolarTerm: SolarTerm? {
        _cachedCurrentSolarTerm
    }
}

// MARK: - Cache Manager
final class CacheManager {
    static let shared = CacheManager()
    
    private var cache = NSCache<NSString, CacheEntry>()
    
    private init() {
        cache.totalCostLimit = AppConstants.Cache.maxCacheSize
    }
    
    func set<T: Codable>(_ value: T, forKey key: String, expiration: TimeInterval) {
        let entry = CacheEntry(value: value, expirationDate: Date().addingTimeInterval(expiration))
        cache.setObject(entry, forKey: key as NSString)
    }
    
    func get<T: Codable>(forKey key: String) -> T? {
        guard let entry = cache.object(forKey: key as NSString) else { return nil }
        guard Date() < entry.expirationDate else {
            cache.removeObject(forKey: key as NSString)
            return nil
        }
        return entry.value as? T
    }
    
    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    func clearAll() {
        cache.removeAllObjects()
    }
}

// MARK: - Cache Entry
private final class CacheEntry: NSObject {
    let value: Any
    let expirationDate: Date
    
    init(value: Any, expirationDate: Date) {
        self.value = value
        self.expirationDate = expirationDate
    }
}

