import SwiftUI

// MARK: - WuWei Grid (五维养生入口)
struct WuWeiGrid: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appStateService: AppStateService
    
    // Inject theme color from parent view
    var themeColor: Color = .shunshiPrimary
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Section Title
            HStack {
                Text("五维养生")
                    .font(AppTypography.sectionTitle())
                    .foregroundColor(Color.AppText.primary(colorScheme))
                
                Spacer()
                
                NavigationLink {
                    WellnessView()
                } label: {
                    Text("查看全部")
                        .font(AppTypography.label())
                        .foregroundColor(themeColor)
                }
            }
            
            // Grid - 直接跳转到对应页面
            HStack(spacing: 0) {
                NavigationLink {
                    DietView()
                } label: {
                    WuWeiGridItemContent(type: .diet, themeColor: themeColor)
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink {
                    LivingView()
                } label: {
                    WuWeiGridItemContent(type: .living, themeColor: themeColor)
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink {
                    ExerciseView()
                } label: {
                    WuWeiGridItemContent(type: .exercise, themeColor: themeColor)
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink {
                    AcupointView()
                } label: {
                    WuWeiGridItemContent(type: .acupoint, themeColor: themeColor)
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink {
                    EmotionView()
                } label: {
                    WuWeiGridItemContent(type: .emotion, themeColor: themeColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - WuWei Grid Item Content (无状态纯视图)
struct WuWeiGridItemContent: View {
    let type: WuWeiType
    var themeColor: Color = .shunshiPrimary
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.Surface.adaptive(colorScheme))
                    .frame(width: AppSize.wuWeiIconSize, height: AppSize.wuWeiIconSize)
                    .shadow(
                        color: colorScheme == .dark ? .clear : .black.opacity(0.05),
                        radius: 4,
                        y: 2
                    )
                
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(themeColor)
                    .scaleEffect(1.0) // Placeholder for potential state
            }
            
            // Title
            Text(type.displayName)
                .font(AppTypography.label())
                .foregroundColor(Color.AppText.secondary(colorScheme))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - WuWei Grid Item
struct WuWeiGridItem: View {
    let type: WuWeiType
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.sm) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.Surface.adaptive(colorScheme))
                        .frame(width: AppSize.wuWeiIconSize, height: AppSize.wuWeiIconSize)
                        .shadow(
                            color: colorScheme == .dark ? .clear : .black.opacity(0.05),
                            radius: 4,
                            y: 2
                        )
                    
                    Image(systemName: type.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.shunshiPrimary)
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(AppAnimation.fast, value: isPressed)
                
                // Title
                Text(type.displayName)
                    .font(AppTypography.label())
                    .foregroundColor(Color.AppText.secondary(colorScheme))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Preview
#Preview {
    WuWeiGrid()
        .padding()
        .background(Color.Background.dark)
        .preferredColorScheme(.dark)
        .environmentObject(AppStateService.shared)
}
