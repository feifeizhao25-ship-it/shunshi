import Foundation
import SwiftUI

// MARK: - 养生图片服务
/// 统一管理所有养生内容的图片资源
@MainActor
class WellnessImageService: ObservableObject {
    static let shared = WellnessImageService()
    
    // MARK: - 图片加载配置
    struct ImageConfig {
        let useLocalImages: Bool        // 优先使用本地图片
        let useAIGeneration: Bool       // 允许AI生成
        let useUnsplash: Bool           // 允许Unsplash图库
        let cacheDuration: TimeInterval // 缓存时间
        
        static let `default` = ImageConfig(
            useLocalImages: true,
            useAIGeneration: true,
            useUnsplash: true,
            cacheDuration: 7 * 24 * 60 * 60 // 7天
        )
    }
    
    private var config: ImageConfig = .default
    
    private init() {}
    
    // MARK: - 获取穴位图片
    func acupointImage(
        name: String,
        angle: AcupointImageAngle = .front,
        completion: @escaping (String?) -> Void
    ) {
        // 1. 优先查找本地图片
        if config.useLocalImages {
            let localImage = AcupointImageAssets.imageName(for: name)
            if let localImage = localImage {
                completion(localImage)
                return
            }
        }
        
        // 2. 尝试AI生成
        if config.useAIGeneration {
            _ = acupointImagePrompt(name: name, angle: angle)
            completion(nil) // AI生成需要异步处理，返回nil表示需要AI生成
            return
        }
        
        completion(nil)
    }
    
    // MARK: - 获取食谱图片
    func recipeImage(name: String) -> String? {
        // 优先本地图片
        if config.useLocalImages {
            if let localImage = RecipeImageAssets.imageURL(for: name) {
                return localImage
            }
        }
        
        // 返回AI生成提示
        return nil
    }
    
    // MARK: - 获取运动图片
    func exerciseImage(name: String) -> String? {
        if config.useLocalImages {
            return ExerciseImageAssets.imageName(for: name)
        }
        return nil
    }
    
    // MARK: - 获取食材图片
    func ingredientImage(name: String) -> String? {
        return DietImageAssets.ingredients[name]
    }
    
    // MARK: - 获取视频缩略图
    func videoThumbnail(category: String) -> String {
        return VideoThumbnailAssets.thumbnail(for: category)
    }
    
    // MARK: - AI图片提示词生成
    func acupointImagePrompt(name: String, angle: AcupointImageAngle) -> String {
        let angleDescription = angle.description
        return "Professional medical illustration of Chinese acupuncture point '\(name)', \(angleDescription) view, clean anatomical diagram with clear red marker dot on the exact point location, traditional Chinese medicine style, educational medical reference, high quality, 8k resolution, soft lighting"
    }
    
    func recipeImagePrompt(name: String, description: String) -> String {
        return "Professional food photography of traditional Chinese dish '\(name)', \(description), elegant ceramic bowl, warm ambient lighting, appetizing presentation, high quality food photography, 8k resolution"
    }
    
    func exerciseImagePrompt(name: String) -> String {
        return "Professional wellness photography of person practicing \(name), peaceful natural setting, morning light, graceful posture, health and wellness theme, high quality, 8k resolution"
    }
}

// MARK: - 穴位图片角度
enum AcupointImageAngle: String, CaseIterable {
    case front = "front"
    case back = "back"
    case side = "side"
    case closeUp = "closeup"
    
    var description: String {
        switch self {
        case .front: return "front view of body"
        case .back: return "back view of body"
        case .side: return "side profile view"
        case .closeUp: return "detailed close-up view"
        }
    }
    
    var displayName: String {
        switch self {
        case .front: return "正面"
        case .back: return "背面"
        case .side: return "侧面"
        case .closeUp: return "特写"
        }
    }
}

// MARK: - 图片加载视图
struct AdaptiveWellnessImage: View {
    let imageName: String?
    let aiPrompt: String?
    let cacheKey: String
    let placeholder: ImagePlaceholder
    let size: CGSize
    
    enum ImagePlaceholder {
        case acupoint
        case recipe
        case exercise
        case ingredient
        case video
        case general
        
        var icon: String {
            switch self {
            case .acupoint: return "hand.point.up.left.fill"
            case .recipe: return "fork.knife"
            case .exercise: return "figure.run"
            case .ingredient: return "leaf.fill"
            case .video: return "play.rectangle.fill"
            case .general: return "photo.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .acupoint: return .red
            case .recipe: return .orange
            case .exercise: return .green
            case .ingredient: return .brown
            case .video: return .purple
            case .general: return .gray
            }
        }
    }
    
    init(
        imageName: String? = nil,
        aiPrompt: String? = nil,
        cacheKey: String,
        placeholder: ImagePlaceholder = .general,
        size: CGSize = CGSize(width: 100, height: 100)
    ) {
        self.imageName = imageName
        self.aiPrompt = aiPrompt
        self.cacheKey = cacheKey
        self.placeholder = placeholder
        self.size = size
    }
    
    var body: some View {
        Group {
            if let imageName = imageName, !imageName.isEmpty {
                // 使用本地图片
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let prompt = aiPrompt {
                // 使用AI生成图片
                AIImageView(
                    prompt: prompt,
                    cacheKey: cacheKey,
                    aspectRatio: size.width / size.height,
                    cornerRadius: 12
                )
                .frame(width: size.width, height: size.height)
            } else {
                // 使用占位图
                placeholderView
            }
        }
    }
    
    private var placeholderView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(placeholder.color.opacity(0.2))
            
            VStack(spacing: 8) {
                Image(systemName: placeholder.icon)
                    .font(.system(size: 32))
                    .foregroundColor(placeholder.color)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
