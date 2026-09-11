import XCTest
import UIKit
@testable import DragDrop

/// A drag reports the container it began in. Turning that back into a row is
/// what lets the library delete the right one.
@MainActor
final class TableViewRowResolutionTests: XCTestCase {

    private final class Source: NSObject, UITableViewDataSource {
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 10 }
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        }
    }

    private var dataSources: [Source] = []
    private var window: UIWindow!

    private func makeTableView() -> UITableView {
        if window == nil {
            window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
            window.isHidden = false
        }

        let tableView = UITableView(frame: CGRect(x: CGFloat(dataSources.count) * 200, y: 0,
                                                  width: 200, height: 400),
                                    style: .plain)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.rowHeight = 40

        let source = Source()
        dataSources.append(source)
        tableView.dataSource = source

        window.addSubview(tableView)
        tableView.reloadData()
        tableView.layoutIfNeeded()
        return tableView
    }

    func testAViewAddedToAContentViewResolvesToItsRow() {
        let tableView = makeTableView()
        let indexPath = IndexPath(row: 2, section: 0)
        guard let cell = tableView.cellForRow(at: indexPath) else { return XCTFail("no cell at row 2") }

        let dragView = UIView()
        cell.contentView.addSubview(dragView)

        XCTAssertEqual(tableView.dragDropState.indexPath(forDragStartingIn: dragView.superview), indexPath)
    }

    func testAViewNestedBelowContentViewStillResolvesToItsRow() {
        let tableView = makeTableView()
        let indexPath = IndexPath(row: 5, section: 0)
        guard let cell = tableView.cellForRow(at: indexPath) else { return XCTFail("no cell at row 5") }

        let wrapper = UIView()
        let dragView = UIView()
        cell.contentView.addSubview(wrapper)
        wrapper.addSubview(dragView)

        XCTAssertEqual(tableView.dragDropState.indexPath(forDragStartingIn: dragView.superview), indexPath)
    }

    func testAViewOutsideAnyCellResolvesToNothing() {
        let tableView = makeTableView()
        let container = UIView()
        let loose = UIView()
        container.addSubview(loose)

        XCTAssertNil(tableView.dragDropState.indexPath(forDragStartingIn: loose.superview))
    }

    func testNoSourceViewResolvesToNothing() {
        let tableView = makeTableView()

        XCTAssertNil(tableView.dragDropState.indexPath(forDragStartingIn: nil))
    }

    /// A cell that belongs to a different table is not this table's business.
    func testACellFromAnotherTableResolvesToNothing() {
        let tableView = makeTableView()
        let other = makeTableView()
        guard let cell = other.cellForRow(at: IndexPath(row: 0, section: 0)) else {
            return XCTFail("no cell in the other table")
        }

        let dragView = UIView()
        cell.contentView.addSubview(dragView)

        XCTAssertNil(tableView.dragDropState.indexPath(forDragStartingIn: dragView.superview))
    }
}
