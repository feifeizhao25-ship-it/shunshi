import Foundation
import SwiftData

// MARK: - Chat Persistence Service
@MainActor
final class ChatPersistenceService {
    static let shared = ChatPersistenceService()
    
    // We need to keep a reference to the context, usually provided by the app container
    // But for a shared singleton, we can use a helper to get it from the main thread/app
    private var modelContext: ModelContext? {
        // In a real app, this might be injected or retrieved from a custom container
        // For simplicity in this agent environment, we assume the modelContainer is set up
        // and we can access it if we had a reference.
        // A better pattern for SwiftData is often to pass the context down or use an actor.
        return nil // Placeholder - will implement a better pattern below
    }
    
    // For this environment, I'll use a simpler approach: a dedicated actor to handle SwiftData
    private let storage: ChatPersistenceActor
    
    private init() {
        let container = try! ModelContainer(for: ChatMessageEntity.self, ChatSessionEntity.self)
        self.storage = ChatPersistenceActor(container: container)
    }
    
    func saveMessage(sessionId: String, role: String, content: String, suggestions: [String]? = nil) async {
        await storage.saveMessage(sessionId: sessionId, role: role, content: content, suggestions: suggestions)
    }
    
    func getMessages(sessionId: String) async -> [ChatMessageEntity] {
        return await storage.getMessages(sessionId: sessionId)
    }
    
    func createSession(id: String, title: String) async {
        await storage.createSession(id: id, title: title)
    }
    
    func getAllSessions() async -> [ChatSessionEntity] {
        return await storage.getAllSessions()
    }
}

// MARK: - Chat Persistence Actor
actor ChatPersistenceActor {
    let container: ModelContainer
    let context: ModelContext
    
    init(container: ModelContainer) {
        self.container = container
        self.context = ModelContext(container)
    }
    
    func saveMessage(sessionId: String, role: String, content: String, suggestions: [String]?) {
        let message = ChatMessageEntity(sessionId: sessionId, role: role, content: content, suggestions: suggestions)
        context.insert(message)
        
        // Update session's last activity
        let descriptor = FetchDescriptor<ChatSessionEntity>(predicate: #Predicate { $0.id == sessionId })
        if let session = try? context.fetch(descriptor).first {
            session.lastUpdatedAt = Date()
        }
        
        try? context.save()
    }
    
    func getMessages(sessionId: String) -> [ChatMessageEntity] {
        let descriptor = FetchDescriptor<ChatMessageEntity>(
            predicate: #Predicate { $0.sessionId == sessionId },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func createSession(id: String, title: String) {
        let session = ChatSessionEntity(id: id, title: title)
        context.insert(session)
        try? context.save()
    }
    
    func getAllSessions() -> [ChatSessionEntity] {
        let descriptor = FetchDescriptor<ChatSessionEntity>(sortBy: [SortDescriptor(\.lastUpdatedAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }
}
