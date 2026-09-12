import XCTest
import UIKit
@testable import DragDrop

/// The whole drag, driven through the delegate callbacks the controller sends.
@MainActor
final class TableViewDragOrchestrationTests: XCTestCase {

    private final class Source: NSObject, UITableViewDataSourceRowMoveSupport {
        var items: [Int]
        init(_ items: [Int]) { self.items = items }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.accessibilityLabel = "\(items[indexPath.row])"
            return cell
        }
        func tableView(_ tableView: UITableView, didRemoveRowAt indexPath: IndexPath) {
            items.remove(at: indexPath.row)
        }
        func tableView(_ tableView: UITableView, didInsertRowAt indexPath: IndexPath, for view: UIView) {
            items.insert(99, at: indexPath.row)
        }
    }

    private var leftSource: Source!
    private var rightSource: Source!
    private var window: UIWindow!
    private var left: UITableView!
    private var right: UITableView!
    private var panel: UIView!
    private var panelController: DragDropController!

    /// `DragAction.view` is weak. The controller keeps the real one alive
    /// through the drag; a test has to do it itself.
    private var draggedViews: [UIView] = []

    private func makeScene() {
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 600, height: 400))

        leftSource = Source(Array(0..<8))
        rightSource = Source(Array(100..<104))

        left = makeTableView(x: 0, source: leftSource)
        right = makeTableView(x: 200, source: rightSource)

        panel = UIView(frame: CGRect(x: 400, y: 0, width: 200, height: 400))
        window.addSubview(panel)
        panelController = DragDropController()
        panelController.dropTargetView = panel

        window.isHidden = false
        left.layoutIfNeeded()
        right.layoutIfNeeded()
    }

    private func makeTableView(x: CGFloat, source: Source) -> UITableView {
        let tableView = UITableView(frame: CGRect(x: x, y: 0, width: 200, height: 400), style: .plain)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.rowHeight = 40
        tableView.dataSource = source

        window.addSubview(tableView)
        tableView.reloadData()
        tableView.layoutIfNeeded()
        tableView.enableDragAndDrop(for: UIView())
        return tableView
    }

    /// A DragAction reporting the container the drag began in, which is what
    /// the controller hands the delegate.
    private func dragAction(from sourceView: UIView?, at location: CGPoint) -> DragAction {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 180, height: 40))
        draggedViews.append(view)

        let drag = DragAction(view: view)
        drag.sourceView = sourceView
        drag.currentLocation = location
        return drag
    }

    private func beginDrag(from tableView: UITableView, row: Int) -> DragAction {
        guard let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)),
              let controller = tableView.dragDropController else {
            XCTFail("no cell at row \(row)")
            return dragAction(from: nil, at: .zero)
        }

        let dragView = UIView()
        cell.contentView.addSubview(dragView)

        let drag = dragAction(from: dragView.superview, at: .zero)
        tableView.dragDropState.dragDropController(controller, willStartDrag: drag, animated: false)
        return drag
    }

    func testTheRowTheDragStartedInIsRemembered() {
        makeScene()
        _ = beginDrag(from: left, row: 3)

        XCTAssertEqual(left.dragDropState.sourceIndexPath, IndexPath(row: 3, section: 0))
    }

    func testHoveringOpensTheVacancyAtTheRowUnderTheFinger() {
        makeScene()
        let drag = beginDrag(from: left, row: 0)
        drag.currentLocation = CGPoint(x: 100, y: 100)

        guard let leftController = left.dragDropController else { return XCTFail("no controller") }
        left.dragDropState.dragDropController(leftController, dragDidHover: drag, from: leftController)

        XCTAssertEqual(left.dragDropState.vacancyIndexPath, IndexPath(row: 2, section: 0))
        XCTAssertEqual(left.dragDropState.vacancyHeight, 40)
    }

    func testLeavingClosesTheVacancy() {
        makeScene()
        let drag = beginDrag(from: left, row: 0)
        drag.currentLocation = CGPoint(x: 100, y: 100)

        guard let leftController = left.dragDropController else { return XCTFail("no controller") }
        let resting = left.rectForRow(at: IndexPath(row: 4, section: 0))

        left.dragDropState.dragDropController(leftController, dragDidHover: drag, from: leftController)
        XCTAssertNotEqual(left.cellForRow(at: IndexPath(row: 4, section: 0))?.frame, resting,
                          "precondition: the gap is open")

        left.dragDropState.dragDropController(leftController, dragDidLeave: drag, from: leftController)

        XCTAssertEqual(left.cellForRow(at: IndexPath(row: 4, section: 0))?.frame, resting)
    }

    /// Leaving must not forget *where* the gap was. `endDrag` sends the leave
    /// from its animation completion before it hands the view over, so a drop on
    /// this table reaches `didReceive` just after its own leave. Clearing the
    /// target on leave lost it every time, and the row was never inserted.
    func testLeavingKeepsTheTargetSoADropStillLands() {
        makeScene()
        let drag = dragAction(from: panel, at: CGPoint(x: 100, y: 100))

        guard let leftController = left.dragDropController, let view = drag.view else {
            return XCTFail("no controller")
        }

        left.dragDropState.dragDropController(leftController, dragDidHover: drag, from: panelController)
        left.dragDropState.dragDropController(leftController, dragDidLeave: drag, from: panelController)
        left.dragDropState.dragDropController(leftController, didReceive: view, from: panelController)
        left.layoutIfNeeded()

        XCTAssertEqual(leftSource.items, [0, 1, 99, 2, 3, 4, 5, 6, 7])
    }

    /// Dropped on something that is not a table: the row simply goes.
    func testDroppingOnANonTableRemovesTheRow() {
        makeScene()
        let drag = beginDrag(from: left, row: 3)

        guard let leftController = left.dragDropController, let view = drag.view else {
            return XCTFail("no controller")
        }
        left.dragDropState.dragDropController(leftController, didMove: view, to: panelController)
        left.layoutIfNeeded()

        XCTAssertEqual(leftSource.items, [0, 1, 2, 4, 5, 6, 7])
        XCTAssertEqual(left.numberOfRows(inSection: 0), 7)
        XCTAssertNil(left.dragDropState.sourceIndexPath)
    }

    /// Table to table: the source removes, then the destination inserts. The
    /// destination hears about it through didReceive, which is the only notice
    /// it gets.
    func testDroppingOnAnotherTableRemovesThenInserts() {
        makeScene()
        let drag = beginDrag(from: left, row: 1)
        drag.currentLocation = CGPoint(x: 100, y: 20)

        guard let leftController = left.dragDropController,
              let rightController = right.dragDropController,
              let view = drag.view else { return XCTFail("no controller") }

        right.dragDropState.dragDropController(rightController, dragDidHover: drag, from: leftController)
        left.dragDropState.dragDropController(leftController, didMove: view, to: rightController)
        right.dragDropState.dragDropController(rightController, didReceive: view, from: leftController)
        left.layoutIfNeeded()
        right.layoutIfNeeded()

        XCTAssertEqual(leftSource.items, [0, 2, 3, 4, 5, 6, 7])
        XCTAssertEqual(rightSource.items, [99, 100, 101, 102, 103])
    }

    /// completeDrop leaves the dragged view sitting on the table as a raw
    /// subview. A table renders its own rows, so it has to go.
    func testTheDroppedViewIsHandedBackRatherThanLeftFloating() {
        makeScene()
        let drag = beginDrag(from: left, row: 1)
        drag.currentLocation = CGPoint(x: 100, y: 20)

        guard let leftController = left.dragDropController,
              let rightController = right.dragDropController,
              let view = drag.view else { return XCTFail("no controller") }

        right.addSubview(view)
        right.dragDropState.dragDropController(rightController, dragDidHover: drag, from: leftController)
        right.dragDropState.dragDropController(rightController, didReceive: view, from: leftController)

        XCTAssertNil(view.superview)
    }

    /// The same hand-back, for the one drop that never reaches didReceive.
    ///
    /// `completeDrop` parents the dragged view onto the table whichever
    /// controller the drop came from, but the correction lived only in
    /// didReceive -- which returns immediately when the source is this table.
    /// A reorder therefore left the view floating over the row it had just
    /// rendered, at the full row rect rather than the cell's inset content
    /// frame, which reads as a row that stayed picked up.
    func testTheViewIsHandedBackWhenTheDropIsAReorder() {
        makeScene()
        let drag = beginDrag(from: left, row: 1)
        drag.currentLocation = CGPoint(x: 100, y: 180)

        guard let leftController = left.dragDropController, let view = drag.view else {
            return XCTFail("no controller")
        }

        left.dragDropState.dragDropController(leftController, dragDidHover: drag, from: leftController)

        // What completeDrop does before any delegate is told.
        left.addSubview(view)

        left.dragDropState.dragDropController(leftController, didMove: view, to: leftController)
        left.dragDropState.dragDropController(leftController, didReceive: view, from: leftController)

        XCTAssertFalse(left.subviews.contains(view),
                       "the dragged view was left floating over the table")
    }

    /// A drop back into the table the drag started in is a reorder, and is
    /// handled once, in didMove. didReceive must not insert a second row.
    func testDroppingBackIntoTheSameTableReorders() {
        makeScene()
        let drag = beginDrag(from: left, row: 1)
        drag.currentLocation = CGPoint(x: 100, y: 180)

        guard let leftController = left.dragDropController, let view = drag.view else {
            return XCTFail("no controller")
        }

        left.dragDropState.dragDropController(leftController, dragDidHover: drag, from: leftController)
        left.dragDropState.dragDropController(leftController, didMove: view, to: leftController)
        left.dragDropState.dragDropController(leftController, didReceive: view, from: leftController)
        left.layoutIfNeeded()

        XCTAssertEqual(leftSource.items.count, 8, "a reorder must not change the count")
        XCTAssertEqual(left.numberOfRows(inSection: 0), 8)
    }

    /// A drag that never started in one of our rows leaves the table alone.
    func testADragFromElsewhereRemovesNothing() {
        makeScene()
        let drag = dragAction(from: panel, at: CGPoint(x: 100, y: 100))

        guard let leftController = left.dragDropController, let view = drag.view else {
            return XCTFail("no controller")
        }
        left.dragDropState.dragDropController(leftController, willStartDrag: drag, animated: false)
        left.dragDropState.dragDropController(leftController, didMove: view, to: panelController)
        left.layoutIfNeeded()

        XCTAssertEqual(leftSource.items.count, 8)
    }

    /// The panel is the source, so only the destination hears anything.
    func testADropFromANonTableInsertsARow() {
        makeScene()
        let drag = dragAction(from: panel, at: CGPoint(x: 100, y: 100))

        guard let leftController = left.dragDropController, let view = drag.view else {
            return XCTFail("no controller")
        }

        left.dragDropState.dragDropController(leftController, dragDidHover: drag, from: panelController)
        left.dragDropState.dragDropController(leftController, didReceive: view, from: panelController)
        left.layoutIfNeeded()

        XCTAssertEqual(leftSource.items, [0, 1, 99, 2, 3, 4, 5, 6, 7])
        XCTAssertEqual(left.numberOfRows(inSection: 0), 9)
    }
}
