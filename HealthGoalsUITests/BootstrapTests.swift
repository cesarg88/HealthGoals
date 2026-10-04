import XCTest
import UIKit

final class BootstrapTests: XCTestCase {
    @MainActor
    func testLaunch() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(app.staticTexts["bootstrap.title"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testContentRemainsVisibleWhenRotating() {
        let device = XCUIDevice.shared
        defer { device.orientation = .portrait }
        device.orientation = .portrait
        let app = XCUIApplication()
        app.launch()
        let title = app.staticTexts["bootstrap.title"]
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
