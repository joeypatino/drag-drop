//
//  UICollectionView+DragDropControllerSupport.swift
//  DragDrop
//
//  Created by Joey Patino on 11/5/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit

public extension UICollectionView {

    internal var dragDropController: DragDropController? {
        get { dragDropState.dragDropController }
        set { dragDropState.dragDropController = newValue }
    }

    internal var isDragInCollectionView: Bool {
        get { dragDropState.isDragInCollectionView }
        set { dragDropState.isDragInCollectionView = newValue }
    }

    internal var isDroppingCell: Bool {
        get { dragDropState.isDroppingCell }
        set { dragDropState.isDroppingCell = newValue }
    }

    // MARK: -

    func enableDragAndDrop(for cell: UICollectionViewCell) {
        if dragDropController == nil { dragDropController = controller() }

        dragDropController?.disableDragAction(for: cell)
        dragDropController?.enableDragAction(for: cell)
    }

    func disableDragAndDrop(for cell: UICollectionViewCell) {
        dragDropController?.disableDragAction(for: cell)
    }

    // MARK: -

    private func controller() -> DragDropController {
        let controller = DragDropController()
        controller.dropTargetView = self
        controller.dragDropDataSource = dragDropState
        controller.dragDropDelegate = dragDropState

        return controller
    }

    internal func dragDropCollectionView(_ controller: DragDropController) -> UICollectionView? {
        controller.dropTargetView as? UICollectionView
    }

    // MARK: -

    internal func startedDragging(in collectionView: UICollectionView?, at point: CGPoint) {
        isDragInCollectionView = true

        guard let collectionView else { return }

        if self === collectionView {
            return startCellRearrangement(point)
        }

        collectionView.startCellSwap(from: cellRearrangeDestination,
                                     in: self,
                                     to: point)

        collectionView.layer.borderColor = UIColor.red.cgColor
        collectionView.layer.borderWidth = 2.0
    }

    internal func isDragging(in collectionView: UICollectionView?, at point: CGPoint) {
        guard let collectionView else { return }

        if self === collectionView {
            return continueCellRearrangement(point)
        }

        collectionView.continueCellSwap(point)
    }

    internal func endedDragging(in collectionView: UICollectionView?, at point: CGPoint) {
        isDragInCollectionView = false

        guard let collectionView else { return }

        if self === collectionView {

            if isDroppingCell { finishCellRearrangement() } else { stopCellRearrangement() }
        } else {

            // when the drag exits the current destination, cancel the swap by
            // reversing any previous swap
            if !isDroppingCell {
                collectionView.reverseCellSwap(from: cellRearrangeDestination, in: self)
            }

            collectionView.layer.borderColor = UIColor.clear.cgColor
            collectionView.layer.borderWidth = 0.0
        }
    }

    internal func shouldRearrange(_ cell: UICollectionViewCell) -> Bool {

        // do not rearrange if our datasource disallows it
        if let indexPath = indexPath(for: cell) {
            return dataSource?.collectionView?(self, canMoveItemAt: indexPath) ?? true
        }

        return true
    }

    internal func didMoveCell(to collectionView: UICollectionView?) {
        guard let collectionView, self !== collectionView else { return }

        // on successful cell transfer, delete the cell from it's
        // final destination in self (the last known location), and
        // then reset after rearrangement..
        deleteCell(at: cellRearrangeDestination)
        finishCellRearrangement()

        // after successful cell transfer in the destination, insert the cell at
        // the final destination (the last known location), and then
        // then reset after the rearrangement..
        collectionView.insertCell(at: collectionView.cellSwapDestination)
        collectionView.finishCellRearrangement()
    }

    internal func didNotAcceptCellSwap(from source: UICollectionView) {

        // on failure to transfer a cell to a different destination,
        // relayout the collectionview, and then cancel any cell
        // rearrangements that may have been made..
        layoutCollectionView(animated: true) { [self] in
            cancelCellRearrangement()
            source.cancelCellRearrangement()
        }
    }
}

// MARK: - DragDropController Delegate

extension CollectionViewDragDropState: DragDropControllerDelegate {

    func dragDropController(_ controller: DragDropController,
                            willStartDrag drag: DragAction,
                            animated: Bool) {
        DLog()
    }

    func dragDropController(_ controller: DragDropController,
                            didStartDrag drag: DragAction) {
        DLog()
    }

    func dragDropController(_ controller: DragDropController,
                            willEndDrag drag: DragAction,
                            animated: Bool) {
        DLog()
        guard let collectionView else { return }
        collectionView.isDroppingCell = true

        // if we ended the drag outside of any valid dragDropController,
        // then we should cancel any rearrangements that were
        // previously made.
        if !collectionView.isDragInCollectionView {
            collectionView.cancelCellRearrangement()
        }
    }

    func dragDropController(_ controller: DragDropController,
                            didEndDrag drag: DragAction) {
        DLog()
        collectionView?.isDroppingCell = false
    }

    // MARK: -

    func dragDropController(_ controller: DragDropController,
                            dragDidEnter drag: DragAction,
                            destinationController destination: DragDropController) {
        DLog()
        guard let collectionView else { return }

        collectionView.startedDragging(in: collectionView.dragDropCollectionView(destination),
                                       at: drag.currentLocation)
    }

    func dragDropController(_ controller: DragDropController,
                            dragDidMove drag: DragAction,
                            destinationController destination: DragDropController) {
        guard let collectionView else { return }

        collectionView.isDragging(in: collectionView.dragDropCollectionView(destination),
                                  at: drag.currentLocation)
    }

    func dragDropController(_ controller: DragDropController,
                            dragDidExit drag: DragAction,
                            destinationController destination: DragDropController) {
        DLog()
        guard let collectionView else { return }

        collectionView.endedDragging(in: collectionView.dragDropCollectionView(destination),
                                     at: drag.currentLocation)
    }

    // MARK: -

    func dragDropController(_ controller: DragDropController,
                            didMove view: UIView,
                            to destination: DragDropController) {
        DLog()
        guard let collectionView else { return }

        collectionView.didMoveCell(to: collectionView.dragDropCollectionView(destination))
    }
}

// MARK: - DragDropController Datasource

extension CollectionViewDragDropState: DragDropControllerDataSource {

    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            in destination: DragDropController) -> CGRect {
        DLog()
        guard let collectionView else { return .zero }

        let targetCollectionView: UICollectionView?
        let indexPath: IndexPath?

        if controller !== destination {
            targetCollectionView = collectionView.dragDropCollectionView(destination)
            indexPath = targetCollectionView?.cellSwapDestination
        } else {
            targetCollectionView = collectionView.dragDropCollectionView(controller)
            indexPath = collectionView.cellRearrangeDestination
        }

        guard let targetCollectionView, let indexPath else { return .zero }

        return targetCollectionView.frameForItem(at: indexPath)
    }

    func dragDropController(_ controller: DragDropController,
                            shouldDrag view: UIView) -> Bool {
        guard let collectionView, let cell = view as? UICollectionViewCell else { return true }
        return collectionView.shouldRearrange(cell)
    }

    func dragDropController(_ controller: DragDropController,
                            canDrop view: UIView,
                            to destination: DragDropController?) -> Bool {
        if controller === destination { return true }
        guard let collectionView, let destination,
              let destinationCollectionView = collectionView.dragDropCollectionView(destination) else {
            return true
        }

        let canDrop = destinationCollectionView.shouldAcceptCellSwap(from: collectionView)

        if !canDrop {
            destinationCollectionView.didNotAcceptCellSwap(from: collectionView)
        }

        return canDrop
    }
}
