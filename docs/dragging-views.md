# Dragging views

The core API, independent of any UIKit collection type. For lists see
[collection views](collection-views.md) and [table views](table-views.md).

## Controllers

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

Controllers discover each other, so a view dragged out of one controller's
target and released over another's is handed across.

## Datasource

Only `frameFor:in:` is required; the rest have defaults.

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

    // Optional. Defaults to nil. See "Closing the gap".
    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            at index: Int) -> CGRect? { nil }
}
```

## Closing the gap

A view dragged out of a container leaves a hole. Implement `frameFor:at:` to
have the views left behind move up and fill it. Return the frame a view should
occupy as the `index`-th view in the controller's own drop target:

```swift
func dragDropController(_ controller: DragDropController,
                        frameFor view: UIView,
                        at index: Int) -> CGRect? {
    guard let dropTargetView = controller.dropTargetView else { return nil }
    return myLayout.frame(at: index, in: dropTargetView)
}
```

The views walked are `controller.draggableViews`, the drop target's subviews
that the controller enabled dragging for, so furniture such as a title label
stays put. Returning nil for any one view abandons the pass, so a partial answer
cannot pile views on top of each other.

Collection views need none of this. Their cells belong to UIKit and the
extension closes the gap through the layout.

## Delegate

`DragDropControllerDelegate` reports to the controller a drag started *from*:
`willStartDrag`, `didStartDrag`, `dragDidEnter`, `dragDidMove`, `dragDidExit`,
`willEndDrag`, `didEndDrag` and `didMove(_:to:)`.

Three more report to the controller a drag is happening *to*: `dragDidHover` and
`dragDidLeave` as it moves over a drop target, and `didReceive(_:from:)` when a
view is dropped into one. Use these when a drop target needs to show it is being
hovered. The source-side callbacks go to the *source* controller's delegate, and
for a drag beginning inside a table or collection view that source is the
controller the extension built for the scroll view, not your view controller.

Every method has a default no-op.

## Dragging from inside a scroll view

Inside a `UIScrollView`, `UITableView` or `UICollectionView` the gesture waits
0.12s before it begins, and fails if the touch moves first, so the scroll view
wins when the user means to scroll. A cell must be pressed and held briefly
before it can be dragged; a quick flick scrolls instead. Views outside a scroll
view drag immediately.

## Draggable views in a table view cell

Add them to the cell's `contentView`, not to the cell:

```swift
cell.contentView.addSubview(dragView)
controller.dropTargetView = cell.contentView
```

UIKit keeps `UITableViewCellContentView` above any view added directly to the
cell. Such a view still renders, because `contentView` is transparent, but
`contentView` intercepts every touch and the drag never starts.
