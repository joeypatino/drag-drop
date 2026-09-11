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
