import SwiftUI

// MARK: - 间距规范
enum Spacing {
    /// 页面边距 - 16px
    static let page: CGFloat = 16
    
    /// 卡片间距 - 12px
    static let card: CGFloat = 12
    
    /// 卡片内边距 - 16px
    static let cardPadding: CGFloat = 16
    
    /// 列表项间距 - 8px
    static let listItem: CGFloat = 8
    
    /// 图标与文字间距 - 8px
    static let iconText: CGFloat = 8
    
    /// 按钮内边距（水平）- 24px
    static let buttonHorizontal: CGFloat = 24
    
    /// 按钮内边距（垂直）- 12px
    static let buttonVertical: CGFloat = 12
    
    /// 组间距 - 20px
    static let section: CGFloat = 20
    
    /// 小间距 - 4px
    static let small: CGFloat = 4
    
    /// 中间距 - 8px
    static let medium: CGFloat = 8
    
    /// 大间距 - 24px
    static let large: CGFloat = 24
    
    /// 特大间距 - 32px
    static let xlarge: CGFloat = 32
    
    /// 导航栏高度
    static let navBarHeight: CGFloat = 44
    
    /// 底部安全区高度
    static let safeAreaBottom: CGFloat = 0
    
    /// TabBar高度
    static let tabBarHeight: CGFloat = 83
}

// MARK: - View Extension for Spacing
extension View {
    /// 页面边距
    func pagePadding() -> some View {
        self.padding(.horizontal, Spacing.page)
    }
    
    /// 卡片内边距
    func cardPadding() -> some View {
        self.padding(Spacing.cardPadding)
    }
    
    /// 标准间距
    func standardPadding() -> some View {
        self.padding(Spacing.card)
    }
    
    /// 小间距
    func smallPadding() -> some View {
        self.padding(Spacing.small)
    }
    
    /// 大间距
    func largePadding() -> some View {
        self.padding(Spacing.large)
    }
    
    /// 垂直间距
    func verticalSpacing(_ value: CGFloat = Spacing.section) -> some View {
        self.padding(.vertical, value)
    }

    /// 水平间距
    func horizontalSpacing(_ value: CGFloat = Spacing.card) -> some View {
        self.padding(.horizontal, value)
    }
}

// MARK: - Legacy Compatibility (兼容旧代码)
enum AppSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let small: CGFloat = 4
    static let medium: CGFloat = 8
    static let md: CGFloat = 8
    static let standard: CGFloat = 12
    static let large: CGFloat = 16
    static let lg: CGFloat = 16
    static let xlarge: CGFloat = 24
    static let xl: CGFloat = 24
    static let xxlarge: CGFloat = 32
    static let xxl: CGFloat = 32
}

enum AppRadius {
    static let sm: CGFloat = 4
    static let small: CGFloat = 4
    static let md: CGFloat = 8
    static let medium: CGFloat = 8
    static let standard: CGFloat = 12
    static let large: CGFloat = 16
    static let lg: CGFloat = 16
    static let xlarge: CGFloat = 20
    static let xl: CGFloat = 20
    static let xxlarge: CGFloat = 24
    static let xxl: CGFloat = 32
    static let card: CGFloat = 16
}

enum AppSize {
    static let buttonHeight: CGFloat = 44
    static let navButtonSize: CGFloat = 44
    static let iconSmall: CGFloat = 16
    static let iconMedium: CGFloat = 24
    static let iconLarge: CGFloat = 32
    static let wuWeiIconSize: CGFloat = 48
    static let tabBarHeight: CGFloat = 83
    static let homeHeaderHeight: CGFloat = 480
}

enum AppAnimation {
    static let fast = Animation.easeInOut(duration: 0.2)
    static let float = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
}
