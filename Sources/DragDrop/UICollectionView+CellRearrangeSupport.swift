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

                cellForItem(at: indexPath)?.frame = frame
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
        // forcing one here the collection view is left tracking *no* cells at
        // all -- visibleCells and indexPathsForVisibleItems both drop to zero
        // and stay there -- while the cells already on screen become orphaned
        // views UIKit no longer manages. They then keep stale content at stale
        // frames forever, and every further drag compounds it.
        layoutIfNeeded()

        // reloadItems restores cell *content* but does not re-apply layout
        // attributes over the frames the vacancy animations set by hand, so
        // cells are left sitting in each other's positions. invalidateLayout()
        // does not clear them either; assigning the layout frames directly
        // does, which is exactly what layoutCollectionView already exists to do.
        layoutCollectionView(animated: false, completion: nil)

        UIView.setAnimationsEnabled(true)
    }
}
