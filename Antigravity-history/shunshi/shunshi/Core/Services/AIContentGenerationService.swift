import Foundation
import UIKit
import Combine

// MARK: - AI Content Generation Service
/// 为五维养生内容生成 AI 图片（使用 nanobanana 模型）
/// 支持穴位、食谱、起居、情志、运动等内容类型

@MainActor
class AIContentGenerationService: ObservableObject {
    static let shared = AIContentGenerationService()
    
    // MARK: - 生成状态
    @Published var generationProgress: [String: Double] = [:]
    @Published var isGenerating: Bool = false
    @Published var generatedContent: [String: GeneratedContent] = [:]
    
    private let falService = FalAIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // 缓存目录
    private let cacheDirectory: URL
    
    struct GeneratedContent: Codable {
        let id: String
        let type: ContentType
        let imageURL: URL?
        let localPath: String?
        let videoURL: URL?
        let generatedAt: Date
        let prompt: String
    }
    
    enum ContentType: String, Codable {
        case acupoint        // 穴位
        case recipe          // 食谱
        case livingTip       // 起居
        case exercise        // 运动
        case emotion         // 情志
        case ingredient      // 食材
    }
    
    private init() {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("wellness_ai_content")
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // 加载已生成的内容
        loadCachedContent()
    }
    
    // MARK: - 批量生成内容图片
    func generateAllContentImages() async {
        guard !isGenerating else { return }
        isGenerating = true
        
        // 生成穴位图片
        for acupoint in WellnessContentService.shared.acupoints {
            await generateAcupointImage(for: acupoint)
        }
        
        // 生成食谱图片
        for tip in LivingTip.sampleData {
            await generateLivingTipImage(for: tip)
        }
        
        // 生成运动图片
        for exercise in ExerciseTip.sampleData {
            await generateExerciseImage(for: exercise)
        }
        
        // 生成情志图片
        for emotion in EmotionTip.sampleData {
            await generateEmotionImage(for: emotion)
        }
        
        isGenerating = false
    }
    
    // MARK: - 生成单个穴位图片
    func generateAcupointImage(for acupoint: Acupoint) async {
        let cacheKey = "acupoint_\(acupoint.id)"
        guard !generatedContent.keys.contains(cacheKey) else { return }
        
        // 穴位图片提示词 - 人体穴位定位图
        let prompt = """
        Traditional Chinese medicine acupoint location diagram for \(acupoint.name), \
        showing precise body location on human body, \
        anatomical illustration style, \
        clean and educational, \
        traditional Chinese medical art, \
        acupoint marked with circle, \
        meridian pathway indicated, \
        professional medical illustration, \
        high quality, detailed
        """
        
        await generateAndCacheContent(
            id: cacheKey,
            type: .acupoint,
            prompt: prompt,
            cacheKey: cacheKey
        )
    }
    
    // MARK: - 生成起居图片
    func generateLivingTipImage(for tip: LivingTip) async {
        let cacheKey = "living_\(tip.id)"
        guard !generatedContent.keys.contains(cacheKey) else { return }
        
        let prompt = """
        Traditional Chinese wellness routine: \(tip.title), \
        serene traditional Chinese scene, \
        wellness lifestyle illustration, \
        peaceful morning or evening atmosphere, \
        natural lighting, \
        elegant traditional Chinese interior or garden, \
        high quality artistic illustration, \
        calm and therapeutic mood
        """
        
        await generateAndCacheContent(
            id: cacheKey,
            type: .livingTip,
            prompt: prompt,
            cacheKey: cacheKey
        )
    }
    
