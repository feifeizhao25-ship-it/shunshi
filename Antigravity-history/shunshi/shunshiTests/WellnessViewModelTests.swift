import Testing
import Foundation
@testable import shunshi

@MainActor
struct WellnessViewModelTests {
    
    @Test func testInitialState() async {
        let viewModel = WellnessViewModel()
        
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
        #expect(viewModel.selectedDimension == .diet)
    }
    
    @Test func testLoadData() async {
        let viewModel = WellnessViewModel()
        await viewModel.loadData()
        
        #expect(viewModel.recipes.count > 0)
        #expect(viewModel.isLoading == false)
    }
    
    @Test func testChangeDimension() async {
        let viewModel = WellnessViewModel()
        
        viewModel.selectedDimension = .exercise
        #expect(viewModel.selectedDimension == .exercise)
    }

}
