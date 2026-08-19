import Foundation
@testable import shunshi

class MockWellnessRepository: WellnessRepositoryProtocol {
    var getOverviewResult: WellnessOverview?
    var getIngredientsResult: PaginatedResult<Ingredient> = .empty()
    var getIngredientDetailResult: Ingredient?
    var getRecipesResult: PaginatedResult<Recipe> = .empty()
    var getRecipeDetailResult: RecipeDetail?
    var getTeasResult: PaginatedResult<Recipe> = .empty()
    var getLivingRecommendationsResult: [LivingRecommendation] = []
    var getExerciseRecommendationsResult: [Exercise] = []
    var getAcupointsResult: [Acupoint] = []
    var getEmotionRecommendationsResult: [EmotionRecommendation] = []
    
    var errorToThrow: Error?

    func getOverview(solarTermId: String?, constitution: ConstitutionType?) async throws -> WellnessOverview {
        if let error = errorToThrow { throw error }
        guard let result = getOverviewResult else {
            throw AppError.operationFailed("Mock get overview failed")
        }
        return result
    }

    func getIngredients(solarTermId: String?, constitution: ConstitutionType?, category: IngredientCategory?, page: Int, pageSize: Int) async throws -> PaginatedResult<Ingredient> {
        if let error = errorToThrow { throw error }
        return getIngredientsResult
    }

    func getIngredientDetail(id: String) async throws -> Ingredient {
        if let error = errorToThrow { throw error }
        guard let result = getIngredientDetailResult else {
            throw AppError.operationFailed("Mock get ingredient detail failed")
        }
        return result
    }

    func getRecipes(solarTermId: String?, constitution: ConstitutionType?, category: RecipeCategory?, difficulty: RecipeDifficulty?, page: Int, pageSize: Int) async throws -> PaginatedResult<Recipe> {
        if let error = errorToThrow { throw error }
        return getRecipesResult
    }

    func getRecipeDetail(id: String) async throws -> RecipeDetail {
        if let error = errorToThrow { throw error }
        guard let result = getRecipeDetailResult else {
            throw AppError.operationFailed("Mock get recipe detail failed")
        }
        return result
    }

    func getTeas(solarTermId: String?, constitution: ConstitutionType?, page: Int, pageSize: Int) async throws -> PaginatedResult<Recipe> {
        if let error = errorToThrow { throw error }
        return getTeasResult
    }

    func getLivingRecommendations(solarTermId: String?, constitution: ConstitutionType?) async throws -> [LivingRecommendation] {
        if let error = errorToThrow { throw error }
        return getLivingRecommendationsResult
    }

    func getExerciseRecommendations(solarTermId: String?, constitution: ConstitutionType?) async throws -> [Exercise] {
        if let error = errorToThrow { throw error }
        return getExerciseRecommendationsResult
    }

    func getAcupoints(solarTermId: String?, constitution: ConstitutionType?, purpose: String?) async throws -> [Acupoint] {
        if let error = errorToThrow { throw error }
        return getAcupointsResult
    }

    func getEmotionRecommendations(solarTermId: String?, constitution: ConstitutionType?) async throws -> [EmotionRecommendation] {
        if let error = errorToThrow { throw error }
        return getEmotionRecommendationsResult
    }
}
