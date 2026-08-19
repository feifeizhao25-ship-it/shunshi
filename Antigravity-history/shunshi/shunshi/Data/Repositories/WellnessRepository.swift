import Foundation

// MARK: - Wellness Repository
final class WellnessRepository: WellnessRepositoryProtocol {
    static let shared = WellnessRepository()
    
    private init() {}
    
    func getOverview(solarTermId: String?, constitution: ConstitutionType?) async throws -> WellnessOverview {
        // Mock data
        return WellnessOverview(
            solarTerm: SolarTermRef(id: solarTermId ?? "daxue", name: "大雪", startDate: nil),
            constitution: constitution,
            summary: "大雪时节，宜温补。\(constitution?.displayName ?? "")者更需注意保暖。",
            dimensions: [],
            todayTips: []
        )
    }
    
    func getIngredients(
        solarTermId: String?,
        constitution: ConstitutionType?,
        category: IngredientCategory?,
        page: Int,
        pageSize: Int
    ) async throws -> PaginatedResult<Ingredient> {
        return .empty()
    }
    
    func getIngredientDetail(id: String) async throws -> Ingredient {
        throw AppError.dataNotFound
    }
    
    func getRecipes(
        solarTermId: String?,
        constitution: ConstitutionType?,
        category: RecipeCategory?,
        difficulty: RecipeDifficulty?,
        page: Int,
        pageSize: Int
    ) async throws -> PaginatedResult<Recipe> {
        // Mock recipes
        let allRecipes: [Recipe] = [
            Recipe(
                id: "1", name: "当归生姜羊肉汤", category: .soup,
                description: "温中补虚，祛寒止痛。适合冬季进补。",
                coverImage: nil, videoUrl: nil,
                effects: ["温中补虚", "祛寒"],
                suitableFor: [.yangDeficiency, .qiDeficiency],
                unsuitableFor: [.yinDeficiency],
                difficulty: .medium, cookingTime: 90, servings: 4, calories: 350,
                rating: 4.8, favoritesCount: 120, isFavorited: false, tags: ["温补"], source: nil, isPremium: false
            ),
            Recipe(
                id: "2", name: "银耳雪梨羹", category: .dessert,
                description: "滋阴润肺，清热生津。适合秋冬燥邪。",
                coverImage: nil, videoUrl: nil,
                effects: ["润肺", "生津"],
                suitableFor: [.yinDeficiency, .balanced],
                unsuitableFor: [.yangDeficiency],
                difficulty: .easy, cookingTime: 45, servings: 2, calories: 150,
                rating: 4.6, favoritesCount: 85, isFavorited: false, tags: ["润肺"], source: nil, isPremium: false
            ),
            Recipe(
                id: "3", name: "茯苓排骨汤", category: .soup,
                description: "健脾利湿，宁心安神。适合湿气重体质。",
                coverImage: nil, videoUrl: nil,
                effects: ["利湿", "健脾"],
                suitableFor: [.phlegmDampness, .dampHeat],
                unsuitableFor: [],
                difficulty: .medium, cookingTime: 60, servings: 3, calories: 280,
                rating: 4.7, favoritesCount: 95, isFavorited: false, tags: ["祛湿"], source: nil, isPremium: false
            ),
            Recipe(
                id: "4", name: "莲子百合粥", category: .congee,
                description: "宁心安神，润肺止咳。适合心神不宁时食用。",
                coverImage: nil, videoUrl: nil,
                effects: ["安神", "润肺"],
                suitableFor: [.qiStagnation, .balanced],
                unsuitableFor: [],
                difficulty: .easy, cookingTime: 40, servings: 2, calories: 180,
                rating: 4.5, favoritesCount: 110, isFavorited: false, tags: ["早安"], source: nil, isPremium: false
            )
        ]
        
        let filtered = allRecipes.filter { recipe in
            if let constitution = constitution {
                return recipe.suitableFor.contains(constitution)
            }
            return true
        }
        
        return PaginatedResult(
            items: Array(filtered.prefix(pageSize)),
            page: page,
            pageSize: pageSize,
            total: filtered.count,
            hasMore: false
        )
    }
    
    func getRecipeDetail(id: String) async throws -> RecipeDetail {
        throw AppError.dataNotFound
    }
    
    func getTeas(solarTermId: String?, constitution: ConstitutionType?, page: Int, pageSize: Int) async throws -> PaginatedResult<Recipe> {
        return .empty()
    }
    
    func getLivingRecommendations(solarTermId: String?, constitution: ConstitutionType?) async throws -> [LivingRecommendation] {
        return []
    }
    
    func getExerciseRecommendations(solarTermId: String?, constitution: ConstitutionType?) async throws -> [Exercise] {
        return []
    }
    
    func getAcupoints(solarTermId: String?, constitution: ConstitutionType?, purpose: String?) async throws -> [Acupoint] {
        return []
    }
    
    func getEmotionRecommendations(solarTermId: String?, constitution: ConstitutionType?) async throws -> [EmotionRecommendation] {
        return []
    }
}
