import XCTest

/// Drives one deliberate drag for the animation-trace harness: the tallest
/// visible card onto the shortest, so any resize is as large as the grid can
/// make it. Paced slowly and held at the end so the recording has unambiguous
/// before/during/after stretches.
final class AnimationTraceDrag: XCTestCase {

    @MainActor
    func testDragTallCardOntoShortSlot() {
        let app = XCUIApplication()
        app.launchArguments += ["-demo", "NormalCollectionViewController", "-animation-trace"]
        app.launch()

        let grid = container("moodboard", in: app)
        XCTAssertTrue(grid.waitForExistence(timeout: 5))

        let cards = identifiers(withPrefix: "swatch-", inside: grid, of: app)
        let heights = cards.map { app.otherElements[$0].frame.height }
        let tallest = zip(cards, heights).max { $0.1 < $1.1 }!
        let shortest = zip(cards, heights).min { $0.1 < $1.1 }!
        print("TRACE dragging \(tallest.0) (\(tallest.1)pt) onto \(shortest.0) (\(shortest.1)pt)")
        XCTAssertGreaterThan(tallest.1 - shortest.1, 40, "need a real size difference to observe")

        // Still for a beat first, so the recording has a clean baseline.
        Thread.sleep(forTimeInterval: 1.0)

        app.otherElements[tallest.0].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.6,
                   thenDragTo: app.otherElements[shortest.0].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)),
                   withVelocity: .slow,
                   thenHoldForDuration: 2.0)

        Thread.sleep(forTimeInterval: 1.5)
    }
}
