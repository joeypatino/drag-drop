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
