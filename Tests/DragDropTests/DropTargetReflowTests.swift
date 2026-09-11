import XCTest
import UIKit
@testable import DragDrop

/// When a view is dragged out of a drop target, the views left behind should
/// close the gap it left rather than stranding a hole. The controller knows
/// which of its drop target's subviews it manages -- they are the ones carrying
/// a DragDropGesture -- and asks the datasource where each one belongs.
@MainActor
final class DraggableViewsTests: XCTestCase {

    func testDraggableViewsListsOnlyTheViewsTheControllerManages() {
        let controller = DragDropController()
        let target = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        controller.dropTargetView = target

        let label = UILabel()
        let first = UIView()
        let second = UIView()
        target.addSubview(label)
        target.addSubview(first)
        target.addSubview(second)

        controller.enableDragAction(for: first)
        controller.enableDragAction(for: second)

        XCTAssertEqual(controller.draggableViews, [first, second])
    }

    func testDraggableViewsKeepsSubviewOrder() {
        let controller = DragDropController()
        let target = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        controller.dropTargetView = target

        let views = (0..<4).map { _ in UIView() }
        for view in views {
            target.addSubview(view)
            controller.enableDragAction(for: view)
        }

        // Moving one to the front must be reflected: index means position in
        // the container, which is what a flow layout datasource keys off.
        target.bringSubviewToFront(views[0])

        XCTAssertEqual(controller.draggableViews, [views[1], views[2], views[3], views[0]])
    }

    func testDraggableViewsDropsAViewOnceDraggingIsDisabled() {
        let controller = DragDropController()
        let target = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        controller.dropTargetView = target

        let view = UIView()
        target.addSubview(view)
        controller.enableDragAction(for: view)
        controller.disableDragAction(for: view)

        XCTAssertTrue(controller.draggableViews.isEmpty)
    }

    func testDraggableViewsIsEmptyWithoutADropTarget() {
        let controller = DragDropController()
        let view = UIView()
        controller.enableDragAction(for: view)

        XCTAssertTrue(controller.draggableViews.isEmpty)
    }
}

// MARK: - Closing the gap

@MainActor
final class DropTargetGapClosingTests: XCTestCase {

    /// Both `dragDropDataSource` and `dropTargetView` are weak, and ARC will
    /// release either one whose last use is the assignment itself. Holding them
    /// here stands in for the view controller that owns them in a real app, so
    /// each test measures the re-flow rather than a collected object.
    private var dataSource: (any DragDropControllerDataSource)?
    private var target: UIView?

    /// A datasource that lays its views out in a single column of 50pt slots.
    private final class ColumnDataSource: DragDropControllerDataSource {
        var wasAsked = false

        func dragDropController(_ controller: DragDropController,
                                frameFor view: UIView,
                                in destination: DragDropController) -> CGRect { .zero }

        func dragDropController(_ controller: DragDropController,
                                frameFor view: UIView,
                                at index: Int) -> CGRect? {
            wasAsked = true
            return CGRect(x: 0, y: CGFloat(index) * 50, width: 100, height: 50)
        }
    }

    /// Implements only what the protocol requires, so the new method takes its
    /// default.
    private final class MinimalDataSource: DragDropControllerDataSource {
        func dragDropController(_ controller: DragDropController,
                                frameFor view: UIView,
                                in destination: DragDropController) -> CGRect { .zero }
    }

    private final class RefusingDataSource: DragDropControllerDataSource {
        func dragDropController(_ controller: DragDropController,
                                frameFor view: UIView,
                                in destination: DragDropController) -> CGRect { .zero }
        func dragDropController(_ controller: DragDropController,
                                frameFor view: UIView,
                                at index: Int) -> CGRect? { nil }
    }

    private func makeColumn(_ count: Int,
                            dataSource: any DragDropControllerDataSource) -> (DragDropController, UIView, [UIView]) {
        let controller = DragDropController()
        let target = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 500))

        self.target = target
        self.dataSource = dataSource
        controller.dropTargetView = target
        controller.dragDropDataSource = dataSource

        let views = (0..<count).map { index -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: CGFloat(index) * 50, width: 100, height: 50))
            target.addSubview(view)
            controller.enableDragAction(for: view)
            return view
        }

        return (controller, target, views)
    }

    func testRemainingViewsCloseTheGapLeftByTheViewThatWasRemoved() {
        let (controller, _, views) = makeColumn(4, dataSource: ColumnDataSource())

        // The second view is dragged away to some other drop target.
        views[1].removeFromSuperview()

        controller.closeGapInDropTarget(animated: false)

        XCTAssertEqual(views[0].frame, CGRect(x: 0, y: 0, width: 100, height: 50))
        XCTAssertEqual(views[2].frame, CGRect(x: 0, y: 50, width: 100, height: 50))
        XCTAssertEqual(views[3].frame, CGRect(x: 0, y: 100, width: 100, height: 50))
    }

    func testViewsTheControllerDoesNotManageAreLeftAlone() {
        let (controller, target, views) = makeColumn(2, dataSource: ColumnDataSource())

        let label = UILabel(frame: CGRect(x: 10, y: 400, width: 80, height: 20))
        target.insertSubview(label, at: 0)

        views[0].removeFromSuperview()
        controller.closeGapInDropTarget(animated: false)

        XCTAssertEqual(label.frame, CGRect(x: 10, y: 400, width: 80, height: 20))
        XCTAssertEqual(views[1].frame, CGRect(x: 0, y: 0, width: 100, height: 50))
    }

    /// The default implementation returns nil, so a datasource written against
    /// the old protocol keeps the layout it had.
    func testADataSourceThatDoesNotImplementTheMethodKeepsItsLayout() {
        let (controller, _, views) = makeColumn(3, dataSource: MinimalDataSource())

        views[0].removeFromSuperview()
        controller.closeGapInDropTarget(animated: false)

        XCTAssertEqual(views[1].frame, CGRect(x: 0, y: 50, width: 100, height: 50))
        XCTAssertEqual(views[2].frame, CGRect(x: 0, y: 100, width: 100, height: 50))
    }

    /// A nil for one view stops the re-flow rather than collapsing the rest on
    /// top of it.
    func testANilFrameLeavesEveryViewWhereItIs() {
        let (controller, _, views) = makeColumn(3, dataSource: RefusingDataSource())

        views[0].removeFromSuperview()
        controller.closeGapInDropTarget(animated: false)

        XCTAssertEqual(views[1].frame, CGRect(x: 0, y: 50, width: 100, height: 50))
        XCTAssertEqual(views[2].frame, CGRect(x: 0, y: 100, width: 100, height: 50))
    }

    func testNothingIsAskedWhenThereIsNoDropTarget() {
        let controller = DragDropController()
        let dataSource = ColumnDataSource()
        self.dataSource = dataSource
        controller.dragDropDataSource = dataSource

        controller.closeGapInDropTarget(animated: false)

        XCTAssertFalse(dataSource.wasAsked)
    }
}

