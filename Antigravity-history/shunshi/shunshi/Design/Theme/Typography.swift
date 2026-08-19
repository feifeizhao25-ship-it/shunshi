import SwiftUI

// MARK: - App Typography
struct AppTypography {
    // MARK: - Title Fonts (宋体风格 - 使用系统衬线字体)
    static func solarTermTitle(_ size: CGFloat = 36) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }
    
    static func sectionTitle(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }
    
    static func cardTitle(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }
    
    // MARK: - Body Fonts (黑体)
    static func headline(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    
    static func subheadline(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    
    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular)
    }
    
    static func caption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .regular)
    }
    
    static func label(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .medium)
    }
    
    static func tabLabel(_ size: CGFloat = 10) -> Font {
        .system(size: size, weight: .medium)
    }
}

// MARK: - View Modifiers for Typography
extension View {
    func solarTermTitleStyle() -> some View {
        self
            .font(AppTypography.solarTermTitle())
            .tracking(4)
    }
    
    func sectionTitleStyle() -> some View {
        self.font(AppTypography.sectionTitle())
    }
    
    func cardTitleStyle() -> some View {
        self.font(AppTypography.cardTitle())
    }
    
    func bodyStyle() -> some View {
        self.font(AppTypography.body())
    }
    
    func captionStyle() -> some View {
        self.font(AppTypography.caption())
    }
}

