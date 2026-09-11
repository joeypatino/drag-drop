//
//  UICollectionView+CellRearrangeSupport.swift
//  DragDrop
//
//  Created by Joey Patino on 11/17/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit

private func CGRectReplaceSize(_ rect: CGRect, _ size: CGSize) -> CGRect {
    CGRect(x: rect.minX, y: rect.minY, width: size.width, height: size.height)
}

public extension UICollectionView {

    var cellRearrangeOrigin: IndexPath? {
        get { dragDropState.cellRearrangeOrigin }
        set { dragDropState.cellRearrangeOrigin = newValue }
    }

    var cellRearrangeDestination: IndexPath? {
        get { dragDropState.cellRearrangeDestination }
        set { dragDropState.cellRearrangeDestination = newValue }
    }

    // MARK: -

    func startCellRearrangement(_ location: CGPoint) {
        DLog()

        if cellRearrangeOrigin == nil {
            cellRearrangeOrigin = indexPathForItem(at: location)
        }

        if cellRearrangeDestination == nil {
            cellRearrangeDestination = indexPathForItem(at: location)
        }

        createVacancyForMovement(from: cellRearrangeOrigin,
                                 to: cellRearrangeDestination,
                                 animated: true, completion: nil)
    }

    func continueCellRearrangement(_ location: CGPoint) {

        guard let toIndexPath = indexPathForItem(at: location) else { return }

        if cellRearrangeDestination?.isSame(as: toIndexPath) != true {

            if let destination = cellRearrangeDestination {
                dataSource?.collectionView?(self, moveItemAt: destination, to: toIndexPath)
            }

            createVacancyForMovement(from: cellRearrangeOrigin,
                                     to: toIndexPath,
                                     animated: true, completion: nil)
        }

        cellRearrangeDestination = toIndexPath
    }

    func stopCellRearrangement() {
        DLog()

        removeVacancy(at: cellRearrangeOrigin, animated: true)
    }

    func finishCellRearrangement() {
        DLog()

        let canMove = true
        //     if ([self.dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)])
        //         canMove = [self.dataSource collectionView:self canMoveItemAtIndexPath:self.cellRearrangeDestination];

        if canMove { return resetAfterRearrange() }
    }

    func cancelCellRearrangement() {
        DLog()

        createVacancyForMovement(from: cellRearrangeOrigin,
                                 to: cellRearrangeOrigin,
                                 animated: true) { [self] in

            if let destination = cellRearrangeDestination, let origin = cellRearrangeOrigin {
                dataSource?.collectionView?(self, moveItemAt: destination, to: origin)
            }

            resetAfterRearrange()
        }
    }

    // MARK: -

    /// Objective-C nil-messaging turned a missing layout attribute into
    /// CGRectZero. Stating that once here keeps every call site consistent and
    /// stops Swift from trapping on an out-of-range index path.
    internal func frameForItem(at indexPath: IndexPath) -> CGRect {
        collectionViewLayout.layoutAttributesForItem(at: indexPath)?.frame ?? .zero
    }

    internal func sizeForItem(at indexPath: IndexPath) -> CGSize {
        collectionViewLayout.layoutAttributesForItem(at: indexPath)?.size ?? .zero
    }

    // MARK: -

    internal func createVacancyForMovement(from fromIndexPath: IndexPath?,
                                           to toIndexPath: IndexPath?,
                                           animated: Bool,
                                           completion: (() -> Void)?) {

        UIView.animate(withDuration: animated ? 0.3 : 0.0) { [self] in

            for indexPath in indexPathsForVisibleItems {

                var frame = frameForItem(at: indexPath)
                let cell = cellForItem(at: indexPath)

                if let fromIndexPath, indexPath.isSame(as: fromIndexPath) {
                    guard let cell, let toIndexPath else { continue }
                    let size = sizeForItem(at: toIndexPath)
                    frame = CGRectReplaceSize(cell.frame, size)
                } else if let fromIndexPath, let toIndexPath,
                          indexPath.isBetween(fromIndexPath, and: toIndexPath) {
                    frame = frameForItem(at: indexPath.decrementingRow)
                } else if let fromIndexPath, let toIndexPath,
                          indexPath.isBetween(toIndexPath, and: fromIndexPath) {
                    frame = frameForItem(at: indexPath.incrementingRow)
                } else if let toIndexPath, indexPath.isSame(as: toIndexPath) {
                    if let fromIndexPath, toIndexPath.isBefore(fromIndexPath) {
                        frame = frameForItem(at: indexPath.incrementingRow)
                    } else if let fromIndexPath, toIndexPath.isAfter(fromIndexPath) {
                        frame = frameForItem(at: indexPath.decrementingRow)
                    }
                }

                cell?.frame = frame

                // A cell lays its contentView out in layoutSubviews, which
                // would otherwise run after this block and snap the contents to
                // their new size while the cell itself tweened. Anything the
                // cell actually draws with is in there, so without this the
                // resize is invisible: the only thing animating is an empty
                // container. Forcing the pass inside the block puts the
                // contents on the same curve.
                cell?.layoutIfNeeded()
            }

        } completion: { _ in
            completion?()
        }
    }

    internal func removeVacancy(at fromIndexPath: IndexPath?, animated: Bool) {
        DLog()

        UIView.animate(withDuration: animated ? 0.3 : 0.0) { [self] in

            for indexPath in indexPathsForVisibleItems {

                // do not adjust the cell that is being moved..
                if let fromIndexPath, indexPath.isSame(as: fromIndexPath) { continue }

                var frame = frameForItem(at: indexPath)

                // if this cell is after/below our cell being moved, then move the cell "up"
                // one indexpath so that the "gap" is closed..
                if let fromIndexPath, indexPath.isAfter(fromIndexPath) {
                    frame = frameForItem(at: indexPath.decrementingRow)
                }

                // Closing the gap moves a cell into a slot that may be a
                // different size, so the contents have to be laid out inside
                // the block here too.
                let cell = cellForItem(at: indexPath)
                cell?.frame = frame
                cell?.layoutIfNeeded()
            }
        }
    }

    // MARK: -

    internal func resetAfterRearrange() {
        DLog()

        cellRearrangeOrigin = nil
        cellRearrangeDestination = nil

        UIView.setAnimationsEnabled(false)
        reloadItems(at: indexPathsForVisibleItems)

        // reloadItems defers cell creation to the next layout pass. Without
        // forcing one the collection view is left tracking no cells at all and
        // everything on screen becomes an orphaned view it no longer manages.
        layoutIfNeeded()

        UIView.setAnimationsEnabled(true)
    }
}