    // MARK: - 生成运动图片
    func generateExerciseImage(for exercise: ExerciseTip) async {
        let cacheKey = "exercise_\(exercise.id)"
        guard !generatedContent.keys.contains(cacheKey) else { return }
        
        let prompt = """
        Traditional Chinese exercise: \(exercise.name), \
        person practicing \(exercise.name) in peaceful natural setting, \
        tai chi or qigong movement illustration, \
        traditional Chinese wellness practice, \
        graceful fluid motion, \
        serene outdoor environment with nature, \
        high quality artistic illustration, \
        educational fitness demonstration
        """
        
        await generateAndCacheContent(
            id: cacheKey,
            type: .exercise,
            prompt: prompt,
            cacheKey: cacheKey
        )
    }
    
    // MARK: - 生成情志图片
    func generateEmotionImage(for emotion: EmotionTip) async {
        let cacheKey = "emotion_\(emotion.id)"
        guard !generatedContent.keys.contains(cacheKey) else { return }
        
        let prompt = """
        Traditional Chinese medicine emotional wellness: \(emotion.title), \
        serene traditional Chinese scene illustrating emotional balance, \
        peaceful garden or natural landscape, \
        harmonious yin yang energy, \
        calm meditation atmosphere, \
        traditional Chinese art style, \
        high quality illustration, \
        emotional healing and wellness theme
        """
        
        await generateAndCacheContent(
            id: cacheKey,
            type: .emotion,
            prompt: prompt,
            cacheKey: cacheKey
        )
    }
    
    // MARK: - 通用生成方法
    private func generateAndCacheContent(
        id: String,
        type: ContentType,
        prompt: String,
        cacheKey: String
    ) async {
        generationProgress[id] = 0
        
        do {
            // 使用 nanobanana 模型生成图片
            let image = try await falService.generateAndCacheImage(
                prompt: prompt,
                cacheKey: cacheKey,
                aspectRatio: .standard
            )
            
            // 保存到缓存
            let localPath = cacheDirectory.appendingPathComponent("\(cacheKey).jpg")
            if let data = image.jpegData(compressionQuality: 0.8) {
                try? data.write(to: localPath)
            }
            
            let content = GeneratedContent(
                id: id,
                type: type,
                imageURL: nil,
                localPath: localPath.path,
                videoURL: nil,
                generatedAt: Date(),
                prompt: prompt
            )
            
            generatedContent[id] = content
            generationProgress[id] = 1.0
            
            // 保存到持久化存储
            saveCachedContent()
            
        } catch {
            print("Failed to generate image for \(id): \(error)")
            generationProgress[id] = -1
        }
    }
    
    // MARK: - 获取生成的图片
    func getImage(for id: String) -> UIImage? {
        guard let content = generatedContent[id],
              let path = content.localPath else {
            return nil
        }
        return UIImage(contentsOfFile: path)
    }
    
    // MARK: - 缓存管理
    private func loadCachedContent() {
        let metadataPath = cacheDirectory.appendingPathComponent("metadata.json")
        guard let data = try? Data(contentsOf: metadataPath),
              let content = try? JSONDecoder().decode([String: GeneratedContent].self, from: data) else {
            return
        }
        generatedContent = content
    }
    
    private func saveCachedContent() {
        let metadataPath = cacheDirectory.appendingPathComponent("metadata.json")
        guard let data = try? JSONEncoder().encode(generatedContent) else { return }
        try? data.write(to: metadataPath)
    }
    
    func clearAllCache() async {
        generatedContent.removeAll()
        generationProgress.removeAll()
        if FileManager.default.fileExists(atPath: cacheDirectory.path) {
            try? FileManager.default.removeItem(at: cacheDirectory)
        }
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        let service = falService
        await service.clearCache()
    }
}

// MARK: - AI Image View Component
import SwiftUI

struct AIImageView: View {
    let prompt: String
    let cacheKey: String
    var aspectRatio: CGFloat = 4.0/3.0
    var cornerRadius: CGFloat = 12
    var showLoadingIndicator: Bool = true
    
    @StateObject private var generationService = AIContentGenerationService.shared
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var retryCount = 0
    
