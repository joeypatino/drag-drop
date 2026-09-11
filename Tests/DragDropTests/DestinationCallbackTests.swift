import XCTest
import UIKit
@testable import DragDrop

/// The library used to talk only to the controller a drag came *from*. A
/// controller being dragged over, or dropped into, heard nothing — which left
/// a drop target unable to react to anything it did not itself start.
@MainActor
final class DestinationCallbackTests: XCTestCase {

    private final class SpyDelegate: DragDropControllerDelegate {
        var received: [(view: UIView, source: DragDropController)] = []

        func dragDropController(_ controller: DragDropController,
                                didReceive view: UIView,
                                from source: DragDropController) {
            received.append((view, source))
        }
    }

    private final class StubDataSource: DragDropControllerDataSource {
        func dragDropController(_ controller: DragDropController,
                                frameFor view: UIView,
                                in destination: DragDropController) -> CGRect { .zero }
    }

    private final class NamedDataSource: DragDropControllerDataSource {
        let answer: CGRect
        init(_ answer: CGRect) { self.answer = answer }

        func dragDropController(_ controller: DragDropController,
                                frameFor view: UIView,
                                in destination: DragDropController) -> CGRect { answer }
    }

    private final class OrderingDelegate: DragDropControllerDelegate {
        var onMove: (() -> Void)?
        var onReceive: (() -> Void)?

        func dragDropController(_ controller: DragDropController,
                                didMove view: UIView,
                                to destination: DragDropController) { onMove?() }

        func dragDropController(_ controller: DragDropController,
                                didReceive view: UIView,
                                from source: DragDropController) { onReceive?() }
    }

    /// Everything the controller holds weakly, kept alive here the way a view
    /// controller would keep it in a real app.
    private var sourceDelegate: SpyDelegate!
    private var destinationDelegate: SpyDelegate!
    private var dataSource: StubDataSource!
    private var extraDataSource: (any DragDropControllerDataSource)?
    private var extraDelegates: [any DragDropControllerDelegate] = []
    private var sourceTarget: UIView!
    private var destinationTarget: UIView!
    private var source: DragDropController!
    private var destination: DragDropController!

    private func makeControllers() {
        sourceDelegate = SpyDelegate()
        destinationDelegate = SpyDelegate()
        dataSource = StubDataSource()

        sourceTarget = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        destinationTarget = UIView(frame: CGRect(x: 200, y: 0, width: 100, height: 100))

        source = DragDropController()
        source.dropTargetView = sourceTarget
        source.dragDropDelegate = sourceDelegate
        source.dragDropDataSource = dataSource

        destination = DragDropController()
        destination.dropTargetView = destinationTarget
        destination.dragDropDelegate = destinationDelegate
    }

    func testTheDestinationIsToldItReceivedTheView() {
        makeControllers()
        let view = UIView()
        sourceTarget.addSubview(view)

        source.completeDrop(of: view, into: destination, frame: .zero)

        XCTAssertEqual(destinationDelegate.received.count, 1)
        XCTAssertIdentical(destinationDelegate.received.first?.view, view)
        XCTAssertIdentical(destinationDelegate.received.first?.source, source)
    }

    /// The source still hears didMove, and hears it first, so a source that
    /// removes its own row does so before the destination inserts one.
    func testTheSourceStillHearsDidMoveAndHearsItFirst() {
        makeControllers()

        var order: [String] = []
        let sourceOrdering = OrderingDelegate()
        let destinationOrdering = OrderingDelegate()
        sourceOrdering.onMove = { order.append("didMove") }
        destinationOrdering.onReceive = { order.append("didReceive") }
        extraDelegates = [sourceOrdering, destinationOrdering]

        source.dragDropDelegate = sourceOrdering
        destination.dragDropDelegate = destinationOrdering

        let view = UIView()
        sourceTarget.addSubview(view)
        source.completeDrop(of: view, into: destination, frame: .zero)

        XCTAssertEqual(order, ["didMove", "didReceive"])
    }

    // MARK: - Ending the hover

    private final class HoverSpy: DragDropControllerDelegate {
        var log: [String] = []

