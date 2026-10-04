import XCTest
import UIKit

final class BootstrapTests: XCTestCase {
    @MainActor
    func testLaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding.progress", ""]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(app.staticTexts["onboarding.intention.title"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testIntentionNavigationAndBack() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding.progress", ""]
        app.launch()
        let continueButton = app.buttons["onboarding.continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 10))
        XCTAssertFalse(continueButton.isEnabled)
        capture(app)
        app.buttons["onboarding.intention.walking"].tap()
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()
        XCTAssertTrue(app.staticTexts["onboarding.health.title"].waitForExistence(timeout: 10))
        capture(app)
        app.buttons["onboarding.back"].tap()
        XCTAssertTrue(continueButton.waitForExistence(timeout: 10))
        XCTAssertTrue(continueButton.isEnabled)
        XCTAssertTrue(app.buttons["onboarding.intention.walking"].isSelected)
    }

    @MainActor
    private func capture(_ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testContentRemainsVisibleWhenRotating() {
        let device = XCUIDevice.shared
        defer { device.orientation = .portrait }
        device.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding.progress", ""]
        app.launch()
        let title = app.staticTexts["onboarding.intention.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))

        // Face ID iPhones do not rotate upside down; iPad covers this orientation.
        var orientations: [UIDeviceOrientation] = [.portrait, .landscapeLeft, .landscapeRight]
        if UIDevice.current.userInterfaceIdiom == .pad {
            orientations.append(.portraitUpsideDown)
        }
        for orientation in orientations {
            device.orientation = orientation
            let window = app.windows.firstMatch
            let landscape = orientation.isLandscape
            let adapted = NSPredicate { _, _ in
                let frame = window.frame
                return frame.width > 0 && frame.height > 0
                    && (landscape ? frame.width > frame.height : frame.height > frame.width)
                    && title.exists && title.isHittable
                    && frame.contains(title.frame)
            }
            let expectation = XCTNSPredicateExpectation(predicate: adapted, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 10), .completed,
                           "Content must remain visible after rotation to \(orientation.rawValue)")
            XCTAssertEqual(app.state, .runningForeground)
        }
    }
}
