import XCTest
import UIKit
@testable import DragDrop

/// The frame a drop animates to is assigned to the dragged view, which lives
/// in the interaction view for the length of the drag. So it has to be stated
/// in the interaction view's coordinates -- the same space the
/// return-to-source branch converts into. A window-space rect is only the
/// same thing while the interaction view sits at the window's origin, which
/// is not true of a host that is inset or presented.
@MainActor
final class DropFrameCoordinateSpaceTests: XCTestCase {

    /// The one datasource method with no default: where the view lands, in
    /// the destination's own coordinates.
    private final class Placement: DragDropControllerDataSource {
        static let frame = CGRect(x: 10, y: 20, width: 50, height: 50)

        func dragDropController(_ controller: DragDropController,
                                frameFor view: UIView,
                                in destination: DragDropController) -> CGRect {
            Self.frame
        }
    }

    private final class EndSpy: DragDropControllerDelegate {
        var frameWhenEnding: CGRect?

        func dragDropController(_ controller: DragDropController,
                                willEndDrag drag: DragAction,
                                animated: Bool) {
            frameWhenEnding = drag.view?.frame
        }
    }

    private var window: UIWindow!
    private var dragged: UIView!

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 600, height: 600))
        window.isHidden = false
    }

    override func tearDown() {
        dragged = nil
        window = nil
        super.tearDown()
    }

    func testTheDropFrameIsStatedInTheInteractionViewsSpace() {
        // A host that does not start at the window's origin -- an inset or
        // presented container. This is the only arrangement in which the two
        // candidate spaces differ at all.
        let host = UIView(frame: CGRect(x: 40, y: 70, width: 500, height: 500))
        window.addSubview(host)

        let interaction = DragInteractionView(frame: host.bounds)
        host.addSubview(interaction)

        // Small and far from the drop point, so the lookup cannot pick it.
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.addSubview(container)

        let source = DragDropController()
        source.dropTargetView = container
        let spy = EndSpy()
        source.dragDropDelegate = spy
        source._dragInteractionView = interaction

        let destinationTarget = UIView(frame: CGRect(x: 300, y: 200, width: 200, height: 200))
        window.addSubview(destinationTarget)

        let destination = DragDropController()
        destination.dropTargetView = destinationTarget
        let placement = Placement()
        destination.dragDropDataSource = placement

        dragged = UIView(frame: CGRect(x: 10, y: 10, width: 50, height: 50))
        container.addSubview(dragged)
        source.enableDragAction(for: dragged)

        let drag = DragAction(view: dragged)
        drag.currentLocation = CGPoint(x: 350, y: 250)

        source.startDrag(drag)
        source.endDrag(drag)

        let inInteractionSpace = destinationTarget.convert(Placement.frame, to: interaction)
        let inWindowSpace = destinationTarget.convert(Placement.frame, to: nil)

        // Guards the test itself: if these ever coincide it proves nothing.
        XCTAssertNotEqual(inInteractionSpace, inWindowSpace)
        XCTAssertEqual(spy.frameWhenEnding, inInteractionSpace)
    }
}
