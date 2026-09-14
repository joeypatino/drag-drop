# Testing

The package scheme is `DragDrop-Package`: with two products, Swift Package
Manager generates a per-product scheme plus this umbrella one, and only the
umbrella runs the tests.

```
xcodebuild test -scheme DragDrop-Package -destination 'platform=iOS Simulator,name=iPhone 17'
xcodebuild test -scheme DragDrop-Package -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:DemoKitTests
xcodebuild test -project Demo/DragDropDemo.xcodeproj -scheme DragDropDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

`DemoKitTests` needs that second line: the generated `DragDrop-Package` scheme
runs only `DragDropTests`, so the first command silently skips it; naming
both bundles in one invocation does not help, only naming `DemoKitTests` alone
does.

UI tests assert on final state, so a bug in how something animated will pass
them. `Tools/animation-trace` covers that case; it proves what an animation
actually put on screen, frame by frame.

The GIFs and stills in `README.md` and `docs/demos.md` are generated rather
than captured by hand. `Tools/demo-media/regenerate.py` drives one existing UI
test per demo, records the simulator, and trims each clip down to the drag;
run it after anything that changes how a demo looks. Renaming or adding a demo
means updating its `DEMOS` map in the same commit, because that map is what
pairs each demo with the test that drags something on it.

The `SwiftUI*Tests` classes launch the demo app with `-swiftui <configuration>`,
which replaces the storyboard root with a hosting controller. The harness is
not in the demo index. Its configurations, and the argument for testing those
and not every demo, are listed in `HarnessConfiguration`.
