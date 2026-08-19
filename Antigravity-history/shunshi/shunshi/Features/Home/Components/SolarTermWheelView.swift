import SwiftUI

// MARK: - Solar Term Wheel View
struct SolarTermWheelView: View {
    let solarTerms: [SolarTerm]
    @Binding var selectedIndex: Int
    
    // UI Constants
    private let wheelSize: CGFloat = 300
    private let itemSize: CGFloat = 44
    
    var body: some View {
        ZStack {
            // Background Circle Path
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                .frame(width: wheelSize, height: wheelSize)
            
            // Season Segments (Gradient Arcs)
            seasonSegments
            
            // Terms on the circle
            ZStack {
                ForEach(0..<24) { index in
                    termItem(index: index)
                }
            }
            .rotationEffect(.degrees(-Double(selectedIndex) * (360.0 / 24.0)))
            
            // Center Content
            centerContent
        }
        .frame(width: wheelSize + itemSize, height: wheelSize + itemSize)
        .animation(.interpolatingSpring(stiffness: 100, damping: 15), value: selectedIndex)
    }
    
    // MARK: - Season Segments
    private var seasonSegments: some View {
        ZStack {
            ForEach(0..<4) { i in
                let season = Season.allCases[i]
                Circle()
                    .trim(from: CGFloat(i) * 0.25 + 0.01, to: CGFloat(i+1) * 0.25 - 0.01)
                    .stroke(
                        LinearGradient(
                            colors: [season.color.opacity(0.4), season.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: wheelSize - 15, height: wheelSize - 15)
                    .rotationEffect(.degrees(-90))
            }
        }
        .rotationEffect(.degrees(-Double(selectedIndex) * (360.0 / 24.0)))
    }
    
    // MARK: - Term Item
    private func termItem(index: Int) -> some View {
        let angle = CGFloat(index) * (360.0 / 24.0) - 90
        let radius = wheelSize / 2
        let name = solarTerms.indices.contains(index) ? solarTerms[index].name : ""
        let isSelected = index == selectedIndex
        
        return Button(action: {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                selectedIndex = index
            }
        }) {
            VStack(spacing: 4) {
                Text(name)
                    .font(isSelected ? AppTypography.headline(15) : AppTypography.caption(11))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.4))
                
                if isSelected {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: itemSize, height: itemSize)
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .rotationEffect(.degrees(Double(selectedIndex) * (360.0 / 24.0)))
        }
        .offset(x: radius * cos(angle * .pi / 180),
                y: radius * sin(angle * .pi / 180))
    }
    
    // MARK: - Center Content
    private var centerContent: some View {
        Group {
            if solarTerms.indices.contains(selectedIndex) {
                let term = solarTerms[selectedIndex]
                VStack(spacing: 4) {
                    Text(term.name)
                        .font(AppTypography.solarTermTitle(32))
                        .foregroundColor(.white)
                    
                    Text(term.nameEn)
                        .font(AppTypography.caption())
                        .foregroundColor(.gray)
                    
                    Text(term.season.displayName + "季")
                        .font(AppTypography.caption(10))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(term.themeColor.opacity(0.2))
                        .foregroundColor(term.themeColor)
                        .clipShape(Capsule())
                        .padding(.top, 4)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(hexCode: "0C1F1D").ignoresSafeArea()
        SolarTermWheelView(
            solarTerms: SolarTermStaticData.solarTerms,
            selectedIndex: .constant(21)
        )
    }
    .preferredColorScheme(.dark)
}
