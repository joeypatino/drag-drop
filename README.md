# drag-drop

A flexible iOS drag and drop implementation written in Swift.

Requires iOS 26 and Swift 6.

<p>
<h2>Swapping cells between collection views</h2>
<img src=http://i.imgur.com/VjXb2Af.gif?1></img>
</p>

<p>
<h2>Reordering collection views cells</h2>
<img src=http://i.imgur.com/oPzGFnq.gif?1></img>
</p>

<p>
<h2>Drag and drop views</h2>
<img src=http://i.imgur.com/ku6YVMv.gif?1></img>
</p>

## Installation

Add the package in Xcode, or declare it as a dependency:

```swift
.package(url: "https://github.com/joeypatino/drag-drop.git", from: "1.0.0")
```

Then `import DragDrop`.

## Dragging views

A `DragDropController` manages the drag actions of the views you register with
it, and the drop actions inside its own `dropTargetView`. Create one per drop
target, then enable dragging on the views that should move.

```swift
let controller = DragDropController()
controller.dragDropDataSource = self
controller.dragDropDelegate = self
controller.dropTargetView = containerView

controller.enableDragAction(for: draggableView)
```

Controllers discover each other automatically, so a view dragged out of one
controller's target and released over another's is handed across.

The datasource decides where a dropped view lands. Only `frameFor:in:` is
required; the rest have sensible defaults.

```swift
extension MyViewController: DragDropControllerDataSource {
    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            in destination: DragDropController) -> CGRect {
        // where the view should end up, in the destination's coordinates
    }

    // Optional. Defaults to true.
    func dragDropController(_ controller: DragDropController,
                            shouldDrag view: UIView) -> Bool { true }

    // Optional. Defaults to true. `destination` is nil when the drag ends
    // outside every drop target.
    func dragDropController(_ controller: DragDropController,
                            canDrop view: UIView,
                            to destination: DragDropController?) -> Bool { true }
}
```

`DragDropControllerDelegate` reports the drag lifecycle — `willStartDrag`,
`didStartDrag`, `dragDidEnter`, `dragDidMove`, `dragDidExit`, `willEndDrag`,
`didEndDrag` and `didMove(_:to:)`. Every one has a default no-op, so implement
only the ones you need.

### Dragging from inside a scroll view

When a draggable view sits inside a `UIScrollView`, `UITableView` or
`UICollectionView`, the gesture waits `kDragPickupBeginDelay` (0.12s) before it
will begin, and fails if the touch moves first. This is deliberate: it lets the
scroll view win when the user actually means to scroll. In practice it means a
cell must be **pressed and held briefly** before it can be dragged — a quick
flick scrolls instead. Views outside a scroll view have no such delay and drag
immediately.

A consequence worth knowing when driving the library from a UI test: use
`press(forDuration:thenDragTo:withVelocity:thenHoldForDuration:)` with a press
longer than 0.12s. The short `press(forDuration:thenDragTo:)` form can register
as a scroll instead of a drag.

### Adding draggable views to a table view cell

Add them to the cell's `contentView`, not to the cell:

```swift
cell.contentView.addSubview(dragView)
controller.dropTargetView = cell.contentView
```

UIKit keeps `UITableViewCellContentView` above any view added directly to the
cell. Such a view still renders (contentView is transparent) but contentView
intercepts every touch, so the drag never starts.

## Collection views

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

## Demo

`Demo/DragDropDemo.xcodeproj` builds an app with seven examples: a 4x4 grid of
drop targets, embedded and doubly-embedded containers, an embedded drop target,
a table view, a collection view, and two collection views swapping cells.

```
open Demo/DragDropDemo.xcodeproj
```

## Tests

```
xcodebuild test -scheme DragDrop -destination 'platform=iOS Simulator,name=iPhone 17'
xcodebuild test -project Demo/DragDropDemo.xcodeproj -scheme DragDropDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## License

MIT. See [LICENSE](LICENSE).
