# Table views

Built on the [core API](dragging-views.md).

## Enabling it

Enable drag and drop per draggable view, which may be the whole `contentView` or
one subview of it:

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

## Row updates

Adopt `UITableViewDataSourceRowMoveSupport` on the datasource. Dragging a view
out of a row removes that row; dropping a view onto the table inserts one where
the finger is. You update your model and the library calls
`deleteRows`/`insertRows` around it:

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

Both are called *before* the row is deleted or inserted, so your model and the
table agree by the time UIKit asks for counts again. The name is `canDragRowAt`
rather than `canMoveRowAt` because `UITableViewDataSource` already declares the
latter for its reorder controls.

Moving a row between two table views is these two firing in turn, the source's
`didRemoveRowAt` then the destination's `didInsertRowAt`, connected through the
view you are handed. Releasing a view back over the table it came from reorders
instead, and needs no extra code.

## Limitations

While a drag hovers, the rows at and below the drop point slide down to show
where it will land. Those frames are set by hand and UIKit undoes them on its
next layout pass, so scrolling mid-drag closes the gap early.

`UITableViewDiffableDataSource` is not supported. The library calls
`deleteRows`/`insertRows`, which a diffable datasource does not expect.