    private let maxRetries = 3
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .cornerRadius(cornerRadius)
                        .transition(.opacity)
                } else if isLoading && showLoadingIndicator {
                    // 加载占位符
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color(.systemGray5))
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .overlay(
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("正在生成AI图片...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if retryCount > 0 {
                                    Text("尝试 \(retryCount)/\(maxRetries)")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                        )
                } else if error != nil {
                    // 错误状态
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color(.systemGray5))
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                Text("图片加载失败")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if retryCount < maxRetries {
                                    Button("点击重试") {
                                        retryCount += 1
                                        Task { @MainActor in
                                            await loadImage()
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundColor(.shunshiPrimary)
                                } else {
                                    Text("请稍后重试")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        )
                } else {
                    // 默认占位符
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color(.systemGray6))
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                        )
                }
            }
            .onAppear {
                Task { @MainActor in
                    await loadImage()
                }
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .animation(.easeInOut(duration: 0.3), value: image != nil)
    }
    
    private func loadImage() async {
        isLoading = true
        error = nil
        
        // 先检查本地缓存
        if let cachedImage = generationService.getImage(for: cacheKey) {
            await MainActor.run {
                image = cachedImage
                isLoading = false
            }
            return
        }
        
        // 生成新图片
        do {
            let newImage = try await FalAIService.shared.generateAndCacheImage(
                prompt: prompt,
                cacheKey: cacheKey,
                aspectRatio: .standard
            )
            await MainActor.run {
                image = newImage
                isLoading = false
                retryCount = 0
            }
        } catch {
            await MainActor.run {
                self.error = error
                isLoading = false
            }
        }
    }
}

// MARK: - Async Image View with Caching
/// 支持异步加载网络图片，带缓存功能
struct CachedAsyncImageView: View {
    let url: URL?
    var aspectRatio: CGFloat = 16.0/9.0
    var cornerRadius: CGFloat = 12
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var imageData: Data?
    
    private let cache = NSCache<NSURL, NSData>()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .cornerRadius(cornerRadius)
                } else if isLoading {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color(.systemGray5))
                        .overlay(
                            ProgressView()
                        )
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color(.systemGray6))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                        )
                }
            }
            .onAppear {
                loadImage()
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }
    
    private func loadImage() {
        guard let url = url else {
            isLoading = false
            return
        }
        
        // 检查缓存
        if let cachedData = cache.object(forKey: url as NSURL) as Data? {
            updateMainImage(from: cachedData)
            return
        }
        
        // 下载图片
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                // 缓存
                cache.setObject(data as NSData, forKey: url as NSURL)
                
                updateMainImage(from: data)
            } catch {
                await MainActor.run {
                    self.error = error
                    isLoading = false
                }
            }
        }
    }
    
    private func updateMainImage(from data: Data) {
        if let uiImage = UIImage(data: data) {
            DispatchQueue.main.async {
                self.image = uiImage
                self.isLoading = false
                self.imageData = data
            }
        }
    }
}

