//
//  UITableView+DragDropControllerSupport.swift
//  DragDrop
//

import UIKit

public extension UITableView {

    internal var dragDropController: DragDropController? {
        get { dragDropState.dragDropController }
        set { dragDropState.dragDropController = newValue }
    }

    // MARK: -

    /// Makes `view` draggable out of the row that contains it.
    ///
    /// `view` is anything inside a cell — the whole `contentView`, or one
    /// subview of it. Call this from `cellForRowAt:` or `willDisplay:`. Like
    /// the collection view's equivalent it disables first, so a reused cell is
    /// left with exactly one gesture.
    func enableDragAndDrop(for view: UIView) {
        if dragDropController == nil { dragDropController = controller() }

        dragDropController?.disableDragAction(for: view)
        dragDropController?.enableDragAction(for: view)
    }

    func disableDragAndDrop(for view: UIView) {
        dragDropController?.disableDragAction(for: view)
    }

    // MARK: -

    private func controller() -> DragDropController {
        let controller = DragDropController()

        // The table itself is the drop target, not each cell's contentView.
        // That is what lets a view be dropped anywhere on the table and land in
        // the row under the finger.
        controller.dropTargetView = self
        controller.dragDropDataSource = dragDropState
        controller.dragDropDelegate = dragDropState

        return controller
    }
}

// MARK: - Resolving a row

internal extension UIView {
    /// The table view cell this view sits inside, however deeply.
    var enclosingTableViewCell: UITableViewCell? {
        var candidate: UIView? = self

        while let view = candidate {
            if let cell = view as? UITableViewCell { return cell }
            candidate = view.superview
        }

        return nil
    }
}

internal extension TableViewDragDropState {
    /// The row a drag began in, worked back from the container the dragged view
    /// left. Nil when that container was not one of this table's cells, which
    /// is the signal that the drag is none of our business.
    func indexPath(forDragStartingIn sourceView: UIView?) -> IndexPath? {
        guard let tableView,
              let cell = sourceView?.enclosingTableViewCell else { return nil }

        return tableView.indexPath(for: cell)
    }
}

// MARK: - Resolving a drop

internal extension UITableView {

    /// The row a drop at `location` lands on.
    ///
    /// `indexPathForRow(at:)` answers nil in the two places a table has no row.
    /// Below the last one means append; above the first means prepend.
    func indexPath(at location: CGPoint) -> IndexPath {
        if let indexPath = indexPathForRow(at: location) { return indexPath }
        if location.y < 0 { return IndexPath(row: 0, section: 0) }

        let section = max(numberOfSections - 1, 0)
        return IndexPath(row: numberOfRows(inSection: section), section: section)
    }

    /// Where a row arriving at `target` will sit.
    ///
    /// `rectForRow(at:)` has no answer for one past the last row, which is
    /// exactly where an append lands, so that case is worked out from the row
    /// above it.
    func rectForRow(arrivingAt target: IndexPath, height: CGFloat) -> CGRect {
        if target.section < numberOfSections,
           target.row < numberOfRows(inSection: target.section) {
            return rectForRow(at: target)
        }

        let section = max(numberOfSections - 1, 0)
        let rows = numberOfSections > 0 ? numberOfRows(inSection: section) : 0

        guard rows > 0 else {
            return CGRect(x: 0, y: 0, width: bounds.width, height: height)
        }

        let last = rectForRow(at: IndexPath(row: rows - 1, section: section))
        return CGRect(x: last.minX, y: last.maxY, width: last.width, height: height)
    }
}

// MARK: - DragDropController conformances
//
// Filled in by later work. `frameFor:in:` is the datasource protocol's only
// requirement without a default, so it needs a body from the start.

extension TableViewDragDropState: DragDropControllerDelegate {}

extension TableViewDragDropState: DragDropControllerDataSource {
    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            in destination: DragDropController) -> CGRect { .zero }
}
