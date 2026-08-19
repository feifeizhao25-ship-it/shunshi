import Foundation
import SwiftUI
import Combine

// MARK: - AI Constitution Test View Model
@MainActor
final class AIConstitutionTestViewModel: ObservableObject {
    @Published var messages: [TestChatMessage] = []
    @Published var isProcessing: Bool = false
    @Published var progress: Double = 0
    @Published var assessmentResult: ConstitutionSystem.ConstitutionResult?
    @Published var showResult: Bool = false
    
    // Dependencies
    private let aiService = AIAgentService.shared
    private let authService = AuthService.shared
    private let constitutionSystem = ConstitutionSystem()
    
    // Internal state
    private var answers: [String: Int] = [:]
    private var allQuestions = ConstitutionSystem.getTestQuestions()
    private var currentQuestionIndex: Int = 0
    private var isFinished: Bool = false
    
    // Vibe constants
    private let conversationalGlue = [
        "好滴，我记下了。",
        "嗯嗯，我明白了。",
        "这样啊，那我们再看看这项...",
        "好，这种情况确实挺普遍的。",
        "明白了，那接下来的这个呢？",
        "懂了，那这方面你感觉怎么样？"
    ]
    
    struct TestChatMessage: Identifiable {
        let id = UUID()
        let role: String // "user" or "assistant"
        let content: String
        let timestamp = Date()
    }
    
    init() {
        // Initialization
    }
    
    func startTest() async {
        messages = []
        answers = [:]
        currentQuestionIndex = 0
        progress = 0
        isFinished = false
        isProcessing = false
        showResult = false
        
        // Initial greeting from AI
        await addAIMessage("你好呀！我是顺时。为了能更好地了解你的身体，我们来像朋友一样聊聊你的日常感受吧，好吗？")
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        // Ask the first question
        await askNextQuestion()
    }
    
    private func askNextQuestion() async {
        guard !isFinished else { return }
        
        guard currentQuestionIndex < allQuestions.count else {
            await finishTest()
            return
        }
        
        let question = allQuestions[currentQuestionIndex]
        await addAIMessage(question.text)
    }
    
    func processUserResponse(text: String, value: Int? = nil) async {
        guard !isProcessing, !isFinished else { return }
        
        guard let finalValue = value else {
            // Natural language response
            await addUserMessage(text)
            await analyzeNaturalLanguageResponse(text)
            return
        }
        
        // Button response
        let optionText = allQuestions[currentQuestionIndex].options.first(where: { $0.value == finalValue })?.text ?? text
        await addUserMessage(optionText)
        
        let question = allQuestions[currentQuestionIndex]
        answers[question.id] = finalValue
        
        currentQuestionIndex += 1
        progress = Double(currentQuestionIndex) / Double(allQuestions.count)
        
        if currentQuestionIndex < allQuestions.count {
            // Add some "glue" to feel more conversational
            let glue = conversationalGlue.randomElement() ?? "好滴。"
            await addAIMessage(glue)
            try? await Task.sleep(nanoseconds: 600_000_000)
            await askNextQuestion()
        } else {
            await finishTest()
        }
    }
    
    private func analyzeNaturalLanguageResponse(_ text: String) async {
        isProcessing = true
        defer { isProcessing = false }
        
        guard currentQuestionIndex < allQuestions.count else { return }
        let question = allQuestions[currentQuestionIndex]
        
        let prompt = """
        你是一个中医体质测评助手。用户对问题"\(question.text)"的回答是："\(text)"。
        请根据中医体质判别量表的5级评分标准，判断用户的程度：
        1: 从不 (程度极轻/完全没有)
        2: 偶尔 (程度较轻/很少有)
        3: 有时 (程度中等/偶尔有)
        4: 经常 (程度较重/频繁有)
        5: 总是 (程度极重/持续有)
        
        请直接输出一个1-5之间的数字。不要输出任何其他解释。
        """
        
        do {
            // Use LLM directly for structured parsing
            let messages = [ChatCompletionMessage(role: "user", content: prompt)]
            let response = try await LLMService.shared.chat(messages: messages, model: .qwen2_5_7B, temperature: 0.1)
            let cleanedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if let value = Int(cleanedResponse), (1...5).contains(value) {
                answers[question.id] = value
                currentQuestionIndex += 1
                progress = Double(currentQuestionIndex) / Double(allQuestions.count)
                
                if currentQuestionIndex < allQuestions.count {
                    let glue = conversationalGlue.randomElement() ?? "明白了。"
                    await addAIMessage(glue)
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await askNextQuestion()
                } else {
                    await finishTest()
                }
            } else {
                await addAIMessage("抱歉，我没太明白。你是想说频率比较高，还是比较低呢？（比如：偶尔、经常）")
            }
        } catch {
            await addAIMessage("刚才网络有点开小差，你能再说一次吗？")
        }
    }
    
    private func finishTest() async {
        guard !isFinished else { return }
        isFinished = true
        isProcessing = true
        
        await addAIMessage("好的，我大概了解了。正在为你分析体质特征，请稍候...")
        
        // Calculate result
        // Simulate a small delay for "analysis" feeling
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let result = ConstitutionSystem.calculateConstitutionResult(answers: answers)
        assessmentResult = result
        
        // Ensure UI updates happen after result is set
        await MainActor.run {
            self.isProcessing = false
            self.showResult = true
        }
    }
    
    private func addAIMessage(_ text: String) async {
        messages.append(TestChatMessage(role: "assistant", content: text))
    }
    
    private func addUserMessage(_ text: String) async {
        messages.append(TestChatMessage(role: "user", content: text))
    }
    
    var currentQuestion: ConstitutionSystem.TestQuestion? {
        guard currentQuestionIndex < allQuestions.count else { return nil }
        return allQuestions[currentQuestionIndex]
    }
}
