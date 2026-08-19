import Foundation
import SwiftUI

// MARK: - Recipe
struct Recipe: Identifiable, Equatable {
    let id: String
    let name: String
    let category: RecipeCategory
    let description: String
    let coverImage: URL?
    let videoUrl: URL?
    let effects: [String]
    let suitableFor: [ConstitutionType]
    let unsuitableFor: [ConstitutionType]
    let difficulty: RecipeDifficulty
    let cookingTime: Int
    let servings: Int
    let calories: Int?
    let rating: Double?
    let favoritesCount: Int
    var isFavorited: Bool
    let tags: [String]
    let source: RecipeSource?
    let isPremium: Bool
    
    var cookingTimeText: String {
        if cookingTime < 60 {
            return "\(cookingTime)分钟"
        } else {
            let hours = cookingTime / 60
            let minutes = cookingTime % 60
            return minutes > 0 ? "\(hours)小时\(minutes)分钟" : "\(hours)小时"
        }
    }
}

// MARK: - Recipe Category
enum RecipeCategory: String, CaseIterable {
    case soup = "soup"
    case congee = "congee"
    case tea = "tea"
    case mainDish = "main_dish"
    case sideDish = "side_dish"
    case dessert = "dessert"
    case medicinalMeal = "medicinal_meal"
    
    var displayName: String {
        switch self {
        case .soup: return "汤羹"
        case .congee: return "粥品"
        case .tea: return "茶饮"
        case .mainDish: return "主菜"
        case .sideDish: return "小菜"
        case .dessert: return "甜品"
        case .medicinalMeal: return "药膳"
        }
    }
    
    var icon: String {
        switch self {
        case .soup: return "cup.and.saucer.fill"
        case .congee: return "bowl.fill"
        case .tea: return "mug.fill"
        case .mainDish: return "fork.knife"
        case .sideDish: return "leaf.fill"
        case .dessert: return "birthday.cake.fill"
        case .medicinalMeal: return "cross.vial.fill"
        }
    }
}

// MARK: - Recipe Difficulty
enum RecipeDifficulty: String, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var displayName: String {
        switch self {
        case .easy: return "简单"
        case .medium: return "中等"
        case .hard: return "复杂"
        }
    }
    
    var stars: Int {
        switch self {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }
}

// MARK: - Recipe Source
struct RecipeSource: Equatable {
    let book: String?
    let author: String?
    let dynasty: String?
    
    var displayText: String? {
        if let book = book {
            if let dynasty = dynasty, let author = author {
                return "出自[\(dynasty)]\(author)《\(book)》"
            } else if let author = author {
                return "出自\(author)《\(book)》"
            }
            return "出自《\(book)》"
        }
        return nil
    }
}

// MARK: - Recipe Detail
struct RecipeDetail: Identifiable, Equatable {
    let id: String
    let recipe: Recipe
    let ingredients: [RecipeIngredient]
    let steps: [RecipeStep]
    let tips: [String]
    let nutritionFacts: NutritionFacts?
    let relatedRecipes: [Recipe]
}

// MARK: - Recipe Ingredient
struct RecipeIngredient: Identifiable, Equatable {
    let id: String
    let name: String
    let amount: String
    let unit: String
    let isOptional: Bool
    let ingredientId: String?
    
    var displayAmount: String {
        "\(amount)\(unit)"
    }
}

// MARK: - Recipe Step
struct RecipeStep: Identifiable, Equatable {
    let id = UUID()
    let order: Int
    let content: String
    let imageUrl: URL?
    let duration: Int?
    
    var durationText: String? {
        guard let duration = duration else { return nil }
        return "\(duration)分钟"
    }
}

// MARK: - Nutrition Facts
struct NutritionFacts: Equatable {
    let calories: Int
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let fiber: Double?
    let sodium: Double?
}

// MARK: - Recipe Mapper
extension Recipe {
    init(from dto: RecipeDTO) {
        self.id = dto.id
        self.name = dto.name
        self.category = RecipeCategory(rawValue: dto.category) ?? .mainDish
        self.description = dto.description
        self.coverImage = dto.coverImage.flatMap { URL(string: $0) }
        self.videoUrl = dto.videoUrl.flatMap { URL(string: $0) }
        self.effects = dto.effects
        self.suitableFor = dto.suitableFor.compactMap { ConstitutionType(rawValue: $0) }
        self.unsuitableFor = dto.unsuitableFor.compactMap { ConstitutionType(rawValue: $0) }
        self.difficulty = RecipeDifficulty(rawValue: dto.difficulty) ?? .medium
        self.cookingTime = dto.cookingTime
        self.servings = dto.servings
        self.calories = dto.calories
        self.rating = dto.rating
        self.favoritesCount = dto.favoritesCount
        self.isFavorited = dto.isFavorited
        self.tags = dto.tags
        self.source = dto.source.map {
            RecipeSource(book: $0.book, author: $0.author, dynasty: $0.dynasty)
        }
        self.isPremium = true // Default for now
    }

    // MARK: - Preview Data
    static let preview = Recipe(
        id: "recipe_preview",
        name: "当归生姜羊肉汤",
        category: .soup,
        description: "温中补虚，祛寒止痛。适合冬季进补，尤其适合阳虚体质者。",
        coverImage: nil,
        videoUrl: nil,
        effects: ["温中补虚", "祛寒止痛", "补血养血"],
        suitableFor: [.yangDeficiency, .qiDeficiency],
        unsuitableFor: [.dampHeat, .yinDeficiency],
        difficulty: .medium,
        cookingTime: 90,
        servings: 4,
        calories: 350,
        rating: 4.8,
        favoritesCount: 1280,
        isFavorited: false,
        tags: ["冬季", "温补", "羊肉"],
        source: RecipeSource(book: "金匮要略", author: "张仲景", dynasty: "东汉"),
        isPremium: true
    )
}

