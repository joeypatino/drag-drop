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
    ///
    /// The query is narrowed twice over, because this is the most expensive
    /// thing the suite does and `waitFor` runs it in a loop. Every property
    /// read on an element makes the runner wait for the app to be idle and
    /// then snapshot it, so the cost is per element examined -- and matching
    /// `.any` examined every element in the app to keep a handful. Asking the
    /// `other` elements for an identifier prefix pushes both filters into the
    /// one query the runner already has to run.
    @MainActor
    func identifiers(withPrefix prefix: String,
                     inside container: XCUIElement,
                     of app: XCUIApplication) -> [String] {
        let bounds = container.frame
        let matching = app.otherElements
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))

        return matching.allElementsBoundByAccessibilityElement
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

    /// The long form of the drag. The short `press(forDuration:thenDragTo:)`
    /// can register as a scroll inside a scroll view, which makes assertions
    /// pass for the wrong reason.
    ///
    /// Both durations are the smallest that clear what they are waiting for,
    /// with room to spare -- a drag happens dozens of times in a suite run, so
    /// a second of slack here is a minute across the whole thing:
    ///
    /// * the press must exceed the library's 0.12s pickup delay, or
    ///   `DragDropGesture` goes straight to `.failed`;
    /// * the hold must outlast the destination's 0.3s hover animation, so the
    ///   release lands on a settled layout rather than a moving one.
    ///
    /// The velocity is the same trade in reverse. The runner synthesises move
    /// events at a fixed rate, so velocity decides how many land along the way,
    /// and the library needs enough of them to enter a target and open its
    /// vacancy. `.slow` spent about a second crossing a screen to deliver far
    /// more than the one entry and one settle that needs.
    ///
    /// All three were run over the whole suite. `.default` took 14s off it;
    /// `.fast` gave none of that back and cost 4s, with the drags that cross
    /// between two panels the worst of it -- past some point the drag outruns
    /// the previews it is supposed to trigger, and the `waitFor` after it spins
    /// for longer than the drag ever saved. So `.default`, measured rather than
    /// assumed, and there is nothing further up this axis worth having.
    @MainActor
    func drag(_ source: XCUIElement, onto destination: XCUIElement) {
        source.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.25,
                   thenDragTo: destination.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)),
                   withVelocity: .default,
                   thenHoldForDuration: 0.4)
    }

    /// Waits until `container` holds exactly `expected` matching views.
    ///
    /// A drop is followed by two animations -- the drop itself and the source's
    /// gap close -- and a second drag started before they settle reads a stale
    /// frame and lands somewhere else. Waiting on the count rather than on a
    /// fixed sleep keeps that honest.
    @MainActor
    @discardableResult
    func waitFor(_ prefix: String,
                 inside container: XCUIElement,
                 of app: XCUIApplication,
                 toCount expected: Int,
                 timeout: TimeInterval = 5,
                 file: StaticString = #filePath,
                 line: UInt = #line) -> [String] {

        let deadline = Date().addingTimeInterval(timeout)
        var found = identifiers(withPrefix: prefix, inside: container, of: app)
        while found.count != expected, Date() < deadline {
            found = identifiers(withPrefix: prefix, inside: container, of: app)
        }
        XCTAssertEqual(found.count, expected,
                       "timed out waiting for \(expected) \"\(prefix)\" views, saw \(found)",
                       file: file, line: line)
        return found
    }

    @MainActor
    func attachScreenshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
