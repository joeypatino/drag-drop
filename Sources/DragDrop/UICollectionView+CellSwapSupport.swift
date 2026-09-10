//
//  UICollectionView+CellSwapSupport.swift
//  DragDrop
//
//  Created by Joey Patino on 11/17/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit

/// Ported from UICollectionViewDataSource_CellSwapSupport. `respondsToSelector:`
/// against it becomes a conditional cast at the call sites.
@MainActor
public protocol UICollectionViewDataSourceCellSwapSupport: UICollectionViewDataSource {

    /// Was @optional. Defaults to true.
    func collectionView(_ sourceCollectionView: UICollectionView,
                        canMoveItemAt sourceIndexPath: IndexPath,
                        to destinationCollectionView: UICollectionView,
                        to destinationIndexPath: IndexPath) -> Bool

    /// Was @required.
    func collectionView(_ collectionView: UICollectionView,
                        moveItemAt sourceIndexPath: IndexPath,
                        to destinationCollectionView: UICollectionView,
                        to destinationIndexPath: IndexPath)
}

public extension UICollectionViewDataSourceCellSwapSupport {
    func collectionView(_ sourceCollectionView: UICollectionView,
                        canMoveItemAt sourceIndexPath: IndexPath,
                        to destinationCollectionView: UICollectionView,
                        to destinationIndexPath: IndexPath) -> Bool { true }
}

public extension UICollectionView {

    var cellSwapOrigin: IndexPath? {
        get { dragDropState.cellSwapOrigin }
        set { dragDropState.cellSwapOrigin = newValue }
    }

    var cellSwapDestination: IndexPath? {
        get { dragDropState.cellSwapDestination }
        set { dragDropState.cellSwapDestination = newValue }
    }

    // MARK: -

    func startCellSwap(from fromIndexPath: IndexPath?,
                       in collectionView: UICollectionView,
                       to location: CGPoint) {
        DLog()

        cellSwapDestination = indexPath(at: location)
        cellSwapOrigin = cellSwapDestination

        if let fromIndexPath, let destination = cellSwapDestination,
           collectionView.canMoveIndexPath(fromIndexPath, to: destination, withDestination: self) {
            collectionView.moveIndexPath(fromIndexPath, to: destination, withDestination: self)

            insertVacancy(at: destination, animated: true)
        } else {
            resetAfterSwap()
        }
    }

    func continueCellSwap(_ location: CGPoint) {
        if cellSwapDestination == nil && cellSwapOrigin == nil { return }

        cellSwapDestination = indexPath(at: location)

        if cellSwapOrigin?.isSame(as: cellSwapDestination ?? IndexPath(row: -1, section: -1)) != true {

            var canMove = true
            if let origin = cellSwapOrigin {
                canMove = dataSource?.collectionView?(self, canMoveItemAt: origin) ?? true
            }

            if canMove, let origin = cellSwapOrigin, let destination = cellSwapDestination {
                dataSource?.collectionView?(self, moveItemAt: origin, to: destination)
            }

            if let destination = cellSwapDestination {
                insertVacancy(at: destination, animated: true)
            }
        }

        cellSwapOrigin = cellSwapDestination
    }

    func reverseCellSwap(from fromIndexPath: IndexPath?, in collectionView: UICollectionView) {
        DLog()
        if cellSwapDestination == nil && cellSwapOrigin == nil { return }

        layoutCollectionView(animated: true, completion: nil)

        if let origin = cellSwapOrigin, let fromIndexPath,
           canMoveIndexPath(origin, to: fromIndexPath, withDestination: collectionView) {
            moveIndexPath(origin, to: fromIndexPath, withDestination: collectionView)
        }
    }

    // MARK: -

    func insertCell(at indexPath: IndexPath?) {
        DLog()
        guard let indexPath else { return }

        UIView.setAnimationsEnabled(false)
        insertItems(at: [indexPath])
        reloadItems(at: indexPathsForVisibleItems)
        UIView.setAnimationsEnabled(true)

        resetAfterSwap()
    }

    func deleteCell(at indexPath: IndexPath?) {
        guard let indexPath else { return }

        UIView.setAnimationsEnabled(false)
        deleteItems(at: [indexPath])
        reloadItems(at: indexPathsForVisibleItems)
        UIView.setAnimationsEnabled(true)
    }

