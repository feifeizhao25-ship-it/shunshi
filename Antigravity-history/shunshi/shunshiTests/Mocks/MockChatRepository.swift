import Foundation
@testable import shunshi

class MockChatRepository: ChatRepositoryProtocol {
    var createSessionResult: ChatSession?
    var sendMessageResult: ChatMessage?
    var getMessagesResult: PaginatedResult<ChatMessage> = PaginatedResult(items: [], page: 1, pageSize: 20, total: 0, hasMore: false)
    var getSessionsResult: PaginatedResult<ChatSession> = PaginatedResult(items: [], page: 1, pageSize: 20, total: 0, hasMore: false)
    
    var errorToThrow: Error?

    func createSession(context: ChatContext) async throws -> ChatSession {
        if let error = errorToThrow { throw error }
        guard let result = createSessionResult else {
            throw AppError.operationFailed("Mock create session failed")
        }
        return result
    }

    func sendMessage(sessionId: String, content: String, messageType: String) async throws -> ChatMessage {
        if let error = errorToThrow { throw error }
        guard let result = sendMessageResult else {
            throw AppError.operationFailed("Mock send message failed")
        }
        return result
    }

    func getMessages(sessionId: String, page: Int, pageSize: Int) async throws -> PaginatedResult<ChatMessage> {
        if let error = errorToThrow { throw error }
        return getMessagesResult
    }

    func getSessions(page: Int, pageSize: Int) async throws -> PaginatedResult<ChatSession> {
        if let error = errorToThrow { throw error }
        return getSessionsResult
    }
}
