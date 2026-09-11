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
