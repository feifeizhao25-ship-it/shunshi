import SwiftUI

// MARK: - Lume Glass Modifier
/// A premium glassmorphism effect with adjustable intensity, frost, and border.
struct LumeGlass: ViewModifier {
    var cornerRadius: CGFloat = 16
    var blur: CGFloat = 10
    var opacity: Double = 0.15
    var shadow: CGFloat = 10
    
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Frost layer
                    BlurView(style: colorScheme == .dark ? .systemThinMaterialDark : .systemThinMaterialLight)
                        .opacity(opacity)
                    
                    // Subtle tint
                    (colorScheme == .dark ? Color.white : Color.black)
                        .opacity(0.02)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                                .white.opacity(colorScheme == .dark ? 0.05 : 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: shadow, x: 0, y: 4)
    }
}

// MARK: - Blur View Helper
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - View Extension
extension View {
    /// Applies a premium glassmorphism effect.
    /// - Parameters:
    ///   - cornerRadius: Radius of the corners.
    ///   - blur: Intensity of the background blur.
    ///   - opacity: Opacity of the frost layer.
    func lumeGlass(
        cornerRadius: CGFloat = 16,
        blur: CGFloat = 10,
        opacity: Double = 0.15,
        shadow: CGFloat = 10
    ) -> some View {
        self.modifier(LumeGlass(cornerRadius: cornerRadius, blur: blur, opacity: opacity, shadow: shadow))
    }
    
    /// A simpler version of glassmorphism already used in some views, 
    /// but unified under the 'lume' naming convention.
    func glassCard() -> some View {
        self.lumeGlass(cornerRadius: 20, blur: 15, opacity: 0.1, shadow: 15)
    }
}
