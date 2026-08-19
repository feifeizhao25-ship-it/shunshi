import SwiftUI

// MARK: - 三候展示卡片
/// 展示当前节气的三候信息（物候现象）
struct SanHouCard: View {
    let solarTerm: SolarTerm
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Section Title
            HStack {
                Text("三候")
                    .font(AppTypography.sectionTitle())
                    .foregroundColor(Color.AppText.primary(colorScheme))
                
                Spacer()
                
                // Current Hou indicator
                if let currentHou = getCurrentHou() {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 10))
                        Text("当前：\(currentHou.name)")
                            .font(AppTypography.label())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(solarTerm.themeColor)
                    )
                }
            }
            
            // San Hou Timeline
            HStack(alignment: .top, spacing: 0) {
                ForEach(0..<3, id: \.self) { index in
                    sanHouItem(index: index)
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - San Hou Item
    private func sanHouItem(index: Int) -> some View {
        let houData = getSanHouData(for: index)
        let isActive = isCurrentHou(index: index)
        
        return VStack(spacing: AppSpacing.sm) {
            // Timeline Dot
            ZStack {
                Circle()
                    .fill(isActive ? solarTerm.themeColor : Color.gray.opacity(0.1))
                    .frame(width: isActive ? 16 : 10, height: isActive ? 16 : 10)
                
                if isActive {
                    Circle()
                        .stroke(solarTerm.themeColor.opacity(0.3), lineWidth: 4)
                        .frame(width: 24, height: 24)
                }
            }
            
            // Hou Label
            Text(houLabel(for: index))
                .font(AppTypography.label())
                .foregroundColor(isActive ? solarTerm.themeColor : .secondary)
            
            // Hou Name
            Text(houData.name)
                .font(AppTypography.headline(14))
                .foregroundColor(isActive ? Color.AppText.primary(colorScheme) : Color.AppText.secondary(colorScheme))
                .multilineTextAlignment(.center)
            
            // Description
            Text(houData.description)
                .font(AppTypography.caption())
                .foregroundColor(Color.AppText.muted(colorScheme))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Days Range
            Text("第\(houData.startDay)-\(houData.endDay)天")
                .font(.system(size: 10))
                .foregroundColor(Color.AppText.muted(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .opacity(isActive ? 1.0 : 0.6)
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.spring(), value: isActive)
    }
    
    // MARK: - Helper Methods
    private func houLabel(for index: Int) -> String {
        switch index {
        case 0: return "初候"
        case 1: return "二候"
        case 2: return "三候"
        default: return ""
        }
    }
    
    private func getSanHouData(for index: Int) -> (name: String, description: String, startDay: Int, endDay: Int) {
        // 从节气数据中获取三候信息
        let sanHou = getSanHouFromSolarTerm()
        guard index < sanHou.count else {
            return ("待更新", "物候现象", 1, 5)
        }
        return sanHou[index]
    }
    
    private func getSanHouFromSolarTerm() -> [(name: String, description: String, startDay: Int, endDay: Int)] {
        // 从节气数据中获取三候信息
        return solarTerm.sanHou.map { ($0.name, $0.description, $0.startDay, $0.endDay) }
    }
    
    private func getCurrentHou() -> (name: String, index: Int)? {
        let day = solarTerm.currentDay
        if day <= 5 {
            return ("初候", 0)
        } else if day <= 10 {
            return ("二候", 1)
        } else {
            return ("三候", 2)
        }
    }
    
    private func isCurrentHou(index: Int) -> Bool {
        guard let current = getCurrentHou() else { return false }
        return current.index == index
    }
}

// MARK: - Preview
#Preview {
    SanHouCard(solarTerm: .preview)
        .padding()
        .background(Color.Background.dark)
        .preferredColorScheme(.dark)
}

