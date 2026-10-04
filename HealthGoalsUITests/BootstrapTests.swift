import UIKit
import XCTest

final class BootstrapTests: XCTestCase {
    @MainActor
    func testLaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding.progress", ""]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: Constants.waitTimeout))
        XCTAssertTrue(app.staticTexts["onboarding.intention.title"].waitForExistence(timeout: Constants.waitTimeout))
    }

    @MainActor
    func testIntentionNavigationAndBack() {
        let app = XCUIApplication()
        app.launchArguments = ["-onboarding.progress", ""]
        app.launch()
        let continueButton = app.buttons["onboarding.continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: Constants.waitTimeout))
        XCTAssertFalse(continueButton.isEnabled)
        capture(app)
        app.buttons["onboarding.intention.walking"].tap()
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()
        XCTAssertTrue(app.staticTexts["onboarding.health.title"].waitForExistence(timeout: Constants.waitTimeout))
        capture(app)
        app.buttons["onboarding.back"].tap()
        XCTAssertTrue(continueButton.waitForExistence(timeout: Constants.waitTimeout))
        XCTAssertTrue(continueButton.isEnabled)
        XCTAssertTrue(app.buttons["onboarding.intention.walking"].isSelected)
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
        XCTAssertTrue(title.waitForExistence(timeout: Constants.waitTimeout))

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
            XCTAssertEqual(
                XCTWaiter.wait(for: [expectation], timeout: Constants.waitTimeout),
                .completed,
                "Content must remain visible after rotation to \(orientation.rawValue)"
            )
            XCTAssertEqual(app.state, .runningForeground)
        }
    }
}

private extension BootstrapTests {
    enum Constants {
        static let waitTimeout: TimeInterval = 10
    }

    @MainActor
    func capture(_ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
