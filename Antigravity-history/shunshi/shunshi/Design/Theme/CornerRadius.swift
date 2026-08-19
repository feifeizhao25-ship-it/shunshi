import SwiftUI

// MARK: - 圆角规范
enum CornerRadius {
    /// 卡片圆角 - 12px
    static let card: CGFloat = 12
    
    /// 按钮圆角 - 8px
    static let button: CGFloat = 8
    
    /// 胶囊按钮圆角 - 20px
    static let capsule: CGFloat = 20
    
    /// 头像圆角（用于圆形）- 50%
    static let avatar: CGFloat = 50
    
    /// 输入框圆角 - 8px
    static let input: CGFloat = 8
    
    /// 标签圆角 - 4px
    static let tag: CGFloat = 4
    
    /// 小的圆角 - 6px
    static let small: CGFloat = 6
    
    /// 中等圆角 - 16px
    static let medium: CGFloat = 16
    
    /// 大圆角 - 24px
    static let large: CGFloat = 24
}

// MARK: - 投影规范
enum ShadowStyle {
    /// 卡片投影 - 轻柔
    static let card = Shadow(
        color: Color.black.opacity(0.08),
        x: 0,
        y: 2,
        blur: 8
    )
    
    /// 悬浮投影 - 中等
    static let elevated = Shadow(
        color: Color.black.opacity(0.12),
        x: 0,
        y: 4,
        blur: 16
    )
    
    /// 底部导航投影
    static let tabBar = Shadow(
        color: Color.black.opacity(0.06),
        x: 0,
        y: -2,
        blur: 8
    )
    
    /// 按钮按下投影
    static let pressed = Shadow(
        color: Color.black.opacity(0.16),
        x: 0,
        y: 4,
        blur: 12
    )
    
    /// 节日/强调投影
    static let accent = Shadow(
        color: Color.black.opacity(0.15),
        x: 0,
        y: 6,
        blur: 20
    )
}

// MARK: - Shadow结构
struct Shadow {
    let color: Color
    let x: CGFloat
    let y: CGFloat
    let blur: CGFloat
}

// MARK: - View Extension for CornerRadius
extension View {
    /// 卡片圆角
    func cardCornerRadius() -> some View {
        self.cornerRadius(CornerRadius.card)
    }
    
    /// 按钮圆角
    func buttonCornerRadius() -> some View {
        self.cornerRadius(CornerRadius.button)
    }
    
    /// 胶囊按钮
    func capsuleCornerRadius() -> some View {
        self.cornerRadius(CornerRadius.capsule)
    }
    
    /// 标签圆角
    func tagCornerRadius() -> some View {
        self.cornerRadius(CornerRadius.tag)
    }
    
    /// 自定义圆角
    func customCornerRadius(_ radius: CGFloat) -> some View {
        self.cornerRadius(radius)
    }
}

// MARK: - View Extension for Shadows
extension View {
    /// 卡片投影
    func cardShadow() -> some View {
        self.shadow(color: ShadowStyle.card.color, radius: ShadowStyle.card.blur, x: ShadowStyle.card.x, y: ShadowStyle.card.y)
    }
    
    /// 悬浮投影
    func elevatedShadow() -> some View {
        self.shadow(color: ShadowStyle.elevated.color, radius: ShadowStyle.elevated.blur, x: ShadowStyle.elevated.x, y: ShadowStyle.elevated.y)
    }
    
    /// TabBar投影
    func tabBarShadow() -> some View {
        self.shadow(color: ShadowStyle.tabBar.color, radius: ShadowStyle.tabBar.blur, x: ShadowStyle.tabBar.x, y: ShadowStyle.tabBar.y)
    }
    
    /// 自定义投影
    func customShadow(_ shadow: Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.blur, x: shadow.x, y: shadow.y)
    }
}

// MARK: - View Extension for Card Style
extension View {
    /// 标准卡片样式
    func cardStyle() -> some View {
        self
            .background(AppBackground.card)
            .cornerRadius(CornerRadius.card)
            .cardShadow()
    }
    
    /// 轻量卡片样式
    func cardLightStyle() -> some View {
        self
            .background(AppBackground.cardLight)
            .cornerRadius(CornerRadius.card)
    }
}
