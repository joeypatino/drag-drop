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
runs only `DragDropTests`, so the first command silently skips it — and naming
both bundles in one invocation does not help, only naming `DemoKitTests` alone
does.

Before adding a UI test, read
[WRITING-UI-TESTS.md](../Demo/DragDropDemoUITests/WRITING-UI-TESTS.md): which delay
to use and why that number, what makes a query expensive, and what a UI test
cannot see. `Tools/animation-trace` covers the last of those — proving what an
animation actually put on screen, frame by frame.
