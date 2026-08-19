import SwiftUI

// MARK: - 老年模式配置
class ElderlyModeConfig: ObservableObject {
    static let shared = ElderlyModeConfig()
    
    @Published var isEnabled: Bool = false
    
    // 放大倍数
    var textScale: CGFloat {
        isEnabled ? 1.3 : 1.0
    }
    
    var iconScale: CGFloat {
        isEnabled ? 1.5 : 1.0
    }
    
    var touchScale: CGFloat {
        isEnabled ? 1.5 : 1.0
    }
    
    private init() {}
}

// MARK: - 老年模式修饰符
struct ElderlyModeModifier: ViewModifier {
    @EnvironmentObject private var config: ElderlyModeConfig
    
    func body(content: Content) -> some View {
        if config.isEnabled {
            content
                .dynamicTypeSize(.accessibility1)
        } else {
            content
        }
    }
}

// MARK: - 老年模式文字放大
struct ElderlyText: View {
    let text: String
    let style: Font.TextStyle
    let weight: Font.Weight
    
    @EnvironmentObject private var config: ElderlyModeConfig
    
    init(_ text: String, style: Font.TextStyle = .body, weight: Font.Weight = .regular) {
        self.text = text
        self.style = style
        self.weight = weight
    }
    
    var body: some View {
        Text(text)
            .font(.system(style, weight: weight))
            .scaleEffect(config.textScale)
    }
}

// MARK: - 老年模式按钮
struct ElderlyButton: View {
    let title: String
    let action: () -> Void
    let style: ButtonStyleType
    
    @EnvironmentObject private var config: ElderlyModeConfig
    
    enum ButtonStyleType {
        case primary
        case secondary
        case plain
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17 * config.textScale, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(minHeight: 48 * config.touchScale)
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
                .cornerRadius(CornerRadius.button * config.touchScale)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return SeasonalColors.currentSeasonPrimary
        case .plain: return SeasonalColors.currentSeasonPrimary
        }
    }
    
    var backgroundColor: Color {
        switch style {
        case .primary: return SeasonalColors.currentSeasonPrimary
        case .secondary: return SeasonalColors.currentSeasonPrimary.opacity(0.15)
        case .plain: return .clear
        }
    }
}

// MARK: - 老年模式大图标
struct ElderlyIcon: View {
    let icon: String
    let size: CGFloat
    
    @EnvironmentObject private var config: ElderlyModeConfig
    
    init(_ icon: String, size: CGFloat = 24) {
        self.icon = icon
        self.size = size
    }
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * config.iconScale))
    }
}

// MARK: - 老年模式卡片
struct ElderlyCard<Content: View>: View {
    let content: Content
    
    @EnvironmentObject private var config: ElderlyModeConfig
    @State private var isExpanded = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .cardStyle()
            .padding(.horizontal, Spacing.page)
            .frame(minHeight: 80 * config.touchScale)
    }
}

// MARK: - 语音朗读支持
struct VoiceReadButton: View {
    let text: String
    @State private var isPlaying = false
    
    var body: some View {
        Button {
            // TODO: 实现语音朗读功能
            isPlaying.toggle()
        } label: {
            Image(systemName: isPlaying ? "speaker.wave.2.fill" : "speaker.wave.1")
                .font(.system(size: 20))
                .foregroundColor(SeasonalColors.currentSeasonPrimary)
        }
    }
}

// MARK: - 响应式布局
struct ResponsiveLayout {
    /// 屏幕宽度类别
    enum SizeClass {
        case compact    // < 375px
        case regular    // 375-414px
        case expanded   // > 414px
    }
    
    static func widthClass(_ width: CGFloat) -> SizeClass {
        if width < 375 {
            return .compact
        } else if width <= 414 {
            return .regular
        } else {
            return .expanded
        }
    }
}

// MARK: - 响应式边距
struct ResponsivePadding: View {
    let compact: CGFloat
    let regular: CGFloat
    let expanded: CGFloat
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        let padding: CGFloat
        switch horizontalSizeClass {
        case .compact:
            padding = compact
        case .regular:
            padding = regular
        case .none:
            padding = regular
        @unknown default:
            padding = regular
        }
        
        return Color.clear
            .padding(.horizontal, padding)
    }
}

// MARK: - 小屏布局适配
struct CompactLayoutModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    func body(content: Content) -> some View {
        if horizontalSizeClass == .compact {
            content
                .dynamicTypeSize(.accessibility1)
        } else {
            content
        }
    }
}

// MARK: - View扩展
extension View {
    func elderlyMode() -> some View {
        modifier(ElderlyModeModifier())
    }
    
    func compactLayout() -> some View {
        modifier(CompactLayoutModifier())
    }
    
    /// 老年模式文字
    func elderlyText(_ text: String, style: Font.TextStyle = .body, weight: Font.Weight = .regular) -> some View {
        ElderlyText(text, style: style, weight: weight)
    }
    
    /// 老年模式按钮
    func elderlyButton(title: String, action: @escaping () -> Void, style: ElderlyButton.ButtonStyleType = .primary) -> some View {
        ElderlyButton(title: title, action: action, style: style)
    }
}

// MARK: - 预览
#Preview("Elderly Mode") {
    ElderlyModeConfig.shared.isEnabled = true
    
    return VStack(spacing: Spacing.section) {
        ElderlyText("老年模式已开启", style: .title2, weight: .bold)
        
        ElderlyButton(title: "大按钮", action: {}, style: .primary)
        
        ElderlyButton(title: "次要按钮", action: {}, style: .secondary)
        
        HStack {
            ElderlyIcon("house.fill", size: 32)
            ElderlyIcon("leaf", size: 32)
            ElderlyIcon("book.fill", size: 32)
            ElderlyIcon("person.fill", size: 32)
        }
    }
    .padding()
    .environmentObject(ElderlyModeConfig.shared)
}