// MARK: - Wellness Video Model
struct WellnessVideo: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let videoURL: URL
    let thumbnailURL: URL?
    let duration: Int // 秒
    let category: VideoCategory
    let views: Int
    let source: VideoSource
    
    enum VideoCategory: String, Codable, CaseIterable {
        case acupoint     // 穴位按摩
        case exercise     // 运动跟练
        case diet         // 饮食教程
        case meditation   // 冥想
        case taiChi       // 太极拳
        case qigong       // 气功
    }
    
    enum VideoSource: String, Codable {
        case bilibili    // B站
        case youtube     // YouTube
        case vimeo
        case custom
    }
    
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Video Data
extension WellnessVideo {
    static let sampleVideos: [WellnessVideo] = [
        // 穴位按摩视频
        WellnessVideo(
            id: "v1",
            title: "涌泉穴按摩教学",
            description: "详细讲解涌泉穴的位置和按摩手法，帮助改善睡眠、缓解疲劳",
            videoURL: URL(string: "https://www.bilibili.com/video/BV1ux411c7hQ")!,
            thumbnailURL: nil,
            duration: 180,
            category: .acupoint,
            views: 125000,
            source: .bilibili
        ),
        WellnessVideo(
            id: "v2",
            title: "太冲穴疏肝理气",
            description: "太冲穴按摩教程，缓解情绪压力，改善头痛",
            videoURL: URL(string: "https://www.bilibili.com/video/BV1GP4y1j7vX")!,
            thumbnailURL: nil,
            duration: 150,
            category: .acupoint,
            views: 89000,
            source: .bilibili
        ),
        
        // 太极拳视频
        WellnessVideo(
            id: "v3",
            title: "太极拳入门基础",
            description: "太极拳起势教学，适合初学者学习",
            videoURL: URL(string: "https://www.bilibili.com/video/BV1Xx4y1k7uL")!,
            thumbnailURL: nil,
            duration: 600,
            category: .taiChi,
            views: 256000,
            source: .bilibili
        ),
        WellnessVideo(
            id: "v4",
            title: "二十四式太极拳",
            description: "完整二十四式太极拳演示和教学",
            videoURL: URL(string: "https://www.bilibili.com/video/BV1mV411k7XJ")!,
            thumbnailURL: nil,
            duration: 900,
            category: .taiChi,
            views: 189000,
            source: .bilibili
        ),
        
        // 八段锦视频
        WellnessVideo(
            id: "v5",
            title: "八段锦完整教学",
            description: "传统八段锦完整动作教学，带呼吸配合",
            videoURL: URL(string: "https://www.bilibili.com/video/BV1jf4y1f7BZ")!,
            thumbnailURL: nil,
            duration: 720,
            category: .qigong,
            views: 312000,
            source: .bilibili
        ),
        
        // 冥想视频
        WellnessVideo(
            id: "v6",
            title: "清晨冥想15分钟",
            description: "帮助清醒头脑的清晨冥想练习",
            videoURL: URL(string: "https://www.bilibili.com/video/BV1aA411j7sM")!,
            thumbnailURL: nil,
            duration: 900,
            category: .meditation,
            views: 156000,
            source: .bilibili
        ),
        
        // 运动跟练视频
        WellnessVideo(
            id: "v7",
            title: "颈部放松操",
            description: "久坐办公族必备，缓解颈椎疲劳",
            videoURL: URL(string: "https://www.bilibili.com/video/BV1X44y1Y7JZ")!,
            thumbnailURL: nil,
            duration: 300,
            category: .exercise,
            views: 203000,
            source: .bilibili
        )
    ]
}

// MARK: - Video Service
@MainActor
class WellnessVideoService: ObservableObject {
    static let shared = WellnessVideoService()
    
    @Published var videos: [WellnessVideo] = WellnessVideo.sampleVideos
    @Published var isLoading = false
    
    func fetchVideos(category: WellnessVideo.VideoCategory? = nil) {
        if let category = category {
            videos = WellnessVideo.sampleVideos.filter { $0.category == category }
        } else {
            videos = WellnessVideo.sampleVideos
        }
    }
    
    func getVideos(for acupoint: Acupoint) -> [WellnessVideo] {
        let acupointName = acupoint.name
        return WellnessVideo.sampleVideos.filter { video in
            video.title.localizedCaseInsensitiveContains(acupointName) ||
            video.category == .acupoint
        }
    }
    
    func getVideos(for exercise: ExerciseTip) -> [WellnessVideo] {
        return WellnessVideo.sampleVideos.filter { video in
            video.title.localizedCaseInsensitiveContains(exercise.name) ||
            video.category == .exercise ||
            video.category == .qigong ||
            video.category == .taiChi
        }
    }
}

// MARK: - Video Player View
import AVKit

struct VideoPlayerView: View {
    let video: WellnessVideo
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    Color.black
                    
