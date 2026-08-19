import Foundation

/// Service responsible for managing the user's Wellness Streak and Growth Stage.
final class WellnessStreakService: ObservableObject {
    static let shared = WellnessStreakService()
    
    private let userRepository = UserRepository.shared
    
    /// Updates the user's streak based on today's activity.
    func recordActivity() async {
        guard var user = userRepository.currentUser else { return }
        let now = Date()
        let calendar = Calendar.current
        
        // 1. Update streak
        if let lastDate = UserDefaults.standard.object(forKey: "last_active_date") as? Date {
            if calendar.isDateInToday(lastDate) {
                // Already recorded today, no change to streak
                return
            } else if calendar.isDateInYesterday(lastDate) {
                // Consecutive day
                user.stats.currentStreak += 1
            } else {
                // Streak broken
                user.stats.currentStreak = 1
            }
        } else {
            // First time
            user.stats.currentStreak = 1
        }
        
        // 2. Update best streak
        if user.stats.currentStreak > user.stats.bestStreak {
            user.stats.bestStreak = user.stats.currentStreak
        }
        
        // 3. Update growth stage
        // Stages: 0: 种子(Seed), 1: 萌芽(Sprout), 2: 幼苗(Sapling), 3: 成木(Tree), 4: 开花(Flower), 5: 结果(Fruit)
        let oldStage = user.stats.zenGrowthStage
        if user.stats.currentStreak >= 30 { user.stats.zenGrowthStage = 5 }
        else if user.stats.currentStreak >= 14 { user.stats.zenGrowthStage = 4 }
        else if user.stats.currentStreak >= 7 { user.stats.zenGrowthStage = 3 }
        else if user.stats.currentStreak >= 3 { user.stats.zenGrowthStage = 2 }
        else if user.stats.currentStreak >= 1 { user.stats.zenGrowthStage = 1 }
        else { user.stats.zenGrowthStage = 0 }
        
        // Notify if stage changed
        if oldStage != user.stats.zenGrowthStage {
            // TODO: Post notification for UI to show celebration
            print("Growth stage changed to: \(user.stats.zenGrowthStage)")
        }
        
        // Save state
        UserDefaults.standard.set(now, forKey: "last_active_date")
        
        // In a real app, we would call an API here. 
        // For this demo, we update the local cache via the repository (if it supported it)
        // Since current UserRepository doesn't have an updateStats method, we'll just track locally for now.
    }
    
    /// Returns the name of the stage for UI display.
    func stageName(for stage: Int) -> String {
        switch stage {
        case 0: return "养生种子"
        case 1: return "初见萌芽"
        case 2: return "茁壮幼苗"
        case 3: return "稳健成木"
        case 4: return "繁花盛开"
        case 5: return "硕果累累"
        default: return "生命之树"
        }
    }
    
    /// Returns the emoji representing the stage.
    func stageEmoji(for stage: Int) -> String {
        switch stage {
        case 0: return "🌱"
        case 1: return "🌿"
        case 2: return "🪴"
        case 3: return "🌳"
        case 4: return "🌸"
        case 5: return "🍎"
        default: return "🌳"
        }
    }
}
