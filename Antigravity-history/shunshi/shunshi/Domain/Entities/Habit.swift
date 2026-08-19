import Foundation
import SwiftUI

// MARK: - Habit Entity
struct Habit: Identifiable, Codable {
    let id: UUID
    let title: String
    let icon: String
    let category: HabitCategory
    let frequency: HabitFrequency
    var streak: Int
    var lastCompletedDate: Date?
    var isCompletedToday: Bool {
        guard let last = lastCompletedDate else { return false }
        return Calendar.current.isDateInToday(last)
    }
    
    enum HabitCategory: String, Codable, CaseIterable {
        case diet = "饮食"
        case exercise = "运动"
        case sleep = "睡眠"
        case mind = "情志"
        case habit = "习惯"
        
        var color: Color {
            switch self {
            case .diet: return .orange
            case .exercise: return .green
            case .sleep: return .indigo
            case .mind: return .purple
            case .habit: return .blue
            }
        }
    }
    
    enum HabitFrequency: String, Codable {
        case daily
        case weekly
    }
}

// MARK: - Habit Activity Record
struct HabitActivity: Identifiable, Codable {
    let id: UUID
    let habitId: UUID
    let date: Date
    let note: String?
}
