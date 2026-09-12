# Collection views

Built on the [core API](dragging-views.md).

Collection views get drag and drop through an extension. Enable it per cell:

```swift
func collectionView(_ collectionView: UICollectionView,
                    willDisplay cell: UICollectionViewCell,
                    forItemAt indexPath: IndexPath) {
    collectionView.enableDragAndDrop(for: cell)
}
```

Reordering within one collection view uses `UICollectionViewDataSource`'s own
`collectionView(_:moveItemAt:to:)` and `collectionView(_:canMoveItemAt:)`.

Moving cells *between* two collection views needs
`UICollectionViewDataSourceCellSwapSupport`:

```swift
extension MyViewController: UICollectionViewDataSourceCellSwapSupport {
    func collectionView(_ collectionView: UICollectionView,
                        moveItemAt sourceIndexPath: IndexPath,
                        to destinationCollectionView: UICollectionView,
                        to destinationIndexPath: IndexPath) {
        // move the item between your two backing arrays
    }

    // Optional. Defaults to true. Return false to refuse a transfer.
    func collectionView(_ collectionView: UICollectionView,
                        canMoveItemAt indexPath: IndexPath,
                        to destinationCollectionView: UICollectionView,
                        to toIndexPath: IndexPath) -> Bool { true }
}
```

To show that a collection view is about to receive a cell from another one, set
`dropHighlight`. It is called with `true` when a drag from elsewhere arrives
over the view and `false` when it leaves; what that looks like is yours to
decide, and leaving it nil means no highlight.

```swift
collectionView.dropHighlight = { [weak card] accepting in
    card?.isHighlighted = accepting
}
```
