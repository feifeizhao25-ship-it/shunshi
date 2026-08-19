import Foundation

// MARK: - Weather Data
struct WeatherData: Codable {
    let temperature: Int
    let feelsLike: Int
    let humidity: Int
    let description: String
    let icon: String
    let windDirection: String
    let windScale: String
    let updateTime: Date
    
    var code: Int { Int(icon) ?? 100 }
    
    var temperatureDisplay: String { "\(temperature)°" }
    var feelsLikeDisplay: String { "体感 \(feelsLike)°" }
    var humidityDisplay: String { "湿度 \(humidity)%" }
    
    // 根据天气给出养生建议
    var wellnessAdvice: String {
        switch temperature {
        case ..<0: return "天气严寒，注意保暖防冻，可适当进补温热食物"
        case 0..<10: return "天气寒冷，注意添衣保暖，适宜温补养生"
        case 10..<20: return "天气凉爽，适合户外运动，注意早晚温差"
        case 20..<30: return "天气舒适，适宜各种养生活动"
        default: return "天气炎热，注意防暑降温，多饮清凉饮品"
        }
    }
    static let `default` = WeatherData(
        temperature: 20,
        feelsLike: 20,
        humidity: 50,
        description: "晴",
        icon: "100",
        windDirection: "南风",
        windScale: "2级",
        updateTime: Date()
    )
}

// MARK: - Living Index (生活指数)
struct LivingIndex: Codable, Identifiable {
    var id: String { type }
    let type: String
    let name: String
    let level: String
    let category: String
    let text: String
    
    var icon: String {
        switch type {
        case "1": return "figure.run"      // 运动指数
        case "3": return "tshirt"          // 穿衣指数
        case "5": return "sun.max"         // 紫外线指数
        case "9": return "allergens"       // 过敏指数
        case "16": return "sun.max.fill"   // 防晒指数
        default: return "info.circle"
        }
    }
}

// MARK: - QWeather Response Models
struct QWeatherResponse: Codable {
    let code: String
    let updateTime: String
    let now: QWeatherNow
}

struct QWeatherNow: Codable {
    let temp: String
    let feelsLike: String
    let icon: String
    let text: String
    let humidity: String
    let windDir: String
    let windScale: String
}

struct QWeatherIndicesResponse: Codable {
    let code: String
    let daily: [QWeatherIndex]
}

struct QWeatherIndex: Codable {
    let type: String
    let name: String
    let level: String
    let category: String
    let text: String
}

// MARK: - Seniverse Response Models
struct SeniverseResponse: Codable {
    let results: [SeniverseResult]
}

struct SeniverseResult: Codable {
    let location: SeniverseLocation
    let now: SeniverseNow
}

struct SeniverseLocation: Codable {
    let name: String
    let country: String
}

struct SeniverseNow: Codable {
    let text: String
    let code: String
    let temperature: String
    let feels_like: String
}

