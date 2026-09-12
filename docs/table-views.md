# Table views

Built on the [core API](dragging-views.md).

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
collection view extension has the same limitation, and the [pickup delay](dragging-views.md#dragging-from-inside-a-scroll-view)
exists to keep scroll and drag apart in the first place.

`UITableViewDiffableDataSource` is not supported: the library calls
`deleteRows`/`insertRows`, which a diffable datasource does not expect.
