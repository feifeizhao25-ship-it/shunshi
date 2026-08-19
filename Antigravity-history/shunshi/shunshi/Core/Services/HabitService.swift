import Foundation
import Combine

// MARK: - Habit Service
final class HabitService: ObservableObject {
    static let shared = HabitService()
    
    @Published var habits: [Habit] = []
    
    private let storageKey = "shunshi_habits"
    
    private init() {
        loadHabits()
        if habits.isEmpty {
            setupDefaultHabits()
        }
    }
    
    func toggleHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            var updatedHabit = habits[index]
            if updatedHabit.isCompletedToday {
                // Already completed, we don't handle un-toggling for now or we reset the date
            } else {
                updatedHabit.lastCompletedDate = Date()
                updatedHabit.streak += 1
            }
            habits[index] = updatedHabit
            saveHabits()
        }
    }
    
    func addHabit(title: String, icon: String, category: Habit.HabitCategory) {
        let newHabit = Habit(
            id: UUID(),
            title: title,
            icon: icon,
            category: category,
            frequency: .daily,
            streak: 0,
            lastCompletedDate: nil
        )
        habits.append(newHabit)
        saveHabits()
    }
    
    private func setupDefaultHabits() {
        habits = [
            Habit(id: UUID(), title: "晨起温水", icon: "drop.fill", category: .diet, frequency: .daily, streak: 0, lastCompletedDate: nil),
            Habit(id: UUID(), title: "午后散步", icon: "figure.walk", category: .exercise, frequency: .daily, streak: 0, lastCompletedDate: nil),
            Habit(id: UUID(), title: "睡前泡脚", icon: "wind", category: .habit, frequency: .daily, streak: 0, lastCompletedDate: nil)
        ]
        saveHabits()
    }
    
    private func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadHabits() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        }
    }
}
