import SwiftUI

// MARK: - Habit Check-In Card
struct HabitCheckInCard: View {
    @StateObject private var habitService = HabitService.shared
    @Environment(\.colorScheme) private var colorScheme
    var careStatus: AIAgentService.CareStatus?
    
    private var headerTitle: String {
        guard let status = careStatus else { return "每日功课" }
        switch status {
        case .stable: return "每日功课"
        case .needsAttention: return "每日功课 (调理期)"
        case .escalate: return "每日功课 (静养期)"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: headerTitle, icon: "pencil.and.outline")
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                ForEach(visibleHabits) { habit in
                    habitRow(habit)
                }
            }
        }
        .padding(.top, AppSpacing.sm)
    }
    
    // Filter habits based on care status (Quiet mode logic)
    private var visibleHabits: [Habit] {
        guard let status = careStatus, status == .escalate else {
            return habitService.habits
        }
        // In Escalate mode, hide high-intensity exercise
        return habitService.habits.filter { $0.category != .exercise }
    }
    
    private func habitRow(_ habit: Habit) -> some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(habit.category.color.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: habit.icon)
                    .foregroundColor(habit.category.color)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.title)
                    .font(AppTypography.headline(16))
                    .foregroundColor(Color.AppText.primary(colorScheme))
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("已坚持 \(habit.streak) 天")
                        .font(AppTypography.caption())
                        .foregroundColor(Color.AppText.secondary(colorScheme))
                }
            }
            
            Spacer()
            
            // Check Button
            Button(action: {
                withAnimation(.spring()) {
                    habitService.toggleHabit(habit)
                }
            }) {
                ZStack {
                    Circle()
                        .stroke(habit.isCompletedToday ? habit.category.color : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 28, height: 28)
                    
                    if habit.isCompletedToday {
                        Circle()
                            .fill(habit.category.color)
                            .frame(width: 18, height: 18)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.Surface.adaptive(colorScheme))
        .cornerRadius(AppRadius.xl)
        .shadow(color: .black.opacity(0.02), radius: 5, y: 2)
    }
}

// MARK: - Preview
#Preview {
    VStack {
        HabitCheckInCard()
            .padding()
    }
    .background(Color.Background.dark)
    .preferredColorScheme(.dark)
}
