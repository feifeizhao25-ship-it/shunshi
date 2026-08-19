import Foundation
import Combine

// MARK: - Consultant View Model
@MainActor
final class ConsultantViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentSession: ChatSession?
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var isSending: Bool = false
    @Published var error: AppError?
    @Published var suggestedQuestions: [String] = []
    
    // MARK: - Dependencies
    private let chatRepository: ChatRepositoryProtocol
    private let appStateService: AppStateService
    private let authService: AuthService
    private let aiAgentService: AIAgentServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        chatRepository: ChatRepositoryProtocol? = nil,
        appStateService: AppStateService? = nil,
        authService: AuthService? = nil,
        aiAgentService: AIAgentServiceProtocol? = nil
    ) {
        self.chatRepository = chatRepository ?? ChatRepository.shared
        self.appStateService = appStateService ?? .shared
        self.authService = authService ?? .shared
        self.aiAgentService = aiAgentService ?? AIAgentService.shared
    }
    
    // MARK: - Computed Properties
    var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }
    
    var greeting: String {
        let timeGreeting = currentTimeGreeting()
        let name = authService.currentUser?.displayName ?? "朋友"
        let streak = authService.currentUser?.stats.currentStreak ?? 0
        let growthEmoji = WellnessStreakService.shared.stageEmoji(for: authService.currentUser?.stats.zenGrowthStage ?? 0)
        let initialFeeling = UserDefaults.standard.string(forKey: "user_initial_feeling") ?? ""
        
        var greetingPrefix = "\(timeGreeting)，\(name)！我是您的顺时主理人。\(growthEmoji)"
        
        if !initialFeeling.isEmpty {
            greetingPrefix += "\n看到您提到此时感觉「\(initialFeeling)」，一定要多注意休息，我也为您准备了一些针对性的养生建议。"
        } else if streak > 1 {
            greetingPrefix += "\n看到您已经连续 \(streak) 天坚持养生了，真为您感到高兴！"
        }
        
        return greetingPrefix + "\n今天有什么我可以帮您的吗？您可以问我节气食疗或简单的按压方法。"
    }
    
    // MARK: - Start New Session
    func startNewSession() async {
        isLoading = true
        error = nil
        
        let context = ChatContext(
            solarTerm: appStateService.currentSolarTerm?.name,
            constitution: authService.currentUser?.constitution?.primary?.type,
            location: nil
        )
        
        do {
            let session = try await chatRepository.createSession(context: context)
            currentSession = session
            
            // Sync to persistence
            await ChatPersistenceService.shared.createSession(id: session.id, title: "节气资讯 - \(Date().monthDayString)")
        } catch {
            Logger.warning("后端会话创建失败，切换到本地模拟会话: \(error.localizedDescription)")
            let mockSessionId = UUID().uuidString
            currentSession = ChatSession(
                id: mockSessionId,
                createdAt: Date(),
                messages: [],
                greeting: ChatGreeting(
                    text: self.greeting,
                    suggestions: [
                        "现在吃什么比较养生？",
                        "推荐一些适合我的运动",
                        "有哪些穴位按摩可以保健？",
                        "如何调理我的体质？"
                    ]
                )
            )
            
            // Sync mock session to persistence
            await ChatPersistenceService.shared.createSession(id: mockSessionId, title: "离线咨询 - \(Date().monthDayString)")
        }
        
        // Load messages from persistence if they exist (for session resume)
        if let session = currentSession {
            let savedMessages = await ChatPersistenceService.shared.getMessages(sessionId: session.id)
            if !savedMessages.isEmpty {
                self.messages = savedMessages.compactMap { entity in
                    guard let role = MessageRole(rawValue: entity.role) else { return nil }
                    return ChatMessage(
                        id: entity.id,
                        role: role,
                        content: entity.content,
                        timestamp: entity.timestamp,
                        recommendations: [],
                        followUpQuestions: entity.suggestions
                    )
                }
                // Update suggested questions from the last message if available
                if let lastAssistantMessage = self.messages.reversed().first(where: { $0.role == .assistant }), 
                   !lastAssistantMessage.followUpQuestions.isEmpty {
                    self.suggestedQuestions = lastAssistantMessage.followUpQuestions
                }
                return // Exit early as we've restored history
            }
        }
        
        messages = []
        
        // Add greeting to messages list
        let fallbackGreeting = currentSession?.greeting?.text ?? self.greeting
        let greetingText = await generateAIGreeting(fallback: fallbackGreeting)
        let initialSuggestions = currentSession?.greeting?.suggestions ?? [
            "现在吃什么比较养生？",
            "推荐一些适合我的运动",
            "有哪些穴位按摩可以保健？",
            "如何调理我的体质？"
        ]
        
        let greetingMessage = ChatMessage(
            role: .assistant,
            content: greetingText,
            followUpQuestions: initialSuggestions
        )
        messages.append(greetingMessage)
        suggestedQuestions = initialSuggestions
        
        isLoading = false
    }
    
    // MARK: - Send Message
    func sendMessage() async {
        guard canSend else { return }
        
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        inputText = ""
        
        // Add user message
        let userMessage = ChatMessage.userMessage(content)
        messages.append(userMessage)

        DataFlywheelService.shared.recordChatMessage(role: "user", contentLength: content.count)
        
        // Add loading message
        messages.append(.loadingMessage)
        isSending = true
        
        do {
            guard let sessionId = currentSession?.id else {
                throw AppError.operationFailed("会话不存在")
            }
            
            // 使用 AIAgentService 进行 AI 处理 (Vibe Coding 2.0 核心)
            // 这样即使后台没有回复，前端也能由 AI Agent 产生符合人设的回复
            var aiContext = AIAgentService.UserContext(
                userId: authService.currentUser?.id ?? "",
                constitution: authService.currentUser?.constitution?.primary?.type.rawValue,
                currentSolarTerm: appStateService.currentSolarTerm?.name,
                selectedWellnessTab: nil,
                conversationHistory: messages.dropLast().map { 
                    AIAgentMessage(role: $0.role.rawValue, content: $0.content) 
                },
                userProfile: authService.currentUser?.profileSummary, // Passing full user data for deeper insight
                currentMood: nil,
                lastActiveTime: UserDefaults.standard.object(forKey: "last_active_date") as? Date,
                isPremium: StoreKitService.shared.subscriptionStatus.isActive // 注入真实的会员状态
            )
            
            // Phase D: Family Context Injection
            let systemMembers = FamilyCareSystem.shared.members
            let aiMembers = systemMembers.map { member in
                AIAgentService.FamilyMember(
                    name: member.nickname,
                    relation: member.relationship.displayName,
                    constitution: member.constitution,
                    healthConcerns: member.healthGoals
                )
            }
            aiContext.familyMembers = aiMembers
            
            if !aiMembers.isEmpty && aiContext.isPremium {
                aiContext.relationshipTier = .family
            }
            
            let aiResponse = try await aiAgentService.processUserMessage(
                message: content,
                context: &aiContext,
                sessionId: sessionId
            )
            
            // 构造回复消息
            let enrichedContent = applyModernWellnessOverlay(to: aiResponse.content)
            let response = ChatMessage(
                role: .assistant,
                content: enrichedContent,
                recommendations: [],
                followUpQuestions: aiResponse.followUpQuestions ?? []
            )

            DataFlywheelService.shared.recordChatMessage(
                role: "assistant",
                contentLength: aiResponse.content.count,
                intent: aiResponse.intent.rawValue
            )
            
            // 异步将消息同步到后台（如果需要的话，但不阻塞 UI 显示）
            Task {
                try? await chatRepository.sendMessage(
                    sessionId: sessionId,
                    content: content,
                    messageType: "text"
                )
            }
            
            // Remove loading message and add response
            messages.removeLast()
            messages.append(response)
            
            // Update suggestions
            if !response.followUpQuestions.isEmpty {
                suggestedQuestions = response.followUpQuestions
            }
            
        } catch let appError as AppError {
            messages.removeLast()
            error = appError
        } catch {
            messages.removeLast()
            self.error = AppError(error)
        }
        
        isSending = false
    }
    
    // MARK: - Send Suggested Question
    func sendSuggestedQuestion(_ question: String) async {
        inputText = question
        await sendMessage()
    }
    
    // MARK: - Clear Chat
    func clearChat() {
        messages = []
        currentSession = nil
        suggestedQuestions = []
    }

    // MARK: - AI Greeting
    private func currentTimeGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "早上好"
        case 12..<14: return "中午好"
        case 14..<18: return "下午好"
        case 18..<22: return "晚上好"
        default: return "夜深了"
        }
    }

    private func generateAIGreeting(fallback: String) async -> String {
        let timeGreeting = currentTimeGreeting()
        let name = authService.currentUser?.displayName ?? "朋友"
        let streak = authService.currentUser?.stats.currentStreak ?? 0
        let growthEmoji = WellnessStreakService.shared.stageEmoji(for: authService.currentUser?.stats.zenGrowthStage ?? 0)
        let solarTerm = appStateService.currentSolarTerm?.name ?? "当下"

        let isPremium = StoreKitService.shared.subscriptionStatus.isActive
        
        // Phase A Upgrade: 关系深度与边界
        let relationshipInstruction = isPremium ?
            "对于尊享会员：表达‘长期的关怀’与‘克制的边界’。很高兴为您服务，但也要温和提醒用户关注现实生活中的真实连接（如与家人互动），不做情感绑架，不制造依赖。" :
            "对于普通用户：热情专业，鼓励尝试更多养生功能。"

        let prompt = """
        你是「顺时小师」，请生成一段自然、温暖的问候语。
        
        【用户信息】
        - 用户身份：\(isPremium ? "尊享会员" : "普通用户")
        - 时间问候：\(timeGreeting)
        - 用户昵称：\(name)
        - 连续养生天数：\(streak)
        - 成长符号：\(growthEmoji)
        - 当前节气：\(solarTerm)
        - 此时状态：\(UserDefaults.standard.string(forKey: "user_initial_feeling") ?? "未知")

        【要求】
        1. 2-3句中文，避免模板化，语气要像老朋友一样。
        2. 必须包含时间问候和称呼用户昵称。
        3. 如果用户感到疲乏或状态不佳，先表示同情和舒缓，再给出简单的生活建议。
        4. 语气亲切自然，不要使用‘诊断’‘治疗’等词汇，可以用1个emoji。
        5. 结尾用一个具体的引导问题。
        6. \(relationshipInstruction)
        """

        do {
            let response = try await LLMService.shared.chat(
                messages: [ChatCompletionMessage(role: "user", content: prompt)],
                model: .qwen2_5_7B,
                temperature: 0.7,
                maxTokens: 200
            )
            let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? fallback : trimmed
        } catch {
            Logger.warning("AI greeting failed: \(error.localizedDescription)")
            return fallback
        }
    }

    // MARK: - Modern Wellness Overlay
    private func applyModernWellnessOverlay(to content: String) -> String {
        let modernSummary = "\n\n【现代健康补充】\n- 睡眠建议：成人建议 7-8 小时，睡前减少蓝光刺激。\n- 营养建议：优先保证蛋白质与蔬菜摄入，控制高糖高油。\n- 运动建议：每天累计 30 分钟中等强度活动。"
        return content + modernSummary
    }
}

