import XCTest

/// Locating draggable views by accessibility identifier rather than by sampling
/// pixels or by `boundBy:`.
///
/// The pixel probes these replace were brittle twice over: they hard-coded a
/// colour, so any restyle broke them, and they hard-coded a slot's coordinates,
/// so a drag that missed a 40pt square by one pixel row read as a logic failure.
/// `element(boundBy:)` is no better -- it orders by the accessibility
/// hierarchy, not by what is where on screen.
extension XCTestCase {

    /// Launches the app straight onto one demo, skipping the index tap.
    @MainActor
    func launchDemo(_ segueIdentifier: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-demo", segueIdentifier]
        app.launch()
        return app
    }

    /// A container addressed by identifier, whatever element type it is -- a
    /// panel is an `other`, the queue is a `table`, the grids are
    /// `collectionView`s, and a caller should not have to care which.
    @MainActor
    func container(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// The identifiers of the draggable views inside `container`, in visual
    /// order -- top to bottom, then left to right.
    ///
    /// Frame containment rather than the accessibility tree, because the
    /// question a gap-closing test asks is "what is on screen, and where".
    @MainActor
    func identifiers(withPrefix prefix: String,
                     inside container: XCUIElement,
                     of app: XCUIApplication) -> [String] {
        let bounds = container.frame
        return app.descendants(matching: .any)
            .allElementsBoundByAccessibilityElement
            .filter { $0.exists && $0.identifier.hasPrefix(prefix) }
            // On screen, and hittable. A row scrolled out of a table still
            // exists and still reports a frame, but that frame cannot be
            // pressed -- treating it as "present" makes a drag land on
            // whatever happens to be at those coordinates instead.
            .filter { $0.isHittable && !$0.frame.isEmpty }
            .filter { bounds.contains(CGPoint(x: $0.frame.midX, y: $0.frame.midY)) }
            .sorted {
                $0.frame.minY == $1.frame.minY
                    ? $0.frame.minX < $1.frame.minX
                    : $0.frame.minY < $1.frame.minY
            }
            .map(\.identifier)
    }

    /// The long form of the drag. The press must exceed the library's 0.12s
    /// pickup delay or `DragDropGesture` goes straight to `.failed`; the short
    /// `press(forDuration:thenDragTo:)` can register as a scroll inside a
    /// scroll view, which makes assertions pass for the wrong reason.
    @MainActor
    func drag(_ source: XCUIElement, onto destination: XCUIElement) {
        source.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.5,
                   thenDragTo: destination.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)),
                   withVelocity: .slow,
                   thenHoldForDuration: 0.8)
    }

    @MainActor
    func attachScreenshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
