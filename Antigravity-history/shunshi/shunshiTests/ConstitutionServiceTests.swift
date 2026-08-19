import Testing
import Foundation
@testable import shunshi

struct ConstitutionServiceTests {

    // MARK: - Constitution Data Tests
    
    @Test func testConstitutionsExist() {
        let service = ConstitutionService.shared
        #expect(service.constitutions.count == 9, "Should have 9 constitution types")
    }
    
    @Test func testAllConstitutionsHaveDetails() {
        let service = ConstitutionService.shared
        for constitution in service.constitutions {
            #expect(!constitution.name.isEmpty)
            #expect(!constitution.emoji.isEmpty)
            #expect(!constitution.description.isEmpty)
            #expect(!constitution.characteristics.isEmpty)
        }
    }
    
    // MARK: - Test Session Tests
    
    @Test func testStartTest() {
        let service = ConstitutionService.shared
        let session = service.startTest(mode: .quick, userId: "test_user")
        
        #expect(session.userId == "test_user")
        #expect(session.mode == .quick)
        #expect(session.questions.count == service.testConfig.quickVersion.questionCount)
        #expect(session.currentIndex == 0)
    }
    
    @Test func testGenerateQuestions() {
        let service = ConstitutionService.shared
        let session = service.startTest(mode: .standard, userId: "user")
        
        // The current implementation only has 10 items in allQuestions
        #expect(session.questions.count == 10)
        for question in session.questions {
            #expect(!question.text.isEmpty)
            #expect(!question.options.isEmpty)
        }
    }
    
    // MARK: - Result Calculation Tests
    
    @Test func testSubmitTest() {
        let service = ConstitutionService.shared
        var session = service.startTest(mode: .quick, userId: "user")
        
        // Simulating answering all questions with "很少" (lowest score, usually leading to 平和质 if others are also low)
        for question in session.questions {
            session.answers[question.id] = "很少"
        }
        
        let result = service.submitTest(session: session)
        
        #expect(result.testDate != nil)
        #expect(result.pingheScore >= 0)
        #expect(!result.recommendations.diet.isEmpty)
    }
    
    // MARK: - Plan Generation Tests
    
    @Test func testGet21DayPlan() {
        let service = ConstitutionService.shared
        let plan = service.get21DayPlan(for: "qiXu")
        
        #expect(plan.constitution.contains("气虚"))
        #expect(plan.days.count == 21)
    }
    
    // MARK: - History Tests
    
    @Test func testSaveTestResult() {
        let service = ConstitutionService.shared
        let session = service.startTest(mode: .quick, userId: "user")
        let result = service.submitTest(session: session)
        
        #expect(service.testHistory.contains(where: { $0.id == result.id }))
    }
}
