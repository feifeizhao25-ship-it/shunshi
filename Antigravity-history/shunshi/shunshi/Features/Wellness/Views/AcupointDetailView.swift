import SwiftUI

// MARK: - Acupoint Detail View (穴位详情页)
struct LivingAcupointDetailView: View {
    let acupoint: Acupoint
    @StateObject private var contentService = WellnessContentService.shared
    @StateObject private var videoService = WellnessVideoService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var isFavorited = false
    @State private var showReminderSheet = false
    @State private var showVideoPlayer = false
    @State private var selectedVideo: WellnessVideo?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Hero Section with AI Generated Image
                heroSection
                
                // Content
                VStack(spacing: AppSpacing.lg) {
                    // Title Section
                    titleSection
                    
                    // Location Section
                    locationSection
                    
                    // Effects Section
                    effectsSection
                    
                    // Audio Guide Section
                    audioGuideSection
                    
                    // Massage Method Section
                    massageMethodSection
                    
                    // Indications Section
                    if !acupoint.indications.isEmpty {
                        indicationsSection
                    }
                    
                    // Contraindications Section
                    if !acupoint.contraindications.isEmpty {
                        contraindicationsSection
                    }
                    
                    // Related Videos Section
                    relatedVideosSection
                    
                    // Solar Term Special Tips
                    solarTermTipsSection
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, 120)
            }
        }
        .background(Color.Background.adaptive(colorScheme).ignoresSafeArea())
        .overlay(alignment: .bottom) {
            // Fixed Bottom Button
            bottomButton
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(acupoint.name)
                    .font(AppTypography.headline(17))
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button(action: { isFavorited.toggle() }) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .foregroundColor(isFavorited ? .red : Color.AppText.muted(colorScheme))
                    }
                }
            }
            
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                        Text("关闭")
                    }
                    .foregroundColor(.shunshiPrimary)
                }
            }
        }
        .sheet(isPresented: $showReminderSheet) {
            ReminderSettingSheet(acupointName: acupoint.name)
                .presentationDetents([.medium])
        }
        .sheet(item: $selectedVideo) { video in
            VideoPlayerView(video: video)
        }
    }
    
    // MARK: - Hero Section with AI Generated Image
    private var heroSection: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.shunshiPrimary.opacity(0.2),
                    Color.Background.adaptive(colorScheme)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 340)
            
            VStack(spacing: AppSpacing.lg) {
                // AI Generated Acupoint Image
                AIImageView(
                    prompt: acupoint.imagePrompt,
                    cacheKey: "acupoint_\(acupoint.id)",
                    aspectRatio: 200/280,
                    cornerRadius: 16
                )
                .frame(width: 220, height: 280)
                .shadow(color: Color.black.opacity(0.1), radius: 20, y: 10)
                
                // Rotation hint
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "rotate.3d")
                    Text("AI生成的穴位定位图")
                }
                .font(AppTypography.caption())
                .foregroundColor(Color.AppText.muted(colorScheme))
            }
            .padding(.top, AppSpacing.xl)
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .bottom) {
                Text(acupoint.name)
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(Color.AppText.primary(colorScheme))
                
                Text(acupoint.pinyin)
                    .font(AppTypography.caption())
                    .foregroundColor(Color.AppText.muted(colorScheme))
                    .padding(.bottom, 6)
            }
            
            // Meridian tag
            HStack(spacing: AppSpacing.sm) {
                Text(acupoint.meridian.displayName)
                    .font(AppTypography.caption())
                    .foregroundColor(.shunshiPrimary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(Color.shunshiPrimary.opacity(0.1))
                    .clipShape(Capsule())
                
                Text("按摩\(acupoint.duration)秒")
                    .font(AppTypography.caption())
                    .foregroundColor(.orange)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeaderAcupoint(title: "穴位定位", icon: "mappin.circle")
            
            Text(acupoint.location)
                .font(AppTypography.body())
                .foregroundColor(Color.AppText.secondary(colorScheme))
                .lineSpacing(6)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
    }
    
    // MARK: - Effects Section
    private var effectsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeaderAcupoint(title: "功效作用", icon: "sparkles")
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(acupoint.effects, id: \.self) { effect in
                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.shunshiPrimary)
                            .font(.system(size: 16))
                        
                        Text(effect)
                            .font(AppTypography.body())
                            .foregroundColor(Color.AppText.secondary(colorScheme))
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
    }
    
    // MARK: - Audio Guide Section
    private var audioGuideSection: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.shunshiPrimary.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "headphones")
                    .foregroundColor(.shunshiPrimary)
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("沉浸式语音引导")
                    .font(AppTypography.headline(16))
                    .foregroundColor(Color.AppText.primary(colorScheme))
                
                Text("跟着小师的节奏，开启身心调理之约")
                    .font(AppTypography.caption(12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                // TODO: Play audio
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }) {
                Text("开始听")
                    .font(AppTypography.label(14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.shunshiPrimary)
                    .clipShape(Capsule())
            }
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .fill(Color.shunshiPrimary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .stroke(Color.shunshiPrimary.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Massage Method Section
    private var massageMethodSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeaderAcupoint(title: "按摩三部曲", icon: "hand.point.up.fill")
            
            VStack(alignment: .leading, spacing: Spacing.medium) {
                massageStep(num: "1", title: "寻穴位", desc: acupoint.location)
                massageStep(num: "2", title: "施手法", desc: acupoint.method)
                massageStep(num: "3", title: "控时长", desc: "建议持续按揉\(acupoint.duration / 60)分钟，感到微微发热或酸胀为宜。")
            }
            
            // Video button
            if !relatedVideos.isEmpty {
                Button(action: {
                    selectedVideo = relatedVideos.first
                }) {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .fill(Color.shunshiPrimary.opacity(0.15))
                                .frame(width: 80, height: 60)
                            
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.shunshiPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(acupoint.name)手法示范")
                                .font(AppTypography.headline(14))
                                .foregroundColor(Color.AppText.primary(colorScheme))
                            
                            Text("15秒循环真人演示")
                                .font(AppTypography.caption())
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color.AppText.muted(colorScheme))
                    }
                    .padding(AppSpacing.md)
                    .background(Color.Background.adaptive(colorScheme).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                }
                .buttonStyle(.plain)
                .padding(.top, AppSpacing.sm)
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
    }
    
    private func massageStep(num: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Text(num)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.shunshiPrimary))
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.headline(15))
                    .foregroundColor(Color.AppText.primary(colorScheme))
                
                Text(desc)
                    .font(AppTypography.body(14))
                    .foregroundColor(Color.AppText.secondary(colorScheme))
                    .lineSpacing(4)
            }
        }
    }
    
    // MARK: - Indications Section
    private var indicationsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeaderAcupoint(title: "主治症状", icon: "cross.case")
            
            FlowLayout(spacing: AppSpacing.sm) {
                ForEach(acupoint.indications, id: \.self) { indication in
                    Text(indication)
                        .font(AppTypography.caption())
                        .foregroundColor(Color.AppText.primary(colorScheme))
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(Color.Surface.darkLighter)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
    }
    
    // MARK: - Contraindications Section
    private var contraindicationsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeaderAcupoint(title: "注意事项", icon: "exclamationmark.triangle")
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(acupoint.contraindications, id: \.self) { item in
                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 14))
                        
                        Text(item)
                            .font(AppTypography.body())
                            .foregroundColor(Color.AppText.secondary(colorScheme))
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Surface.adaptive(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
    }
    
    // MARK: - Related Videos Section
    private var relatedVideosSection: some View {
        Group {
            if !relatedVideos.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        SectionHeaderAcupoint(title: "相关视频", icon: "play.rectangle")
                        Spacer()
                        NavigationLink(destination: VideoListView()) {
                            Text("查看全部")
                                .font(AppTypography.label(12))
                                .foregroundColor(.shunshiPrimary)
                        }
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.md) {
                            ForEach(relatedVideos.prefix(3)) { video in
                                VideoCard(video: video)
                                    .frame(width: 180)
                                    .onTapGesture {
                                        selectedVideo = video
                                    }
                            }
                        }
                    }
                }
                .padding(AppSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.Surface.adaptive(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
            }
        }
    }
    
    private var relatedVideos: [WellnessVideo] {
        videoService.getVideos(for: acupoint)
    }
    
    // MARK: - Solar Term Tips Section
    private var solarTermTipsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: "snowflake")
                    .foregroundColor(.seasonWinter)
                Text("当前节气养生提示")
                    .font(AppTypography.headline(16))
                    .foregroundColor(Color.AppText.primary(colorScheme))
            }
            
            Text("在当前节气按摩\(acupoint.name)，可\(acupoint.effects.first ?? "调和气血")。建议每日早晚各按揉\(acupoint.duration / 60)分钟，力度适中，感到酸胀为宜。")
                .font(AppTypography.body())
                .foregroundColor(Color.AppText.secondary(colorScheme))
                .lineSpacing(6)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.shunshiPrimary.opacity(0.1), Color.shunshiPrimary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .stroke(Color.shunshiPrimary.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Bottom Button
    private var bottomButton: some View {
        Button(action: { showReminderSheet = true }) {
            HStack {
                Image(systemName: "bell.fill")
                Text("设置按摩提醒")
            }
            .font(AppTypography.headline(16))
            .foregroundColor(Color.Background.dark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
            .background(Color.shunshiPrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
            .shadow(color: Color.shunshiPrimary.opacity(0.4), radius: 12, y: 6)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.xl)
        .background(
            LinearGradient(
                colors: [Color.Background.adaptive(colorScheme).opacity(0), Color.Background.adaptive(colorScheme)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Section Header
struct SectionHeaderAcupoint: View {
    let title: String
    let icon: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(.shunshiPrimary)
            Text(title)
                .font(AppTypography.headline(16))
                .foregroundColor(Color.AppText.primary(colorScheme))
        }
    }
}

// MARK: - Reminder Setting Sheet
struct ReminderSettingSheet: View {
    let acupointName: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var morningReminder = true
    @State private var eveningReminder = true
    @State private var morningTime = Date()
    @State private var eveningTime = Date()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                // Morning Reminder
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Toggle(isOn: $morningReminder) {
                        HStack {
                            Image(systemName: "sunrise.fill")
                                .foregroundColor(.orange)
                            Text("早间提醒")
                                .font(AppTypography.headline(15))
                        }
                    }
                    .tint(.shunshiPrimary)
                    
                    if morningReminder {
                        DatePicker("", selection: $morningTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .frame(height: 100)
                    }
                }
                .padding(AppSpacing.lg)
                .background(Color.Surface.adaptive(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
                
                // Evening Reminder
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Toggle(isOn: $eveningReminder) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.indigo)
                            Text("晚间提醒")
                                .font(AppTypography.headline(15))
                        }
                    }
                    .tint(.shunshiPrimary)
                    
                    if eveningReminder {
                        DatePicker("", selection: $eveningTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .frame(height: 100)
                    }
                }
                .padding(AppSpacing.lg)
                .background(Color.Surface.adaptive(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
                
                Spacer()
                
                // Save Button
                Button(action: {
                    // TODO: Save reminder settings
                    dismiss()
                }) {
                    Text("保存设置")
                        .font(AppTypography.headline(16))
                        .foregroundColor(Color.Background.dark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.lg)
                        .background(Color.shunshiPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
                }
            }
            .padding(AppSpacing.md)
            .background(Color.Background.adaptive(colorScheme).ignoresSafeArea())
            .navigationTitle("\(acupointName)按摩提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        LivingAcupointDetailView(acupoint: Acupoint.sampleData[1])
    }
    .preferredColorScheme(.dark)
    .environmentObject(WellnessVideoService.shared)
}
