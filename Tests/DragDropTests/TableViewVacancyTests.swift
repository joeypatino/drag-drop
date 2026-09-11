import XCTest
import UIKit
@testable import DragDrop

/// The gap that opens under a drag so the drop point is visible before the
/// finger lifts.
@MainActor
final class TableViewVacancyTests: XCTestCase {

    private final class Source: NSObject, UITableViewDataSource {
        var rows = 8
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows }
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        }
    }

    /// Rows 0, 2, 4… are 30 tall and the rest 60, so a constant offset cannot
    /// accidentally pass the variable-height test.
    private final class VariableHeights: NSObject, UITableViewDelegate {
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            indexPath.row.isMultiple(of: 2) ? 30 : 60
        }
    }

    private var dataSource: Source!
    private var heights: VariableHeights!
    private var window: UIWindow!

    private func makeTableView(variableHeights: Bool = false) -> UITableView {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 200, height: 400), style: .plain)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        dataSource = Source()
        tableView.dataSource = dataSource

        if variableHeights {
            heights = VariableHeights()
            tableView.delegate = heights
        } else {
            tableView.rowHeight = 40
        }

        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 400))
        window.addSubview(tableView)
        window.isHidden = false

        tableView.reloadData()
        tableView.layoutIfNeeded()
        return tableView
    }

    private func frames(of tableView: UITableView) -> [IndexPath: CGRect] {
        var found: [IndexPath: CGRect] = [:]
        for indexPath in tableView.indexPathsForVisibleRows ?? [] {
            found[indexPath] = tableView.cellForRow(at: indexPath)?.frame
        }
        return found
    }

    func testRowsAtAndAfterTheTargetSlideDown() {
        let tableView = makeTableView()
        let before = frames(of: tableView)

        tableView.openVacancy(at: IndexPath(row: 3, section: 0), height: 40, animated: false)

        for (indexPath, frame) in frames(of: tableView) {
            guard let original = before[indexPath] else { continue }
            let expected = indexPath.row >= 3 ? original.offsetBy(dx: 0, dy: 40) : original
            XCTAssertEqual(frame, expected, "row \(indexPath.row) is in the wrong place")
        }
    }

    func testRowsBeforeTheTargetDoNotMove() {
        let tableView = makeTableView()
        let before = frames(of: tableView)

        tableView.openVacancy(at: IndexPath(row: 5, section: 0), height: 40, animated: false)
        let after = frames(of: tableView)

        for row in 0..<5 {
            let indexPath = IndexPath(row: row, section: 0)
            XCTAssertEqual(after[indexPath], before[indexPath])
        }
    }

    /// Every frame is recomputed from rectForRow rather than nudged, so moving
    /// the finger to a new row closes the old gap and opens the new one in one
    /// pass. Without that the offsets accumulate.
    func testOpeningAtANewRowDoesNotAccumulate() {
        let tableView = makeTableView()

        tableView.openVacancy(at: IndexPath(row: 2, section: 0), height: 40, animated: false)
        tableView.openVacancy(at: IndexPath(row: 5, section: 0), height: 40, animated: false)
        let afterTwoPasses = frames(of: tableView)

        tableView.closeVacancy(animated: false)
        tableView.openVacancy(at: IndexPath(row: 5, section: 0), height: 40, animated: false)

        XCTAssertEqual(afterTwoPasses, frames(of: tableView))
    }

    func testClosingPutsEveryRowBack() {
        let tableView = makeTableView()
        let before = frames(of: tableView)

        tableView.openVacancy(at: IndexPath(row: 1, section: 0), height: 40, animated: false)
        tableView.closeVacancy(animated: false)

        XCTAssertEqual(frames(of: tableView), before)
    }

    /// The gap is the size of the row that will actually appear, so nothing
    /// jumps when it does.
    func testTheGapIsTheDestinationRowsHeight() {
        let tableView = makeTableView(variableHeights: true)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 999))

        XCTAssertEqual(tableView.vacancyHeight(for: IndexPath(row: 0, section: 0), draggedView: view), 30)
        XCTAssertEqual(tableView.vacancyHeight(for: IndexPath(row: 1, section: 0), draggedView: view), 60)
    }

    /// One past the end has no row to measure, so fall back to the table's own
    /// rowHeight and then to the dragged view.
    func testTheGapPastTheEndFallsBackToTheRowHeight() {
        let tableView = makeTableView()
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 999))

        XCTAssertEqual(tableView.vacancyHeight(for: IndexPath(row: 8, section: 0), draggedView: view), 40)
    }

    func testTheGapFallsBackToTheDraggedViewWhenThereIsNothingElse() {
        let tableView = makeTableView(variableHeights: true)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 77))

        // Variable heights means rowHeight is automaticDimension, and row 8
        // does not exist, so only the dragged view is left to measure.
        XCTAssertEqual(tableView.vacancyHeight(for: IndexPath(row: 8, section: 0), draggedView: view), 77)
    }
}
