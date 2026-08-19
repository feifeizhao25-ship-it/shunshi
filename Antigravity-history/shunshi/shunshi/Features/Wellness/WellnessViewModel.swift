import Foundation
import Combine

// MARK: - Wellness View Model
@MainActor
final class WellnessViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedDimension: WellnessDimension = .diet
    @Published var overview: WellnessOverview?
    @Published var recipes: [Recipe] = []
    @Published var ingredients: [Ingredient] = []
    @Published var exercises: [Exercise] = []
    @Published var acupoints: [Acupoint] = []
    @Published var isLoading: Bool = false
    @Published var error: AppError?
    
    // MARK: - Pagination
    @Published var hasMoreRecipes: Bool = true
    private var currentPage: Int = 1
    private let pageSize: Int = 20
    
    // MARK: - Dependencies
    private let appStateService: AppStateService
    private let authService: AuthService
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        appStateService: AppStateService? = nil,
        authService: AuthService? = nil
    ) {
        self.appStateService = appStateService ?? .shared
        self.authService = authService ?? .shared
    }
    
    // MARK: - Computed Properties
    var currentSolarTerm: SolarTerm? {
        appStateService.currentSolarTerm
    }
    
    var userConstitution: ConstitutionType? {
        authService.currentUser?.constitution?.primary?.type
    }
    
    // MARK: - Load Data
    func loadData() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        // For now, load mock data
        // TODO: Replace with actual API calls
        await loadMockData()
        
        isLoading = false
    }
    
    // MARK: - Load More Recipes
    func loadMoreRecipes() async {
        guard hasMoreRecipes, !isLoading else { return }
        
        currentPage += 1
        // TODO: Load more from API
    }
    
    // MARK: - Refresh
    func refresh() async {
        currentPage = 1
        hasMoreRecipes = true
        await loadData()
    }
    
    // MARK: - Select Dimension
    func selectDimension(_ dimension: WellnessDimension) {
        selectedDimension = dimension
        Task {
            await loadDimensionData(dimension)
        }
    }
    
    // MARK: - Private Methods
    private func loadDimensionData(_ dimension: WellnessDimension) async {
        // TODO: Load specific dimension data
    }
    
    private func loadMockData() async {
        // Mock delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Mock recipes
        recipes = (1...5).map { index in
            Recipe(
                id: "recipe_\(index)",
                name: "养生汤品\(index)",
                category: .soup,
                description: "适合当前节气的养生汤品",
                coverImage: nil,
                videoUrl: nil,
                effects: ["健脾养胃", "补气养血"],
                suitableFor: [.balanced, .qiDeficiency],
                unsuitableFor: [],
                difficulty: .easy,
                cookingTime: 60,
                servings: 2,
                calories: 200,
                rating: 4.5,
                favoritesCount: 100,
                isFavorited: false,
                tags: ["养生", "补气"],
                source: nil,
                isPremium: false
            )
        }
    }
}

// MARK: - Wellness Tab
enum WellnessTab: String, CaseIterable, Identifiable {
    case overview = "overview"
    case diet = "diet"
    case living = "living"
    case exercise = "exercise"
    case emotion = "emotion"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .overview: return "概览"
        case .diet: return "饮食"
        case .living: return "起居"
        case .exercise: return "运动"
        case .emotion: return "情志"
        }
    }
    
    var icon: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .diet: return "leaf.fill"
        case .living: return "bed.double.fill"
        case .exercise: return "figure.walk"
        case .emotion: return "heart.fill"
        }
    }
}

