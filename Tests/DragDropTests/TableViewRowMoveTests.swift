import XCTest
import UIKit
@testable import DragDrop

/// The row updates themselves. The datasource drops or adds the item first, so
/// the model and the table agree before UIKit is told anything.
@MainActor
final class TableViewRowMoveTests: XCTestCase {

    private final class Source: NSObject, UITableViewDataSourceRowMoveSupport {
        var items: [Int] = Array(0..<5)
        var canDrag = true

        /// The table's row count at the moment each callback ran, which is how
        /// the ordering contract is checked.
        var tableCountWhenRemoved: Int?
        var tableCountWhenInserted: Int?
        var insertedViews: [UIView] = []

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.accessibilityLabel = "\(items[indexPath.row])"
            return cell
        }

        func tableView(_ tableView: UITableView, didRemoveRowAt indexPath: IndexPath) {
            tableCountWhenRemoved = tableView.numberOfRows(inSection: 0)
            items.remove(at: indexPath.row)
        }

        func tableView(_ tableView: UITableView, didInsertRowAt indexPath: IndexPath, for view: UIView) {
            tableCountWhenInserted = tableView.numberOfRows(inSection: 0)
            insertedViews.append(view)
            items.insert(99, at: indexPath.row)
        }

        func tableView(_ tableView: UITableView, canDragRowAt indexPath: IndexPath) -> Bool { canDrag }
    }

    /// Implements only UITableViewDataSource, so the library must leave it alone.
    private final class PlainSource: NSObject, UITableViewDataSource {
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 5 }
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        }
    }

    private var dataSource: (any UITableViewDataSource)!
    private var window: UIWindow!

    private func makeTableView(_ source: any UITableViewDataSource) -> UITableView {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 200, height: 400), style: .plain)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.rowHeight = 40

        dataSource = source
        tableView.dataSource = source

        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 400))
        window.addSubview(tableView)
        window.isHidden = false

        tableView.reloadData()
        tableView.layoutIfNeeded()
        return tableView
    }

    func testRemovingARowDropsTheItemAndTheRow() {
        let source = Source()
        let tableView = makeTableView(source)

        tableView.removeRow(at: IndexPath(row: 1, section: 0))
        tableView.layoutIfNeeded()

        XCTAssertEqual(source.items, [0, 2, 3, 4])
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 4)
    }

    /// Getting this backwards crashes UIKit, so it is pinned explicitly.
    func testTheDataSourceDropsTheItemBeforeTheRowGoes() {
        let source = Source()
        let tableView = makeTableView(source)

        tableView.removeRow(at: IndexPath(row: 1, section: 0))

        XCTAssertEqual(source.tableCountWhenRemoved, 5,
                       "the datasource should be called while the table still has every row")
    }

    func testInsertingARowAddsTheItemAndTheRow() {
        let source = Source()
        let tableView = makeTableView(source)
        let view = UIView()

        tableView.insertRow(at: IndexPath(row: 2, section: 0), for: view)
        tableView.layoutIfNeeded()

        XCTAssertEqual(source.items, [0, 1, 99, 2, 3, 4])
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 6)
        XCTAssertIdentical(source.insertedViews.first, view)
    }

    func testTheDataSourceAddsTheItemBeforeTheRowAppears() {
        let source = Source()
        let tableView = makeTableView(source)

        tableView.insertRow(at: IndexPath(row: 2, section: 0), for: UIView())

        XCTAssertEqual(source.tableCountWhenInserted, 5)
    }

    /// A drop past the end of the model appends rather than trapping.
    func testInsertingPastTheEndClampsToAnAppend() {
        let source = Source()
        let tableView = makeTableView(source)

        tableView.insertRow(at: IndexPath(row: 99, section: 0), for: UIView())
        tableView.layoutIfNeeded()

        XCTAssertEqual(source.items, [0, 1, 2, 3, 4, 99])
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 6)
    }

    func testADataSourceThatDoesNotConformIsLeftAlone() {
        let tableView = makeTableView(PlainSource())

        tableView.removeRow(at: IndexPath(row: 1, section: 0))
        tableView.insertRow(at: IndexPath(row: 1, section: 0), for: UIView())
        tableView.layoutIfNeeded()

        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 5)
    }

    func testMovingARowDownCorrectsForTheRemoval() {
        let source = Source()
        let tableView = makeTableView(source)

        // 0 1 2 3 4 -> take 1 out, put it back where row 4 was.
        tableView.moveRow(from: IndexPath(row: 1, section: 0),
                          to: IndexPath(row: 4, section: 0),
                          for: UIView())
        tableView.layoutIfNeeded()

        XCTAssertEqual(source.items, [0, 2, 3, 99, 4])
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 5)
    }

    func testMovingARowUpNeedsNoCorrection() {
        let source = Source()
        let tableView = makeTableView(source)

        tableView.moveRow(from: IndexPath(row: 3, section: 0),
                          to: IndexPath(row: 1, section: 0),
                          for: UIView())
        tableView.layoutIfNeeded()

        XCTAssertEqual(source.items, [0, 99, 1, 2, 4])
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 5)
    }

    func testCanDragRowAtDefaultsToTrue() {
        final class Minimal: NSObject, UITableViewDataSourceRowMoveSupport {
            func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }
            func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                UITableViewCell()
            }
            func tableView(_ tableView: UITableView, didRemoveRowAt indexPath: IndexPath) {}
            func tableView(_ tableView: UITableView, didInsertRowAt indexPath: IndexPath, for view: UIView) {}
        }

        XCTAssertTrue(Minimal().tableView(UITableView(), canDragRowAt: IndexPath(row: 0, section: 0)))
    }
}
