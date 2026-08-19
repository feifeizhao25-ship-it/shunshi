import Foundation
import SwiftUI

@MainActor
final class ConditioningPlanViewModel: ObservableObject {
    @Published var plan: ConditioningPlan?
    @Published var isLoading: Bool = false
    @Published var selectedDay: Int = 1
    @Published var error: String?
    
    private let planService = PlanGenerationService.shared
    
    func loadPlan(constitution: String, solarTerm: String) async {
        isLoading = true
        error = nil
        
        do {
            // Mock userId for now
            let generatedPlan = try await planService.generatePlan(for: "current_user", constitution: constitution, solarTerm: solarTerm)
            self.plan = generatedPlan
            self.isLoading = false
        } catch {
            self.error = "未能生成调理方案，请稍后再试"
            self.isLoading = false
        }
    }
    
    var currentDayTasks: PlanDayTask? {
        plan?.weeklyTasks.first(where: { $0.dayOfWeek == selectedDay })
    }
}
