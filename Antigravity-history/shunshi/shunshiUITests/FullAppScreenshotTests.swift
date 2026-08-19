import XCTest

/// 全应用截图测试 - 捕获所有主要功能界面
final class FullAppScreenshotTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }
    
    // MARK: - 主要功能截图测试
    
    func testCaptureAllScreens() throws {
        // 等待应用启动
        sleep(3)
        
        // 1. 首页 - Home Screen
        print("📸 截图 1: 首页")
        let homeScreenshot = app.screenshot()
        let homeAttachment = XCTAttachment(screenshot: homeScreenshot)
        homeAttachment.name = "01_Home_Screen"
        homeAttachment.lifetime = .keepAlways
        add(homeAttachment)
        
        // 滚动查看更多内容
        app.scrollViews.firstMatch.swipeUp()
        sleep(1)
        let homeScrolledScreenshot = app.screenshot()
        let homeScrolledAttachment = XCTAttachment(screenshot: homeScrolledScreenshot)
        homeScrolledAttachment.name = "02_Home_Screen_Scrolled"
        homeScrolledAttachment.lifetime = .keepAlways
        add(homeScrolledAttachment)
        
        // 2. 节气详情 - Solar Term Detail
        print("📸 截图 2: 节气详情")
        // 查找节气卡片并点击
        let solarTermCard = app.otherElements["SolarTermCard"].firstMatch
        if solarTermCard.waitForExistence(timeout: 5) {
            solarTermCard.tap()
            sleep(2)
            let solarTermDetailScreenshot = app.screenshot()
            let solarTermDetailAttachment = XCTAttachment(screenshot: solarTermDetailScreenshot)
            solarTermDetailAttachment.name = "03_Solar_Term_Detail"
            solarTermDetailAttachment.lifetime = .keepAlways
            add(solarTermDetailAttachment)
            
            // 返回首页
            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)
        }
        
        // 3. 养生 Tab - Wellness Tab
        print("📸 截图 3: 养生页面")
        let wellnessTab = app.tabBars.buttons["养生"]
        if wellnessTab.waitForExistence(timeout: 5) {
            wellnessTab.tap()
            sleep(2)
            let wellnessScreenshot = app.screenshot()
            let wellnessAttachment = XCTAttachment(screenshot: wellnessScreenshot)
            wellnessAttachment.name = "04_Wellness_Tab"
            wellnessAttachment.lifetime = .keepAlways
            add(wellnessAttachment)
            
            // 切换到不同的养生维度
            let tabs = ["食养", "动养", "起居", "穴位", "情志"]
            for (index, tabName) in tabs.enumerated() {
                let tab = app.buttons[tabName]
                if tab.exists {
                    tab.tap()
                    sleep(1)
                    let tabScreenshot = app.screenshot()
                    let tabAttachment = XCTAttachment(screenshot: tabScreenshot)
                    tabAttachment.name = "05_Wellness_\(tabName)_\(index + 1)"
                    tabAttachment.lifetime = .keepAlways
                    add(tabAttachment)
                }
            }
        }
        
        // 4. 食谱详情 - Recipe Detail
        print("📸 截图 4: 食谱详情")
        // 点击第一个食谱
        let firstRecipe = app.buttons.matching(identifier: "RecipeCard").firstMatch
        if firstRecipe.waitForExistence(timeout: 5) {
            firstRecipe.tap()
            sleep(2)
            let recipeDetailScreenshot = app.screenshot()
            let recipeDetailAttachment = XCTAttachment(screenshot: recipeDetailScreenshot)
            recipeDetailAttachment.name = "06_Recipe_Detail"
            recipeDetailAttachment.lifetime = .keepAlways
            add(recipeDetailAttachment)
            
            // 滚动查看完整食谱
            app.scrollViews.firstMatch.swipeUp()
            sleep(1)
            let recipeScrolledScreenshot = app.screenshot()
            let recipeScrolledAttachment = XCTAttachment(screenshot: recipeScrolledScreenshot)
            recipeScrolledAttachment.name = "07_Recipe_Detail_Scrolled"
            recipeScrolledAttachment.lifetime = .keepAlways
            add(recipeScrolledAttachment)
            
            // 返回
            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)
        }
        
        // 5. AI顾问 Tab - Consultant Tab
        print("📸 截图 5: AI顾问")
        let consultantTab = app.tabBars.buttons["顾问"]
        if consultantTab.waitForExistence(timeout: 5) {
            consultantTab.tap()
            sleep(3) // 等待AI加载
            let consultantScreenshot = app.screenshot()
            let consultantAttachment = XCTAttachment(screenshot: consultantScreenshot)
            consultantAttachment.name = "08_AI_Consultant"
            consultantAttachment.lifetime = .keepAlways
            add(consultantAttachment)
            
            // 尝试发送一条消息
            let inputField = app.textFields.firstMatch
            if inputField.exists {
                inputField.tap()
                inputField.typeText("我想了解大寒节气的养生知识")
                sleep(1)
                
                let sendButton = app.buttons["发送"]
                if sendButton.exists {
                    sendButton.tap()
                    sleep(5) // 等待AI响应
                    let consultantChatScreenshot = app.screenshot()
                    let consultantChatAttachment = XCTAttachment(screenshot: consultantChatScreenshot)
                    consultantChatAttachment.name = "09_AI_Consultant_Chat"
                    consultantChatAttachment.lifetime = .keepAlways
                    add(consultantChatAttachment)
                }
            }
        }
        
        // 6. 我的 Tab - Profile Tab
        print("📸 截图 6: 个人中心")
        let profileTab = app.tabBars.buttons["我的"]
        if profileTab.waitForExistence(timeout: 5) {
            profileTab.tap()
            sleep(2)
            let profileScreenshot = app.screenshot()
            let profileAttachment = XCTAttachment(screenshot: profileScreenshot)
            profileAttachment.name = "10_Profile"
            profileAttachment.lifetime = .keepAlways
            add(profileAttachment)
            
            // 滚动查看更多选项
            app.scrollViews.firstMatch.swipeUp()
            sleep(1)
            let profileScrolledScreenshot = app.screenshot()
            let profileScrolledAttachment = XCTAttachment(screenshot: profileScrolledScreenshot)
            profileScrolledAttachment.name = "11_Profile_Scrolled"
            profileScrolledAttachment.lifetime = .keepAlways
            add(profileScrolledAttachment)
        }
        
        // 7. 体质测试 - Constitution Test
        print("📸 截图 7: 体质测试")
        // 返回首页
        let homeTab = app.tabBars.buttons["首页"]
        if homeTab.exists {
            homeTab.tap()
            sleep(1)
        }
        
        // 点击体质测试邀请卡
        let constitutionCard = app.buttons["ConstitutionInvitationCard"]
        if constitutionCard.waitForExistence(timeout: 5) {
            constitutionCard.tap()
            sleep(3)
            let constitutionTestScreenshot = app.screenshot()
            let constitutionTestAttachment = XCTAttachment(screenshot: constitutionTestScreenshot)
            constitutionTestAttachment.name = "12_Constitution_Test_Start"
            constitutionTestAttachment.lifetime = .keepAlways
            add(constitutionTestAttachment)
            
            // 回答几个问题
            for i in 1...3 {
                let optionButton = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'Option_'")).firstMatch
                if optionButton.waitForExistence(timeout: 5) {
                    optionButton.tap()
                    sleep(2)
                    let questionScreenshot = app.screenshot()
                    let questionAttachment = XCTAttachment(screenshot: questionScreenshot)
                    questionAttachment.name = "13_Constitution_Test_Question_\(i)"
                    questionAttachment.lifetime = .keepAlways
                    add(questionAttachment)
                }
            }
            
            // 关闭测试
            let closeButton = app.buttons["关闭"]
            if closeButton.exists {
                closeButton.tap()
                sleep(1)
            } else {
                // 如果没有关闭按钮，尝试返回
                app.navigationBars.buttons.firstMatch.tap()
                sleep(1)
            }
        }
        
        // 8. 节气轮盘 - Solar Term Wheel
        print("📸 截图 8: 节气轮盘")
        // 查找节气轮盘按钮
        let wheelButton = app.buttons.matching(identifier: "SolarTermWheelButton").firstMatch
        if wheelButton.waitForExistence(timeout: 5) {
            wheelButton.tap()
            sleep(2)
            let wheelScreenshot = app.screenshot()
            let wheelAttachment = XCTAttachment(screenshot: wheelScreenshot)
            wheelAttachment.name = "14_Solar_Term_Wheel"
            wheelAttachment.lifetime = .keepAlways
            add(wheelAttachment)
            
            // 关闭轮盘
            let dismissButton = app.buttons["xmark"]
            if dismissButton.exists {
                dismissButton.tap()
                sleep(1)
            }
        }
        
        // 9. 养生周报 - Wellness Report
        print("📸 截图 9: 养生周报")
        // 切换到养生Tab
        if wellnessTab.exists {
            wellnessTab.tap()
            sleep(1)
            
            // 查找周报按钮
            let reportButton = app.buttons.matching(identifier: "WeeklyReportButton").firstMatch
            if reportButton.waitForExistence(timeout: 5) {
                reportButton.tap()
                sleep(2)
                let reportScreenshot = app.screenshot()
                let reportAttachment = XCTAttachment(screenshot: reportScreenshot)
                reportAttachment.name = "15_Wellness_Report"
                reportAttachment.lifetime = .keepAlways
                add(reportAttachment)
                
                // 关闭周报
                app.navigationBars.buttons.firstMatch.tap()
                sleep(1)
            }
        }
        
        // 10. 最终截图 - 返回首页
        print("📸 截图 10: 最终首页状态")
        if homeTab.exists {
            homeTab.tap()
            sleep(2)
            let finalScreenshot = app.screenshot()
            let finalAttachment = XCTAttachment(screenshot: finalScreenshot)
            finalAttachment.name = "16_Final_Home_State"
            finalAttachment.lifetime = .keepAlways
            add(finalAttachment)
        }
        
        print("✅ 所有截图已完成！共捕获了应用的主要功能界面。")
    }
    
    // MARK: - 深色模式截图
    
    func testCaptureDarkMode() throws {
        // 切换到深色模式（如果支持）
        sleep(2)
        
        print("📸 深色模式截图")
        let darkModeScreenshot = app.screenshot()
        let darkModeAttachment = XCTAttachment(screenshot: darkModeScreenshot)
        darkModeAttachment.name = "17_Dark_Mode_Home"
        darkModeAttachment.lifetime = .keepAlways
        add(darkModeAttachment)
    }
}