                    VStack(spacing: 16) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.white)
                        
                        Text(video.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(video.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // 打开外部链接按钮
                        Link(destination: video.videoURL) {
                            Label("在\(video.source.displayName)中打开", systemImage: "safari")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.shunshiPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationTitle(video.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

extension WellnessVideo.VideoSource {
    var displayName: String {
        switch self {
        case .bilibili: return "哔哩哔哩"
        case .youtube: return "YouTube"
        case .vimeo: return "Vimeo"
        case .custom: return "视频源"
        }
    }
    
    var icon: String {
        switch self {
        case .bilibili: return "play.rectangle.fill"
        case .youtube: return "play.circle.fill"
        case .vimeo: return "film"
        case .custom: return "video"
        }
    }
}

// MARK: - Video Card Component
struct VideoCard: View {
    let video: WellnessVideo
    var showThumbnail: Bool = true
    @Environment(\.colorScheme) private var colorScheme
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 缩略图
            ZStack {
                if let thumbnailImage = thumbnailImage {
                    Image(uiImage: thumbnailImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 100)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.shunshiPrimary.opacity(0.3), Color.shunshiPrimary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 100)
                }
                
                // 播放按钮覆盖层
                VStack {
                    Spacer()
                    HStack {
                        // 时长标签
                        Text(video.formattedDuration)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                        
                        Spacer()
                        
                        // 播放图标
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        
                        Spacer()
                        
                        // 来源标签
                        Text(video.source.displayName)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.shunshiPrimary)
                            .clipShape(Capsule())
                    }
                    .padding(8)
                }
            }
            
            // 标题和来源
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(video.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.AppText.primary(colorScheme))
                        .lineLimit(2)
                    
                    Spacer()
                }
                
                HStack {
                    Label(video.source.displayName, systemImage: video.source.icon)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("·")
                        .foregroundColor(.secondary)
                    
                    Text("\(formatViews(video.views))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        guard showThumbnail, let thumbnailURL = video.thumbnailURL else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: thumbnailURL)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.thumbnailImage = image
                    }
                }
            } catch {
                print("Failed to load thumbnail: \(error)")
            }
        }
    }
    
    private func formatViews(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1f万", Double(count) / 10000)
        } else if count >= 1000 {
            return String(format: "%.1f千", Double(count) / 1000)
        }
        return "\(count)"
    }
}

// MARK: - Video List View
struct VideoListView: View {
    @StateObject private var videoService = WellnessVideoService.shared
    @State private var selectedCategory: WellnessVideo.VideoCategory?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 分类筛选
                    categoryFilter
                    
                    // 视频网格
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 12) {
                        ForEach(filteredVideos) { video in
                            NavigationLink(destination: VideoPlayerView(video: video)) {
                                VideoCard(video: video)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.Background.adaptive(colorScheme))
            .navigationTitle("养生视频")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                videoService.fetchVideos()
            }
        }
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "全部",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil,
                    action: { 
                        selectedCategory = nil
                        videoService.fetchVideos(category: nil)
                    }
                )
                
                ForEach(WellnessVideo.VideoCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: selectedCategory == category,
                        action: { 
                            selectedCategory = category
                            videoService.fetchVideos(category: category)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var filteredVideos: [WellnessVideo] {
        if let category = selectedCategory {
            return videoService.videos.filter { $0.category == category }
        }
        return videoService.videos
    }
}

extension WellnessVideo.VideoCategory {
    var displayName: String {
        switch self {
        case .acupoint: return "穴位按摩"
        case .exercise: return "运动跟练"
        case .diet: return "饮食教程"
        case .meditation: return "冥想"
        case .taiChi: return "太极拳"
        case .qigong: return "气功"
        }
    }
    
    var icon: String {
        switch self {
        case .acupoint: return "hand.point.up"
        case .exercise: return "figure.walk"
        case .diet: return "fork.knife"
        case .meditation: return "brain.head.profile"
        case .taiChi: return "figure.mind.and.body"
        case .qigong: return "wind"
        }
    }
}
