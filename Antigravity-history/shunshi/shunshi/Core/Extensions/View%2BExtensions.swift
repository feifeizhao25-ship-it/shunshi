import SwiftUI

// MARK: - Conditional Modifier
extension View {
    /// Apply modifier conditionally
    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Apply modifier conditionally with else branch
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
    
    /// Apply modifier if value is not nil
    @ViewBuilder
    func ifLet<Value, Content: View>(
        _ value: Value?,
        transform: (Self, Value) -> Content
    ) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - Loading Overlay
extension View {
    func loadingOverlay(_ isLoading: Bool) -> some View {
        overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(1.5)
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
}

// MARK: - Error Alert
extension View {
    func errorAlert(
        error: Binding<AppError?>,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        alert(
            "出错了",
            isPresented: Binding(
                get: { error.wrappedValue != nil },
                set: { if !$0 { error.wrappedValue = nil } }
            ),
            presenting: error.wrappedValue
        ) { appError in
            Button("确定", role: .cancel) { }
            if appError.isRetryable, let onRetry = onRetry {
                Button("重试") { onRetry() }
            }
        } message: { appError in
            Text(appError.errorDescription ?? "未知错误")
        }
    }
}

// MARK: - Hide Keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
    
    func onTapToDismissKeyboard() -> some View {
        onTapGesture {
            hideKeyboard()
        }
    }
}

// MARK: - Safe Area
extension View {
    func readSafeArea(_ safeArea: Binding<EdgeInsets>) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        safeArea.wrappedValue = geometry.safeAreaInsets
                    }
            }
        )
    }
}

// MARK: - Frame Helpers
extension View {
    func frame(size: CGFloat) -> some View {
        frame(width: size, height: size)
    }
    
    func maxWidth(_ alignment: Alignment = .center) -> some View {
        frame(maxWidth: .infinity, alignment: alignment)
    }
    
    func maxHeight(_ alignment: Alignment = .center) -> some View {
        frame(maxHeight: .infinity, alignment: alignment)
    }
    
    func maxFrame(_ alignment: Alignment = .center) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }
}

// MARK: - Shadow Helpers
extension View {
    func softShadow(
        color: Color = .black.opacity(0.1),
        radius: CGFloat = 10,
        y: CGFloat = 5
    ) -> some View {
        shadow(color: color, radius: radius, x: 0, y: y)
    }
    
    /// 使 NavigationStack 背景透明
    func transparentNavigationStack() -> some View {
        self.modifier(TransparentNavigationModifier())
    }
}

private struct TransparentNavigationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
    }
}

