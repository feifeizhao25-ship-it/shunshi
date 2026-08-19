import Foundation
import SwiftData

// MARK: - Care History Entity
@Model
final class CareHistoryEntity {
    var id: UUID
    var date: Date
    var userId: String
    var status: String // "stable", "needs_attention", "escalate"
    var summary: String?
    var followUpIntent: String? // JSON string or intent identifier
    
    init(date: Date = Date(), userId: String, status: String, summary: String? = nil, followUpIntent: String? = nil) {
        self.id = UUID()
        self.date = date
        self.userId = userId
        self.status = status
        self.summary = summary
        self.followUpIntent = followUpIntent
    }
}

// MARK: - Care History Service
@MainActor
final class CareHistoryService {
    static let shared = CareHistoryService()
    
    private let storage: CareHistoryActor
    
    private init() {
        let container = try! ModelContainer(for: CareHistoryEntity.self)
        self.storage = CareHistoryActor(container: container)
    }
    
    func recordEvent(userId: String, status: String, summary: String?, followUpIntent: String?) async {
        await storage.recordEvent(userId: userId, status: status, summary: summary, followUpIntent: followUpIntent)
    }
    
    func getHistory(userId: String, from startDate: Date, to endDate: Date) async -> [CareHistoryEntity] {
        await storage.getHistory(userId: userId, from: startDate, to: endDate)
    }
    
    func clearHistory(userId: String) async {
        await storage.clearHistory(userId: userId)
    }
}

// MARK: - Care History Actor
actor CareHistoryActor {
    let container: ModelContainer
    let context: ModelContext
    
    init(container: ModelContainer) {
        self.container = container
        self.context = ModelContext(container)
    }
    
    func recordEvent(userId: String, status: String, summary: String?, followUpIntent: String?) {
        let event = CareHistoryEntity(
            userId: userId,
            status: status,
            summary: summary,
            followUpIntent: followUpIntent
        )
        context.insert(event)
        try? context.save()
    }
    
    func getHistory(userId: String, from startDate: Date, to endDate: Date) -> [CareHistoryEntity] {
        let descriptor = FetchDescriptor<CareHistoryEntity>(
            predicate: #Predicate { $0.userId == userId && $0.date >= startDate && $0.date <= endDate },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func clearHistory(userId: String) {
        try? context.delete(model: CareHistoryEntity.self, where: #Predicate { $0.userId == userId })
        try? context.save()
    }
}
