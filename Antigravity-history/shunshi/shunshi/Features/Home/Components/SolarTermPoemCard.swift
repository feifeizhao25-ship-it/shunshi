import SwiftUI

// MARK: - 节气诗歌卡片
/// 展示当前节气相关的古诗词
struct SolarTermPoemCard: View {
    let solarTerm: SolarTerm
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded: Bool = false
    @State private var showCultureDetail: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with decorative elements
            headerSection
            
            // Poem Content
            poemContent
            
            // Footer with author info
            if isExpanded {
                footerSection
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .fill(poemBackgroundGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .stroke(solarTerm.themeColor.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 8, x: 0, y: 4)
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
        .fullScreenCover(isPresented: $showCultureDetail) {
            SolarTermCultureView(solarTerm: solarTerm)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("节气诗词")
                    .font(AppTypography.label())
                    .foregroundColor(Color.AppText.muted(colorScheme))
                
                Text(poemTitle)
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundColor(Color.AppText.primary(colorScheme))
            }
            
            Spacer()
            
            // Decorative icon
            Image(systemName: "text.book.closed.fill")
                .font(.system(size: 20))
                .foregroundColor(solarTerm.themeColor.opacity(0.6))
        }
        .padding(AppSpacing.lg)
    }
    
    // MARK: - Poem Content
    private var poemContent: some View {
        VStack(alignment: .center, spacing: AppSpacing.md) {
            // Poem lines with vertical layout style
            Text(poemLines)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(Color.AppText.primary(colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .shadow(color: colorScheme == .dark ? .black : .clear, radius: 1)
            
            // Expand indicator
            HStack(spacing: AppSpacing.xs) {
                Text(isExpanded ? "收起" : "展开详情")
                    .font(AppTypography.caption())
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10))
            }
            .foregroundColor(solarTerm.themeColor)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.lg)
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: AppSpacing.md) {
            Divider()
                .background(solarTerm.themeColor.opacity(0.2))
            
            // Author & Dynasty
            HStack {
                Text("【\(poemDynasty)】\(poemAuthor)")
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(Color.AppText.secondary(colorScheme))
                
                Spacer()
            }
            
            // Translation if available
            if let translation = poemTranslation {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("译文")
                        .font(AppTypography.label())
                        .foregroundColor(Color.AppText.muted(colorScheme))
                    
                    Text(translation)
                        .font(AppTypography.body())
                        .foregroundColor(Color.AppText.secondary(colorScheme))
                        .lineSpacing(4)
                }
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.lg)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Computed Properties
    private var poemBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.Surface.adaptive(colorScheme),
                solarTerm.themeColor.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // 诗歌数据 - 实际应从节气数据获取
    // 诗歌数据 - 从节气数据获取
    private var poemTitle: String { solarTerm.poem?.title ?? "\(solarTerm.name)" }
    private var poemLines: String { 
        solarTerm.poem?.content ?? "未见诗云，但见霜凝。"
    }
    private var poemAuthor: String { solarTerm.poem?.author ?? "佚名" }
    private var poemDynasty: String { solarTerm.poem?.dynasty ?? "未知" }
    private var poemTranslation: String? { 
        // 实际数据中如果没带译文，可以先为预览提供一个占位
        nil 
    }
}

// MARK: - Preview
#Preview {
    VStack {
        SolarTermPoemCard(solarTerm: .preview)
    }
    .padding()
    .background(Color.Background.dark)
    .preferredColorScheme(.dark)
}

