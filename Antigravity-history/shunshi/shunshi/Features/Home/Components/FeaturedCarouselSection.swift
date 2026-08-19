import SwiftUI

// MARK: - Featured Carousel Section
struct FeaturedCarouselSection: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentIndex = 0
    
    private let carouselItems: [CarouselItem] = [
        CarouselItem(
            title: "大寒养生",
            subtitle: "温补肾阳，抵御严寒",
            imageId: "1607962837359-5e7e89f86776",
            gradientColors: [.blue, .purple],
            isPremium: false
        ),
        CarouselItem(
            title: "八段锦",
            subtitle: "传统养生功法，强身健体",
            imageId: "1544367567879-0490979c091a",
            gradientColors: [.green, .teal],
            isPremium: false
        ),
        CarouselItem(
            title: "冬季食疗",
            subtitle: "会员专属食谱，养护脾胃",
            imageId: "1603073163308-9654c3fb70b5",
            gradientColors: [.orange, .red],
            isPremium: true
        ),
        CarouselItem(
            title: "穴位养生",
            subtitle: "足三里、涌泉穴按摩指南",
            imageId: "1552196563-55cd4e7ed812",
            gradientColors: [.purple, .pink],
            isPremium: false
        )
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            // 轮播图
            TabView(selection: $currentIndex) {
                ForEach(carouselItems.indices, id: \.self) { index in
                    CarouselCard(item: carouselItems[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Custom Capsule + Dot Indicator
            HStack(spacing: 6) {
                ForEach(carouselItems.indices, id: \.self) { index in
                    if index == currentIndex {
                        Capsule()
                            .fill(Color.shunshiPrimary)
                            .frame(width: 20, height: 6)
                            .transition(.scale)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                            .transition(.scale)
                    }
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
        }
    }
}

// MARK: - Carousel Item
struct CarouselItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageId: String
    let gradientColors: [Color]
    let isPremium: Bool
    
    var imageURL: URL? {
        URL(string: "https://images.unsplash.com/photo-\(imageId)?w=800&h=400&fit=crop")
    }
}

// MARK: - Carousel Card
struct CarouselCard: View {
    let item: CarouselItem
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 背景图片
            if let url = item.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        gradientPlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        gradientPlaceholder
                    @unknown default:
                        gradientPlaceholder
                    }
                }
            } else {
                gradientPlaceholder
            }
            
            // Gradient Overlay for Text Readability
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.5),
                    .init(color: .black.opacity(0.4), location: 0.8),
                    .init(color: .black.opacity(0.8), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    if item.isPremium {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                            Text("会员")
                                .font(.caption2.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing))
                        )
                    }
                }
                
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding()
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var gradientPlaceholder: some View {
        LinearGradient(
            colors: item.gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    FeaturedCarouselSection()
        .padding()
        .background(Color.Background.dark)
        .preferredColorScheme(.dark)
}