    // MARK: -

    internal func resetAfterSwap() {
        DLog()

        cellSwapOrigin = nil
        cellSwapDestination = nil
    }

    // MARK: - Cell Rearrangement

    func shouldAcceptCellSwap(from source: UICollectionView) -> Bool {
        DLog()
        return cellSwapOrigin != nil && cellSwapDestination != nil
    }

    /// Future support for selective cell swaps...
    internal func canMoveIndexPath(_ fromIndexPath: IndexPath,
                                   to toIndexPath: IndexPath,
                                   withDestination destination: UICollectionView) -> Bool {

        guard let dataSource = destination.dataSource as? any UICollectionViewDataSourceCellSwapSupport else {
            return true
        }

        return dataSource.collectionView(self, canMoveItemAt: fromIndexPath,
                                         to: destination, to: toIndexPath)
    }

    internal func moveIndexPath(_ fromIndexPath: IndexPath,
                                to toIndexPath: IndexPath,
                                withDestination destination: UICollectionView) {

        guard let dataSource = self.dataSource as? any UICollectionViewDataSourceCellSwapSupport else {
            return
        }

        dataSource.collectionView(self, moveItemAt: fromIndexPath,
                                  to: destination, to: toIndexPath)
    }

    internal func insertVacancy(at toIndexPath: IndexPath, animated: Bool) {
        DLog()

        UIView.animate(withDuration: animated ? 0.3 : 0.0) { [self] in

            for indexPath in indexPathsForVisibleItems {

                var frame = frameForItem(at: indexPath)

                if indexPath.isAfter(toIndexPath) || indexPath.isSame(as: toIndexPath) {
                    frame = frameForItem(at: indexPath.incrementingRow)
                }

                cellForItem(at: indexPath)?.frame = frame
            }
        }
    }

    func layoutCollectionView(animated: Bool, completion: (() -> Void)?) {
        DLog()

        UIView.animate(withDuration: animated ? 0.3 : 0.0) { [self] in

            for indexPath in indexPathsForVisibleItems {
                cellForItem(at: indexPath)?.frame = frameForItem(at: indexPath)
            }

        } completion: { _ in
            completion?()
        }
    }

    // MARK: - Helpers

    internal func indexPath(at location: CGPoint) -> IndexPath? {
        indexPathForItem(at: location) ?? findClosestIndexPath(to: location)
    }

    internal func findClosestIndexPath(to touchLocation: CGPoint) -> IndexPath? {

        let collectionViewIndexPaths = indexPathsForVisibleItems.sorted { $0.compare($1) == .orderedAscending }

        var distanceToNearestIndexPath = CGFloat.greatestFiniteMagnitude
        var locationIsBelowVisibleCells = true
        var nearestIndexPath: IndexPath?

        let pointIsBelowFrame: (CGPoint, CGRect) -> Bool = { point, rect in
            point.y <= rect.maxY
        }

        let pointIsToTheRightOfFrame: (CGPoint, CGRect) -> Bool = { point, rect in
            point.x >= rect.maxX
        }

        for indexPath in collectionViewIndexPaths {
            guard let cellLayoutAttributes = collectionViewLayout.layoutAttributesForItem(at: indexPath) else {
                continue
            }
            let distanceToCell = distance(touchLocation, cellLayoutAttributes.center)

            if pointIsBelowFrame(touchLocation, cellLayoutAttributes.frame) {
                locationIsBelowVisibleCells = false
            }

            if collectionViewIndexPaths.last == indexPath
                && pointIsToTheRightOfFrame(touchLocation, cellLayoutAttributes.frame) {
                locationIsBelowVisibleCells = true
            }

            if distanceToCell < distanceToNearestIndexPath {
                distanceToNearestIndexPath = distanceToCell
                nearestIndexPath = indexPath
            }
        }

        if locationIsBelowVisibleCells {

            var section = 0
            var row = 0

            if let nearestIndexPath {
                section = nearestIndexPath.section
                row = (dataSource?.collectionView(self, numberOfItemsInSection: section) ?? 1) - 1
            }

            nearestIndexPath = IndexPath(row: row, section: section)
        }

        return nearestIndexPath
    }

    internal func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }
}
