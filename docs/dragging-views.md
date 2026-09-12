# Dragging views

The core API, independent of any UIKit collection type. For lists see
[collection views](collection-views.md) and [table views](table-views.md).

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

## Closing the gap

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
did not itself start — which is how the [table view extension](table-views.md) inserts a row
for a view dragged in from anywhere.

Reach for those three whenever a drop target needs to show it is being hovered.
The source-side `dragDidEnter` and `dragDidExit` go to the *source* controller's
delegate, and when a drag begins inside a table or collection view that source
is the controller the extension built for the scroll view — not your view
controller — so a drop target that only implements the source-side callbacks
gets no hover feedback for a row dragged out of a list.

Every one has a default no-op, so implement only the ones you need.

## Dragging from inside a scroll view

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

## Adding draggable views to a table view cell

Add them to the cell's `contentView`, not to the cell:

```swift
cell.contentView.addSubview(dragView)
controller.dropTargetView = cell.contentView
```

UIKit keeps `UITableViewCellContentView` above any view added directly to the
cell. Such a view still renders (contentView is transparent) but contentView
intercepts every touch, so the drag never starts.
