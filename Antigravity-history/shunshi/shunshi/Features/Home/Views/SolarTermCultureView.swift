import SwiftUI

struct SolarTermCultureView: View {
    let solarTerm: SolarTerm
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Background Image (AI generated)
            AIImageView(
                prompt: "Traditional Chinese ink wash painting of \(solarTerm.name), artistic, ethereal, misty mountains, cultural atmosphere, 8k",
                cacheKey: "solarterm_culture_bg_\(solarTerm.id)",
                aspectRatio: 9/16,
                cornerRadius: 0
            )
            .ignoresSafeArea()
            
            // Overlay Gradient
            LinearGradient(
                colors: [.black.opacity(0.3), .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xxl) {
                // Header
                headerSection
                
                Spacer()
                
                // Poem Section
                poemSection
                
                // Customs Section
                customsSection
                
                Spacer()
                
                // Close Button
                dismissButton
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.xxl)
        }
        .colorScheme(.dark) // Culture view looks best in dark mode
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(solarTerm.name)
                .font(AppTypography.solarTermTitle(48))
                .tracking(6)
            
            Text(solarTerm.nameEn.uppercased())
                .font(AppTypography.caption(12))
                .tracking(4)
                .opacity(0.6)
        }
    }
    
    private var poemSection: some View {
        VStack(spacing: AppSpacing.lg) {
            if let poem = solarTerm.poem {
                Text(poem.title)
                    .font(AppTypography.sectionTitle(20))
                
                VStack(spacing: 12) {
                    ForEach(poem.content.components(separatedBy: "，"), id: \.self) { line in
                        Text(line)
                            .font(AppTypography.body(18))
                    }
                }
                
                Text("— \(poem.fullAuthor)")
                    .font(AppTypography.caption(14))
                    .opacity(0.7)
            }
        }
    }
    
    private var customsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 20, height: 1)
                Text("节气习俗")
                    .font(AppTypography.subheadline(14))
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 1)
            }
            .opacity(0.6)
            
            FlowLayout(spacing: 12) {
                ForEach(solarTerm.customs, id: \.self) { custom in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 4, height: 4)
                        Text(custom)
                            .font(AppTypography.body(14))
                    }
                }
            }
        }
    }
    
    private var dismissButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark")
                .font(.system(size: 20, weight: .light))
                .foregroundColor(.white)
                .padding()
                .background(Circle().fill(.white.opacity(0.1)))
        }
    }
}

#Preview {
    SolarTermCultureView(solarTerm: .preview)
}
