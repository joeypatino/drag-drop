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
    func insertRow(at indexPath: IndexPath, for view: UIView) {
        guard let dataSource = rowMoveDataSource else { return }

        // The drop point was resolved against the table, which can be one past
        // the end of a model that has meanwhile shrunk.
        var target = indexPath
        target.row = min(target.row, dataSource.tableView(self, numberOfRowsInSection: target.section))

        dataSource.tableView(self, didInsertRowAt: target, for: view)
        insertRows(at: [target], with: .fade)
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
