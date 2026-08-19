import XCTest
@testable import shunshi

/// 集成测试 - 测试真实的AI服务和完整功能流程
/// 这些测试会调用真实的API，需要网络连接
@MainActor
final class IntegrationTests: XCTestCase {
    
    // MARK: - AI Consultant Tests
    
    func testRealAIConsultantResponse() async throws {
        let viewModel = ConsultantViewModel()
        
        // 创建新会话
        await viewModel.startNewSession()
        
        // 等待会话创建
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        XCTAssertNotNil(viewModel.currentSession, "应该创建了会话")
        XCTAssertFalse(viewModel.messages.isEmpty, "应该有问候消息")
        
        // 发送真实问题
        viewModel.inputText = "我最近总是感觉疲劳，有什么养生建议吗？"
        await viewModel.sendMessage()
        
        // 等待AI响应
        var retries = 0
        while viewModel.isSending && retries < 30 {
            try await Task.sleep(nanoseconds: 500_000_000)
            retries += 1
        }
        
        XCTAssertFalse(viewModel.isSending, "发送应该完成")
        XCTAssertGreaterThanOrEqual(viewModel.messages.count, 2, "应该至少有用户消息和AI回复")
        
        // 验证AI回复的质量
        let aiResponse = viewModel.messages.last { $0.role == .assistant }
        XCTAssertNotNil(aiResponse, "应该有AI回复")
        XCTAssertGreaterThan(aiResponse?.content.count ?? 0, 20, "AI回复应该有实质内容")
        
        // 验证不是预设回复
        let mockResponses = ["Mock AI Response", "测试回复", "默认回复"]
        let isRealResponse = !mockResponses.contains { aiResponse?.content.contains($0) ?? false }
        XCTAssertTrue(isRealResponse, "应该是真实的AI回复，不是Mock数据")
        
        print("✅ AI回复内容: \(aiResponse?.content ?? "")")
    }
    
    func testAIConsultantFollowUpQuestions() async throws {
        let viewModel = ConsultantViewModel()
        await viewModel.startNewSession()
        
        viewModel.inputText = "我想了解大寒节气的养生知识"
        await viewModel.sendMessage()
        
        // 等待响应
        var retries = 0
        while viewModel.isSending && retries < 30 {
            try await Task.sleep(nanoseconds: 500_000_000)
            retries += 1
        }
        
        // 验证有推荐的后续问题
        XCTAssertFalse(viewModel.suggestedQuestions.isEmpty, "应该有推荐的后续问题")
        print("✅ 推荐问题: \(viewModel.suggestedQuestions)")
    }
    
    // MARK: - AI Constitution Test
    
