import Testing
import Foundation
@testable import shunshi

@MainActor
struct ConsultantViewModelTests {
    
    @Test func testInitialState() {
        let chatRepo = MockChatRepository()
        let appState = AppStateService.shared
        let authService = AuthService.shared
        let aiAgent = MockAIAgentService()
        
        let viewModel = ConsultantViewModel(
            chatRepository: chatRepo,
            appStateService: appState,
            authService: authService,
            aiAgentService: aiAgent
        )
        
        #expect(viewModel.messages.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.isSending == false)
        #expect(viewModel.inputText == "")
    }
    
    @Test func testGreeting() {
        let viewModel = ConsultantViewModel()
        let greeting = viewModel.greeting
        #expect(!greeting.isEmpty)
        #expect(greeting.contains("我是您的养生顾问"))
    }
    
    @Test func testStartNewSession() async {
        let chatRepo = MockChatRepository()
        let aiAgent = MockAIAgentService()
        
        let viewModel = ConsultantViewModel(
            chatRepository: chatRepo,
            aiAgentService: aiAgent
        )
        
        // Mock successful session creation
        let session = ChatSession(id: "test_session", createdAt: Date(), messages: [], greeting: nil)
        chatRepo.createSessionResult = session
        
        await viewModel.startNewSession()
        
        #expect(viewModel.currentSession?.id == "test_session")
        #expect(viewModel.messages.count == 1) // One greeting message
        #expect(viewModel.messages.first?.role == .assistant)
    }
    
    @Test func testSendMessage() async {
        let chatRepo = MockChatRepository()
        let aiAgent = MockAIAgentService()
        
        let viewModel = ConsultantViewModel(
            chatRepository: chatRepo,
            aiAgentService: aiAgent
        )
        
        // Setup session
        viewModel.currentSession = ChatSession(id: "test_session", createdAt: Date(), messages: [], greeting: nil)
        
        // Mock AI response
        let aiResponse = AIAgentService.AIResponse(
            content: "Hello from AI",
            intent: .chat,
            scenario: nil,
            cards: nil,
            followUpQuestions: ["Question 1?"],
            shouldFollowUp: true,
            safetyLevel: .safe,
            timestamp: Date()
        )
        aiAgent.processUserMessageResult = aiResponse
        
        viewModel.inputText = "Hello AI"
        await viewModel.sendMessage()
        
        #expect(viewModel.messages.count == 2) // User message + AI response
        #expect(viewModel.messages.last?.content == "Hello from AI")
        #expect(viewModel.suggestedQuestions.contains("Question 1?"))
        #expect(viewModel.isSending == false)
    }
}
