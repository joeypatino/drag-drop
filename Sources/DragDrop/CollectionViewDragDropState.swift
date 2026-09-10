//
//  CollectionViewDragDropState.swift
//  DragDrop
//
//  Created by Joey Patino on 11/5/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit
import ObjectiveC.runtime

/// Holds everything the three UICollectionView extensions used to keep in eight
/// separate associated objects, and carries the DragDropController delegate and
/// datasource conformances.
///
/// In the Objective-C those conformances sat on UICollectionView itself, so
/// every collection view in the process retroactively conformed. Swift would
/// need @retroactive for that, and Apple discourages it, so the box conforms
/// instead. The method bodies are otherwise unchanged — `self` becomes
/// `collectionView`.
@MainActor
final class CollectionViewDragDropState {
    weak var collectionView: UICollectionView?

    var dragDropController: DragDropController?
    var isDragInCollectionView = false
    var isDroppingCell = false

    var cellRearrangeOrigin: IndexPath?
    var cellRearrangeDestination: IndexPath?
    var cellSwapOrigin: IndexPath?
    var cellSwapDestination: IndexPath?

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }
}

private enum AssociatedKeys {
    /// `&someGlobalVar` is no longer valid in Swift 6, so allocate a unique,
    /// never-freed address to use as the association key.
    nonisolated(unsafe) static let dragDropState =
        UnsafeRawPointer(UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1))
}

extension UICollectionView {
    /// Lazily created and then stable for the life of the collection view.
    var dragDropState: CollectionViewDragDropState {
        if let existing = objc_getAssociatedObject(self, AssociatedKeys.dragDropState)
            as? CollectionViewDragDropState {
            return existing
        }

        let state = CollectionViewDragDropState(collectionView: self)
        objc_setAssociatedObject(self, AssociatedKeys.dragDropState, state, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return state
    }
}
