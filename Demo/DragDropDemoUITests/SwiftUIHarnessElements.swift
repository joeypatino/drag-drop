import XCTest

extension XCTestCase {

    /// Launches straight into one SwiftUI harness configuration.
    @MainActor
    func launchHarness(_ configuration: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-swiftui", configuration]
        app.launch()
        return app
    }

    /// `ok`, `offset` or `covered`. See `HarnessLog.probe`.
    @MainActor
    func probe(in app: XCUIApplication) -> String {
        app.staticTexts["probe"].label
    }

    /// `drag(_:onto:)` with the release point chosen, for tests where the
    /// centre of the destination would hide an offset.
    @MainActor
    func drag(_ source: XCUIElement, onto destination: XCUIElement, at offset: CGVector) {
        source.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.25,
                   thenDragTo: destination.coordinate(withNormalizedOffset: offset),
                   withVelocity: .default,
                   thenHoldForDuration: 0.4)
    }

    /// Waits for a SwiftUI text to read exactly `expected`.
    @MainActor
    func waitForLabel(_ element: XCUIElement, _ expected: String, timeout: TimeInterval = 5,
                      file: StaticString = #filePath, line: UInt = #line) {
        let deadline = Date().addingTimeInterval(timeout)
        while element.label != expected, Date() < deadline {}
        XCTAssertEqual(element.label, expected, file: file, line: line)
    }
}