        func dragDropController(_ controller: DragDropController,
                                dragDidHover drag: DragAction,
                                from source: DragDropController) { log.append("hover") }

        func dragDropController(_ controller: DragDropController,
                                dragDidLeave drag: DragAction,
                                from source: DragDropController) { log.append("leave") }

        func dragDropController(_ controller: DragDropController,
                                dragDidEnter drag: DragAction,
                                destinationController destination: DragDropController) {
            log.append("enter")
        }

        func dragDropController(_ controller: DragDropController,
                                dragDidExit drag: DragAction,
                                destinationController destination: DragDropController) {
            log.append("exit")
        }
    }

    /// A drop that lands is not a departure. Telling the destination the drag
    /// left it asks it to undo the preview it is about to commit -- which is
    /// how a table came to animate its open gap shut and straight back open
    /// again, half a row's worth, after the dropped row had already landed.
    func testADestinationTheDropLandsInIsNotToldTheDragLeftIt() {
        makeControllers()
        let destinationSpy = HoverSpy()
        extraDelegates = [destinationSpy]
        destination.dragDropDelegate = destinationSpy

        let drag = DragAction(view: UIView())
        source.notifyDropTarget(destination, of: drag)
        source.notifyDropTarget(nil, of: drag, handingTo: destination)

        XCTAssertEqual(destinationSpy.log, ["hover"])
    }

    /// A drag that moves off the target, or ends nowhere, still leaves it.
    func testADestinationTheDragMovesAwayFromIsToldItLeft() {
        makeControllers()
        let destinationSpy = HoverSpy()
        extraDelegates = [destinationSpy]
        destination.dragDropDelegate = destinationSpy

        let drag = DragAction(view: UIView())
        source.notifyDropTarget(destination, of: drag)
        source.notifyDropTarget(nil, of: drag)

        XCTAssertEqual(destinationSpy.log, ["hover", "leave"])
    }

    /// The source's own family is untouched. It reports where the drag is
    /// rather than what it did, and the collection view finishes a
    /// rearrangement from `dragDidExit`.
    func testTheSourceStillHearsDragDidExitWhenTheDropLands() {
        makeControllers()
        let sourceSpy = HoverSpy()
        extraDelegates = [sourceSpy]
        source.dragDropDelegate = sourceSpy

        let drag = DragAction(view: UIView())
        source.notifyDropTarget(destination, of: drag)
        source.notifyDropTarget(nil, of: drag, handingTo: destination)

        XCTAssertEqual(sourceSpy.log, ["enter", "exit"])
    }

    /// A delegate that ignores the new callbacks is untouched, which is what
    /// keeps the collection view extension working exactly as it did.
    func testADelegateThatIgnoresTheCallbacksIsUnaffected() {
        makeControllers()

        final class OldDelegate: DragDropControllerDelegate {}
        let old = OldDelegate()
        extraDelegates = [old]
        destination.dragDropDelegate = old

        let view = UIView()
        sourceTarget.addSubview(view)
        source.completeDrop(of: view, into: destination, frame: .zero)

        XCTAssertIdentical(view.superview, destinationTarget)
    }

    /// `frameFor:in:` answers in the destination's coordinate space, and the
    /// destination is what knows its own layout, so it answers when it has a
    /// datasource of its own.
    func testTheDestinationsDataSourceAnswersForTheFrame() {
        makeControllers()

        let destinationDataSource = NamedDataSource(CGRect(x: 7, y: 7, width: 7, height: 7))
        extraDataSource = destinationDataSource
        destination.dragDropDataSource = destinationDataSource

        XCTAssertEqual(source.frameForDrop(of: UIView(), into: destination),
                       CGRect(x: 7, y: 7, width: 7, height: 7))
    }

    /// A destination with no datasource of its own keeps the old behaviour.
    func testTheSourcesDataSourceAnswersWhenTheDestinationHasNone() {
        makeControllers()
        destination.dragDropDataSource = nil

        XCTAssertEqual(source.frameForDrop(of: UIView(), into: destination), .zero)
    }
}
