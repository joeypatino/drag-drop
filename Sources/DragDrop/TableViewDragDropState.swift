//
//  TableViewDragDropState.swift
//  DragDrop
//

import UIKit
import ObjectiveC.runtime

/// Holds the drag state for one table view and carries the DragDropController
/// delegate and datasource conformances.
///
/// The same shape as CollectionViewDragDropState, and for the same reason:
/// conforming UITableView itself would need @retroactive, which Apple
/// discourages, and would make every table view in the process conform.
@MainActor
final class TableViewDragDropState {
    weak var tableView: UITableView?

    var dragDropController: DragDropController?

    /// The row the drag began in. Captured when the drag starts, because by the
    /// time it ends the dragged view has long since left the cell.
    var sourceIndexPath: IndexPath?

    /// Where the gap is currently held open, and how tall it is.
    var vacancyIndexPath: IndexPath?
    var vacancyHeight: CGFloat = 0

    init(tableView: UITableView) {
        self.tableView = tableView
    }

    func clearVacancy() {
        vacancyIndexPath = nil
        vacancyHeight = 0
    }
}

private enum AssociatedKeys {
    /// `&someGlobalVar` is no longer valid in Swift 6, so allocate a unique,
    /// never-freed address to use as the association key.
    nonisolated(unsafe) static let dragDropState =
        UnsafeRawPointer(UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1))
}

extension UITableView {
    /// Lazily created and then stable for the life of the table view.
    var dragDropState: TableViewDragDropState {
        if let existing = objc_getAssociatedObject(self, AssociatedKeys.dragDropState)
            as? TableViewDragDropState {
            return existing
        }

        let state = TableViewDragDropState(tableView: self)
        objc_setAssociatedObject(self, AssociatedKeys.dragDropState, state, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return state
    }
}
