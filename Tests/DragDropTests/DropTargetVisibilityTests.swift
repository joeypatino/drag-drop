import XCTest
import UIKit
@testable import DragDrop

/// A controller registers itself for the life of the process, so the set of
/// candidates for a drop includes every controller still alive -- including
/// those belonging to a screen that has been navigated away from. Only the
/// ones actually on screen can receive a drop.
@MainActor
final class DropTargetVisibilityTests: XCTestCase {

    private final class MoveSpy: DragDropControllerDelegate {
        var log: [String] = []

        func dragDropController(_ controller: DragDropController,
                                didMove view: UIView,
                                to destination: DragDropController) {
            log.append("didMove")
        }

        func dragDropController(_ controller: DragDropController,
                                didReceive view: UIView,
                                from source: DragDropController) {
            log.append("didReceive")
        }
    }

    private var window: UIWindow!

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        window.isHidden = false
    }

    override func tearDown() {
        window = nil
        super.tearDown()
    }

    /// A view controller pushed past is retained by the navigation stack, so
    /// its drop target stays registered with a frame that still overlaps.
    /// Converting a rect between two hierarchies when one has no window is
    /// undefined, and it answered a rect that contained the point -- so the
    /// drop could be handed to a table nobody could see.
    func testATargetThatIsNotInAWindowIsNeverChosen() {
        let onScreen = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        window.addSubview(onScreen)

        // Same geometry, no window: the screen that was navigated away from.
        let offScreen = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let detachedHost = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        detachedHost.addSubview(offScreen)

        let visible = DragDropController()
        visible.dropTargetView = onScreen

        let gone = DragDropController()
        gone.dropTargetView = offScreen

        let source = DragDropController()

        // `gone` is deeper in its hierarchy, so depth would have preferred it.
        XCTAssertIdentical(source.controllerForDrop(at: CGPoint(x: 50, y: 50),
                                                    in: window,
                                                    among: [visible, gone]),
                           visible)

        XCTAssertNil(source.controllerForDrop(at: CGPoint(x: 50, y: 50),
                                              in: window,
                                              among: [gone]))
    }

    func testAHiddenTargetIsNeverChosen() {
        let hiddenView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        hiddenView.isHidden = true
        window.addSubview(hiddenView)

        let hidden = DragDropController()
        hidden.dropTargetView = hiddenView

        let source = DragDropController()

        XCTAssertNil(source.controllerForDrop(at: CGPoint(x: 50, y: 50),
                                              in: window,
                                              among: [hidden]))
    }

    /// `dropTargetView` is weak. With nowhere to put the view, the drop used
    /// to tell both delegates it had succeeded and leave the view in the
    /// interaction view, which is torn down moments later.
    func testADropIntoADestinationWithNoTargetViewReportsNothing() {
        let spy = MoveSpy()

        let sourceTarget = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        window.addSubview(sourceTarget)

        let source = DragDropController()
        source.dropTargetView = sourceTarget
        source.dragDropDelegate = spy

        let destination = DragDropController()
        destination.dragDropDelegate = spy
        XCTAssertNil(destination.dropTargetView)

        let view = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        sourceTarget.addSubview(view)

        source.completeDrop(of: view, into: destination, frame: .zero)

        XCTAssertEqual(spy.log, [], "a drop that had nowhere to land reported success")
        XCTAssertIdentical(view.superview, sourceTarget)
    }
}