    func testRealAIConstitutionTest() async throws {
        let viewModel = AIConstitutionTestViewModel()
        
        await viewModel.startTest()
        
        // 等待初始化
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        XCTAssertNotNil(viewModel.currentQuestion, "应该有当前问题")
        XCTAssertFalse(viewModel.messages.isEmpty, "应该有消息")
        
        // 回答几个问题（使用不同的答案以触发AI对话）
        let responses = [
            ("经常", 5),
            ("有时", 3),
            ("偶尔", 2),
            ("很少", 1),
            ("从不", 1)
        ]
        
        var questionCount = 0
        for (text, value) in responses {
            guard viewModel.currentQuestion != nil && questionCount < 5 else { break }
            
            await viewModel.processUserResponse(text: text, value: value)
            questionCount += 1
            
            // 等待处理
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        XCTAssertGreaterThan(questionCount, 0, "应该回答了一些问题")
        print("✅ 已回答 \(questionCount) 个问题")
        
        // 验证消息中有AI的对话式回复
        let aiMessages = viewModel.messages.filter { $0.role == .assistant }
        XCTAssertGreaterThan(aiMessages.count, 1, "应该有多条AI消息")
        
        // 检查是否有真实的对话内容
        let hasRealContent = aiMessages.contains { message in
            message.content.count > 10 && 
            !message.content.contains("Mock") &&
            !message.content.contains("测试")
        }
        XCTAssertTrue(hasRealContent, "应该有真实的AI对话内容")
    }
    
    // MARK: - Solar Term Service
    
    func testSolarTermDataIntegrity() async throws {
        let repository = SolarTermRepository()
        
        let currentTerm = await repository.getCurrentSolarTerm()
        XCTAssertNotNil(currentTerm, "应该能获取当前节气")
        
        if let term = currentTerm {
            XCTAssertFalse(term.name.isEmpty, "节气名称不应为空")
            XCTAssertFalse(term.nameEn.isEmpty, "英文名称不应为空")
            XCTAssertFalse(term.description.isEmpty, "描述不应为空")
            XCTAssertGreaterThan(term.sanHou.count, 0, "应该有三候数据")
            
            print("✅ 当前节气: \(term.name) (\(term.nameEn))")
            print("   日期范围: \(term.startDate) - \(term.endDate)")
            print("   当前第 \(term.currentDay) 天")
        }
        
        // 测试所有24节气数据
        let allTerms = await repository.getAllSolarTerms()
        XCTAssertEqual(allTerms.count, 24, "应该有24个节气")
        
        for term in allTerms {
            XCTAssertFalse(term.name.isEmpty, "\(term.id) 的名称不应为空")
            XCTAssertEqual(term.sanHou.count, 3, "\(term.name) 应该有3个候")
        }
        
        print("✅ 所有24节气数据完整")
    }
    
    // MARK: - Wellness Service
    
    func testWellnessRecordService() async throws {
        let service = WellnessRecordService.shared
        
        // 测试获取养生指数
        let score = service.calculateTodayScore()
        XCTAssertGreaterThanOrEqual(score, 0, "养生指数应该 >= 0")
        XCTAssertLessThanOrEqual(score, 100, "养生指数应该 <= 100")
        
        print("✅ 当前养生指数: \(score)")
        
        // 测试获取今日指标
        let metrics = service.getTodayMetrics()
        XCTAssertEqual(metrics.count, 5, "应该有5个维度的指标")
        
        for metric in metrics {
            print("   \(metric.title): \(metric.currentValue)/\(metric.targetValue) \(metric.unit)")
        }
        
        // 测试打卡功能
        let initialCheckIns = service.habitCheckIns.filter {
            Calendar.current.isDate($0.date, inSameDayAs: Date()) && $0.completed
        }.count
        
        // 模拟打卡
        service.toggleHabitCheckIn(habitId: "early_sleep")
        
        let newCheckIns = service.habitCheckIns.filter {
            Calendar.current.isDate($0.date, inSameDayAs: Date()) && $0.completed
        }.count
        
        XCTAssertNotEqual(initialCheckIns, newCheckIns, "打卡状态应该改变")
        
        print("✅ 打卡功能正常")
    }
    
    // MARK: - Recipe Service
    
    func testRecipeRecommendations() async throws {
        let repository = WellnessRepository.shared
        
        // 测试获取今日推荐
        let todayRecipes = await repository.getTodayRecommendedRecipes(limit: 3)
        XCTAssertGreaterThan(todayRecipes.count, 0, "应该有今日推荐食谱")
        
        for recipe in todayRecipes {
            XCTAssertFalse(recipe.name.isEmpty, "食谱名称不应为空")
            XCTAssertFalse(recipe.description.isEmpty, "食谱描述不应为空")
            XCTAssertGreaterThan(recipe.effects.count, 0, "应该有功效说明")
            
            print("✅ 推荐食谱: \(recipe.name)")
            print("   功效: \(recipe.effects.joined(separator: ", "))")
        }
    }
    
    // MARK: - Image Generation
    
    func testAIImageGeneration() async throws {
        let service = FalAIService.shared
        
        let prompt = "Traditional Chinese ink wash painting of 大寒 (Great Cold), winter landscape, artistic"
        
        do {
            let image = try await service.generateImage(prompt: prompt)
            XCTAssertNotNil(image, "应该生成图片")
            
            // 验证图片尺寸
            XCTAssertGreaterThan(image.size.width, 0, "图片宽度应该大于0")
            XCTAssertGreaterThan(image.size.height, 0, "图片高度应该大于0")
            
            print("✅ AI图片生成成功: \(image.size.width)x\(image.size.height)")
        } catch {
            XCTFail("图片生成失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - End-to-End Flow
    
    func testCompleteUserJourney() async throws {
        print("\n🚀 开始完整用户旅程测试...\n")
        
        // 1. 启动应用，获取节气信息
        let solarTermRepo = SolarTermRepository()
        let currentTerm = await solarTermRepo.getCurrentSolarTerm()
        XCTAssertNotNil(currentTerm)
        print("1️⃣ 获取当前节气: \(currentTerm?.name ?? "未知")")
        
        // 2. 查看养生指数
        let wellnessService = WellnessRecordService.shared
        let score = wellnessService.calculateTodayScore()
        print("2️⃣ 当前养生指数: \(score)")
        
        // 3. 获取今日推荐食谱
        let wellnessRepo = WellnessRepository.shared
        let recipes = await wellnessRepo.getTodayRecommendedRecipes(limit: 2)
        print("3️⃣ 今日推荐食谱: \(recipes.map { $0.name }.joined(separator: ", "))")
        
        // 4. 与AI顾问对话
        let consultant = ConsultantViewModel()
        await consultant.startNewSession()
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        consultant.inputText = "根据\(currentTerm?.name ?? "当前节气")，我应该注意什么？"
        await consultant.sendMessage()
        
        var retries = 0
        while consultant.isSending && retries < 30 {
            try await Task.sleep(nanoseconds: 500_000_000)
            retries += 1
        }
        
        let aiResponse = consultant.messages.last { $0.role == .assistant }
        print("4️⃣ AI顾问回复: \(aiResponse?.content.prefix(100) ?? "")...")
        
        // 5. 验证整体流程
        XCTAssertNotNil(currentTerm, "应该获取到节气")
        XCTAssertGreaterThan(score, 0, "应该有养生指数")
        XCTAssertGreaterThan(recipes.count, 0, "应该有推荐食谱")
        XCTAssertNotNil(aiResponse, "应该有AI回复")
        XCTAssertGreaterThan(aiResponse?.content.count ?? 0, 20, "AI回复应该有实质内容")
        
        print("\n✅ 完整用户旅程测试通过！\n")
    }
}
