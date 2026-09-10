import XCTest
@testable import DragDrop

final class IndexPathAdditionsTests: XCTestCase {
    private func ip(_ row: Int, _ section: Int = 0) -> IndexPath {
        IndexPath(row: row, section: section)
    }

    func testIncrementingAndDecrementingRowStayInSection() {
        XCTAssertEqual(ip(3, 2).incrementingRow, ip(4, 2))
        XCTAssertEqual(ip(3, 2).decrementingRow, ip(2, 2))
    }

    func testIsBeforeAndIsAfterWithinASection() {
        XCTAssertTrue(ip(1).isBefore(ip(2)))
        XCTAssertFalse(ip(2).isBefore(ip(1)))
        XCTAssertTrue(ip(2).isAfter(ip(1)))
        XCTAssertFalse(ip(1).isAfter(ip(2)))
    }

    func testIsBeforeAndIsAfterAcrossSections() {
        XCTAssertTrue(ip(9, 0).isBefore(ip(0, 1)))
        XCTAssertTrue(ip(0, 1).isAfter(ip(9, 0)))
    }

    func testIsSame() {
        XCTAssertTrue(ip(4, 1).isSame(as: ip(4, 1)))
        XCTAssertFalse(ip(4, 1).isSame(as: ip(4, 2)))
    }

    func testIsBetweenIsExclusiveAndOrderSensitive() {
        // Matches the Objective-C: strictly greater than the first argument
        // and strictly less than the second.
        XCTAssertTrue(ip(2).isBetween(ip(1), and: ip(3)))
        XCTAssertFalse(ip(2).isBetween(ip(3), and: ip(1)))
        XCTAssertFalse(ip(1).isBetween(ip(1), and: ip(3)))
        XCTAssertFalse(ip(3).isBetween(ip(1), and: ip(3)))
    }
}
