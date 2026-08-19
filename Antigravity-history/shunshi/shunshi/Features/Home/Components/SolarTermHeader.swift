import SwiftUI

// MARK: - Solar Term Header
struct SolarTermHeader: View {
    let solarTerm: SolarTerm
    @Environment(\.colorScheme) private var colorScheme
    @State private var floatOffset: CGFloat = 0
    @State private var showWheel = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background Image Placeholder
            backgroundLayer
            
            // Gradient Overlay
            gradientOverlay
            
            // Top Bar
            topBar
            
            // Content
            contentLayer
        }
        .frame(height: AppSize.homeHeaderHeight)
        .sheet(isPresented: $showWheel) {
            SolarTermWheelOverlay(solarTerms: SolarTermStaticData.solarTerms, currentTerm: solarTerm)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            withAnimation(AppAnimation.float) {
                floatOffset = -5
            }
        }
    }
    
    // MARK: - Background Layer
    private var backgroundLayer: some View {
        ZStack {
            // Base color matching season
            LinearGradient(
                colors: [
                    solarTerm.themeColor.opacity(0.3),
                    Color.Background.dark
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // AI Generated Atmospheric Image
            AIImageView(
                prompt: "Beautiful traditional Chinese landscape painting of \(solarTerm.nameEn) (\(solarTerm.name), \(solarTerm.season.displayName) season), ethereal ink wash style, soft colors, high quality, artistic atmosphere",
                cacheKey: "solarterm_bg_\(solarTerm.id)",
                aspectRatio: 1,
                cornerRadius: 0
            )
            .opacity(0.4)
            .scaleEffect(1.2)
            .offset(y: -50)
            .blur(radius: 20)
            .offset(y: floatOffset)
            .blendMode(.screen)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Gradient Overlay
    private var gradientOverlay: some View {
        VStack {
            Spacer()
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.Background.adaptive(colorScheme).opacity(0.8),
                    Color.Background.adaptive(colorScheme)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        VStack {
            HStack {
                IconButton(icon: "square.grid.2x2") {}
                Spacer()
                IconButton(icon: "calendar") {
                    showWheel = true
                }
                IconButton(icon: "bell") {}
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, 50)
            
            Spacer()
        }
    }
    
    // MARK: - Content Layer
    private var contentLayer: some View {
        VStack(spacing: AppSpacing.md) {
            // Solar Term Icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                Image(systemName: solarTerm.icon)
                    .font(.system(size: 28))
                    .foregroundColor(.shunshiPrimary)
            }
            .offset(y: floatOffset)
            
            // Solar Term Name
            Text(solarTerm.name)
                .font(.system(size: 48, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .tracking(8)
            
            // Date Info
            HStack(spacing: AppSpacing.sm) {
                Circle()
                    .fill(Color.shunshiPrimary)
                    .frame(width: 4, height: 4)
                
                Text("\(solarTerm.startDate.formatted("MM.dd")) - \(solarTerm.endDate.formatted("MM.dd"))")
                    .font(AppTypography.caption())
                    .foregroundColor(.shunshiPrimary.opacity(0.9))
                
                Circle()
                    .fill(Color.shunshiPrimary)
                    .frame(width: 4, height: 4)
                
                Text(Date().lunarDateString)
                    .font(AppTypography.caption())
                    .foregroundColor(.shunshiPrimary.opacity(0.9))
                
                Circle()
                    .fill(Color.shunshiPrimary)
                    .frame(width: 4, height: 4)
                
                Text("第 \(solarTerm.currentDay) 天")
                    .font(AppTypography.caption())
                    .foregroundColor(.shunshiPrimary.opacity(0.9))
            }
            
            // Description
            HStack(alignment: .top, spacing: AppSpacing.xs) {
                Text("\u{201C}")
                    .font(.system(size: 24, design: .serif))
                    .foregroundColor(.white.opacity(0.4))

                Text(solarTerm.description)
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 280)

                Text("\u{201D}")
                    .font(.system(size: 24, design: .serif))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            // Next Solar Term Countdown
            HStack(spacing: AppSpacing.sm) {
                Text("距离")
                    .font(AppTypography.label())
                    .foregroundColor(.gray)
                
                Text(solarTerm.nextSolarTerm?.name ?? "下一节气")
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundColor(.white)
                
                Text("还有")
                    .font(AppTypography.label())
                    .foregroundColor(.gray)
                
                Text("\(solarTerm.daysUntilNext)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.shunshiPrimary)
                
                Text("天")
                    .font(AppTypography.label())
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(.ultraThinMaterial)
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .padding(.bottom, AppSpacing.xl)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        SolarTermHeader(solarTerm: .preview)
    }
    .background(Color.Background.dark)
    .ignoresSafeArea()
    .preferredColorScheme(.dark)
}

