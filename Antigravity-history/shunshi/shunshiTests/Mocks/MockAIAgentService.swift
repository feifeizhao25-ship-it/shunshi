import Foundation
@testable import shunshi

class MockAIAgentService: AIAgentServiceProtocol {
    var processUserMessageResult: AIAgentService.AIResponse?
    var processUserMessageError: Error?
    
    func processUserMessage(
        message: String,
        context: inout AIAgentService.UserContext,
        sessionId: String
    ) async throws -> AIAgentService.AIResponse {
        if let error = processUserMessageError {
            throw error
        }
        return processUserMessageResult ?? AIAgentService.AIResponse(
            content: "Mock AI Response",
            intent: .chat,
            scenario: nil,
            cards: nil,
            followUpQuestions: ["Follow up?"],
            shouldFollowUp: true,
            safetyLevel: .safe,
            timestamp: Date()
        )
    }
}
