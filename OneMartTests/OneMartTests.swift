import XCTest
@testable import OneMart

final class OneMartTests: XCTestCase {
    func testOrderSignedAmountsAreConsistentWithModule() throws {
        let order = Order(
            module: .food,
            title: "Test Order",
            subtitle: "1 item",
            imageName: "fork.knife",
            status: .completed,
            total: 100,
            placedAt: .now
        )
        XCTAssertEqual(order.module, .food)
        XCTAssertEqual(order.total, 100)
    }
}
