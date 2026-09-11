import XCTest
import UIKit
@testable import DragDrop

/// What the table's state box answers when the drag controller asks it things.
@MainActor
final class TableViewDragDataSourceTests: XCTestCase {

    private final class Source: NSObject, UITableViewDataSourceRowMoveSupport {
        var items: [Int] = Array(0..<8)
        var canDrag = true

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        }
        func tableView(_ tableView: UITableView, didRemoveRowAt indexPath: IndexPath) {
            items.remove(at: indexPath.row)
        }
        func tableView(_ tableView: UITableView, didInsertRowAt indexPath: IndexPath, for view: UIView) {
            items.insert(99, at: indexPath.row)
        }
        func tableView(_ tableView: UITableView, canDragRowAt indexPath: IndexPath) -> Bool { canDrag }
    }

    private var dataSource: Source!
    private var window: UIWindow!
    private var panel: UIView!
    private var panelController: DragDropController!

    private func makeTableView() -> UITableView {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 200, height: 400), style: .plain)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.rowHeight = 40

        dataSource = Source()
        tableView.dataSource = dataSource

        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        window.addSubview(tableView)
        window.isHidden = false

        tableView.reloadData()
        tableView.layoutIfNeeded()
        tableView.enableDragAndDrop(for: UIView())
        return tableView
    }

    private func makePanel() -> DragDropController {
        panel = UIView(frame: CGRect(x: 200, y: 0, width: 200, height: 400))
        window.addSubview(panel)

        let controller = DragDropController()
        controller.dropTargetView = panel
        panelController = controller
        return controller
    }

    /// A drop onto the table goes where the gap is already open.
    func testTheFrameForATableDestinationIsTheOpenVacancy() {
        let tableView = makeTableView()
        tableView.dragDropState.vacancyIndexPath = IndexPath(row: 3, section: 0)
        tableView.dragDropState.vacancyHeight = 40

        guard let controller = tableView.dragDropController else { return XCTFail("no controller") }
        let frame = tableView.dragDropState.dragDropController(controller,
                                                               frameFor: UIView(),
                                                               in: controller)

        XCTAssertEqual(frame, tableView.rectForRow(at: IndexPath(row: 3, section: 0)))
    }

    func testTheFrameIsZeroWhenNoVacancyIsOpen() {
        let tableView = makeTableView()
        tableView.dragDropState.clearVacancy()

        guard let controller = tableView.dragDropController else { return XCTFail("no controller") }
        XCTAssertEqual(tableView.dragDropState.dragDropController(controller,
                                                                  frameFor: UIView(),
                                                                  in: controller), .zero)
    }

    /// A table is never asked about a container it does not own: `endDrag` asks
    /// the destination's own datasource. This pins the table's half of that —
    /// it answers zero rather than guessing.
    func testTheTableDoesNotGuessAtANonTableDestination() {
        let tableView = makeTableView()
        let destination = makePanel()

        guard let controller = tableView.dragDropController else { return XCTFail("no controller") }
        XCTAssertEqual(tableView.dragDropState.dragDropController(controller,
                                                                  frameFor: UIView(),
                                                                  in: destination), .zero)
    }

    func testShouldDragHonoursTheDataSource() {
        let tableView = makeTableView()
        guard let controller = tableView.dragDropController,
              let cell = tableView.cellForRow(at: IndexPath(row: 2, section: 0))
        else { return XCTFail("no cell at row 2") }

        let dragView = UIView()
        cell.contentView.addSubview(dragView)

        dataSource.canDrag = false
        XCTAssertFalse(tableView.dragDropState.dragDropController(controller, shouldDrag: dragView))

        dataSource.canDrag = true
        XCTAssertTrue(tableView.dragDropState.dragDropController(controller, shouldDrag: dragView))
    }

    /// A view that is not in one of our cells is not ours to refuse.
    func testShouldDragAllowsAViewOutsideAnyCell() {
        let tableView = makeTableView()
        guard let controller = tableView.dragDropController else { return XCTFail("no controller") }

        dataSource.canDrag = false

        let container = UIView()
        let loose = UIView()
        container.addSubview(loose)

        XCTAssertTrue(tableView.dragDropState.dragDropController(controller, shouldDrag: loose))
    }

    /// Rows are UIKit's to place. The plain-view re-flow must never run on a
    /// table, which it will not as long as this keeps taking the nil default.
    func testTheTableOptsOutOfThePlainViewReflow() {
        let tableView = makeTableView()
        guard let controller = tableView.dragDropController else { return XCTFail("no controller") }

        XCTAssertNil(tableView.dragDropState.dragDropController(controller, frameFor: UIView(), at: 0))
    }
}
