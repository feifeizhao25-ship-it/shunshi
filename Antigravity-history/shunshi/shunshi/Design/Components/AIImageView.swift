import SwiftUI

// MARK: - AI Generated Image View
/// Displays an AI-generated image using fal.ai nano-banana-pro model
struct AIImageView: View {
    let prompt: String
    let cacheKey: String
    let aspectRatio: CGFloat
    let cornerRadius: CGFloat
    
    @StateObject private var viewModel = AIImageViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        prompt: String,
        cacheKey: String,
        aspectRatio: CGFloat = 4/3,
        cornerRadius: CGFloat = AppRadius.lg
    ) {
        self.prompt = prompt
        self.cacheKey = cacheKey
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let image = viewModel.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else if viewModel.isLoading {
                    loadingView
                } else if viewModel.error != nil {
                    placeholderView
                } else {
                    placeholderView
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: cacheKey) {
            await viewModel.loadImage(prompt: prompt, cacheKey: cacheKey)
        }
    }
    
    private var loadingView: some View {
        ZStack {
            Color.gray.opacity(0.2)
            VStack(spacing: AppSpacing.sm) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("AI生成中...")
                    .font(AppTypography.caption(12))
                    .foregroundColor(Color.AppText.muted(colorScheme))
            }
        }
    }
    
    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.shunshiPrimary.opacity(0.3),
                    Color.shunshiSecondary.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "photo.artframe")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

// MARK: - AI Image View Model
@MainActor
class AIImageViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentCacheKey: String?
    
    private let falService = FalAIService.shared
    
    func loadImage(prompt: String, cacheKey: String) async {
        // If it's already loading or same image is loaded, skip
        if isLoading || (image != nil && currentCacheKey == cacheKey) {
            return
        }
        
        // If key changed, reset image
        if currentCacheKey != cacheKey {
            self.image = nil
        }
        
        isLoading = true
        error = nil
        currentCacheKey = cacheKey
        
        do {
            let result = try await falService.generateAndCacheImage(
                prompt: prompt,
                cacheKey: cacheKey,
                aspectRatio: .standard
            )
            self.image = result
        } catch {
            self.error = error.localizedDescription
            Logger.error("Failed to generate image", error: error)
        }
        
        isLoading = false
    }
}

// MARK: - Preview
#Preview {
    VStack {
        AIImageView(
            prompt: "A serene Chinese garden with bamboo and lotus flowers, traditional ink painting style",
            cacheKey: "preview_garden"
        )
        .frame(height: 200)
        .padding()
    }
    .preferredColorScheme(.dark)
}

