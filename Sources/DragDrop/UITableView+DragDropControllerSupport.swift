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

// MARK: - DragDropController Delegate

extension TableViewDragDropState: DragDropControllerDelegate {

    func dragDropController(_ controller: DragDropController,
                            willStartDrag drag: DragAction,
                            animated: Bool) {
        DLog()

        // The controller has already reparented the dragged view into the
        // interaction view, so `drag.sourceView` is the only way back to the
        // cell it came from.
        sourceIndexPath = indexPath(forDragStartingIn: drag.sourceView)
    }

    // The hover pair rather than dragDidEnter/dragDidMove/dragDidExit: those
    // report to the controller a drag started *from*, and a table has to react
    // to drags it did not start. Implementing both families would also run the
    // vacancy twice per move whenever a table is its own destination.

    func dragDropController(_ controller: DragDropController,
                            dragDidHover drag: DragAction,
                            from source: DragDropController) {
        guard let tableView, let view = drag.view else { return }

        let target = tableView.indexPath(at: drag.currentLocation)
        let height = tableView.vacancyHeight(for: target, draggedView: view)

        vacancyIndexPath = target
        vacancyHeight = height

        tableView.openVacancy(at: target, height: height, animated: true)
    }

    func dragDropController(_ controller: DragDropController,
                            dragDidLeave drag: DragAction,
                            from source: DragDropController) {
        DLog()
        guard let tableView else { return }

        // The gap closes, but where it was is deliberately kept. `endDrag`
        // sends this leave from its animation completion *before* it hands the
        // view over, so a drop on this table arrives at `didReceive` just after
        // its own leave -- and the target recorded by the last hover is exactly
        // the row the drop belongs in. Clearing here would lose it every time.
        // The two callbacks that consume it clear it instead.
        tableView.closeVacancy(animated: true)
    }

    func dragDropController(_ controller: DragDropController,
                            didMove view: UIView,
                            to destination: DragDropController) {
        DLog()
        guard let tableView, let source = sourceIndexPath else { return }

        sourceIndexPath = nil

        // Released back over the table it came from: a reorder, and the one
        // case where both halves belong to the same table. Handled here so the
        // two row updates can share one animation; `didReceive` stays out of it.
        if destination === controller {
            guard let target = vacancyIndexPath else { return }

            tableView.moveRow(from: source, to: target, for: view)
            clearVacancy()
            return
        }

        // Dropped anywhere else, table or not: this table only loses a row. A
        // destination that is a table inserts its own in `didReceive`.
        tableView.removeRow(at: source)
    }

    func dragDropController(_ controller: DragDropController,
                            didReceive view: UIView,
                            from source: DragDropController) {
        DLog()
        guard source !== controller else { return }
        guard let tableView, let target = vacancyIndexPath else { return }

        // `completeDrop` added the dragged view as a raw subview of the table.
        // That is right for a plain drop target and wrong for a table, which
        // renders its own rows -- left there the view floats over the real
        // cells. The same correction the collection view extension makes.
        view.removeFromSuperview()

        clearVacancy()
        tableView.insertRow(at: target, for: view)
    }
}

// MARK: - DragDropController Datasource

extension TableViewDragDropState: DragDropControllerDataSource {

    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            in destination: DragDropController) -> CGRect {

        // `endDrag` asks the destination's own datasource, so this is only ever
        // reached for a table destination. Anything else is not ours to answer.
        guard let destinationTable = destination.dropTargetView as? UITableView,
              let target = destinationTable.dragDropState.vacancyIndexPath else { return .zero }

        return destinationTable.rectForRow(arrivingAt: target,
                                           height: destinationTable.dragDropState.vacancyHeight)
    }

    func dragDropController(_ controller: DragDropController, shouldDrag view: UIView) -> Bool {

        // Called before the view is reparented, so its superview is still the
        // cell it belongs to.
        guard let tableView,
              let indexPath = indexPath(forDragStartingIn: view.superview),
              let dataSource = tableView.rowMoveDataSource else { return true }

        return dataSource.tableView(tableView, canDragRowAt: indexPath)
    }

    // `frameFor:at:` deliberately takes its nil default. That hook re-flows the
    // views inside a plain drop target; a table's rows are UIKit's to place.
}
