import XCTest
@testable import shunshi

@MainActor
final class AIConstitutionTestViewModelTests: XCTestCase {
    
    func testFullFlow() async {
        let viewModel = AIConstitutionTestViewModel()
        
        // Start the test
        await viewModel.startTest()
        
        // Initial greeting delay is 0.8s
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Verify started
        XCTAssertFalse(viewModel.messages.isEmpty)
        XCTAssertNotNil(viewModel.currentQuestion)
        
        // Iterate through all questions
        var answeredCount = 0
        let maxQuestions = 100 // Safety break
        
        while let _ = viewModel.currentQuestion {
            guard answeredCount < maxQuestions else {
                XCTFail("Exceeded max questions limit")
                return
            }
            
            // Simulate answering "Never" (value: 1)
            // This path avoids LLM call
            await viewModel.processUserResponse(text: "从不", value: 1)
            
            answeredCount += 1
            
            // Wait for the "conversational glue" delay (0.6s) + small buffer
            // Only happens if there is a next question
            if viewModel.currentQuestion != nil {
                try? await Task.sleep(nanoseconds: 800_000_000)
            }
        }
        
        // After loop finishes, finishTest should have been triggered
        // finishTest has a 1.0s delay
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Verify completion
        XCTAssertTrue(viewModel.showResult, "showResult should be true")
        XCTAssertNotNil(viewModel.assessmentResult, "assessmentResult should be populated")
        XCTAssertEqual(viewModel.progress, 1.0, accuracy: 0.1)
        
        // Additional check: Ensure invoking processUserResponse again doesn't crash or change state
        let resultBefore = viewModel.assessmentResult
        await viewModel.processUserResponse(text: "Extra input", value: 1)
        XCTAssertEqual(viewModel.assessmentResult?.testDate, resultBefore?.testDate)
    }
}
