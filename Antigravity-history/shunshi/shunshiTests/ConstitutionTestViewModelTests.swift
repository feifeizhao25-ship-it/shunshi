import XCTest
@testable import shunshi

@MainActor
final class ConstitutionTestViewModelTests: XCTestCase {
    
    func testInitialization() {
        let viewModel = ConstitutionTestViewModel()
        XCTAssertEqual(viewModel.totalQuestions, 54, "Total questions should be 54")
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertFalse(viewModel.isCompleted)
        XCTAssertNil(viewModel.resultType)
    }
    
    func testQuestionProgress() async {
        let viewModel = ConstitutionTestViewModel()
        
        // Answer all questions with 'sometimes'
        for i in 0..<54 {
            XCTAssertEqual(viewModel.currentIndex, i)
            viewModel.selectOption(.sometimes)
            
            // Wait for the auto-advance animation/delay
            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4s
        }
        
        XCTAssertTrue(viewModel.isCompleted)
        XCTAssertNotNil(viewModel.resultType)
    }
    
    func testResultCalculationBalanced() async {
        let viewModel = ConstitutionTestViewModel()
        
        // To make it balanced, answer 'always' for balanced questions and 'never' for others
        for i in 0..<54 {
            let question = viewModel.questions[i]
            if question.constitutionType == .balanced {
                viewModel.selectOption(.always)
            } else {
                viewModel.selectOption(.never)
            }
            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4s
        }
        
        XCTAssertTrue(viewModel.isCompleted)
        XCTAssertEqual(viewModel.resultType, .balanced)
    }

    func testResultCalculationQiDeficiency() async {
        let viewModel = ConstitutionTestViewModel()
        
        // To make it qiDeficiency, answer 'always' for qiDeficiency questions and 'never' for others
        for i in 0..<54 {
            let question = viewModel.questions[i]
            if question.constitutionType == .qiDeficiency {
                viewModel.selectOption(.always)
            } else {
                viewModel.selectOption(.never)
            }
            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4s
        }
        
        XCTAssertTrue(viewModel.isCompleted)
        XCTAssertEqual(viewModel.resultType, .qiDeficiency)
    }
}
