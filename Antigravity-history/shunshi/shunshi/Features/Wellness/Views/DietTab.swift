import SwiftUI

// MARK: - Diet Tab
struct DietTab: View {
    @ObservedObject var viewModel: WellnessViewModel
    @State private var selectedCategory: DietCategory = .all
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Picker
            categoryPicker
            
            // Content
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.recipes) { recipe in
                        DietRecipeCard(recipe: recipe)
                    }
                    
                    // Load More
                    if viewModel.hasMoreRecipes {
                        ProgressView()
                            .padding()
                            .onAppear {
                                Task {
                                    await viewModel.loadMoreRecipes()
                                }
                            }
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Category Picker
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(DietCategory.allCases) { category in
                    CategoryChip(
                        title: category.displayName,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Diet Category
enum DietCategory: String, CaseIterable, Identifiable {
    case all = "all"
    case recommended = "recommended"
    case soup = "soup"
    case congee = "congee"
    case tea = "tea"
    case sideDish = "side_dish"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all: return "全部"
        case .recommended: return "推荐"
        case .soup: return "汤羹"
        case .congee: return "粥品"
        case .tea: return "茶饮"
        case .sideDish: return "小菜"
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color(.tertiarySystemBackground))
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Diet Recipe Card
struct DietRecipeCard: View {
    let recipe: Recipe
    @Environment(\.colorScheme) private var colorScheme

    /// AI图片提示词
    private var imagePrompt: String {
        "Delicious \(recipe.name) Chinese dish, traditional ceramic plate, warm food photography, appetizing, high quality"
    }

    var body: some View {
        NavigationLink {
            RecipeDetailView(recipe: recipe)
        } label: {
            HStack(spacing: 12) {
                // AI Generated Image
                AIImageView(
                    prompt: imagePrompt,
                    cacheKey: "diet_recipe_\(recipe.id)",
                    aspectRatio: 1,
                    cornerRadius: 12
                )
                .frame(width: 100, height: 100)
                
                // Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(recipe.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        Label(recipe.cookingTimeText, systemImage: "clock")
                        Label(recipe.difficulty.displayName, systemImage: "chart.bar")
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                // Favorite
                Button {
                    // TODO: Toggle favorite
                } label: {
                    Image(systemName: recipe.isFavorited ? "heart.fill" : "heart")
                        .foregroundStyle(recipe.isFavorited ? .red : .secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    NavigationStack {
        DietTab(viewModel: WellnessViewModel())
    }
}

