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
.package(url: "https://github.com/joeypatino/drag-drop.git", branch: "master")
```

Once a release is tagged, prefer the version form:

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

    // Optional. Defaults to nil. See "Closing the gap" below.
    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            at index: Int) -> CGRect? { nil }
}
```

### Closing the gap

Drag a view out of a container and it leaves a hole where it used to be. To have
the views left behind shuffle up and fill it, implement `frameFor:at:` — the
frame a view should occupy as the `index`-th view in the controller's own drop
target:

```swift
func dragDropController(_ controller: DragDropController,
                        frameFor view: UIView,
                        at index: Int) -> CGRect? {
    guard let dropTargetView = controller.dropTargetView else { return nil }
    return myLayout.frame(at: index, in: dropTargetView)
}
```

Once a view has been handed to another controller, the one it left walks the
views still in its drop target and moves each to the frame you return for its
new index, animated over `dropAnimationDuration`. The views it walks are
`controller.draggableViews` — the drop target's subviews that the controller
enabled dragging for, in subview order — so furniture like a title label is left
where it is.

The default returns nil, which leaves the remaining views alone. A nil for any
one view abandons the whole pass, so a partial answer cannot pile views on top
of each other.

Collection views need none of this: their cells belong to UIKit, and the
`UICollectionView` extension already closes the gap through the layout.

`DragDropControllerDelegate` reports the drag lifecycle to the controller a drag
started *from* — `willStartDrag`, `didStartDrag`, `dragDidEnter`, `dragDidMove`,
`dragDidExit`, `willEndDrag`, `didEndDrag` and `didMove(_:to:)`.

Three more report to the controller a drag is happening *to*: `dragDidHover` and
`dragDidLeave` as it moves over a drop target, and `didReceive(_:from:)` when a
view is dropped into one. They are what lets a drop target react to a drag it
did not itself start — which is how the table view extension below inserts a row
for a view dragged in from anywhere.

Every one has a default no-op, so implement only the ones you need.

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

## Table views

Table views get drag and drop through an extension. Enable it per draggable
view — the whole `contentView`, or one subview of it:

```swift
func tableView(_ tableView: UITableView,
               cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

    let dragView = UIView(frame: ...)
    cell.contentView.addSubview(dragView)
    tableView.enableDragAndDrop(for: dragView)

    return cell
}
```

Then adopt `UITableViewDataSourceRowMoveSupport` on the datasource. Dragging a
view out of a row removes that row and the table collapses; dropping a view onto
the table inserts a row where the finger is. You update your model, and the
library calls `deleteRows`/`insertRows` around it:

```swift
extension MyViewController: UITableViewDataSourceRowMoveSupport {

    func tableView(_ tableView: UITableView, didRemoveRowAt indexPath: IndexPath) {
        rows.remove(at: indexPath.row)
    }

    func tableView(_ tableView: UITableView,
                   didInsertRowAt indexPath: IndexPath,
                   for view: UIView) {
        rows.insert(Item(), at: indexPath.row)
    }

    // Optional. Defaults to true.
    func tableView(_ tableView: UITableView, canDragRowAt indexPath: IndexPath) -> Bool { true }
}
```

Both methods are called **before** the row is deleted or inserted, so your model
and the table agree by the time UIKit asks for counts again.

It is `canDragRowAt` rather than `canMoveRowAt` because `UITableViewDataSource`
already declares the latter for its reorder controls.

Moving a row between two table views is these two firing in turn — the source's
`didRemoveRowAt`, then the destination's `didInsertRowAt` — and you connect the
halves through the view you are handed. Releasing a view back over the table it
came from reorders instead, and needs no extra code.

While a drag hovers over a table, the rows at and below the drop point slide
down to show where it will land. Setting cell frames by hand is something UIKit
undoes on its next layout pass, so scrolling mid-drag closes that gap early; the
collection view extension has the same limitation, and the pickup delay
described above exists to keep scroll and drag apart in the first place.

`UITableViewDiffableDataSource` is not supported: the library calls
`deleteRows`/`insertRows`, which a diffable datasource does not expect.

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
