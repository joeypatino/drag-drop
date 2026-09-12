import XCTest

/// The two screens that used to be indistinguishable. What separates them is
/// which views receive a drop, so that is what these assert. How it is drawn is
/// covered by the screenshots in docs/media; whether the mid-drag states reach
/// the screen is a job for Tools/animation-trace, not for a UI test.
final class DropTargetLegibilityTests: XCTestCase {

    @MainActor
    private func state(_ identifier: String, in app: XCUIApplication) -> String {
        let element = container(identifier, in: app)
        XCTAssertTrue(element.waitForExistence(timeout: 5), "no \(identifier)")
        return element.value as? String ?? "none"
    }

    /// Target inside target: both boxes receive. This is the one the hand-set
    /// flag got wrong -- Camera Roll is a drop target and never declared it, so
    /// the screen claimed to have one receiving zone where it has two.
    @MainActor
    func testSharedAlbumHasATargetInsideATarget() {
        let app = launchDemo("TargetInsideTargetViewController")
        XCTAssertEqual(state("panel-roll", in: app), "receiving")
        XCTAssertEqual(state("panel-album", in: app), "receiving")
    }

    /// Target inside scenery: the stack and the gallery receive, and the phone
    /// frame holding the stack is not a panel at all, so it never reports a
    /// state. That absence is the difference from Shared Album.
    @MainActor
    func testWidgetComposerHasATargetInsideSomethingInert() {
        let app = launchDemo("TargetInsideNonTargetViewController")
        XCTAssertEqual(state("panel-stack", in: app), "receiving")
        XCTAssertEqual(state("panel-gallery", in: app), "receiving")
    }

    /// Lineup's targets are the grids, not the cards holding them, so these
    /// panels are marked only because the screen names its owning panel
    /// outright. Looking the owner up from the target would have missed them.
    @MainActor
    func testLineupPanelsReceiveThroughTheirGrids() {
        let app = launchDemo("CollectionSwapViewController")
        XCTAssertEqual(state("panel-starters", in: app), "receiving")
        XCTAssertEqual(state("panel-bench", in: app), "receiving")
    }

    /// Each screen states its own capability, so the two read differently
    /// before you touch anything at all.
    @MainActor
    func testEachScreenNamesWhatItProves() {
        let album = launchDemo("TargetInsideTargetViewController")
        XCTAssertEqual(album.staticTexts["demo-proposition"].label,
                       "A drop target inside a drop target")

        let widget = launchDemo("TargetInsideNonTargetViewController")
        XCTAssertEqual(widget.staticTexts["demo-proposition"].label,
                       "A target inset in a non-target container")
    }
}
