import XCTest
import UIKit
@testable import DragDrop

@MainActor
final class DragDropControllerRegistryTests: XCTestCase {
    func testControllersRegisterThemselvesOnInit() {
        let before = DragDropControllerRegistry.shared.allControllers.count
        let controller = DragDropController()

        let all = DragDropControllerRegistry.shared.allControllers
        XCTAssertEqual(all.count, before + 1)
        XCTAssertTrue(all.contains { $0 === controller })
    }

    /// Regression test for the unsafe-unretained CFArray in the Objective-C
    /// original, which left dangling pointers behind.
    func testReleasedControllersAreRemovedFromTheRegistry() {
        let before = DragDropControllerRegistry.shared.allControllers.count

        do {
            let controller = DragDropController()
            XCTAssertEqual(DragDropControllerRegistry.shared.allControllers.count, before + 1)
            _ = controller
        }

        XCTAssertEqual(DragDropControllerRegistry.shared.allControllers.count, before)
    }
}
