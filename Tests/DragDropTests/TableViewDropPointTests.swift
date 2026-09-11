import XCTest
import UIKit
@testable import DragDrop

/// Where a view released over a table lands, including the two places a table
/// has no row: above the first and below the last.
@MainActor
final class TableViewDropPointTests: XCTestCase {

    private final class Source: NSObject, UITableViewDataSource {
        var rows = 5
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows }
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        }
    }

    private var dataSource: Source!
    private var window: UIWindow!

    private func makeTableView(rows: Int = 5) -> UITableView {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 200, height: 400), style: .plain)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.rowHeight = 40

        dataSource = Source()
        dataSource.rows = rows
        tableView.dataSource = dataSource

        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 400))
        window.addSubview(tableView)
        window.isHidden = false

        tableView.reloadData()
        tableView.layoutIfNeeded()
        return tableView
    }

    func testAPointInsideARowResolvesToThatRow() {
        let tableView = makeTableView()

        XCTAssertEqual(tableView.indexPath(at: CGPoint(x: 100, y: 100)), IndexPath(row: 2, section: 0))
    }

    /// Releasing in the empty space under a short table appends.
    func testAPointBelowTheLastRowResolvesToOnePastTheEnd() {
        let tableView = makeTableView()

        XCTAssertEqual(tableView.indexPath(at: CGPoint(x: 100, y: 380)), IndexPath(row: 5, section: 0))
    }

    func testAPointAboveTheFirstRowResolvesToTheFirstRow() {
        let tableView = makeTableView()

        XCTAssertEqual(tableView.indexPath(at: CGPoint(x: 100, y: -50)), IndexPath(row: 0, section: 0))
    }

    func testAnEmptyTableResolvesToItsOnlyPossibleRow() {
        let tableView = makeTableView(rows: 0)

        XCTAssertEqual(tableView.indexPath(at: CGPoint(x: 100, y: 100)), IndexPath(row: 0, section: 0))
    }

    func testTheRectForAnArrivingRowIsTheRowAlreadyThere() {
        let tableView = makeTableView()

        XCTAssertEqual(tableView.rectForRow(arrivingAt: IndexPath(row: 2, section: 0), height: 999),
                       tableView.rectForRow(at: IndexPath(row: 2, section: 0)))
    }

    /// One past the end has no row to borrow from, so it sits directly below
    /// the last one at the height it will actually be.
    func testTheRectForARowArrivingPastTheEndSitsBelowTheLastRow() {
        let tableView = makeTableView()
        let last = tableView.rectForRow(at: IndexPath(row: 4, section: 0))

        let arriving = tableView.rectForRow(arrivingAt: IndexPath(row: 5, section: 0), height: 40)

        XCTAssertEqual(arriving, CGRect(x: last.minX, y: last.maxY, width: last.width, height: 40))
    }

    func testTheRectForARowArrivingInAnEmptyTableStartsAtTheTop() {
        let tableView = makeTableView(rows: 0)

        XCTAssertEqual(tableView.rectForRow(arrivingAt: IndexPath(row: 0, section: 0), height: 40),
                       CGRect(x: 0, y: 0, width: 200, height: 40))
    }
}
