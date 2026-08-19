import Testing
import Foundation
@testable import shunshi

@MainActor
struct HomeViewModelTests {
    
    @Test func testInitialState() {
        let viewModel = HomeViewModel()
        
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
        #expect(viewModel.todayTips.isEmpty)
        #expect(viewModel.todayRecipes.isEmpty)
    }
    
    @Test func testLoadData() async {
        let solarRepo = MockSolarTermRepository()
        let wellnessRepo = MockWellnessRepository()
        let viewModel = HomeViewModel(
            solarTermRepository: solarRepo,
            wellnessRepository: wellnessRepo
        )
        
        await viewModel.loadData()
        
        #expect(viewModel.isLoading == false)
        #expect(viewModel.todayTips.count > 0)
        #expect(viewModel.dailyRituals.count > 0)
        #expect(viewModel.dailyRituals.contains { $0.period == .morning })
    }
}