// MARK: - Completing a drop

/// The tail of `endDrag`: the dragged view is handed to the destination, the
/// gesture goes with it, the delegate hears about it, and the source closes the
/// gap it was left with.
@MainActor
final class CompleteDropTests: XCTestCase {

    private final class ColumnDataSource: DragDropControllerDataSource {
        func dragDropController(_ controller: DragDropController,
                                frameFor view: UIView,
                                in destination: DragDropController) -> CGRect { .zero }

        func dragDropController(_ controller: DragDropController,
                                frameFor view: UIView,
                                at index: Int) -> CGRect? {
            CGRect(x: 0, y: CGFloat(index) * 50, width: 100, height: 50)
        }
    }

    private final class SpyDelegate: DragDropControllerDelegate {
        var moved: [(view: UIView, destination: DragDropController)] = []

        func dragDropController(_ controller: DragDropController,
                                didMove view: UIView,
                                to destination: DragDropController) {
            moved.append((view, destination))
        }
    }

    private var dataSource: ColumnDataSource!
    private var delegate: SpyDelegate!
    private var sourceTarget: UIView!
    private var destinationTarget: UIView!
    private var source: DragDropController!
    private var destination: DragDropController!
    private var views: [UIView] = []

    override func setUp() {
        super.setUp()

        dataSource = ColumnDataSource()
        delegate = SpyDelegate()

        sourceTarget = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 500))
        destinationTarget = UIView(frame: CGRect(x: 200, y: 0, width: 100, height: 500))

        source = DragDropController()
        source.dropTargetView = sourceTarget
        source.dragDropDataSource = dataSource
        source.dragDropDelegate = delegate

        destination = DragDropController()
        destination.dropTargetView = destinationTarget

        views = (0..<3).map { index -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: CGFloat(index) * 50, width: 100, height: 50))
            sourceTarget.addSubview(view)
            source.enableDragAction(for: view)
            return view
        }
    }

    func testTheViewsLeftBehindCloseTheGap() {
        source.completeDrop(of: views[0], into: destination,
                            frame: CGRect(x: 0, y: 0, width: 100, height: 50))

        XCTAssertEqual(views[1].frame, CGRect(x: 0, y: 0, width: 100, height: 50))
        XCTAssertEqual(views[2].frame, CGRect(x: 0, y: 50, width: 100, height: 50))
    }

    func testTheDroppedViewMovesIntoTheDestinationAtTheGivenFrame() {
        let frame = CGRect(x: 10, y: 20, width: 100, height: 50)

        source.completeDrop(of: views[0], into: destination, frame: frame)

        XCTAssertIdentical(views[0].superview, destinationTarget)
        XCTAssertEqual(views[0].frame, frame)
    }

    func testTheDestinationTakesOverTheDragGesture() {
        source.completeDrop(of: views[0], into: destination, frame: .zero)

        XCTAssertEqual(source.draggableViews, [views[1], views[2]])
        XCTAssertEqual(destination.draggableViews, [views[0]])
    }

    func testTheDelegateIsToldTheViewMoved() {
        source.completeDrop(of: views[0], into: destination, frame: .zero)

        XCTAssertEqual(delegate.moved.count, 1)
        XCTAssertIdentical(delegate.moved.first?.view, views[0])
        XCTAssertIdentical(delegate.moved.first?.destination, destination)
    }

    /// The delegate may rearrange the container itself, so it runs before the
    /// re-flow and the re-flow has the last word.
    func testTheGapIsClosedAfterTheDelegateHasRun() {
        final class MovingDelegate: DragDropControllerDelegate {
            var framesWhenCalled: [CGRect] = []
            var remaining: [UIView] = []

            func dragDropController(_ controller: DragDropController,
                                    didMove view: UIView,
                                    to destination: DragDropController) {
                framesWhenCalled = remaining.map(\.frame)
            }
        }

        let movingDelegate = MovingDelegate()
        movingDelegate.remaining = [views[1], views[2]]
        source.dragDropDelegate = movingDelegate

        source.completeDrop(of: views[0], into: destination, frame: .zero)

        XCTAssertEqual(movingDelegate.framesWhenCalled,
                       [CGRect(x: 0, y: 50, width: 100, height: 50),
                        CGRect(x: 0, y: 100, width: 100, height: 50)],
                       "the delegate should see the layout before the gap closes")
        XCTAssertEqual(views[1].frame, CGRect(x: 0, y: 0, width: 100, height: 50))
    }
}
