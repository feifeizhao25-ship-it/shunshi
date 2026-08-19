import Foundation
import CoreLocation

// MARK: - Weather Service
/// 天气服务 - 主：和风天气 备：心知天气
@MainActor
final class WeatherService {
    static let shared = WeatherService()
    
    var cachedWeather: WeatherData?
    var cacheTime: Date?
    
    var currentWeather: WeatherData {
        cachedWeather ?? WeatherData.default
    }
    
    private let cacheDuration: TimeInterval = 30 * 60 // 30分钟缓存
    
    enum WeatherError: LocalizedError {
        case noAPIKey
        case invalidResponse
        case networkError(Error)
        case locationNotAvailable
        case allAPIsFailed
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey: return "天气API密钥未配置"
            case .invalidResponse: return "天气数据解析失败"
            case .networkError(let error): return "网络错误: \(error.localizedDescription)"
            case .locationNotAvailable: return "无法获取位置信息"
            case .allAPIsFailed: return "所有天气API均不可用"
            }
        }
    }
    
    // MARK: - Get Weather (with failover)
    func getWeather(location: CLLocationCoordinate2D) async throws -> WeatherData {
        // Check cache
        if let cached = cachedWeather, let time = cacheTime,
           Date().timeIntervalSince(time) < cacheDuration {
            return cached
        }
        
        // Try primary API (QWeather)
        do {
            let weather = try await fetchFromQWeather(location: location)
            cachedWeather = weather
            cacheTime = Date()
            return weather
        } catch {
            Logger.warning("QWeather API failed, trying backup: \(error)")
        }
        
        // Try backup API (Seniverse)
        do {
            let weather = try await fetchFromSeniverse(location: location)
            cachedWeather = weather
            cacheTime = Date()
            return weather
        } catch {
            Logger.error("All weather APIs failed")
            throw WeatherError.allAPIsFailed
        }
    }
    
    // MARK: - QWeather (和风天气)
    private func fetchFromQWeather(location: CLLocationCoordinate2D) async throws -> WeatherData {
        let apiKey = ThirdPartyAPI.Weather.QWeather.apiKey
        guard !apiKey.isEmpty else { throw WeatherError.noAPIKey }
        
        let locationStr = "\(location.longitude),\(location.latitude)"
        let urlString = "\(ThirdPartyAPI.Weather.QWeather.baseURL)/weather/now?location=\(locationStr)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else { throw WeatherError.invalidResponse }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(QWeatherResponse.self, from: data)
        
        guard response.code == "200" else { throw WeatherError.invalidResponse }
        
        return WeatherData(
            temperature: Int(response.now.temp) ?? 0,
            feelsLike: Int(response.now.feelsLike) ?? 0,
            humidity: Int(response.now.humidity) ?? 0,
            description: response.now.text,
            icon: response.now.icon,
            windDirection: response.now.windDir,
            windScale: response.now.windScale,
            updateTime: Date()
        )
    }
    
    // MARK: - Seniverse (心知天气)
    private func fetchFromSeniverse(location: CLLocationCoordinate2D) async throws -> WeatherData {
        let apiKey = ThirdPartyAPI.Weather.Seniverse.apiKey
        guard !apiKey.isEmpty else { throw WeatherError.noAPIKey }
        
        let locationStr = "\(location.latitude):\(location.longitude)"
        let urlString = "\(ThirdPartyAPI.Weather.Seniverse.baseURL)/weather/now.json?key=\(apiKey)&location=\(locationStr)&language=zh-Hans"
        
        guard let url = URL(string: urlString) else { throw WeatherError.invalidResponse }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(SeniverseResponse.self, from: data)
        
        guard let result = response.results.first else { throw WeatherError.invalidResponse }
        
        return WeatherData(
            temperature: Int(result.now.temperature) ?? 0,
            feelsLike: Int(result.now.feels_like) ?? 0,
            humidity: 0,
            description: result.now.text,
            icon: result.now.code,
            windDirection: "",
            windScale: "",
            updateTime: Date()
        )
    }
    
    // MARK: - Get Living Index (生活指数)
    func getLivingIndex(location: CLLocationCoordinate2D) async throws -> [LivingIndex] {
        let apiKey = ThirdPartyAPI.Weather.QWeather.apiKey
        guard !apiKey.isEmpty else { throw WeatherError.noAPIKey }
        
        let locationStr = "\(location.longitude),\(location.latitude)"
        // type: 1-运动,3-穿衣,5-紫外线,9-过敏,16-防晒
        let urlString = "\(ThirdPartyAPI.Weather.QWeather.baseURL)/indices/1d?type=1,3,5,9,16&location=\(locationStr)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else { throw WeatherError.invalidResponse }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(QWeatherIndicesResponse.self, from: data)
        
        return response.daily.map { index in
            LivingIndex(
                type: index.type,
                name: index.name,
                level: index.level,
                category: index.category,
                text: index.text
            )
        }
    }
}

