import Testing
import Foundation
@testable import shunshi

@MainActor
struct ProfileViewModelTests {
    
    @Test func testInitialState() {
        let auth = AuthService.shared
        let viewModel = ProfileViewModel(authService: auth)
        
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }
    
    @Test func testDisplayName() {
        let auth = AuthService.shared
        let viewModel = ProfileViewModel(authService: auth)
        
        #expect(viewModel.displayName == "未登录" || !viewModel.displayName.isEmpty)
    }
}
