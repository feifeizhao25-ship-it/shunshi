import SwiftUI

// MARK: - Solar Ritual Section (融合时间轴与打卡)
struct SolarRitualSection: View {
    @ObservedObject var recordService: WellnessRecordService
    let rituals: [HomeViewModel.RitualItem]
    var themeColor: Color = .shunshiPrimary
    @Environment(\.colorScheme) private var colorScheme
    
    private var currentPeriod: RitualPeriod {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 11 { return .morning }
        if hour < 17 { return .afternoon }
        return .evening
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                Text("今日养成")
                    .font(AppTypography.sectionTitle())
                    .foregroundColor(Color.AppText.primary(colorScheme))
                
                Spacer()
                
                Text("\(completedCount) / \(rituals.count) 已完成")
                    .font(AppTypography.label())
                    .foregroundColor(themeColor)
            }
            
            // Ritual Timeline
            VStack(spacing: 0) {
                ritualGroup(period: .morning)
                ritualGroup(period: .afternoon)
                ritualGroup(period: .evening)
            }
        }
        .padding(AppSpacing.lg)
        .glassCardStyle()
    }
    
    private var completedCount: Int {
        let today = Date()
        return recordService.habitCheckIns.filter { 
            Calendar.current.isDate($0.date, inSameDayAs: today) && $0.completed 
        }.count
    }
    
    
    // MARK: - Ritual Groups
    private func ritualGroup(period: RitualPeriod) -> some View {
        let items = rituals(for: period)
        let isActive = currentPeriod == period
        let isPast = currentPeriod.order > period.order
        
        return HStack(alignment: .top, spacing: 16) {
            // Left: Timeline Line
            VStack(spacing: 0) {
                Circle()
                    .fill(isActive ? themeColor : (isPast ? themeColor.opacity(0.3) : Color.secondary.opacity(0.2)))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle().stroke(themeColor.opacity(0.2), lineWidth: isActive ? 4 : 0)
                    )
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            
            // Right: Content
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text(period.displayName)
                    .font(AppTypography.subheadline(14).bold())
                    .foregroundColor(isActive ? themeColor : (isPast ? .secondary : Color.AppText.primary(colorScheme)))
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach(items) { ritual in
                            ritualCard(ritual: ritual)
                        }
                    }
                    .padding(.bottom, period == .evening ? 0 : AppSpacing.lg)
                }
            }
        }
    }
    
    private func ritualCard(ritual: HomeViewModel.RitualItem) -> some View {
        let isCompleted = recordService.habitCheckIns.contains { 
            Calendar.current.isDate($0.date, inSameDayAs: Date()) && $0.habitId == ritual.id && $0.completed 
        }
        
        return Button {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                recordService.toggleHabitCheckIn(habitId: ritual.id)
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? themeColor : themeColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                        .scaleEffect(isCompleted ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCompleted)
                    
                    Image(systemName: isCompleted ? "checkmark" : ritual.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isCompleted ? .white : themeColor)
                        .scaleEffect(isCompleted ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.05), value: isCompleted)
                }
                
                Text(ritual.name)
                    .font(AppTypography.caption(12).weight(.medium))
                    .foregroundColor(isCompleted ? Color.AppText.primary(colorScheme) : Color.AppText.secondary(colorScheme))
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Data Helpers
    enum RitualPeriod {
        case morning, afternoon, evening
        
        var displayName: String {
            switch self {
            case .morning: return "晨起 · 唤醒"
            case .afternoon: return "午后 · 舒容"
            case .evening: return "暮时 · 安神"
            }
        }
        
        var order: Int {
            switch self {
            case .morning: return 0
            case .afternoon: return 1
            case .evening: return 2
            }
        }
    }
    
    private func rituals(for period: RitualPeriod) -> [HomeViewModel.RitualItem] {
        rituals.filter { ritual in
            switch period {
            case .morning: return ritual.period == .morning
            case .afternoon: return ritual.period == .afternoon
            case .evening: return ritual.period == .evening
            }
        }
    }
}

extension View {
    func glassCardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: AppRadius.xl)
                    .fill(Color.Surface.adaptive(.light).opacity(0.8))
                    .background(BlurView(style: .systemMaterial))
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct RitualSection_Previews: PreviewProvider {
    static var previews: some View {
        SolarRitualSection(
            recordService: WellnessRecordService.shared,
            rituals: [
                .init(id: "1", name: "Test Ritual", icon: "drop.fill", period: .morning)
            ]
        )
            .padding()
            .background(Color.Background.dark)
            .preferredColorScheme(.dark)
    }
}
