import Foundation

// MARK: - App Constants
enum AppConstants {
    // MARK: - App Info
    static let appName = "顺时"
    static let appNameEN = "Shunshi"
    static let bundleId = Bundle.main.bundleIdentifier ?? "com.shunshi.app"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - API
    enum API {
        #if DEBUG
        static let baseURL = "https://api-dev.shunshi.app/v1"
        #else
        static let baseURL = "https://api.shunshi.app/v1"
        #endif

        static let cdnBaseURL = "https://cdn.shunshi.app"
        static let timeout: TimeInterval = 30
        static let maxRetryCount = 3

        // ⚠️ 安全说明：LLM / 图像生成 API 的密钥不能写在客户端。
        // App 二进制可被解包，任何人都能提取出来盗刷你的额度。
        // 这些调用必须经由自有后端代理，密钥只保存在服务端。
        // 下列常量此前硬编码了真实密钥（现已移除，相关密钥须全部吊销）。
        static let falBaseURL = "https://fal.run/fal-ai/fast-sdxl" // nanobanana (fast-sdxl alias) for speed and quality

        // 硅基流动 (SiliconFlow) - 主力LLM API：改为经后端代理调用
        static let siliconFlowBaseURL = "https://api.siliconflow.cn/v1"

        // OpenRouter - 备用LLM API：改为经后端代理调用
        static let openRouterBaseURL = "https://openrouter.ai/api/v1"

        // Claude API
        static let claudeApiKey = "sk-ant-api03-xxx" // Placeholder for Claude API key
        
        // 通义千问 (Qwen) API
        static let qwenApiKey = "sk-xxx" // Placeholder for Qwen API key
        
        // 文心一言 (Ernie) API
        static let ernieApiKey = "xxx" // Placeholder for Ernie API key

        // Supabase
        static let supabaseURL = "https://swacmijjwirofmussbpp.supabase.co"
        static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN3YWNtaWpqd2lyb2ZtdXNzYnBwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzU1NTc0MDYsImV4cCI6MjA1MTEzMzQwNn0.example"
    }
    
    // MARK: - Storage Keys
    enum StorageKeys {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let userId = "user_id"
        static let hasCompletedOnboarding = "has_completed_onboarding"
        static let selectedConstitution = "selected_constitution"
        static let lastSolarTermCheck = "last_solar_term_check"
        static let appTheme = "app_theme"
        static let notificationsEnabled = "notifications_enabled"
        static let morningReminderTime = "morning_reminder_time"
        static let eveningReminderTime = "evening_reminder_time"
    }
    
    // MARK: - Keychain
    enum Keychain {
        static let service = "com.shunshi.app.keychain"
        static let accessGroup: String? = nil
    }
    
    // MARK: - Cache
    enum Cache {
        static let solarTermCacheDuration: TimeInterval = 60 * 60 * 24 // 24 hours
        static let recipeCacheDuration: TimeInterval = 60 * 60 * 6 // 6 hours
        static let maxCacheSize: Int = 50 * 1024 * 1024 // 50MB
    }
    
    // MARK: - Pagination
    enum Pagination {
        static let defaultPageSize = 20
        static let maxPageSize = 50
    }
    
    // MARK: - Validation
    enum Validation {
        static let phoneRegex = "^1[3-9]\\d{9}$"
        static let smsCodeLength = 6
        static let nicknameMinLength = 2
        static let nicknameMaxLength = 20
    }
    
    // MARK: - Analytics
    enum Analytics {
        static let sessionTimeout: TimeInterval = 30 * 60 // 30 minutes
    }
    
    // MARK: - Feature Flags
    enum Features {
        static let aiConsultantEnabled = true
        static let socialFeaturesEnabled = false
        static let premiumFeaturesEnabled = true
    }
}

// MARK: - API Endpoints
enum APIEndpoints {
    // Auth
    static let sendSMS = "/auth/sms/send"
    static let loginPhone = "/auth/login/phone"
    static let loginOAuth = "/auth/login/oauth"
    static let refreshToken = "/auth/token/refresh"
    static let logout = "/auth/logout"
    
    // User
    static let userProfile = "/user/profile"
    static let userAvatar = "/user/avatar"
    static let userPreferences = "/user/preferences"
    
    // Solar Terms
    static let solarTermsCurrent = "/solar-terms/current"
    static let solarTermsList = "/solar-terms"
    static let solarTermsCalendar = "/solar-terms/calendar"
    static func solarTermDetail(_ id: String) -> String { "/solar-terms/\(id)" }
    
    // Wellness
    static let wellnessOverview = "/wellness/overview"
    static let dietIngredients = "/wellness/diet/ingredients"
    static let dietRecipes = "/wellness/diet/recipes"
    static let dietTeas = "/wellness/diet/teas"
    static let livingRecommendations = "/wellness/living/recommendations"
    static let exerciseRecommendations = "/wellness/exercise/recommendations"
    static let acupoints = "/wellness/acupoints"
    static let emotionRecommendations = "/wellness/emotion/recommendations"
    
    // Constitution
    static let constitutionQuestionnaire = "/constitution/questionnaire"
    static let constitutionSubmit = "/constitution/submit"
    
    // Consultant
    static let consultantSessions = "/consultant/sessions"
    static func consultantMessages(_ sessionId: String) -> String { "/consultant/sessions/\(sessionId)/messages" }
    
    // Favorites & Records
    static let favorites = "/favorites"
    static let records = "/records"
    static let annualReport = "/records/annual-report"
    
    // Discover
    static let discoverFeatured = "/discover/featured"
    static let discoverArticles = "/discover/articles"
    
    // System
    static let systemConfig = "/system/config"
    static let feedback = "/system/feedback"
}
