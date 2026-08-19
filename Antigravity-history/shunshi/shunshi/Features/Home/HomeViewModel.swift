import Foundation
import Combine

// MARK: - Home View Model
@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var solarTerm: SolarTerm?
    @Published var wellnessOverview: WellnessOverview?
    @Published var integratedTips: [IntegratedTip] = []
    @Published var todayRecipes: [Recipe] = []
    @Published var isLoading: Bool = false
    @Published var error: AppError?
    @Published var showSolarTermDetail: Bool = false
    @Published var initialFeeling: String? = nil
    @Published var dailyRituals: [RitualItem] = []
    @Published var dailyCompanionMessage: String = "今天先给自己一点时间，做一次缓慢的深呼吸。"
    @Published var dailyCompanionActionTitle: String = "开始3分钟呼吸"
    @Published var dailyCompanionTags: [String] = ["呼吸", "放松"]
    @Published var isGeneratingCompanion: Bool = false
    @Published var dailyPlanFocus: String = "今日重点：稳住节奏"
    @Published var dailyPlanSummary: String = "把今天拆成三件小事，完成一件就算进步。"
    @Published var dailyPlanSteps: [DailyPlanStep] = []
    @Published var isGeneratingPlan: Bool = false
    
    // Phase B: 连续性关怀状态
    @Published var careStatus: AIAgentService.CareStatus?
    @Published var followUpIntent: AIAgentService.FollowUpIntent?

    
    // MARK: - Ritual Model
    struct RitualItem: Identifiable, Equatable {
        let id: String
        let name: String
        let icon: String
        let period: RitualPeriod
        
        enum RitualPeriod: String {
            case morning, afternoon, evening
        }
    }
    
    // MARK: - Dependencies
    private let solarTermRepository: SolarTermRepositoryProtocol
    private let wellnessRepository: WellnessRepositoryProtocol
    private let appStateService: AppStateService
    private let authService: AuthService
    private let constitutionService: ConstitutionService
    private let modernHealthService: ModernHealthService
    private let taskCoordinator: WellnessTaskCoordinator
    private let aiService = LLMService.shared
    private let preferenceService = WellnessPreferenceService.shared
    private let flywheelService = DataFlywheelService.shared
    private let feedbackService = AIResponseFeedbackService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        solarTermRepository: SolarTermRepositoryProtocol? = nil,
        wellnessRepository: WellnessRepositoryProtocol? = nil,
        appStateService: AppStateService? = nil,
        authService: AuthService? = nil,
        constitutionService: ConstitutionService? = nil
    ) {
        self.solarTermRepository = solarTermRepository ?? SolarTermRepository.shared
        self.wellnessRepository = wellnessRepository ?? WellnessRepository.shared
        self.appStateService = appStateService ?? .shared
        self.authService = authService ?? .shared
        self.constitutionService = constitutionService ?? .shared
        self.modernHealthService = .shared
        self.taskCoordinator = .shared
        
        setupBindings()
    }
    
    // MARK: - Setup Bindings
    private func setupBindings() {
        appStateService.$currentSolarTerm
            .receive(on: DispatchQueue.main)
            .sink { [weak self] solarTerm in
                self?.solarTerm = solarTerm
                self?.generateIntegratedTips()
            }
            .store(in: &cancellables)
            
        // 监听主动关怀消息
        NotificationCenter.default.publisher(for: NSNotification.Name("ProactiveMessageReceived"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleProactiveMessage(notification)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load Data
    func loadData() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            // Load solar term
            await appStateService.loadCurrentSolarTerm()
            solarTerm = appStateService.currentSolarTerm
            
            // Load personalized recommendations
            let constitution = resolveUserConstitution()
            let recipeResult = try await wellnessRepository.getRecipes(
                solarTermId: solarTerm?.id,
                constitution: constitution,
                category: nil,
                difficulty: nil,
                page: 1,
                pageSize: 3
            )
            todayRecipes = recipeResult.items
            
            // Generate integrated tips combining traditional and modern
            generateIntegratedTips()
            
        } catch let appError as AppError {
            error = appError
        } catch {
            self.error = AppError(error)
        }
        
        // Fetch feeling from onboarding
        initialFeeling = UserDefaults.standard.string(forKey: "user_initial_feeling")
        
        Task { await generateDailyCompanion(force: false) }
        
        isLoading = false
    }
    
    // MARK: - Refresh
    func refresh() async {
        await appStateService.loadCurrentSolarTerm(forceRefresh: true)
        solarTerm = appStateService.currentSolarTerm
        generateIntegratedTips()
        Task { await generateDailyCompanion(force: true) }
    }
    
    // MARK: - Generate Integrated Tips
    private func generateIntegratedTips() {
        guard let solarTerm = solarTerm else {
            integratedTips = []
            return
        }
        
        _ = resolveUserConstitution()
        let nutrition = modernHealthService.todayNutrition
        let sleep = modernHealthService.todaySleep
        let mood = modernHealthService.todayMood
        let exercise = modernHealthService.todayExercise
        
        var tips: [IntegratedTip] = []
        
        // MARK: 饮食锦囊 - 融合节气建议与现代营养数据
        let hydrationPercent = modernHealthService.nutritionGoals.waterMl > 0
            ? nutrition.totalWater / modernHealthService.nutritionGoals.waterMl
            : 0
        _ = modernHealthService.nutritionGoals.calories > 0
            ? nutrition.totalCalories / Double(modernHealthService.nutritionGoals.calories)
            : 0.0
        
        let dietTip = IntegratedTip(
            type: .diet,
            title: "今日饮食",
            traditionalAdvice: "宜食\(solarTerm.yi.prefix(3).joined(separator: "、"))",
            modernInsight: nil,
            modernMetric: IntegratedTip.ModernMetric(
                value: "\(Int(nutrition.totalWater))",
                unit: "ml",
                target: "\(Int(modernHealthService.nutritionGoals.waterMl))ml",
                progress: hydrationPercent,
                status: hydrationPercent < 0.5 ? .alert : (hydrationPercent < 0.8 ? .warning : .good)
            ),
            time: nil,
            priority: hydrationPercent < 0.5 ? .high : (hydrationPercent < 0.8 ? .medium : .low)
        )
        tips.append(dietTip)
        
        // MARK: 起居锦囊 - 融合节气原则与现代睡眠数据
        let sleepPercent = sleep.averageDuration / 8.0
        let sleepTip = IntegratedTip(
            type: .living,
            title: "起居调养",
            traditionalAdvice: solarTerm.healthPrinciple,
            modernInsight: sleep.averageDuration < 6.5 
                ? "昨夜睡眠\(String(format: "%.1f", sleep.averageDuration))小时，建议今晚提前休息"
                : "睡眠时长良好，保持规律作息",
            modernMetric: IntegratedTip.ModernMetric(
                value: String(format: "%.1f", sleep.averageDuration),
                unit: "h",
                target: "7.5h",
                progress: min(sleepPercent, 1.2),
                status: sleepPercent < 0.6 ? .alert : (sleepPercent < 0.8 ? .warning : .good)
            ),
            time: "今晚",
            priority: sleepPercent < 0.6 ? .high : (sleepPercent < 0.8 ? .medium : .low)
        )
        tips.append(sleepTip)
        
        // MARK: 运动锦囊 - 融合传统导引与现代运动数据
        let exerciseGoal = modernHealthService.exerciseGoal
        let exercisePercent = exerciseGoal.dailyMinutes > 0
            ? Double(exercise.totalMinutes) / Double(exerciseGoal.dailyMinutes)
            : 0.0
        let exerciseTip = IntegratedTip(
            type: .exercise,
            title: "运动建议",
            traditionalAdvice: "适宜进行轻柔舒缓的运动",
            modernInsight: exercise.totalMinutes < 20
                ? "已运动\(exercise.totalMinutes)分钟，建议再补充\(max(0, 20 - exercise.totalMinutes))分钟"
                : "今日运动达标，注意适当休息",
            modernMetric: IntegratedTip.ModernMetric(
                value: "\(exercise.totalMinutes)",
                unit: "min",
                target: "\(exerciseGoal.dailyMinutes)min",
                progress: min(exercisePercent, 1.2),
                status: exercisePercent < 0.5 ? .warning : (exercisePercent >= 1.0 ? .good : .warning)
            ),
            time: "清晨或傍晚",
            priority: exercisePercent < 0.3 ? .high : (exercisePercent < 0.6 ? .medium : .low)
        )
        tips.append(exerciseTip)
        
        // MARK: 情志锦囊 - 融合七情调和与现代情绪数据
        let moodPercent = mood.averageScore / 10.0
        let moodTip = IntegratedTip(
            type: .emotion,
            title: "情志调养",
            traditionalAdvice: "保持心境平和，避免过激情志",
            modernInsight: mood.averageScore < 6.5
                ? "情绪波动较大，建议进行5分钟冥想"
                : "心境平和，继续保持",
            modernMetric: IntegratedTip.ModernMetric(
                value: String(format: "%.1f", mood.averageScore),
                unit: "分",
                target: "8分",
                progress: min(moodPercent, 1.0),
                status: moodPercent < 0.6 ? .alert : (moodPercent < 0.75 ? .warning : .good)
            ),
            time: "随时",
            priority: moodPercent < 0.6 ? .high : (moodPercent < 0.75 ? .medium : .low)
        )
        tips.append(moodTip)
        
        integratedTips = tips
        
        // Generate rituals
        generateDailyRituals(solarTerm: solarTerm)
    }
    
    // MARK: - Generate Daily Rituals
    private func generateDailyRituals(solarTerm: SolarTerm) {
        // Here we build rituals based on solar term recommendations
        var rituals: [RitualItem] = []
        
        // Morning
        rituals.append(RitualItem(id: "drink_water", name: "晨起温水", icon: "drop.fill", period: .morning))
        rituals.append(RitualItem(id: "sun_light", name: "清晨日光", icon: "sun.max.fill", period: .morning))
        
        // Afternoon
        rituals.append(RitualItem(id: "daily_exercise", name: "节气导引", icon: "figure.walk", period: .afternoon))
        rituals.append(RitualItem(id: "tea_time", name: "节气茶饮", icon: "cup.and.saucer.fill", period: .afternoon))
        
        // Evening
        rituals.append(RitualItem(id: "foot_bath", name: "药浴泡脚", icon: "footprints", period: .evening))
        rituals.append(RitualItem(id: "early_sleep", name: "早睡按时", icon: "moon.zzz.fill", period: .evening))
        
        self.dailyRituals = rituals
    }

    // MARK: - Daily Companion (AI)
    private struct DailyCompanionPayload {
        let message: String
        let action: String
        let tags: [String]
    }
    
    enum DailyPlanAction: String, Codable {
        case breathing
        case habitCheckin
        case diet
        case living
        case exercise
        case emotion
        case acupoint
    }

    struct DailyPlanStep: Identifiable, Codable {
        let id: UUID
        let title: String
        let detail: String
        let time: String?
        let dimension: String?
        let taskId: String?
        let action: DailyPlanAction?
        
        init(
            title: String,
            detail: String,
            time: String? = nil,
            dimension: String? = nil,
            taskId: String? = nil,
            action: DailyPlanAction? = nil
        ) {
            self.id = UUID()
            self.title = title
            self.detail = detail
            self.time = time
            self.dimension = dimension
            self.taskId = taskId
            self.action = action
        }
    }
    
    private struct DailyPlanPayload: Codable {
        let focus: String
        let summary: String
        let steps: [DailyPlanStep]
        // Phase B: 新增储字段
        let careStatus: AIAgentService.CareStatus?
        let followUp: AIAgentService.FollowUpIntent?
    }

    private var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }

    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing")
    }

    func generateDailyCompanion(force: Bool) async {
        guard !isGeneratingCompanion else { return }
        
        if !force {
            let cachedDate = UserDefaults.standard.string(forKey: AppConstants.StorageKeys.dailyCompanionDate)
            if cachedDate == todayKey,
               let cachedMessage = UserDefaults.standard.string(forKey: AppConstants.StorageKeys.dailyCompanionMessage),
               let cachedAction = UserDefaults.standard.string(forKey: AppConstants.StorageKeys.dailyCompanionAction) {
                dailyCompanionMessage = cachedMessage
                dailyCompanionActionTitle = cachedAction
                if let cachedTags = UserDefaults.standard.stringArray(forKey: AppConstants.StorageKeys.dailyCompanionTags) {
                    dailyCompanionTags = cachedTags
                }
                return
            }
        }
        
        if isUITesting {
            dailyCompanionMessage = "今天做一件小事就够了：喝一杯温水，给身体一个开始。"
            dailyCompanionActionTitle = "开始今日小动作"
            dailyCompanionTags = ["温水", "启动"]
            return
        }
        
        isGeneratingCompanion = true
        defer { isGeneratingCompanion = false }
        
        let solarTermName = solarTerm?.name ?? "当下节气"
        let timeOfDay = AIAgentService.TimeOfDay.current.rawValue
        let moodScore = modernHealthService.todayMood.averageScore
        let sleepHours = modernHealthService.todaySleep.averageDuration
        let waterIntake = Int(modernHealthService.todayNutrition.totalWater)
        let preferenceInsight = preferenceService.insightSummary() ?? "暂无明确偏好"
        let flywheelSummary = flywheelService.profileSummary()
        let companionFeedback = feedbackService.feedbackSummary(context: .dailyCompanion)
        
        let prompt = """
        你是顺时App的AI陪伴助手。请基于用户当下信息生成一句不反感、温和但能推动行动的“今日陪伴”内容。
        背景信息：节气=\(solarTermName)，时间段=\(timeOfDay)，情绪评分≈\(String(format: "%.1f", moodScore))/10，昨夜睡眠≈\(String(format: "%.1f", sleepHours))小时，今日饮水≈\(waterIntake)ml。
        用户偏好：\(preferenceInsight)。
        用户画像摘要：\(flywheelSummary)。
        用户反馈：\(companionFeedback)。
        要求：
        - 语气亲切、不夸大疗效、不医疗化
        - 内容 1-2 句即可，包含一个可立即执行的小行动
        - 输出格式严格为四行：
        标题：今日陪伴
        正文：<内容>
        行动：<行动按钮文案，不超过10字>
        标签：<2-3个标签，用逗号分隔>
        """
        
        do {
            let response = try await aiService.chat(
                messages: [ChatCompletionMessage(role: "user", content: prompt)],
                model: .gpt4oMini,
                temperature: 0.6,
                maxTokens: 300,
                enableFallback: true
            )
            
            let payload = parseDailyCompanionResponse(response) ?? DailyCompanionPayload(
                message: "给自己一点节奏，先做一次缓慢深呼吸，然后再开始今天的任务。",
                action: "开始深呼吸",
                tags: ["呼吸", "节奏"]
            )
            
            dailyCompanionMessage = payload.message
            dailyCompanionActionTitle = payload.action
            dailyCompanionTags = payload.tags
            
            UserDefaults.standard.set(todayKey, forKey: AppConstants.StorageKeys.dailyCompanionDate)
            UserDefaults.standard.set(payload.message, forKey: AppConstants.StorageKeys.dailyCompanionMessage)
            UserDefaults.standard.set(payload.action, forKey: AppConstants.StorageKeys.dailyCompanionAction)
            UserDefaults.standard.set(payload.tags, forKey: AppConstants.StorageKeys.dailyCompanionTags)
        } catch {
            dailyCompanionMessage = "今天先把节奏放慢一点，做一段舒缓的伸展就很棒。"
            dailyCompanionActionTitle = "开始伸展"
            dailyCompanionTags = ["伸展", "放松"]
        }
    }
    
    private func parseDailyCompanionResponse(_ response: String) -> DailyCompanionPayload? {
        let lines = response
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var message = ""
        var action = ""
        var tags: [String] = []
        
        for line in lines {
            if line.hasPrefix("正文：") {
                message = line.replacingOccurrences(of: "正文：", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("行动：") {
                action = line.replacingOccurrences(of: "行动：", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("标签：") {
                let tagText = line.replacingOccurrences(of: "标签：", with: "")
                tags = tagText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            }
        }
        
        if message.isEmpty {
            message = lines.first ?? ""
        }
        
        if action.isEmpty {
            action = "开始小动作"
        }
        
        if tags.isEmpty {
            tags = ["陪伴", "节奏"]
        }
        
        guard !message.isEmpty else { return nil }
        return DailyCompanionPayload(message: message, action: action, tags: tags)
    }
    
    // MARK: - Daily Plan (AI)
    func generateDailyPlan(force: Bool) async {
        guard !isGeneratingPlan else { return }
        
        if !force {
            let cachedDate = UserDefaults.standard.string(forKey: AppConstants.StorageKeys.dailyPlanDate)
            if cachedDate == todayKey,
               let data = UserDefaults.standard.data(forKey: AppConstants.StorageKeys.dailyPlanPayload),
               let cached = try? JSONDecoder().decode(DailyPlanPayload.self, from: data) {
                dailyPlanFocus = cached.focus
                dailyPlanSummary = cached.summary
                dailyPlanSteps = enrichPlanSteps(cached.steps)
                // Phase B: 恢复状态
                careStatus = cached.careStatus
                followUpIntent = cached.followUp
                return
            }
        }
        
        if isUITesting {
            dailyPlanFocus = "今日重点：轻任务启动"
            dailyPlanSummary = "先完成一件小事，再逐步进入状态。"
            dailyPlanSteps = buildPlanSteps(from: taskCoordinator.todayTasks)
            return
        }
        
        isGeneratingPlan = true
        defer { isGeneratingPlan = false }
        
        taskCoordinator.generateTodayTasks()
        let tasks = taskCoordinator.todayTasks.filter { !$0.isCompleted }
        dailyPlanSteps = buildPlanSteps(from: tasks)
        
        let solarTermName = solarTerm?.name ?? "当下节气"
        let timeOfDay = AIAgentService.TimeOfDay.current.rawValue
        let moodScore = modernHealthService.todayMood.averageScore
        let sleepHours = modernHealthService.todaySleep.averageDuration
        let waterIntake = Int(modernHealthService.todayNutrition.totalWater)
        let preferenceInsight = preferenceService.insightSummary() ?? "暂无明确偏好"
        let flywheelSummary = flywheelService.profileSummary()
        let planFeedback = feedbackService.feedbackSummary(context: .dailyPlan)
        let taskSummary = tasks.prefix(3).map { task in
            "\(task.title)（\(task.scheduledTime ?? "今日" )，约\(task.estimatedMinutes)分钟）"
        }.joined(separator: "；")
        
        let isPremium = StoreKitService.shared.subscriptionStatus.isActive
        let isFamily = false // TODO: Check actual family status
        let model: LLMService.ModelType = isPremium ? .qwen2_5_72B : .gpt4oMini
        
        // 构建不同深度的 Prompt
        var systemRole = ""
        if isFamily {
            systemRole = "你是顺时App的【家庭养生管家】。你需要基于家庭成员的健康状况，为用户（家长/组织者）生成统筹兼顾的个性化计划。关注点包括用户自身及家人的健康。"
        } else if isPremium {
            systemRole = "你是顺时App的【高级私人养生顾问】。请基于Deep-Context为尊贵用户生成极具洞察力的个性化计划。"
        } else {
            systemRole = "你是顺时App的AI养生计划助手。请生成简洁的今日计划。"
        }
            
        let prompt = """
        \(systemRole)
        请输出“今日计划”的重点与总结：
        
        环境：节气=\(solarTermName)，时间=\(timeOfDay)
        身心数据：情绪=\(String(format: "%.1f", moodScore))/10，睡眠=\(String(format: "%.1f", sleepHours))h，饮水=\(waterIntake)ml
        今日任务：\(taskSummary)
        画像与偏好：\(flywheelSummary)、\(preferenceInsight)
        反馈历史：\(planFeedback)
        
        要求：
        1. 语气：\(isPremium ? (isFamily ? "亲切、稳重、富有家庭责任感" : "专业、共情、不仅关注身体更关注内心状态") : "温和、简洁")
        2. 重点：\(isPremium ? "结合体质与昨日数据，给出一个深刻的洞察" : "给出一个行动建议")
        3. 总结：\(isPremium ? (isFamily ? "关联节气与家庭生活，给出温馨寄语" : "关联节气气候与用户现状，给出定制化寄语") : "鼓励完成任务")
        4. 格式严格保持两行：
        重点：<内容>
        总结：<内容>
        
        \(isPremium ? """
        【高级连续性输出】
        请在最后输出一段元数据（用XML标签包裹）：
        <metadata>
        {
          "care_status": "stable" | "needs_attention" | "escalate",
          "follow_up": {
            "in_days": 1-7,
            "intent": "sleep_check",
            "topic": "跟进的具体话题"
          }
        }
        </metadata>
        """ : "")
        """
        
        do {
            let response = try await aiService.chat(
                messages: [ChatCompletionMessage(role: "user", content: prompt)],
                model: model,
                temperature: isPremium ? 0.8 : 0.6,
                maxTokens: isPremium ? 400 : 200,
                enableFallback: true
            )
            
            // Phase B: 解析元数据
            var cleanResponse = response
            var parsedCareStatus: AIAgentService.CareStatus?
            var parsedFollowUp: AIAgentService.FollowUpIntent?
            
            if isPremium, let metadataRange = response.range(of: "<metadata>[\\s\\S]*?</metadata>", options: .regularExpression) {
                let metadataString = String(response[metadataRange])
                    .replacingOccurrences(of: "<metadata>", with: "")
                    .replacingOccurrences(of: "</metadata>", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let data = metadataString.data(using: .utf8) {
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
                        parsedCareStatus = AIAgentService.CareStatus(rawValue: dto.care_status)
                        if let fu = dto.follow_up {
                            let intent = AIAgentService.FollowUpIntent(inDays: fu.in_days, intent: fu.intent, topic: fu.topic)
                            parsedFollowUp = intent
                            
                            // 立即调度跟进通知
                            Task {
                                await PushNotificationService.shared.scheduleFollowUp(intent: intent)
                            }
                        }
                    }
                }
                cleanResponse.removeSubrange(metadataRange)
            }
            
            let parsed = parseDailyPlanResponse(cleanResponse)
            dailyPlanFocus = parsed?.focus ?? fallbackPlanFocus()
            dailyPlanSummary = parsed?.summary ?? fallbackPlanSummary()
            careStatus = parsedCareStatus
            followUpIntent = parsedFollowUp
        } catch {
            dailyPlanFocus = fallbackPlanFocus()
            dailyPlanSummary = fallbackPlanSummary()
        }
        
        let payload = DailyPlanPayload(
            focus: dailyPlanFocus,
            summary: dailyPlanSummary,
            steps: dailyPlanSteps,
            careStatus: careStatus,
            followUp: followUpIntent
        )
        
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(todayKey, forKey: AppConstants.StorageKeys.dailyPlanDate)
            UserDefaults.standard.set(data, forKey: AppConstants.StorageKeys.dailyPlanPayload)
        }
    }
    
    // MARK: - Handlers
    private func handleProactiveMessage(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let content = userInfo["content"] as? String,
              let typeRaw = userInfo["type"] as? String else { return }
        
        // 如果是异常介入（如危机干预），更新 UI 状态
        if let type = AIAgentService.IntentType(rawValue: typeRaw),
           type == .crisis || type == .medical {
            // 切换到 Needs Attention 或 Escalate
            self.careStatus = .escalate
            self.dailyPlanFocus = "当前重点：请照顾好自己"
            self.dailyPlanSummary = "我们一直在这里陪着你。如有需要，请及时寻求专业帮助。"
        }
        
        // 更新伴侣消息（可选，让用户在首页也能看到最新的关怀）
        self.dailyCompanionMessage = content
        self.dailyCompanionActionTitle = "查看详情"
    }
    
    private func buildPlanSteps(from tasks: [UnifiedWellnessTask]) -> [DailyPlanStep] {
        var steps: [DailyPlanStep] = []
        
        let actionTitle = dailyCompanionActionTitle.isEmpty ? "开始深呼吸" : dailyCompanionActionTitle
        let actionDetail = dailyCompanionMessage.isEmpty ? "做一次缓慢深呼吸，帮助进入状态。" : dailyCompanionMessage
        steps.append(DailyPlanStep(
            title: actionTitle,
            detail: actionDetail,
            time: "现在",
            dimension: WellnessDimension.emotion.rawValue,
            taskId: nil,
            action: .breathing
        ))
        
        for task in tasks.prefix(2) {
            steps.append(DailyPlanStep(
                title: task.title,
                detail: task.description,
                time: task.scheduledTime ?? "今天",
                dimension: task.dimension.rawValue,
                taskId: task.id,
                action: action(for: task.dimension)
            ))
        }
        
        while steps.count < 3 {
            let fallback = steps.count == 1
                ? DailyPlanStep(
                    title: "喝一杯温水",
                    detail: "补充水分，帮助身体启动。",
                    time: "早晨",
                    dimension: WellnessDimension.living.rawValue,
                    taskId: nil,
                    action: .living
                )
                : DailyPlanStep(
                    title: "轻量舒展",
                    detail: "做5分钟拉伸，放松肩颈。",
                    time: "下午",
                    dimension: WellnessDimension.exercise.rawValue,
                    taskId: nil,
                    action: .exercise
                )
            steps.append(fallback)
        }
        
        return steps
    }

    private func enrichPlanSteps(_ steps: [DailyPlanStep]) -> [DailyPlanStep] {
        guard !steps.isEmpty else { return steps }
        return steps.enumerated().map { index, step in
            if step.action != nil { return step }
            var resolvedAction: DailyPlanAction?
            if step.taskId == nil && index == 0 {
                resolvedAction = .breathing
            } else if let raw = step.dimension,
                      let dimension = WellnessDimension(rawValue: raw) {
                resolvedAction = action(for: dimension)
            }
            guard let resolvedAction else { return step }
            return DailyPlanStep(
                title: step.title,
                detail: step.detail,
                time: step.time,
                dimension: step.dimension,
                taskId: step.taskId,
                action: resolvedAction
            )
        }
    }

    private func action(for dimension: WellnessDimension) -> DailyPlanAction {
        switch dimension {
        case .diet: return .diet
        case .living: return .living
        case .exercise: return .exercise
        case .emotion: return .emotion
        case .acupoint: return .acupoint
        }
    }
    
    private func parseDailyPlanResponse(_ response: String) -> (focus: String, summary: String)? {
        let lines = response
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var focus = ""
        var summary = ""
        
        for line in lines {
            if line.hasPrefix("重点：") {
                focus = line.replacingOccurrences(of: "重点：", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("总结：") {
                summary = line.replacingOccurrences(of: "总结：", with: "").trimmingCharacters(in: .whitespaces)
            }
        }
        
        if focus.isEmpty {
            focus = lines.first ?? ""
        }
        if summary.isEmpty, lines.count > 1 {
            summary = lines[1]
        }
        
        guard !focus.isEmpty else { return nil }
        return (focus: focus, summary: summary.isEmpty ? fallbackPlanSummary() : summary)
    }
    
    private func fallbackPlanFocus() -> String {
        let sleep = modernHealthService.todaySleep.averageDuration
        let mood = modernHealthService.todayMood.averageScore
        let water = modernHealthService.todayNutrition.totalWater
        
        if sleep < 6.5 {
            return "今日重点：优先补足睡眠"
        }
        if water < 800 {
            return "今日重点：补水与节奏"
        }
        if mood < 6.0 {
            return "今日重点：安稳情绪"
        }
        return "今日重点：稳住节奏"
    }
    
    private func fallbackPlanSummary() -> String {
        "把今天拆成三件小事，完成一件就算进步。"
    }
    
    // MARK: - Computed Properties
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        var baseGreeting = ""
        switch hour {
        case 5..<12: baseGreeting = "早上好"
        case 12..<14: baseGreeting = "中午好"
        case 14..<18: baseGreeting = "下午好"
        case 18..<22: baseGreeting = "晚上好"
        default: baseGreeting = "夜深了"
        }
        
        if let feeling = initialFeeling {
            switch feeling {
            case "精神饱满": return "\(baseGreeting)，活力满满的一天！"
            case "有些疲惫": return "\(baseGreeting)，觉得累就先抱抱自己吧。"
            case "手脚冰凉": return "\(baseGreeting)，记得多喝热水，保暖要紧。"
            case "身体燥热": return "\(baseGreeting)，清心寡欲，消暑降火。"
            case "焦虑压力": return "\(baseGreeting)，深呼吸，压力终会过去。"
            case "消化不良": return "\(baseGreeting)，少食多餐，养护肠胃。"
            default: return baseGreeting
            }
        }
        return baseGreeting
    }
    
    var userName: String {
        authService.currentUser?.displayName ?? "养生达人"
    }
    
    var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: Date())
    }
    
    var solarTermProgress: Double {
        solarTerm?.progress ?? 0
    }
    
    var isConstitutionTested: Bool {
        authService.currentUser?.hasTestedConstitution ?? false
    }

    // MARK: - Constitution Resolution
    private func resolveUserConstitution() -> ConstitutionType? {
        if let constitution = authService.currentUser?.constitution?.primary?.type {
            return constitution
        }

        if let serviceResult = constitutionService.userProfile?.currentResult?.primaryConstitution {
            return mapServiceConstitution(serviceResult)
        }

        return nil
    }

    private func mapServiceConstitution(_ dimension: ConstitutionDimension) -> ConstitutionType {
        switch dimension {
        case .qiXu:
            return .qiDeficiency
        case .yangXu:
            return .yangDeficiency
        case .yinXu:
            return .yinDeficiency
        case .tanShi:
            return .phlegmDampness
        case .shiRe:
            return .dampHeat
        case .xueYu:
            return .bloodStasis
        case .qiYu:
            return .qiStagnation
        case .teBing:
            return .inherited
        case .pingHe:
            return .balanced
        }
    }
    
    var daysUntilNext: String {
        guard let days = solarTerm?.daysUntilNext, let next = solarTerm?.nextSolarTerm else {
            return ""
        }
        return "距离\(next.name)还有\(days)天"
    }
}
