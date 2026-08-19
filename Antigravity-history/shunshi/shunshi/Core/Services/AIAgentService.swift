import Foundation
import SwiftUI

// MARK: - AIAgentService - 顺时AI核心服务
/// 基于多模型协作的养生陪伴助手系统
/// 包含：养生问答、情感陪伴、主动关怀、快捷指令等功能
/// 
/// 核心升级 (Phase A/B):
/// - RelationshipTier: 关系分层 (Free/Premium/Family)
/// - CareStatus: 照顾状态 (Stable/NeedsAttention/Escalate)
/// - FollowUp: 连续性跟进引擎
// MARK: - 辅助结构
struct AIAgentMessage {
    let role: String
    let content: String
}

// MARK: - AIAgentUserProfile removed in favor of direct String summaries

// MARK: - AIAgentServiceProtocol
protocol AIAgentServiceProtocol {
    func processUserMessage(
        message: String,
        context: inout AIAgentService.UserContext,
        sessionId: String
    ) async throws -> AIAgentService.AIResponse
}

actor AIAgentService: AIAgentServiceProtocol {
    static let shared = AIAgentService()
    
    // MARK: - 配置
    private let config = AIConfig.shared
    private let detector = AbnormalEventDetector() // Phase C Monitor
    
    // MARK: - 用户记忆（MVP简化版）
    struct UserMemory {
        var nickname: String = ""
        var ageRange: String = ""
        var constitution: String = ""
        var concerns: [String] = []
        var foodTaboos: [String] = []
        var preferences: [String: String] = [:]  // 简化的偏好存储
    }
    
    // MARK: - 关系分层 (Phase A)
    enum RelationshipTier {
        case free       // 基础照顾（行动建议）
        case premium    // 深度照顾（连续性、跟进、阶段记忆、托付结构）
        case family     // 家庭托付（家人可感知）
    }

    // MARK: - 照顾状态 (Phase A)
    enum CareStatus: String, Codable {
        case stable          // 状态稳定
        case needsAttention  // 需要关注
        case escalate        // 需要升级/异常（如医疗边界、心理危机）
    }

    // MARK: - 跟进意图 (Phase B)
    struct FollowUpIntent: Codable {
        let inDays: Int       // 几天后跟进
        let intent: String    // 跟进意图（如 sleep_check）
        let topic: String     // 跟进话题
    }

    // MARK: - 家庭成员 (Phase D)
    struct FamilyMember: Codable {
        let name: String
        let relation: String // "父亲", "母亲", "伴侣", "孩子"
        let constitution: String?
        let healthConcerns: [String]
    }
    
    // MARK: - 用户上下文

    struct UserContext {
        let userId: String
        var memory: UserMemory
        var currentSolarTerm: SolarTermInfo? // Changed from SolarTerm? to SolarTermInfo? to match existing type
        var weather: String?
        var timeOfDay: TimeOfDay
        var conversationHistory: [AIAgentMessage]
        var selectedWellnessTab: String? 
        var userProfile: String?
        var currentMood: String?
        var lastActiveTime: Date?
        var relationshipTier: RelationshipTier // Phase A: 关系分层
        var familyMembers: [FamilyMember] = [] // Phase D: 家庭成员上下文
        
        // 兼容性计算属性
        var isPremium: Bool {
            return relationshipTier == .premium || relationshipTier == .family
        }
        

        // 兼容旧代码的初始化构造器
        init(
            userId: String,
            constitution: String? = nil,
            currentSolarTerm: String? = nil,
            selectedWellnessTab: String? = nil,
            conversationHistory: [AIAgentMessage] = [],
            userProfile: String? = nil,
            currentMood: String? = nil,
            lastActiveTime: Date? = nil,
            isPremium: Bool = false, // 兼容旧参数
            relationshipTier: RelationshipTier? = nil // 新参数优先
        ) {
            self.userId = userId
            self.memory = UserMemory(
                constitution: constitution ?? "",
                concerns: [],
                foodTaboos: [],
                preferences: [:]
            )
            self.conversationHistory = conversationHistory
            self.userProfile = userProfile
            self.currentSolarTerm = nil 
            self.weather = nil
            self.timeOfDay = .current
            self.timeOfDay = .current
            
            if let tier = relationshipTier {
                self.relationshipTier = tier
            } else {
                self.relationshipTier = isPremium ? .premium : .free
            }
        }
    }
    
    // MARK: - 意图类型
    enum IntentType: String {
        // 养生咨询类
        case solarTerm = "SOLAR_TERM"           // 节气养生
        case constitution = "CONSTITUTION"      // 体质调理
        case foodTherapy = "FOOD_THERAPY"       // 食疗饮食
        case tea = "TEA"                         // 茶饮调理
        case acupoint = "ACUPOINT"               // 穴位保健
        case exercise = "EXERCISE"               // 运动功法
        case sleep = "SLEEP"                     // 睡眠调理
        case emotion = "EMOTION"                 // 情志调养
        
        // 情感陪伴类
        case chat = "CHAT"                       // 日常闲聊
        case vent = "VENT"                       // 情绪倾诉
        case share = "SHARE"                     // 生活分享
        case encourage = "ENCOURAGE"             // 寻求鼓励
        
        // 功能操作类
        case checkIn = "CHECK_IN"                // 打卡操作
        case query = "QUERY"                     // 查询记录
        case setting = "SETTING"                 // 设置修改
        case quickCommand = "QUICK_COMMAND"      // 快捷指令
        
        // 边界触发类
        case medical = "MEDICAL"                 // 医疗咨询
        case crisis = "CRISIS"                   // 心理危机
        
        // 其他
        case help, other
        
        // 关怀系统专用
        case dailyCare = "daily_care"
        case solarTermAdvice = "solar_term_advice"
        case emotionalCompanion = "emotional_companion"
        case wellnessConsultation = "wellness_consultation"
        case constitutionGuidance = "constitution_guidance"
        case casualChat = "casual_chat"
    }
    
    // MARK: - 问答场景类型
    enum QuestionScenario {
        case instant          // 即时问答（快问快答）
        case inDepth          // 深度咨询（多轮对话）
        case contextual       // 情境问答（结合节气/天气/时间）
    }
    
    // MARK: - 情感场景
    enum EmotionalScenario: String {
        case insomnia = "insomnia"              // 失眠倾诉
        case workFatigue = "work_fatigue"        // 工作疲惫
        case moodLow = "mood_low"                // 情绪低落
        case holidayLonely = "holiday_lonely"    // 节日孤独
        case seasonalEmotion = "seasonal_emotion" // 季节性情绪波动
        case seekingEncourage = "seeking_encourage" // 寻求鼓励
    }
    
    // MARK: - AI响应
    struct AIResponse {
        let content: String
        let intent: IntentType
        let scenario: QuestionScenario?
        let cards: [ContentCard]?
        var followUpQuestions: [String]?
        let shouldFollowUp: Bool  // 是否需要追问
        let safetyLevel: SafetyLevel
        let timestamp: Date
        
        // 新增：照顾状态与跟进 (Phase A/B)
        var careStatus: CareStatus?
        var followUp: FollowUpIntent?
    }
    
    // MARK: - 内容卡片
    struct ContentCard: Identifiable {
        let id = UUID()
        let type: CardType
        let title: String
        let subtitle: String?
        let action: String?
        
        enum CardType {
            case recipe, tea, acupoint, exercise, solarTerm, constitution, weather
        }
    }
    
    // MARK: - 安全等级
    enum SafetyLevel: Int {
        case safe = 0
        case mild = 1
        case moderate = 2
        case high = 3
        case crisis = 4
    }
    
    // MARK: - 时间段
    enum TimeOfDay: String {
        case morning = "早晨"
        case noon = "中午"
        case afternoon = "下午"
        case evening = "晚上"
        case night = "深夜"
        
        static var current: TimeOfDay {
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 5..<12: return .morning
            case 12..<14: return .noon
            case 14..<18: return .afternoon
            case 18..<22: return .evening
            default: return .night
            }
        }
    }
    
    // MARK: - 节气信息
    struct SolarTermInfo {
        let name: String
        let day: Int
        let emoji: String
    }
    
    private init() {}
    
    // MARK: - 主对话接口
    func processUserMessage(
        message: String,
        context: inout UserContext,
        sessionId: String
    ) async throws -> AIResponse {
        // 1. 保存用户消息
        await ChatPersistenceService.shared.saveMessage(
            sessionId: sessionId,
            role: "user",
            content: message
        )
        
        // 2. 意图识别（带本地回退）
        let intent: IntentType
        do {
            intent = try await classifyIntent(message: message, context: context)
        } catch {
            intent = inferIntentLocally(from: message)
        }
        
        // 3. 检测心理危机
        let crisisResult = await detectCrisis(message: message)
        if crisisResult.isCrisis {
            let response = handleCrisisIntervention(context: context)
            await saveConversation(message: message, response: response, sessionId: sessionId)
            return response
        }
        
        // 5. 异常事件检测 (Phase C)
        let analysisResult = await detector.analyze(message: message, context: context)
        if analysisResult.isAbnormal {
            // 如果检测到异常，强制更新状态
            if analysisResult.riskLevel == .escalate {
               // 严重异常，直接进入危机干预流程
               let response = handleCrisisIntervention(context: context)
               await saveConversation(message: message, response: response, sessionId: sessionId)
               return response
            } else if analysisResult.riskLevel == .needsAttention {
               // 轻微异常，记录日志，并在Prompt中增加关怀
               Logger.info("检测到异常情绪: \(analysisResult.trigger ?? "")")
               // 这里可以修改context或插入特殊prompt，暂时仅记录
            }
        }
        
        // 6. 判读问答场景
        let scenario = determineScenario(message: message, intent: intent)
        
        // 7. 安全检测 (原有逻辑保留作为双重保障)
        let safetyLevel = await checkSafetyLevel(message: message)
        
        // 6. 根据意图路由（带重试机制）
        var response: AIResponse
        switch safetyLevel {
        case .high, .moderate:
            response = await handleMedicalBoundary(message: message, context: context, intent: intent)
        default:
            // 尝试调用真实AI服务，带重试
            response = await generateWithRetry(
                message: message,
                intent: intent,
                scenario: scenario,
                context: &context
            )
        }
        
        // 7. 追问机制：如果信息不足，标记需要追问
        if response.shouldFollowUp {
            let followUp = generateFollowUpQuestion(for: intent, context: context)
            response.followUpQuestions = [followUp]
        }
        
        // 8. 保存对话历史
        await saveConversation(message: message, response: response, sessionId: sessionId)
        
        return response
    }
    
    // MARK: - 带重试的AI生成
    private func generateWithRetry(
        message: String,
        intent: IntentType,
        scenario: QuestionScenario,
        context: inout UserContext,
        maxRetries: Int = 2
    ) async -> AIResponse {
        // 尝试调用AI服务，带重试
        for attempt in 0..<maxRetries {
            do {
                return try await routeAndGenerate(
                    message: message,
                    intent: intent,
                    scenario: scenario,
                    context: &context
                )
            } catch {
                Logger.warning("AI调用失败 (尝试 \(attempt + 1)/\(maxRetries)): \(error.localizedDescription)")
                
                // 等待后重试（指数退避）
                if attempt < maxRetries - 1 {
                    try? await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 1_000_000_000))
                }
            }
        }
        
        // 所有重试都失败了，使用简化版AI提示词做最后一次尝试
        do {
            return try await generateSimplifiedResponse(
                message: message,
                intent: intent,
                context: context
            )
        } catch {
            Logger.error("简化AI调用也失败了: \(error.localizedDescription)")
            // 最终回退到本地回复
            return await generateLocalFallbackResponse(
                message: message,
                intent: intent,
                context: context
            )
        }
    }
    
    // MARK: - 简化版AI回复（用于网络不佳时）
    private func generateSimplifiedResponse(
        message: String,
        intent: IntentType,
        context: UserContext
    ) async throws -> AIResponse {
        let userName = context.memory.nickname.isEmpty ? "您" : context.memory.nickname
        let solarTerm = context.currentSolarTerm?.name ?? getCurrentSolarTermInfo()?.name ?? "当前"
        
        let simplifiedPrompt = """
        你是「小顺」，一个专业的养生陪伴助手。
        
        用户：\(userName)
        节气：\(solarTerm)
        问题：\(message)
        
        请用2-3句话简短回答，要亲切温暖，用「您」称呼用户，适当用emoji。
        """
        
        let response = try await LLMService.shared.chat(
            messages: [ChatCompletionMessage(role: "user", content: simplifiedPrompt)],
            model: .qwen2_5_7B, // 使用小模型加快响应
            temperature: 0.7,
            maxTokens: 200,
            enableFallback: false // 禁用进一步回退
        )
        
        return AIResponse(
            content: response,
            intent: intent,
            scenario: .instant,
            cards: nil,
            followUpQuestions: ["还有什么想问的吗？"],
            shouldFollowUp: false,
            safetyLevel: .safe,
            timestamp: Date()
        )
    }
    
    // MARK: - 本地意图推断（当API不可用时）
    private func inferIntentLocally(from message: String) -> IntentType {
        let lowercased = message.lowercased()
        
        if lowercased.contains("吃") || lowercased.contains("食谱") || lowercased.contains("食物") || lowercased.contains("菜单") {
            return .foodTherapy
        }
        if lowercased.contains("运动") || lowercased.contains("锻炼") || lowercased.contains("跑步") || lowercased.contains("瑜伽") {
            return .exercise
        }
        if lowercased.contains("睡眠") || lowercased.contains("睡不着") || lowercased.contains("失眠") || lowercased.contains("觉") {
            return .sleep
        }
        if lowercased.contains("心情") || lowercased.contains("情绪") || lowercased.contains("难过") || lowercased.contains("开心") {
            return .emotion
        }
        if lowercased.contains("穴位") || lowercased.contains("按摩") || lowercased.contains("经络") {
            return .acupoint
        }
        if lowercased.contains("茶") || lowercased.contains("喝什么") || lowercased.contains("养生茶") {
            return .tea
        }
        if lowercased.contains("体质") || lowercased.contains("养生") || lowercased.contains("习惯") {
            return .constitution
        }
        if lowercased.contains("节气") || lowercased.contains("季节") {
            return .solarTerm
        }
        if lowercased.contains("打卡") {
            return .checkIn
        }
        if lowercased.contains("今天") && (lowercased.contains("吃") || lowercased.contains("推荐")) {
            return .quickCommand
        }
        
        return .chat
    }
    
    // MARK: - 本地回退回复（当API不可用时）
    private func generateLocalFallbackResponse(
        message: String,
        intent: IntentType,
        context: UserContext
    ) async -> AIResponse {
        let userName = context.memory.nickname.isEmpty ? "您" : context.memory.nickname
        let solarTerm = context.currentSolarTerm?.name ?? getCurrentSolarTermInfo()?.name ?? "当前"
        
        let prompt = """
        你是「小顺」，一个温暖专业的养生陪伴助手。
        
        用户称呼：\(userName)
        当前节气：\(solarTerm)
        用户问题：\(message)
        
        请用2-4句话自然回答，避免固定模板，语气亲切，适当用emoji，
        如果涉及疾病/用药，仅做温和提醒就医。
        """
        
        do {
            let response = try await LLMService.shared.chat(
                messages: [ChatCompletionMessage(role: "user", content: prompt)],
                model: .qwen2_5_7B,
                temperature: 0.7,
                maxTokens: 250
            )
            
            return AIResponse(
                content: response,
                intent: intent,
                scenario: .instant,
                cards: nil,
                followUpQuestions: ["还有什么想聊的吗？"],
                shouldFollowUp: false,
                safetyLevel: .safe,
                timestamp: Date()
            )
        } catch {
            return AIResponse(
                content: "抱歉，当前服务有点忙，等会儿再试试好吗？",
                intent: intent,
                scenario: .instant,
                cards: nil,
                followUpQuestions: [],
                shouldFollowUp: false,
                safetyLevel: .safe,
                timestamp: Date()
            )
        }
    }
    
    // MARK: - 意图分类
    private func classifyIntent(message: String, context: UserContext) async throws -> IntentType {
        let prompt = buildIntentClassificationPrompt(message: message, context: context)
        
        let messages = [
            ChatCompletionMessage(role: "system", content: prompt),
            ChatCompletionMessage(role: "user", content: message)
        ]
        
        let response = try await LLMService.shared.chat(
            messages: messages,
            model: .qwen2_5_7B,
            temperature: 0.1,
            maxTokens: 100
        )
        
        return parseIntent(from: response)
    }
    
    // MARK: - 心理危机检测
    private func detectCrisis(message: String) async -> (isCrisis: Bool, keywords: [String]) {
        let lowercased = message.lowercased()
        let crisisKeywords = [
            "自杀", "不想活", "死", "伤害自己", "绝望", 
            "没意思", "活够了", "不想醒来", "活着没意义"
        ]
        
        let detectedKeywords = crisisKeywords.filter { lowercased.contains($0) }
        return (isCrisis: !detectedKeywords.isEmpty, keywords: detectedKeywords)
    }
    
    // MARK: - 问答场景判断
    private func determineScenario(message: String, intent: IntentType) -> QuestionScenario {
        let lowercased = message.lowercased()
        
        // 即时问答关键词
        let instantKeywords = ["是什么", "怎么做", "怎么吃", "为什么", "多少", "推荐"]
        
        // 深度咨询关键词
        let depthKeywords = ["详细说说", "能具体讲讲吗", "我想了解", "能不能解释"]
        
        // 情境问答判断
        if let solarTerm = getCurrentSolarTermInfo(),
           lowercased.contains(solarTerm.name) || lowercased.contains("这个季节") {
            return .contextual
        }
        
        if depthKeywords.contains(where: { lowercased.contains($0) }) {
            return .inDepth
        }
        
        if instantKeywords.contains(where: { lowercased.contains($0) }) {
            return .instant
        }
        
        // 默认即时问答
        return .instant
    }
    
    // MARK: - 安全检测
    private func checkSafetyLevel(message: String) async -> SafetyLevel {
        let lowercased = message.lowercased()
        
        // Level 4 - 危机关键词
        let crisisKeywords = ["自杀", "不想活", "死", "伤害自己", "绝望", "没意思", "活够了"]
        if crisisKeywords.contains(where: { lowercased.contains($0) }) {
            return .crisis
        }
        
        // Level 3 - 医疗关键词
        let medicalKeywords = ["病", "疼", "痛", "症状", "药", "治疗", "化验", "体检", "诊断"]
        if medicalKeywords.contains(where: { lowercased.contains($0) }) {
            let isMedical = await confirmMedicalInquiry(message: message)
            return isMedical ? .high : .safe
        }
        
        return .safe
    }
    
    private func confirmMedicalInquiry(message: String) async -> Bool {
        let prompt = "判断以下内容是否涉及医疗咨询（疾病诊断、症状判断、用药建议）：\n\n用户输入：\(message)\n\n仅回复「是」或「否」"
        
        do {
            let response = try await LLMService.shared.chat(
                messages: [ChatCompletionMessage(role: "user", content: prompt)],
                model: .qwen2_5_7B,
                temperature: 0.1,
                maxTokens: 10
            )
            return response.contains("是")
        } catch {
            return false
        }
    }
    
    // MARK: - 路由与生成
    private func routeAndGenerate(
        message: String,
        intent: IntentType,
        scenario: QuestionScenario,
        context: inout UserContext
    ) async throws -> AIResponse {
        switch intent {
        // 快捷指令处理
        case .quickCommand:
            return await handleQuickCommand(message: message, context: &context)
            
        // 情感场景处理
        case .vent, .encourage:
            return try await handleEmotionalCompanion(message: message, intent: intent, context: &context)
            
        // 养生咨询类
        case .solarTerm, .constitution, .foodTherapy, .tea,
             .acupoint, .exercise, .sleep, .emotion:
            return try await handleWellnessConsultation(
                message: message,
                intent: intent,
                scenario: scenario,
                context: &context
            )
            
        // 功能操作类
        case .checkIn, .query, .setting:
            return await handleActionIntent(intent: intent, context: &context)
            
        // 日常闲聊
        case .chat, .share:
            return try await handleCasualChat(message: message, context: &context)
            
        default:
            return try await handleCasualChat(message: message, context: &context)
        }
    }
    
    // MARK: - 通用元数据解析 (Phase A Upgrade)
    private func parseMetadata(from response: inout String, context: UserContext) -> (CareStatus?, FollowUpIntent?) {
        guard context.isPremium,
              let metadataRange = response.range(of: "<metadata>[\\s\\S]*?</metadata>", options: .regularExpression) else {
            return (nil, nil)
        }
        
        let metadataString = String(response[metadataRange])
            .replacingOccurrences(of: "<metadata>", with: "")
            .replacingOccurrences(of: "</metadata>", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        response.removeSubrange(metadataRange)
        
        guard let data = metadataString.data(using: .utf8) else { return (nil, nil) }
        
        struct MetadataDTO: Codable {
            let care_status: String
            let follow_up: FollowUpDTO?
        }
        struct FollowUpDTO: Codable {
            let in_days: Int
            let intent: String
            let topic: String
        }
        
        if let dto = try? JSONDecoder().decode(MetadataDTO.self, from: data) {
            let careStatus = CareStatus(rawValue: dto.care_status)
            let followUp = dto.follow_up.map { FollowUpIntent(inDays: $0.in_days, intent: $0.intent, topic: $0.topic) }
            
            // Persist Care History (Phase B)
            if let status = careStatus {
                let followUpStr = followUp.map { "\($0.intent): \($0.topic)" }
                Task {
                    await CareHistoryService.shared.recordEvent(
                        userId: context.userId,
                        status: status.rawValue,
                        summary: nil, // Summary extracted from conversation if possible
                        followUpIntent: followUpStr
                    )
                }
            }
            
            return (careStatus, followUp)
        }
        
        return (nil, nil)
    }
    
    // MARK: - 元数据Prompt指令
    private func getMetadataInstruction(for context: UserContext) -> String {
        guard context.isPremium else { return "" }
        return """
        
        【高级功能输出】
        请在回答的最后，严格按照以下格式输出一段元数据（不要出现在正文中，用XML标签包裹）：
        <metadata>
        {
          "care_status": "stable" | "needs_attention" | "escalate",
          "follow_up": {
            "in_days": 1-7,
            "intent": "sleep_check" | "mood_check" | "general_check",
            "topic": "跟进的具体话题"
          }
        }
        </metadata>
        
        care_status 说明：
        - stable: 用户状态平稳、积极
        - needs_attention: 用户有轻微不适、情绪低落或需要鼓励
        - escalate: 用户提到严重症状、极度消极或涉及医疗/心理危机边界
        """
    }

    // MARK: - 养生咨询处理（标准回答模板：结论+原理+行动建议）
    private func handleWellnessConsultation(
        message: String,
        intent: IntentType,
        scenario: QuestionScenario,
        context: inout UserContext
    ) async throws -> AIResponse {
        // 检查是否需要追问获取更多信息
        let needsFollowUp = needsMoreInfo(intent: intent, context: context)
        
        // 构建养生专业Prompt
        let prompt = buildWellnessPrompt(message: message, context: context, intent: intent, scenario: scenario)
        
        // Premium User: 使用更强大的 72B 模型，获取更深度的见解
        // Free User: 使用 7B 模型，保证响应速度但深度适中
        let model: ModelType = context.isPremium ? .qwen2_5_72B : .qwen2_5_7B
        
        var rawResponse = try await LLMService.shared.chat(
            messages: [ChatCompletionMessage(role: "user", content: prompt)],
            model: model,
            temperature: context.isPremium ? 0.8 : 0.7, // 会员版更具创造性和个性化
            maxTokens: context.isPremium ? 800 : 400      // 会员版回答更详尽
        )
        
        // 解析元数据 (Phase A)
        let (careStatus, followUp) = parseMetadata(from: &rawResponse, context: context)
        
        // 优化为小顺风格（结论+原理+行动建议）
        let optimizedResponse = try await optimizeToStandardFormat(
            rawResponse: rawResponse,
            context: context,
            scenario: scenario
        )
        
        // 提取内容卡片
        let cards = extractCards(from: optimizedResponse, intent: intent)
        
        return AIResponse(
            content: optimizedResponse,
            intent: intent,
            scenario: scenario,
            cards: cards,
            followUpQuestions: nil,
            shouldFollowUp: needsFollowUp,
            safetyLevel: .safe,
            timestamp: Date(),
            careStatus: careStatus,
            followUp: followUp
        )
    }
    
    // MARK: - 情感陪伴处理
    private func handleEmotionalCompanion(
        message: String,
        intent: IntentType,
        context: inout UserContext
    ) async throws -> AIResponse {
        // 识别情感场景
        let emotionScenario = detectEmotionalScenario(message)
        
        // 构建情感陪伴Prompt
        let prompt = buildCompanionPrompt(
            message: message,
            context: context,
            scenario: emotionScenario
        )
        
        var response = try await LLMService.shared.chat(
            messages: [ChatCompletionMessage(role: "system", content: prompt)],
            model: .deepseekV3,
            temperature: 0.8,
            maxTokens: 300
        )
        
        // 解析元数据 (Phase A)
        let (careStatus, followUp) = parseMetadata(from: &response, context: context)
        
        // 检查是否有负面情绪信号
        let hasNegativeSignal = detectNegativeEmotion(message)
        
        return AIResponse(
            content: response,
            intent: intent,
            scenario: nil,
            cards: nil,
            followUpQuestions: ["愿意多聊聊吗？", "今天过得怎么样？"],
            shouldFollowUp: false,
            safetyLevel: hasNegativeSignal ? .mild : .safe,
            timestamp: Date(),
            careStatus: careStatus,
            followUp: followUp
        )
    }
    
    // MARK: - 快捷指令处理
    private func handleQuickCommand(message: String, context: inout UserContext) async -> AIResponse {
        let lowercased = message.lowercased()
        
        var intent: IntentType = .quickCommand
        var followUpQuestions: [String] = ["还想了解什么养生问题呢？"]
        
        if lowercased.contains("今天吃什么") || lowercased.contains("推荐菜谱") {
            intent = .foodTherapy
            followUpQuestions = ["想看具体做法吗？", "有忌口吗？"]
        }
        
        if lowercased.contains("睡不着") || lowercased.contains("失眠") {
            intent = .sleep
            followUpQuestions = ["最近睡眠怎么样？", "要不要试试放松小练习？"]
        }
        
        if lowercased.contains("按什么穴位") || lowercased.contains("穴位") {
            intent = .acupoint
            followUpQuestions = ["想调理什么问题？", "要不要我教你怎么找穴位？"]
        }
        
        let prompt: String
        if intent == .quickCommand {
            let userName = context.memory.nickname.isEmpty ? "您" : context.memory.nickname
            let solarTerm = context.currentSolarTerm?.name ?? getCurrentSolarTermInfo()?.name ?? "当前"
            let metadataInstruction = getMetadataInstruction(for: context)
            
            prompt = """
            你是「小顺」，一个温暖专业的养生陪伴助手。
            
            用户称呼：\(userName)
            当前节气：\(solarTerm)
            用户输入：\(message)
            
            请用2-4句话自然回答，告诉用户你能提供的帮助方向（不超过5条），
            语气亲切，不要模板化，不要编号。
            \(metadataInstruction)
            """
        } else {
            prompt = buildWellnessPrompt(message: message, context: context, intent: intent, scenario: .instant)
        }
        
        do {
            var response = try await LLMService.shared.chat(
                messages: [ChatCompletionMessage(role: "user", content: prompt)],
                model: .qwen2_5_7B,
                temperature: 0.7,
                maxTokens: 300
            )
            
            let (careStatus, followUp) = parseMetadata(from: &response, context: context)
            
            return AIResponse(
                content: response,
                intent: intent,
                scenario: .instant,
                cards: nil,
                followUpQuestions: followUpQuestions,
                shouldFollowUp: false,
                safetyLevel: .safe,
                timestamp: Date(),
                careStatus: careStatus,
                followUp: followUp
            )
        } catch {
            return await generateLocalFallbackResponse(message: message, intent: intent, context: context)
        }
    }
    
    // MARK: - 日常闲聊
    private func handleCasualChat(message: String, context: inout UserContext) async throws -> AIResponse {
        let prompt = buildCasualChatPrompt(context: context)
        
        var response = try await LLMService.shared.chat(
            messages: [
                ChatCompletionMessage(role: "system", content: prompt),
                ChatCompletionMessage(role: "user", content: message)
            ],
            model: .deepseekV3,
            temperature: 0.8,
            maxTokens: 200
        )
        
        let (careStatus, followUp) = parseMetadata(from: &response, context: context)
        
        return AIResponse(
            content: response,
            intent: .chat,
            scenario: .instant,
            cards: nil,
            followUpQuestions: ["还有想聊的吗？", "今天过得怎么样？"],
            shouldFollowUp: false,
            safetyLevel: .safe,
            timestamp: Date(),
            careStatus: careStatus,
            followUp: followUp
        )
    }
    
    // MARK: - 医疗边界处理（AI生成温柔提醒）
    private func handleMedicalBoundary(
        message: String,
        context: UserContext,
        intent: IntentType
    ) async -> AIResponse {
        let userName = context.memory.nickname.isEmpty ? "您" : context.memory.nickname
        let prompt = """
        你是「小顺」，一个温暖的养生陪伴助手。用户的问题涉及医疗边界。

        用户称呼：\(userName)
        用户输入：\(message)

        请生成2-3句中文回复：
        1. 先共情关心用户。
        2. 温和提示需要专业医生判断，避免给出诊断/用药建议。
        3. 可以邀请用户继续聊日常养生问题。
        4. 语气亲切自然，可用1个emoji。
        """

        do {
            let response = try await LLMService.shared.chat(
                messages: [ChatCompletionMessage(role: "user", content: prompt)],
                model: .qwen2_5_7B,
                temperature: 0.6,
                maxTokens: 200
            )
            let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
            return AIResponse(
                content: trimmed.isEmpty ? BoundaryResponseLibrary.randomResponse(for: intent) : trimmed,
                intent: .medical,
                scenario: nil,
                cards: nil,
                followUpQuestions: ["想了解日常养生调理吗？", "有什么养生问题可以问我"],
                shouldFollowUp: false,
                safetyLevel: .high,
                timestamp: Date()
            )
        } catch {
            return AIResponse(
                content: BoundaryResponseLibrary.randomResponse(for: intent),
                intent: .medical,
                scenario: nil,
                cards: nil,
                followUpQuestions: ["想了解日常养生调理吗？", "有什么养生问题可以问我"],
                shouldFollowUp: false,
                safetyLevel: .high,
                timestamp: Date()
            )
        }
    }
    
    // MARK: - 危机干预处理
    private func handleCrisisIntervention(context: UserContext) -> AIResponse {
        let response = """
        我注意到您说的话让我很担心您...

        您现在是不是感觉很难受？我在这里，愿意听您说说。

        无论发生什么，都有人愿意帮助您。如果您愿意，可以聊聊发生了什么吗？

        另外，如果您需要专业帮助，可以拨打心理援助热线：
        • 全国心理援助热线：400-161-9995
        • 北京心理危机干预中心：010-82951332

        我会一直陪着您的。
        """
        
        return AIResponse(
            content: response,
            intent: .crisis,
            scenario: nil,
            cards: nil,
            followUpQuestions: ["愿意聊聊吗？", "我可以帮您联系专业帮助"],
            shouldFollowUp: false,
            safetyLevel: .crisis,
            timestamp: Date()
        )
    }
    
    // MARK: - 功能操作处理
    private func handleActionIntent(intent: IntentType, context: inout UserContext) async -> AIResponse {
        let userName = context.memory.nickname.isEmpty ? "您" : context.memory.nickname
        let intentName: String
        let defaultFollowUps: [String]
        switch intent {
        case .checkIn:
            intentName = "打卡"
            defaultFollowUps = ["还有其他要打卡的吗？", "想看看您的打卡记录吗？"]
        case .query:
            intentName = "查询"
            defaultFollowUps = ["想查什么内容？"]
        case .setting:
            intentName = "设置"
            defaultFollowUps = ["还有其他要设置的吗？"]
        default:
            intentName = "操作"
            defaultFollowUps = ["还有什么需要我帮您的吗？"]
        }

        let prompt = """
        你是「小顺」，一个温暖的养生陪伴助手，正在处理用户的功能操作请求。

        用户称呼：\(userName)
        操作类型：\(intentName)

        请生成1-2句简短回复：
        1. 确认你会帮用户处理。
        2. 语气亲切自然，不要模板化。
        3. 可用1个emoji。
        """

        do {
            let response = try await LLMService.shared.chat(
                messages: [ChatCompletionMessage(role: "user", content: prompt)],
                model: .qwen2_5_7B,
                temperature: 0.6,
                maxTokens: 120
            )
            let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
            let content = trimmed.isEmpty ? "好的，我来帮您处理~" : trimmed

            return AIResponse(
                content: content,
                intent: intent,
                scenario: nil,
                cards: nil,
                followUpQuestions: defaultFollowUps,
                shouldFollowUp: false,
                safetyLevel: .safe,
                timestamp: Date()
            )
        } catch {
            return AIResponse(
                content: "好的，我来帮您处理~",
                intent: intent,
                scenario: nil,
                cards: nil,
                followUpQuestions: defaultFollowUps,
                shouldFollowUp: false,
                safetyLevel: .safe,
                timestamp: Date()
            )
        }
    }
    
    // MARK: - 响应优化为标准格式
    private func optimizeToStandardFormat(
        rawResponse: String,
        context: UserContext,
        scenario: QuestionScenario
    ) async throws -> String {
        let prompt = """
        你是「小顺」，一个温暖的养生陪伴助手。请将以下回答优化为标准格式：
        
        标准格式要求：
        1. **结论** - 开头给出直接答案（1句话）
        2. **原理解释** - 简要说明原理（1-2句话，用通俗语言）
        3. **行动建议** - 给出具体可操作的建议（3-4条）
        
        人设要求：
        - 口语化，口吻亲切
        - 句子简短，不超过50字
        - 使用语气词：呢、哦、呀、啦
        - 适当使用emoji，每句最多1个
        - 用「\(context.memory.nickname.isEmpty ? "您" : context.memory.nickname)」称呼用户
        
        原始回答：
        \(rawResponse)
        
        优化后的回答：
        """
        
        return try await LLMService.shared.chat(
            messages: [ChatCompletionMessage(role: "user", content: prompt)],
            model: .qwen2_5_7B,
            temperature: 0.8,
            maxTokens: 200
        )
    }
    
    // MARK: - 追问机制
    private func needsMoreInfo(intent: IntentType, context: UserContext) -> Bool {
        // 如果缺少关键信息，返回true表示需要追问
        switch intent {
        case .constitution:
            return context.memory.constitution.isEmpty
        case .foodTherapy:
            return context.memory.concerns.isEmpty && context.memory.foodTaboos.isEmpty
        case .sleep:
            return context.memory.preferences["sleep_time"] == nil
        default:
            return false
        }
    }
    
    private func generateFollowUpQuestion(for intent: IntentType, context: UserContext) -> String {
        switch intent {
        case .constitution:
            return "您之前做过体质测试吗？告诉我您的体质，我可以给出更针对性的建议~"
        case .foodTherapy:
            return "请问您有什么饮食禁忌或者过敏的食物吗？"
        case .sleep:
            return "您一般几点睡觉呀？睡眠质量怎么样？"
        default:
            return "您方便告诉我更多一点吗？比如您现在的体质或者最近关注什么问题~"
        }
    }
    
    // MARK: - 情感场景识别
    private func detectEmotionalScenario(_ message: String) -> EmotionalScenario {
        let lowercased = message.lowercased()
        
        if lowercased.contains("失眠") || lowercased.contains("睡不着") || lowercased.contains("睡眠") {
            return .insomnia
        }
        if lowercased.contains("累") || lowercased.contains("疲惫") || lowercased.contains("工作") {
            return .workFatigue
        }
        if lowercased.contains("难过") || lowercased.contains("心情不好") || lowercased.contains("烦") {
            return .moodLow
        }
        if lowercased.contains("鼓励") || lowercased.contains("加油") || lowercased.contains("坚持") {
            return .seekingEncourage
        }
        
        return .workFatigue // 默认
    }
    
    private func detectNegativeEmotion(_ message: String) -> Bool {
        let negativeKeywords = ["难过", "伤心", "崩溃", "焦虑", "压力大", "烦", "累", "睡不着"]
        return negativeKeywords.contains { message.contains($0) }
    }
    
    // MARK: - Prompt构建
    private func buildIntentClassificationPrompt(message: String, context: UserContext) -> String {
        return """
        # 意图分类任务

        请分析用户输入，判断其意图类型。

        ## 用户记忆信息
        - 昵称：\(context.memory.nickname.isEmpty ? "未知" : context.memory.nickname)
        - 体质：\(context.memory.constitution.isEmpty ? "未知" : context.memory.constitution)
        - 关注：\(context.memory.concerns.joined(separator: "、"))

        ## 意图分类
        养生咨询类：
        - SOLAR_TERM：节气养生
        - CONSTITUTION：体质调理
        - FOOD_THERAPY：食疗饮食
        - TEA：茶饮调理
        - ACUPOINT：穴位保健
        - EXERCISE：运动功法
        - SLEEP：睡眠调理
        - EMOTION：情志调养

        情感陪伴类：
        - CHAT：日常闲聊
        - VENT：情绪倾诉（表达负面情绪）
        - ENCOURAGE：寻求鼓励
        - SHARE：生活分享

        功能操作类：
        - CHECK_IN：打卡操作
        - QUERY：查询记录
        - SETTING：设置修改
        - QUICK_COMMAND：快捷指令

        ## 用户输入
        \(message)

        ## 输出
        仅回复意图类型（如：FOOD_THERAPY）
        """
    }
    
    private func buildWellnessPrompt(
        message: String,
        context: UserContext,
        intent: IntentType,
        scenario: QuestionScenario
    ) -> String {
        let userName = context.memory.nickname.isEmpty ? "您" : context.memory.nickname
        let solarTerm = context.currentSolarTerm?.name ?? getCurrentSolarTermInfo()?.name ?? "当前节气"
        let solarTermEmoji = context.currentSolarTerm?.emoji ?? "🌿"
        
        let scenarioInstructions: String
        switch scenario {
        case .instant:
            scenarioInstructions = "给出简洁直接的回答，1-2句话给出结论，然后3-4条具体建议"
        case .inDepth:
            scenarioInstructions = "详细解释原理，但用通俗语言，给出完整的调理方案"
        case .contextual:
            scenarioInstructions = "结合当前\(solarTerm)节气的特点给出建议"
        }
        
        // 根据意图类型给出专门指导
        let intentSpecificGuidance: String
        switch intent {
        case .foodTherapy:
            intentSpecificGuidance = "推荐具体食材，说明为什么适合，给出简单做法"
        case .acupoint:
            intentSpecificGuidance = "说明穴位位置（用简单定位法）、按摩手法和时间"
        case .exercise:
            intentSpecificGuidance = "推荐适合的运动类型、时长、注意事项"
        case .sleep:
            intentSpecificGuidance = "分析可能原因，给出睡前准备、助眠方法"
        case .emotion:
            intentSpecificGuidance = "先共情理解，再给调节情绪的方法"
        case .tea:
            intentSpecificGuidance = "推荐具体茶饮，说明功效，给出冲泡方法"
        case .constitution:
            intentSpecificGuidance = "解释体质特点，给出日常养生建议"
        case .solarTerm:
            intentSpecificGuidance = "说明\(solarTerm)的养生重点，给出具体建议"
        default:
            intentSpecificGuidance = "给出专业、实用的养生建议"
        }
        
        // 差异化 Prompt 构建 (Phase A Upgrade)
        let relationshipContext: String
        let metadataInstruction: String
        
        switch context.relationshipTier {
        case .free:
            relationshipContext = "你的角色是「AI养生助手」。给出简洁、可行动的建议。"
            metadataInstruction = ""
        case .premium:
            relationshipContext = "你的角色是「高级私人养生顾问」。你需要提供「深度照顾」，不仅回答问题，还要关注用户的长期状态、建立信任感、体现安全边界。\n对于需要持续关注的问题（如失眠、情绪），请主动规划后续跟进。"
            metadataInstruction = getMetadataInstruction(for: context)
        case .family:
            relationshipContext = "你的角色是「家庭养生管家」。你不仅关注用户的个人健康，还需考虑其作为家庭成员（长辈、伴侣或父母）的角色。在建议中适当融入家庭关怀（如：这也适合做给父母吃、带孩子一起做）。保持「深度照顾」的高标准，关注长期状态。"
            metadataInstruction = getMetadataInstruction(for: context)
        }
        

        
        // 获取家庭上下文 (Phase D)
        let familyContext = getFamilyContextString(for: context)
        
        return """
        \(relationshipContext)
        你是「小顺」，一个温暖专业的养生陪伴助手，正在和用户「\(userName)」对话。
        \(familyContext)

        【当前情境】
        节气：\(solarTerm) \(solarTermEmoji)
        时间：\(context.timeOfDay.rawValue)
        用户体质：\(context.memory.constitution.isEmpty ? "暂未了解" : context.memory.constitution)
        \(!context.memory.foodTaboos.isEmpty ? "饮食禁忌：\(context.memory.foodTaboos.joined(separator: "、"))" : "")

        【用户问题】
        \(message)

        【回答要求】
        1. 用「\(userName)」称呼用户，语气亲切自然，像朋友聊天
        2. \(scenarioInstructions)
        3. \(intentSpecificGuidance)
        4. 适当用emoji增加亲和力，但不要过多
        5. 句子简短，每句话不超过30个字
        6. 用口语化表达，避免太学术的术语
        7. 结尾可以问问用户还有没有其他问题
        \(metadataInstruction)

        请直接给出自然流畅的回答：
        """
    }
    
    private func buildCompanionPrompt(
        message: String,
        context: UserContext,
        scenario: EmotionalScenario
    ) -> String {
        let userName = context.memory.nickname.isEmpty ? "您" : context.memory.nickname
        
        let scenarioGuidance: String
        switch scenario {
        case .insomnia:
            scenarioGuidance = "用户失眠了，先理解失眠的痛苦，再给一些助眠小方法，语气要温柔"
        case .workFatigue:
            scenarioGuidance = "用户工作很累，表达理解和心疼，分享缓解疲劳的方法"
        case .moodLow:
            scenarioGuidance = "用户情绪低落，重点是倾听和陪伴，让用户感觉被理解"
        case .holidayLonely:
            scenarioGuidance = "用户可能感到孤独，表达陪伴和温暖"
        case .seasonalEmotion:
            scenarioGuidance = "季节性情绪波动，结合节气给予关怀"
        case .seekingEncourage:
            scenarioGuidance = "用户需要鼓励，给予真诚的肯定和支持"
        }
        
        return """
        你是「小顺」，一个温暖贴心的养生陪伴助手。正在和用户「\(userName)」聊天。

        【场景】\(scenarioGuidance)

        【你的风格】
        - 像知心朋友一样聊天，自然亲切
        - 多用语气词：呢、哦、呀、啦
        - 句子简短，每句话不超过20字
        - 适当用emoji，但不要过多
        - 先共情理解，再给建议

        【用户说的话】
        \(message)

        请像朋友一样自然地回复：
        """
    }
    
    private func buildCasualChatPrompt(context: UserContext) -> String {
        return """
        # 小顺角色

        你是「小顺」，一个懂中医养生、有人情温度的AI朋友。

        ## 基本信息
        - 你是养生陪伴助手，不是医生
        - 用户昵称：\(context.memory.nickname.isEmpty ? "您" : context.memory.nickname)
        - 用户体质：\(context.memory.constitution.isEmpty ? "未知" : context.memory.constitution)

        ## 说话风格
        - 口语化，口吻亲切
        - 句子简短
        - 善用语气词
        - 适当用emoji
        - 用「\(context.memory.nickname.isEmpty ? "您" : context.memory.nickname)」称呼用户

        ## 你能做什么
        - 聊养生话题
        - 日常聊天、陪伴
        - 倾听和支持

        ## 你不能做什么
        - 不诊断疾病
        - 不推荐药物
        - 不做医疗建议

        请自然回应用户，保持小顺的人设风格。
        """
    }
    
    // MARK: - Helper: Build Family Context String
    private func getFamilyContextString(for context: UserContext) -> String {
        guard context.relationshipTier == .family, !context.familyMembers.isEmpty else {
            return ""
        }
        
        var familyInfo = "\n【家庭成员概况】\n"
        for member in context.familyMembers {
            familyInfo += "- \(member.relation)（\(member.name)）：\(member.constitution ?? "未知体质")，关注类目：\(member.healthConcerns.joined(separator: "、"))\n"
        }
        return familyInfo
    }
    
    // MARK: - 工具方法
    private func parseIntent(from response: String) -> IntentType {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if trimmed.contains("SOLAR_TERM") { return .solarTerm }
        if trimmed.contains("CONSTITUTION") { return .constitution }
        if trimmed.contains("FOOD_THERAPY") { return .foodTherapy }
        if trimmed.contains("TEA") { return .tea }
        if trimmed.contains("ACUPOINT") { return .acupoint }
        if trimmed.contains("EXERCISE") { return .exercise }
        if trimmed.contains("SLEEP") { return .sleep }
        if trimmed.contains("EMOTION") { return .emotion }
        if trimmed.contains("CHAT") { return .chat }
        if trimmed.contains("VENT") { return .vent }
        if trimmed.contains("SHARE") { return .share }
        if trimmed.contains("ENCOURAGE") { return .encourage }
        if trimmed.contains("CHECK_IN") { return .checkIn }
        if trimmed.contains("QUERY") { return .query }
        if trimmed.contains("SETTING") { return .setting }
        if trimmed.contains("QUICK_COMMAND") { return .quickCommand }
        
        return .other
    }
    
    private func getCurrentSolarTermInfo() -> SolarTermInfo? {
        // 使用 UISolarTerm 获取真实节气信息
        let currentTerm = UISolarTerm.current
        let emoji = getSolarTermEmoji(for: currentTerm.name)
        
        // 计算节气已过天数
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        var termDateComponents = DateComponents()
        termDateComponents.year = year
        termDateComponents.month = currentTerm.month
        termDateComponents.day = currentTerm.day
        
        let termDate = calendar.date(from: termDateComponents) ?? now
        let daysPassed = calendar.dateComponents([.day], from: termDate, to: now).day ?? 1
        
        return SolarTermInfo(name: currentTerm.name, day: max(1, daysPassed), emoji: emoji)
    }
    
    private func getSolarTermEmoji(for termName: String) -> String {
        let emojiMap: [String: String] = [
            "立春": "🌱", "雨水": "💧", "惊蛰": "⚡", "春分": "🌸",
            "清明": "🌿", "谷雨": "🌧️", "立夏": "🌳", "小满": "🌾",
            "芒种": "🌻", "夏至": "☀️", "小暑": "🔥", "大暑": "🌋",
            "立秋": "🍂", "处暑": "🌤️", "白露": "💨", "秋分": "🍁",
            "寒露": "❄️", "霜降": "🧊", "立冬": "🌨️", "小雪": "❄️",
            "大雪": "⛄", "冬至": "🌙", "小寒": "🧣", "大寒": "❄️"
        ]
        return emojiMap[termName] ?? "🌸"
    }
    
    private func extractCards(from response: String, intent: IntentType) -> [ContentCard]? {
        // 简单解析内容卡片
        return nil
    }
    
    private func saveConversation(message: String, response: AIResponse, sessionId: String) async {
        await ChatPersistenceService.shared.saveMessage(
            sessionId: sessionId,
            role: "assistant",
            content: response.content,
            suggestions: response.followUpQuestions
        )
    }


// MARK: - 边界话术库
enum BoundaryResponseLibrary {
    private static let responses: [String: [String]] = [
        "general": [
            "听起来您有些担心呢，这个问题涉及医学诊断，建议您咨询专业医生哦~",
            "身体不舒服还是要及时就医呢，让我从日常养生角度分享一些调理建议给您参考~",
            "这个问题我不太擅长判断，建议您去医院看看医生呢。平时可以注意..."
        ],
        "medication": [
            "用药方面我没办法给建议呢，每个人的情况不同，一定要咨询医生或药师哦~",
            "药物使用需要专业指导，您一定要问过医生再用哦~"
        ],
        "diagnosis": [
            "诊断疾病需要专业医生来做，我没有这个能力呢。建议您尽快就医检查~",
            "这个超出我的能力范围了，我只懂一些养生知识。身体不舒服还是要看医生哦~"
        ],
        "report": [
            "体检报告的解读需要专业医学知识，建议您带着报告去找医生咨询一下~",
            "我看不懂体检报告呢，这个还是要请教医生。平时有什么养生问题可以问我~"
        ]
    ]
    
    static func randomResponse(for intent: AIAgentService.IntentType) -> String {
        // 根据意图类型选择话术
        switch intent {
        case .medical:
            return responses["general"]?.randomElement() ?? "身体不舒服建议就医哦~"
        default:
            return responses["general"]?.randomElement() ?? "这个问题建议咨询专业人士呢~"
        }
    }
}

// MARK: - AI配置
struct AIConfig {
    static let shared = AIConfig()
    
    let claudeApiKey = AppConstants.API.claudeApiKey
    let claudeModel = "claude-3-5-sonnet-20241022"
    let qwenApiKey = AppConstants.API.qwenApiKey
    let qwenMaxModel = "qwen-max"
    let qwenLiteModel = "qwen-lite"
    
    private init() {}
}

// MARK: - 扩展
extension AIAgentService {
    struct AIUserProfile {
        let nickname: String
        let age: Int?
        let gender: String?
        let city: String?
        let interests: [String]
    }
}

// 类型别名供外部使用
typealias AIUserProfile = AIAgentService.AIUserProfile

// MARK: - 主动关怀服务 (AI Agent专用)
class AIProactiveCareService {
    static let shared = AIProactiveCareService()
    
    // MARK: - 关怀类型
    enum CareType {
        case morningGreeting      // 早安问候
        case solarTermReminder    // 节气提醒
        case weatherAlert         // 天气突变提醒
        case habitReminder        // 习惯打卡提醒
        case checkInMiss          // 打卡中断提醒
        case longAbsence          // 久未登录关怀
        case achievement          // 成就达成
    }
    
    // MARK: - 智能推送时段
    func calculateOptimalTime(for user: AIUserProfile, careType: CareType) -> Date {
        // 根据用户历史活跃时间计算最佳推送时段
        let calendar = Calendar.current
        let hour: Int
        switch careType {
        case .morningGreeting:
            // 根据用户历史活跃时间调整
            hour = 7 // 默认7-8点
        case .habitReminder:
            // 根据用户设置的提醒时间
            hour = 8
        default:
            hour = 10
        }
        
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }
    
    // MARK: - 生成关怀消息
    func generateCareMessage(for careType: CareType, user: AIUserProfile, context: [String: Any]?) -> String {
        switch careType {
        case .morningGreeting:
            let solarTerm = context?["solarTerm"] as? String ?? "小雪"
            let weather = context?["weather"] as? String ?? "晴"
            return "早安呀，\(user.nickname)！今天\(solarTerm)，天气\(weather)，记得\(getWeatherTip(weather: weather))哦~🌿"
            
        case .solarTermReminder:
            let solarTerm = context?["solarTerm"] as? String ?? "小雪"
            return "今日\(solarTerm)！养生重点是：\(getSolarTermTip(solarTerm: solarTerm))，记得照顾好自己哦~❄️"
            
        case .weatherAlert:
            let weather = context?["weather"] as? String ?? "降温"
            return "天气\(weather)了，\(user.nickname)记得添衣保暖哦~多喝热水，注意身体！🌸"
            
        case .habitReminder:
            let habit = context?["habit"] as? String ?? "养生习惯"
            return "\(habit)打卡时间到啦！坚持就是胜利哦，\(user.nickname)加油~💪"
            
        case .checkInMiss:
            return "\(user.nickname)，您的养生打卡中断了2天呢。不过没关系，重新开始就好啦！我在这里等您~🌿"
            
        case .longAbsence:
            return "好久不见，\(user.nickname)~最近怎么样？有什么想聊的吗？小顺一直在这里陪您~💚"
            
        case .achievement:
            let achievement = context?["achievement"] as? String ?? "新成就"
            return "太棒了！\(user.nickname)解锁了新成就「\(achievement)」！继续保持哦~🏆"
        }
    }
    
    private func getWeatherTip(weather: String) -> String {
        if weather.contains("晴") {
            return "多喝水、适当运动"
        } else if weather.contains("雨") || weather.contains("冷") {
            return "注意保暖、带好雨具"
        } else if weather.contains("热") {
            return "防暑降温、少吃生冷"
        }
        return "保重身体"
    }
    
    private func getSolarTermTip(solarTerm: String) -> String {
        let tips: [String: String] = [
            "小雪": "温补养藏、早睡晚起",
            "大雪": "保暖防寒、适当进补",
            "冬至": "养肾护阳、饺子或汤圆",
            "立春": "养肝护脾、少酸多甘"
        ]
        return tips[solarTerm] ?? "顺应时节、调整作息"
    }
}

extension AIAgentService {
    // MARK: - 主动关怀接口
    func handleProactiveMessage(
        content: String,
        type: IntentType,
        sessionId: String
    ) async {
        // 保存AI发送的消息
        await ChatPersistenceService.shared.saveMessage(
            sessionId: sessionId,
            role: "assistant",
            content: content
        )
        
        // 发送通知给UI
        NotificationCenter.default.post(
            name: NSNotification.Name("ProactiveMessageReceived"),
            object: nil,
            userInfo: [
                "content": content,
                "type": type.rawValue,
                "sessionId": sessionId
            ]
        )
    }
}

// MARK: - 异常事件监测 (Phase C)
/// 负责监测用户对话中的异常模式（如频繁消极、深夜活跃等）
actor AbnormalEventDetector {
    struct AnalysisResult {
        let isAbnormal: Bool
        let riskLevel: AIAgentService.CareStatus
        let trigger: String?
    }
    
    // 简单的内存事件日志（实际应持久化）
    private var eventLog: [(timestamp: Date, content: String, sentiment: Double)] = []
    
    func analyze(message: String, context: AIAgentService.UserContext) -> AnalysisResult {
        // 1. 记录事件
        let sentiment = analyzeSentiment(message)
        eventLog.append((Date(), message, sentiment))
        
        // 2. 清理旧日志（只保留最近24小时）
        let dayAgo = Date().addingTimeInterval(-86400)
        eventLog.removeAll { $0.timestamp < dayAgo }
        
        // 3. 规则检测
        
        // 规则A: 连续消极情绪
        let negativeCount = eventLog.suffix(5).filter { $0.sentiment < -0.6 }.count
        if negativeCount >= 3 {
             return AnalysisResult(isAbnormal: true, riskLevel: .needsAttention, trigger: "连续消极情绪")
        }
        
        // 规则B: 深夜频繁活跃 (凌晨1-4点)
        let calendar = Calendar.current
        let lateNightMessages = eventLog.filter {
            let hour = calendar.component(.hour, from: $0.timestamp)
            return hour >= 1 && hour <= 4
        }
        if lateNightMessages.count >= 3 {
            return AnalysisResult(isAbnormal: true, riskLevel: .needsAttention, trigger: "深夜频繁活跃")
        }
        
        // 规则C: 关键词触发 (直接升级)
        let crisisKeywords = ["不想活", "绝望", "结束", "痛苦", "没有意义"]
        if crisisKeywords.contains(where: { message.contains($0) }) {
            return AnalysisResult(isAbnormal: true, riskLevel: .escalate, trigger: "危机关键词")
        }
        
        return AnalysisResult(isAbnormal: false, riskLevel: .stable, trigger: nil)
    }
    
    // 简易情感分析 (Mock)
    // 范围: -1.0 (极度消极) 到 1.0 (极度积极)
    private func analyzeSentiment(_ text: String) -> Double {
        let negativeWords = ["难过", "伤心", "累", "烦", "痛", "死", "病", "哭", "失眠"]
        let positiveWords = ["开心", "高兴", "棒", "好", "幸福", "期待", "舒服"]
        
        var score: Double = 0.0
        for word in negativeWords { if text.contains(word) { score -= 0.5 } }
        for word in positiveWords { if text.contains(word) { score += 0.5 } }
        
        return max(-1.0, min(1.0, score))
    }
}
