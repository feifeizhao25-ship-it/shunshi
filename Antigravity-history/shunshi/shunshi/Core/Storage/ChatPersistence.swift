import Foundation
import SwiftData

// MARK: - Chat Message Entity
@Model
final class ChatMessageEntity {
    @Attribute(.unique) var id: String
    var sessionId: String
    var role: String // "user", "assistant", "system"
    var content: String
    var timestamp: Date
    
    // Optional: Suggested actions stored as JSON string
    var suggestionsJSON: String?
    
    init(id: String = UUID().uuidString, sessionId: String, role: String, content: String, timestamp: Date = Date(), suggestions: [String]? = nil) {
        self.id = id
        self.sessionId = sessionId
        self.role = role
        self.content = content
        self.timestamp = timestamp
        
        if let suggestions = suggestions, let data = try? JSONEncoder().encode(suggestions) {
            self.suggestionsJSON = String(data: data, encoding: .utf8)
        }
    }
    
    var suggestions: [String] {
        guard let json = suggestionsJSON, let data = json.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }
}

// MARK: - Chat Session Entity
@Model
final class ChatSessionEntity {
    @Attribute(.unique) var id: String
    var title: String
    var createdAt: Date
    var lastUpdatedAt: Date
    var summary: String?
    
    init(id: String = UUID().uuidString, title: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.lastUpdatedAt = createdAt
    }
}
