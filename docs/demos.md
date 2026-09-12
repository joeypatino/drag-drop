# The demo screens

Seven screens, each built around one arrangement of drop targets. They exist to
exercise a specific capability of the library, so each entry below says what you
are looking at, what you can pick up, **which views actually receive a drop**,
and what that configuration proves.

The last of those is the one worth reading. Several screens look alike — a box
inside a box is a box inside a box — and what separates them is which of those
boxes is a drop target.

Launch any of them straight from the command line:

```
xcrun simctl launch <device> com.onitaps.Drag-Drop -demo <SegueIdentifier>
```

---

## Shift Rota

<img src="media/FourByFourViewController.png" width="300"> <img src="media/FourByFourViewController.gif" width="300">

**Layout.** Four equal panels in a 2×2 grid — Morning, Afternoon, Evening,
Night — each with its hours, a count badge, and a "No cover" placeholder when it
empties. Staff are circular initials chips.

**Draggable.** Every avatar chip, in any panel.

**Receives.** All four panels. They are peers: four separate controllers, none
inside another.

**What it tests.** That a drop can be *refused*. The datasource answers
`canDrop` with `controller !== destination`, so a person cannot be dropped back
onto the shift they are already on — the panel under the finger visibly stands
down rather than pretending it will accept. It is also the only screen with more
than two targets, so it exercises picking one destination out of several, and
the gap-closing reflow that runs in the panel a chip leaves.

**Identifier.** `FourByFourViewController`

---

## Shared Album

<img src="media/EmbeddedViewController.png" width="300"> <img src="media/EmbeddedViewController.gif" width="300">

**Layout.** One large "Camera Roll" panel holding a row of photo thumbnails,
and — starting below that row and filling the rest of the card — an "Iceland
2024" panel **inside it**.

**Draggable.** Every photo thumbnail, in either panel.

**Receives.** Both. The album's drop target is a subview of the roll's drop
target, so any point inside the album is inside *two* targets at once.

**What it tests.** Nested drop targets, and that the inner one wins. When two
targets overlap, the library picks the innermost by depth in the view hierarchy,
which is what makes a parent/child pair usable at all: without it the roll would
swallow every drop that landed anywhere in its bounds, and the album could never
receive anything.

The containment is the point of the screen. These two panels are not siblings
drawn close together — one really is inside the other, and photos still move
between them in both directions.

**Identifier.** `EmbeddedViewController`

---

## Widget Composer

<img src="media/DoubleEmbeddedViewController.png" width="300"> <img src="media/DoubleEmbeddedViewController.gif" width="300">

**Layout.** A decorative phone — wallpaper, rounded frame, a fake status bar —
with a "Widget Stack" panel inset inside it, and a "Widget Gallery" panel on the
ordinary background below.

**Draggable.** Every widget tile, in either panel.

**Receives.** The widget stack and the gallery. **The phone frame does not.** It
is scenery: it has no controller and no drop target, and holding a widget over
the wallpaper does nothing at all.

**What it tests.** That a drop target still works when it is buried inside a
container that knows nothing about dragging. The library has to translate the
drag's position down through that inert ancestor to decide what is under the
finger. Compare with Shared Album: there the outer box competes for the drop,
here the outer box is not in the running.

**Identifier.** `DoubleEmbeddedViewController`

---

## Files

<img src="media/EmbeddedDropTargetViewController.png" width="300"> <img src="media/EmbeddedDropTargetViewController.gif" width="300">

**Layout.** A "Downloads" panel of file tiles above, a "Documents" panel below,
and parked in the corner of Documents a larger "Projects" folder tile.

**Draggable.** Every file tile.

**Receives.** Downloads, Documents — and the **folder tile itself**, which is an
item and a drop target at the same time.

**What it tests.** That something item-sized can receive a drop. A file dropped
on the folder does not sit on top of it: it shrinks to a pip on the folder's own
2×2 grid and the folder's badge counts what it holds. Because the folder sits
inside Documents, this is also nested resolution at close quarters — the folder
is a 72pt square inside a full-width target, and the drop has to go to whichever
the finger is actually over.

**Identifier.** `EmbeddedDropTargetViewController`

---

## Up Next

<img src="media/NormalTableViewController.png" width="300"> <img src="media/NormalTableViewController.gif" width="300">

**Layout.** A play queue in a `UITableView` down the left, and a "Saved" panel
on the right.

**Draggable.** Every track row, and every card in Saved.

**Receives.** The table as a whole — not each cell — and the Saved panel. That
is what lets a card be dropped anywhere on the table and land in the row under
the finger.

**What it tests.** `UITableView` integration in both directions. Dragging a row
out removes it and closes the gap; dropping a card in inserts a row at the point
of the drop; dropping a row back on the table reorders it. While a drag hovers,
the table opens a gap under the finger the height of the row that will land
there, so the destination is visible before you let go.

**Identifier.** `NormalTableViewController`

---

## Moodboard

<img src="media/NormalCollectionViewController.png" width="300"> <img src="media/NormalCollectionViewController.gif" width="300">

**Layout.** One masonry grid of 300 colour cards. Heights vary but are seeded,
so a given position always gets the same height.

**Draggable.** Every card.

**Receives.** The collection view itself. One target, no nesting.

**What it tests.** Reordering inside a single `UICollectionView`, at a scale
where a wrong frame is obvious. The varied heights are deliberate: slots keep
their own height, so a card visibly resizes into whichever slot it is dragged
over, and any mistake in the layout maths shows up immediately instead of hiding
behind a uniform grid.

**Identifier.** `NormalCollectionViewController`

---

## Lineup

<img src="media/DoubleCollectionViewController.png" width="300"> <img src="media/DoubleCollectionViewController.gif" width="300">

**Layout.** Two titled cards side by side, "Starters" and "Bench", each wrapping
its own collection view of player tiles.

**Draggable.** Every player.

**Receives.** The two collection views. Note that the drop target is the
collection view, not the panel around it — the panel is chrome.

**What it tests.** Moving an item between two *separate* collection views, with
the destination allowed to refuse: the datasource returns
`!destination.contains(player)`, so a player already on the other list cannot be
moved there twice. Each side keeps its own datasource, and both counts update
when one crosses over.

**Identifier.** `DoubleCollectionViewController`

---

## At a glance

| Screen | Receives | Inert | Capability |
|---|---|---|---|
| Shift Rota | 4 peer panels | — | A drop can be refused |
| Shared Album | roll **and** album inside it | — | Nested targets; innermost wins |
| Widget Composer | stack, gallery | the phone frame | Reaching a target through a non-participating ancestor |
| Files | 2 panels **and** a folder item | — | An item that is itself a target |
| Up Next | the table, a panel | — | Table rows out and in, with a gap under the finger |
| Moodboard | one collection view | — | Reordering in place |
| Lineup | two collection views | the panels around them | Transfer between two collection views, refusable |
