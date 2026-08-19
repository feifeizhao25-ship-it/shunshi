import SwiftUI

// MARK: - 通用卡片视图
struct ShunshiCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .cardStyle()
            .padding(.horizontal, Spacing.page)
    }
}

// MARK: - 空状态视图
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonTitle: String?
    let onButtonTap: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        buttonTitle: String? = nil,
        onButtonTap: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.onButtonTap = onButtonTap
    }
    
    var body: some View {
        VStack(spacing: Spacing.card) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppText.tertiary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(AppText.primary)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(AppText.secondary)
                .multilineTextAlignment(.center)
            
            if let buttonTitle = buttonTitle, let onTap = onButtonTap {
                Button(action: onTap) {
                    Text(buttonTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.buttonHorizontal)
                        .padding(.vertical, Spacing.buttonVertical)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.capsule)
                                .fill(SeasonalColors.currentSeasonPrimary)
                        )
                }
                .padding(.top, Spacing.small)
            }
        }
        .padding(Spacing.xlarge)
    }
}

// MARK: - 骨架屏视图
struct ShunshiSkeletonView: View {
    let lines: Int
    let cornerRadius: CGFloat
    
    init(lines: Int = 3, cornerRadius: CGFloat = CornerRadius.small) {
        self.lines = lines
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        VStack(spacing: Spacing.small) {
            ForEach(0..<lines, id: \.self) { _ in
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppBackground.cardLight)
                    .frame(height: 16)
            }
        }
        .padding(Spacing.card)
        .cardStyle()
        .redacted(reason: .placeholder)
        .shimmering()
    }
}

// MARK: - Shimmer Effect Modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.5),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + phase * geometry.size.width * 3)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - 加载状态视图
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: Spacing.card) {
            // 品牌Logo呼吸效果
            Image(systemName: "leaf.fill")
                .font(.system(size: 40))
                .foregroundColor(SeasonalColors.currentSeasonPrimary)
                .scaleEffect(1.0)
                .animation(
                    Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: 1.0
                )
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppText.secondary)
        }
        .padding(Spacing.xlarge)
    }
}

// MARK: - 成就徽章视图
struct AchievementBadge: View {
    let name: String
    let icon: String
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: Spacing.small) {
            ZStack {
                Circle()
                    .fill(
                        isUnlocked
                            ? SeasonalColors.currentSeasonPrimary.opacity(0.2)
                            : AppBackground.cardLight
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(
                        isUnlocked
                            ? SeasonalColors.currentSeasonPrimary
                            : AppText.tertiary
                    )
            }
            
            Text(name)
                .font(.caption2)
                .foregroundColor(
                    isUnlocked
                        ? AppText.primary
                        : AppText.tertiary
                )
        }
        .opacity(isUnlocked ? 1 : 0.5)
    }
}

// MARK: - 进度指示器
struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    
    init(progress: Double, lineWidth: CGFloat = 6, size: CGFloat = 60) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(AppBackground.cardLight, lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    SeasonalColors.currentSeasonPrimary,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(AppText.primary)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 标签视图
struct ShunshiTag: View {
    let text: String
    let color: Color
    
    init(_ text: String, color: Color = SeasonalColors.currentSeasonPrimary) {
        self.text = text
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(color)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.tag)
                    .fill(color.opacity(0.15))
            )
    }
}

// MARK: - 分段控制器
struct ShunshiSegmentedControl: View {
    @Binding var selection: Int
    let options: [String]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selection = index
                    }
                } label: {
                    Text(options[index])
                        .font(.subheadline)
                        .fontWeight(selection == index ? .medium : .regular)
                        .foregroundColor(selection == index ? .white : AppText.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.small)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.button)
                                .fill(
                                    selection == index
                                        ? SeasonalColors.currentSeasonPrimary
                                        : Color.clear
                                )
                        )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.button)
                .fill(AppBackground.cardLight)
        )
    }
}

// MARK: - 预览
#Preview("Empty State") {
    EmptyStateView(
        icon: "book.closed",
        title: "还没有养生记录呢~",
        subtitle: "记录每一天，看到自己的变化",
        buttonTitle: "开始今天的记录",
        onButtonTap: {}
    )
}

#Preview("Skeleton") {
    ShunshiSkeletonView(lines: 4)
}

#Preview("Loading") {
    LoadingView(message: "正在分析您的养生数据...")
}

