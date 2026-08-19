import Foundation

// MARK: - LLM Service
/// Service for AI chat completions using SiliconFlow API (硅基流动)
actor LLMService {
    static let shared = LLMService()
    
    private let baseURL = AppConstants.API.siliconFlowBaseURL
    private let apiKey = AppConstants.API.siliconFlowApiKey
    
    // 推荐模型列表
    enum Model: String {
        case qwen2_5_7B = "Qwen/Qwen2.5-7B-Instruct"       // 轻量快速
        case qwen2_5_32B = "Qwen/Qwen2.5-32B-Instruct"     // 中等能力
        case qwen2_5_72B = "Qwen/Qwen2.5-72B-Instruct"     // 强大能力
        case deepseekV3 = "deepseek-ai/DeepSeek-V3"        // DeepSeek最新
        case glm4_9B = "THUDM/glm-4-9b-chat"               // 智谱GLM
    }
    
    enum LLMError: LocalizedError {
        case invalidURL
        case noAPIKey
        case networkError(Error)
        case invalidResponse
        case decodingFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "无效的URL"
            case .noAPIKey: return "API密钥未配置"
            case .networkError(let error): return "网络错误: \(error.localizedDescription)"
            case .invalidResponse: return "服务器响应无效"
            case .decodingFailed(let error): return "解析响应失败: \(error.localizedDescription)"
            }
        }
    }
    
    private init() {}
    
    // MARK: - Chat Completion
    func chat(
        messages: [ChatCompletionMessage],
        model: Model = .deepseekV3,
        temperature: Double = 0.7,
        maxTokens: Int = 1024,
        enableFallback: Bool = true
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw LLMError.noAPIKey
        }
        
        do {
            return try await performChatRequest(
                messages: messages,
                model: model.rawValue,
                temperature: temperature,
                maxTokens: maxTokens
            )
        } catch {
            Logger.warning("LLM \(model.rawValue) failed: \(error.localizedDescription)")
            
            if enableFallback {
                // 回退逻辑：如果 DeepSeek V3 失败，尝试 Qwen 72B；如果 Qwen 72B 失败，尝试 GLM
                let fallbackModel: Model
                switch model {
                case .deepseekV3: fallbackModel = .qwen2_5_72B
                case .qwen2_5_72B: fallbackModel = .glm4_9B
                default: throw error
                }
                
                Logger.info("Attempting fallback to \(fallbackModel.rawValue)...")
                return try await performChatRequest(
                    messages: messages,
                    model: fallbackModel.rawValue,
                    temperature: temperature,
                    maxTokens: maxTokens
                )
            } else {
                throw error
            }
        }
    }
    
    private func performChatRequest(
        messages: [ChatCompletionMessage],
        model: String,
        temperature: Double,
        maxTokens: Int
    ) async throws -> String {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw LLMError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30 // 缩短超时，以便快速切换模型
        
        let body = ChatCompletionRequest(
            model: model,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens,
            stream: false
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            Logger.error("LLM API error: \(httpResponse.statusCode) - \(errorText)")
            throw LLMError.invalidResponse
        }
        
        let result = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        return result.choices.first?.message.content ?? ""
    }
    
    // MARK: - History Summarization
    func summarizeHistory(_ history: [ChatCompletionMessage]) async throws -> String {
        let prompt = "请复述并总结以下对话的核心内容，重点包括用户的状态、偏好、提出的问题以及已经给出的核心建议。总结要简练，便于作为后续对话的背景资料：\n\n"
        let historyText = history.map { "\($0.role): \($0.content)" }.joined(separator: "\n")
        
        let messages = [ChatCompletionMessage(role: "user", content: prompt + historyText)]
        return try await chat(messages: messages, model: .qwen2_5_7B, maxTokens: 512, enableFallback: true)
    }
    
    // MARK: - Wellness Chat (带养养生系统提示)
    func wellnessChat(
        userMessage: String,
        context: WellnessContext,
        history: [ChatCompletionMessage] = []
    ) async throws -> String {
        let systemPrompt = buildWellnessSystemPrompt(context: context)
        
        var messages: [ChatCompletionMessage] = [
            ChatCompletionMessage(role: "system", content: systemPrompt)
        ]
        messages.append(contentsOf: history)
        messages.append(ChatCompletionMessage(role: "user", content: userMessage))
        
        return try await chat(messages: messages, model: .qwen2_5_7B, temperature: 0.7)
    }
    
    private func buildWellnessSystemPrompt(context: WellnessContext) -> String {
        let wellnessName = context.wellnessType?.displayName ?? "综合"

        return """
        你是「顺时」——一个懂中医养生、有人情温度的 AI 朋友。

        【你的身份】
        - 不是医生，不是客服，是一个温和、有耐心、不说教的朋友
        - 有生活智慧，情绪敏感，用日常表达而非专业术语
        - 陪伴用户顺应天时，不急于"治好"或"解决"

        【当前信息】
        - 当前节气：\(context.solarTerm ?? "大雪")
        - 养生维度：\(wellnessName)
        - 用户体质偏向：\(context.constitution ?? "平和质")（注意：体质是阶段状态，会变化）

        【回复公式：先共情 → 再陪伴 → 最后建议】
        如果三者只能选一个，优先共情。

        【回复原则】
        1. 先回应用户的"感受"，再回应"问题"
        2. 建议不超过 3 条，必须是能立即执行的小动作（2分钟内可完成）
        3. 永远生成一个"未来跟进点"（如：过两三天我们再看看感觉怎么样？）
        4. 允许沉默和模糊，不追求回答完整，追求让人舒服
        5. 如涉及疾病、用药，温和引导就医，不做判断

        【禁止】
        - 命令式语气（如"你必须""一定要"）
        - 说教或教科书风格
        - 一次灌输过多信息
        - KPI 感极强的提醒
        - 过度使用 emoji

        【示例】
        ❌ 错误："你这是气虚，需要补气。建议多吃山药、红枣..."
        ✅ 正确："听你这么说，最近身体确实有点透支了。我们先从作息轻轻调整一下，过两三天我陪你再看看，好吗？"
        """
    }
}

