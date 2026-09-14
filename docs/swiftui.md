# SwiftUI

Built on the [core API](dragging-views.md).

The library is UIKit. Use it from SwiftUI by wrapping the views that drag and
receive drops in a `UIViewRepresentable`.

## Who owns what

Keep the controllers in the coordinator, and build and enable the draggable
views once, in `makeUIView`:

```swift
struct Board: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let target = UIView()
        let controller = DragDropController()
        controller.dropTargetView = target
        controller.dragDropDataSource = context.coordinator
        controller.dragDropDelegate = context.coordinator
        context.coordinator.controller = controller

        for item in items {
            let view = ItemView(item)
            target.addSubview(view)
            controller.enableDragAction(for: view)
        }
        return target
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
```

- **The coordinator holds the controller.** The library refers to controllers
  weakly, so a controller nothing else holds is gone before the first drag.
- **`updateUIView` leaves draggable views alone.** The library moves them
  between containers itself. Rebuilding them from your model there duplicates
  or loses views mid-drop.
- **Report drops outward.** Update SwiftUI state from `didMove`, `didReceive`,
  or your table and collection datasources. Re-rendering during a drag is fine.

Two representables find each other the same way two UIKit containers do, with
no wiring between them.

## What is tested

Drags work at a hosting root, between sibling representables, inside a sheet,
under a sheet that leaves the screen usable, inside `ScrollView` and `List`,
and with wrapped table and collection views. A drop never lands in a target
on a screen kept alive behind a `NavigationStack` push or on an unselected
`TabView` tab. Inside a scroll container a view must be held briefly before
it lifts, so a swipe still scrolls.

## Not supported

`scaleEffect` and `rotationEffect` on a representable: a picked-up view leaves
its transformed ancestor and changes size for the length of the drag.

If SwiftUI tears down and rebuilds the representable -- a `List` row scrolled
away and back, for example -- `makeUIView` runs again. Views and controllers
held only in the UIKit subtree are then created fresh, so keep the model in
your own state.
