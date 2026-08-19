import SwiftUI

// MARK: - Solar Term Wheel Overlay
struct SolarTermWheelOverlay: View {
    let solarTerms: [SolarTerm]
    let currentTerm: SolarTerm
    
    @State private var selectedIndex: Int = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var navigateToDetail = false
    
    init(solarTerms: [SolarTerm], currentTerm: SolarTerm) {
        self.solarTerms = solarTerms
        self.currentTerm = currentTerm
        _selectedIndex = State(initialValue: currentTerm.index - 1)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.Background.adaptive(colorScheme).ignoresSafeArea()
                
                VStack(spacing: AppSpacing.xl) {
                    Text("二十四节气日历")
                        .font(AppTypography.headline(20))
                        .padding(.top, AppSpacing.lg)
                    
                    Text("春生、夏长、秋收、冬藏")
                        .font(AppTypography.caption())
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    SolarTermWheelView(
                        solarTerms: solarTerms,
                        selectedIndex: $selectedIndex
                    )
                    
                    Spacer()
                    
                    // Action Button
                    Button(action: {
                        navigateToDetail = true
                    }) {
                        HStack {
                            Text("查看 \(selectedTerm.name) 养生详情")
                            Image(systemName: "chevron.right")
                        }
                        .font(AppTypography.subheadline())
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.vertical, AppSpacing.md)
                        .background(selectedTerm.themeColor)
                        .clipShape(Capsule())
                        .shadow(color: selectedTerm.themeColor.opacity(0.3), radius: 10, y: 5)
                    }
                    .padding(.bottom, AppSpacing.xxl)
                }
                .padding()
            }
            .navigationDestination(isPresented: $navigateToDetail) {
                SolarTermDetailView(solarTerm: selectedTerm)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
    
    private var selectedTerm: SolarTerm {
        if solarTerms.indices.contains(selectedIndex) {
            return solarTerms[selectedIndex]
        }
        return currentTerm
    }
}

// MARK: - Preview
#Preview {
    SolarTermWheelOverlay(
        solarTerms: SolarTermStaticData.solarTerms,
        currentTerm: .preview
    )
}
