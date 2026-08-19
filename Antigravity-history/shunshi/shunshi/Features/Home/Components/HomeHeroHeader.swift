import SwiftUI

// MARK: - Home Hero Header (增强版顶部视图)
struct HomeHeroHeader: View {
    let solarTerm: SolarTerm
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var animation
    
    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return "\(formatter.string(from: solarTerm.startDate)) - \(formatter.string(from: solarTerm.endDate))"
    }
    
    private var daysUntilNextText: String {
        "距离\(solarTerm.nextSolarTerm?.name ?? "下个节气")还有 \(solarTerm.daysUntilNext) 天"
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background Layer: AI Image or Gradient
            ZStack {
                // Background Gradient based on season
                LinearGradient(
                    colors: [
                        solarTerm.themeColor.opacity(0.8),
                        solarTerm.themeColor.opacity(0.4),
                        Color.Background.adaptive(colorScheme).opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // AI Generated Background Pattern (Subtle)
                AIImageView(
                    prompt: "Traditional Chinese wash painting background for \(solarTerm.name), ethereal, minimal",
                    cacheKey: "home_header_bg_\(solarTerm.id)",
                    aspectRatio: 1,
                    cornerRadius: 0
                )
                .blendMode(.overlay)
                .opacity(0.3)
                .blur(radius: 20)
            }
            .frame(height: 280)
            .ignoresSafeArea(edges: .top)
            
            // Content Layer
            VStack(spacing: AppSpacing.sm) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(solarTerm.nameEn.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(solarTerm.name)
                            .font(.system(size: 48, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .tracking(8)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    // Progressive Indicator
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 4)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: solarTerm.progress)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 0) {
                            Text("\(Int(solarTerm.progress * 100))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Text("%")
                                .font(.system(size: 8))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Label(dateRangeText, systemImage: "calendar")
                            Text("·")
                            Text("第 \(solarTerm.currentDay) / \(solarTerm.totalDays) 天")
                        }
                        .font(AppTypography.caption(12).weight(.medium))
                        .foregroundColor(.white.opacity(0.9))
                        
                        Text(daysUntilNextText)
                            .font(AppTypography.subheadline(14).bold())
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                .background(
                    BlurView(style: .systemUltraThinMaterialDark)
                        .cornerRadius(AppRadius.lg)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .frame(height: 280)
        .background(Color.Background.adaptive(colorScheme))
    }
}

#Preview {
    HomeHeroHeader(solarTerm: .preview)
        .preferredColorScheme(.dark)
}
