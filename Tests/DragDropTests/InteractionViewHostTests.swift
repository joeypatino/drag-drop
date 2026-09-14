import XCTest
import UIKit
@testable import DragDrop

/// Where the interaction view lives, and whether the two places that read a
/// window-space location inside it convert first.
///
/// Every host here starts 60pt below the window's top edge, the way a page
/// sheet does. At the window's origin the right and wrong answers coincide.
@MainActor
final class InteractionViewHostTests: XCTestCase {

    private final class HoverSpy: DragDropControllerDelegate {
        var hovers = 0

        func dragDropController(_ controller: DragDropController,
                                dragDidHover drag: DragAction,
                                from source: DragDropController) {
            hovers += 1
        }
    }

    private var window: UIWindow!
    private var dragged: UIView!
    private var spy: HoverSpy!

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        window.isHidden = false
        spy = HoverSpy()
    }

    override func tearDown() {
        dragged = nil
        spy = nil
        window = nil
        super.tearDown()
    }

    /// Gives the pickup animation's completion, which sends the first hover,
    /// time to run.
    private func settle() {
        let settled = expectation(description: "pickup animation completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { settled.fulfill() }
        wait(for: [settled], timeout: 2)
    }

    private func makeOffsetInteractionView() -> DragInteractionView {
        let host = UIView(frame: CGRect(x: 0, y: 60, width: 400, height: 740))
        window.addSubview(host)
        let interaction = DragInteractionView(frame: host.bounds)
        host.addSubview(interaction)

        // `dragMoved` locates the drag representation with `hitTest`, relying
        // on the handler the controller's own `dragInteractionView` always
        // installs to return the last subview unconditionally -- the drag
        // representation is not necessarily under the point that is moving
        // it there. A view built directly, as here, has none by default, so
        // one is added to match production. See
        // `DragActionTests.testInteractionViewConsultsHitTestHandlerFirst`.
        interaction.hitTestHandler = { [weak interaction] _, _ in interaction?.subviews.last }

        return interaction
    }

    /// Whatever is presented, and whatever the root view controller is, the
    /// drag is hosted by the window it is happening in.
    func testTheInteractionViewCoversTheWindowTheDragStartedIn() {
        let sheet = UIView(frame: CGRect(x: 0, y: 60, width: 400, height: 740))
        window.addSubview(sheet)

        let source = DragDropController()
        source.dropTargetView = sheet
        dragged = UIView(frame: CGRect(x: 20, y: 20, width: 50, height: 50))
        sheet.addSubview(dragged)
        source.enableDragAction(for: dragged)

        let drag = DragAction(view: dragged)
        drag.currentLocation = CGPoint(x: 45, y: 105)
        source.startDrag(drag)

        XCTAssertTrue(source._dragInteractionView?.superview === window)
        XCTAssertEqual(source._dragInteractionView?.frame, window.bounds)
        XCTAssertEqual(dragged.convert(dragged.bounds, to: nil),
                       CGRect(x: 20, y: 80, width: 50, height: 50),
                       "picking the view up should not move it on screen")

        // Lets the pickup animation's completion run and release `source`
        // before teardown. Left dangling, the completion fires later, kept
        // alive by its own closure, and -- because `source` is still on the
        // process-wide DragDropControllerRegistry -- can hand a stray hover to
        // whatever unrelated test happens to be waiting at the time.
        settle()
    }

    /// The window point (200, 490) is inside the target. Compared, unconverted,
    /// against the target's rect in the offset interaction view -- y 340 to
    /// 440 -- it is not.
    func testADropTargetUnderTheFingerIsFoundWhenTheInteractionViewIsOffset() {
        let interaction = makeOffsetInteractionView()

        let targetView = UIView(frame: CGRect(x: 0, y: 400, width: 400, height: 100))
        window.addSubview(targetView)
        let destination = DragDropController()
        destination.dropTargetView = targetView
        destination.dragDropDelegate = spy

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.addSubview(container)
        let source = DragDropController()
        source.dropTargetView = container
        source._dragInteractionView = interaction

        dragged = UIView(frame: CGRect(x: 10, y: 10, width: 50, height: 50))
        container.addSubview(dragged)
        source.enableDragAction(for: dragged)

        let drag = DragAction(view: dragged)
        drag.currentLocation = CGPoint(x: 200, y: 490)
        source.startDrag(drag)
        settle()

        XCTAssertEqual(spy.hovers, 1)
    }

    /// Touched at its centre and moved to (200, 300), the view's centre should
    /// be at (200, 300) on screen, not 60pt below it.
    func testAMovedViewStaysUnderTheFingerWhenTheInteractionViewIsOffset() {
        let interaction = makeOffsetInteractionView()

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        window.insertSubview(container, at: 0)
        let source = DragDropController()
        source.dropTargetView = container
        source._dragInteractionView = interaction

        dragged = UIView(frame: CGRect(x: 100, y: 100, width: 50, height: 50))
        container.addSubview(dragged)
        source.enableDragAction(for: dragged)

        let start = DragAction(view: dragged)
        start.currentLocation = CGPoint(x: 125, y: 125)
        source.startDrag(start)

        let move = DragAction(view: dragged)
        move.firstTouchOffset = CGPoint(x: 25, y: 25)
        move.currentLocation = CGPoint(x: 200, y: 300)
        source.dragMoved(move)

        let onScreen = dragged.convert(dragged.bounds, to: nil)
        XCTAssertEqual(CGPoint(x: onScreen.midX, y: onScreen.midY), CGPoint(x: 200, y: 300))

        // See the note in testTheInteractionViewCoversTheWindowTheDragStartedIn:
        // without this, `source`'s pending pickup-animation completion outlives
        // the test and can hand a stray hover to whichever test is next.
        settle()
    }
}
