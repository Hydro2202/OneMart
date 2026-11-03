import XCTest

final class OneMartUITests: XCTestCase {
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.exists)
    }
}
