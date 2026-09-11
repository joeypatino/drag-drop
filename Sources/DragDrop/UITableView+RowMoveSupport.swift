//
//  UITableView+RowMoveSupport.swift
//  DragDrop
//

import UIKit

/// Adopt this on a table view's datasource to let views be dragged out of its
/// rows and dropped into it.
///
/// The two required methods each update your model. The library calls
/// `deleteRows`/`insertRows` for you straight afterwards, so a table-to-table
/// move is these two firing in turn — the source's `didRemoveRowAt` and then
/// the destination's `didInsertRowAt` — and you connect the halves through the
/// view you are handed.
@MainActor
public protocol UITableViewDataSourceRowMoveSupport: UITableViewDataSource {

    /// The view in this row was dragged away. Remove the row's item from your
    /// model.
    ///
    /// Called *before* the library deletes the row, so the model and the table
    /// agree by the time UIKit asks for counts again.
    func tableView(_ tableView: UITableView, didRemoveRowAt indexPath: IndexPath)

    /// `view` was dropped onto the table at this row. Insert an item for it.
    ///
    /// Called *before* the library inserts the row, for the same reason.
    func tableView(_ tableView: UITableView,
                   didInsertRowAt indexPath: IndexPath,
                   for view: UIView)

    /// Optional. Defaults to true. Refuse to let this row's view be dragged.
    ///
    /// Deliberately not named `canMoveRowAt`: `UITableViewDataSource` already
    /// declares that for its reorder controls, and the two would have collided.
    func tableView(_ tableView: UITableView, canDragRowAt indexPath: IndexPath) -> Bool
}

public extension UITableViewDataSourceRowMoveSupport {
    func tableView(_ tableView: UITableView, canDragRowAt indexPath: IndexPath) -> Bool { true }
}

// MARK: - The vacancy

internal extension UITableView {

    /// Opens a gap `height` tall at `target`, sliding the rows at and after it
    /// down so the drop point is visible before the finger lifts.
    ///
    /// The collection view opens its gap by moving each cell into the *next*
    /// index path's frame, which a table cannot borrow: the next row's frame is
    /// the wrong answer when heights vary. A table is a single column, though,
    /// so one uniform offset opens a correct gap whatever the heights are.
    ///
    /// Every frame is recomputed from `rectForRow(at:)` rather than nudged, so
    /// calling this again for a different row closes the old gap and opens the
    /// new one in the same pass. That is why a drag needs no explicit close
    /// between moves.
    func openVacancy(at target: IndexPath, height: CGFloat, animated: Bool) {
        UIView.animate(withDuration: animated ? 0.3 : 0.0) { [self] in

            for indexPath in indexPathsForVisibleRows ?? [] {
                var frame = rectForRow(at: indexPath)

                if indexPath.isSame(as: target) || indexPath.isAfter(target) {
                    frame.origin.y += height
                }

                cellForRow(at: indexPath)?.frame = frame
            }
        }
    }

    /// Puts every visible row back where the table says it belongs.
    func closeVacancy(animated: Bool) {
        UIView.animate(withDuration: animated ? 0.3 : 0.0) { [self] in

            for indexPath in indexPathsForVisibleRows ?? [] {
                cellForRow(at: indexPath)?.frame = rectForRow(at: indexPath)
            }
        }
    }

    /// How tall a gap to open for a row arriving at `target`: the height of the
    /// row already there, so nothing jumps when the real row appears. An append
    /// has no such row, so it falls back to the table's own row height and
    /// finally to the dragged view.
    func vacancyHeight(for target: IndexPath, draggedView: UIView) -> CGFloat {
        if target.section < numberOfSections,
           target.row < numberOfRows(inSection: target.section) {
            let existing = rectForRow(at: target).height
            if existing > 0 { return existing }
        }

        // automaticDimension is negative, so this rejects it too.
        if rowHeight > 0 { return rowHeight }

        return draggedView.frame.height
    }
}

// MARK: - Row updates

internal extension UITableView {

    var rowMoveDataSource: (any UITableViewDataSourceRowMoveSupport)? {
        dataSource as? any UITableViewDataSourceRowMoveSupport
    }

    /// Drops the row whose view was dragged away.
    func removeRow(at indexPath: IndexPath) {
        guard let dataSource = rowMoveDataSource else { return }

        dataSource.tableView(self, didRemoveRowAt: indexPath)
        deleteRows(at: [indexPath], with: .automatic)
    }

    /// Adds a row for a view dropped onto the table.
    ///
    /// `.none`, because this row is a hand-over rather than an arrival. The
    /// dragged view has just been taken away from the very spot the row is
    /// filling, and it left at full opacity -- so a `.fade` starts the row at
    /// nothing and the slot is visibly empty for a few frames before the row
    /// appears in it. Inserting without an animation puts the row up in the
    /// same frame the dragged view goes, which is the swap the eye expects.
    func insertRow(at indexPath: IndexPath, for view: UIView) {
        guard let dataSource = rowMoveDataSource else { return }

        // The drop point was resolved against the table, which can be one past
        // the end of a model that has meanwhile shrunk.
        var target = indexPath
        target.row = min(target.row, dataSource.tableView(self, numberOfRowsInSection: target.section))

        dataSource.tableView(self, didInsertRowAt: target, for: view)
        insertRows(at: [target], with: .none)
    }

    /// A view dragged out of one of this table's rows and released over another
    /// of them: a reorder.
    ///
    /// This is the one path where the ordering contract is relaxed. Both model
    /// updates run first, leaving it already correct, and the two row updates
    /// then go into one batch so UIKit animates a single move rather than a
    /// collapse followed by an expansion.
    func moveRow(from source: IndexPath, to target: IndexPath, for view: UIView) {
        guard let dataSource = rowMoveDataSource else { return }

        // `target` was resolved before the removal, so a destination below the
        // source is about to shift up by one.
        var destination = target
        if destination.section == source.section, destination.row > source.row {
            destination.row -= 1
        }

        dataSource.tableView(self, didRemoveRowAt: source)

        destination.row = min(destination.row,
                              dataSource.tableView(self, numberOfRowsInSection: destination.section))
        dataSource.tableView(self, didInsertRowAt: destination, for: view)

        performBatchUpdates {
            deleteRows(at: [source], with: .automatic)
            insertRows(at: [destination], with: .fade)
        }
    }
}
