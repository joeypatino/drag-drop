import XCTest
import UIKit
@testable import DragDrop

@MainActor
final class TableViewDragDropStateTests: XCTestCase {

    private final class Source: NSObject, UITableViewDataSource {
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 10 }
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        }
    }

    private var dataSource: Source!
    private var window: UIWindow!

    /// Built per test rather than in setUp: setUp is not main-actor isolated,
    /// and these are all UIKit objects.
    private func makeTableView() -> UITableView {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 200, height: 400), style: .plain)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.rowHeight = 40

        dataSource = Source()
        tableView.dataSource = dataSource

        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 400))
        window.addSubview(tableView)
        window.isHidden = false

        tableView.reloadData()
        tableView.layoutIfNeeded()
        return tableView
    }

    func testStateIsCreatedLazilyAndIsStable() {
        let tableView = makeTableView()

        tableView.dragDropState.sourceIndexPath = IndexPath(row: 3, section: 0)

        XCTAssertEqual(tableView.dragDropState.sourceIndexPath, IndexPath(row: 3, section: 0))
        XCTAssertIdentical(tableView.dragDropState.tableView, tableView)
    }

    func testStateIsPerTableView() {
        let first = makeTableView()
        let second = makeTableView()

        first.dragDropState.sourceIndexPath = IndexPath(row: 1, section: 0)

        XCTAssertNil(second.dragDropState.sourceIndexPath)
    }

    func testEnableDragAndDropAttachesOneGesturePerView() {
        let tableView = makeTableView()
        let view = UIView()

        tableView.enableDragAndDrop(for: view)
        tableView.enableDragAndDrop(for: view)

        let gestures = view.gestureRecognizers?.filter { $0 is DragDropGesture } ?? []
        XCTAssertEqual(gestures.count, 1, "enable must disable first, so a reused cell keeps one gesture")
    }

    func testTheTableViewItselfIsTheDropTarget() {
        let tableView = makeTableView()

        tableView.enableDragAndDrop(for: UIView())

        XCTAssertIdentical(tableView.dragDropController?.dropTargetView, tableView)
    }

    func testDisableDragAndDropRemovesTheGesture() {
        let tableView = makeTableView()
        let view = UIView()

        tableView.enableDragAndDrop(for: view)
        tableView.disableDragAndDrop(for: view)

        let gestures = view.gestureRecognizers?.filter { $0 is DragDropGesture } ?? []
        XCTAssertTrue(gestures.isEmpty)
    }

    func testClearVacancyResetsBothFields() {
        let tableView = makeTableView()
        tableView.dragDropState.vacancyIndexPath = IndexPath(row: 2, section: 0)
        tableView.dragDropState.vacancyHeight = 44

        tableView.dragDropState.clearVacancy()

        XCTAssertNil(tableView.dragDropState.vacancyIndexPath)
        XCTAssertEqual(tableView.dragDropState.vacancyHeight, 0)
    }
}
