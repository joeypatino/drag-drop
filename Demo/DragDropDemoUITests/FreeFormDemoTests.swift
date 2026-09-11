import XCTest

/// The four free-form screens: the rota's four peer targets, the album's
/// nested target, the composer's target inside a non-target, and the Files
/// folder that is itself a target.
final class FreeFormDemoTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - Shift Rota

    @MainActor
    func testMovingSomeoneBetweenShiftsUpdatesBothPanels() {
        let app = launchDemo("FourByFourViewController")

        let morning = app.otherElements["panel-morning"]
        let night = app.otherElements["panel-night"]
        XCTAssertTrue(morning.waitForExistence(timeout: 5))

        let before = identifiers(withPrefix: "staff-", inside: morning, of: app)
        XCTAssertEqual(before.count, 5, "Morning starts with five")
        XCTAssertEqual(identifiers(withPrefix: "staff-", inside: night, of: app).count, 6)

        let moved = before[0]
        drag(app.otherElements[moved], onto: night)
        attachScreenshot(app, "rota-after-move")

        let morningAfter = identifiers(withPrefix: "staff-", inside: morning, of: app)
        XCTAssertFalse(morningAfter.contains(moved), "\(moved) should have left Morning")
        XCTAssertEqual(morningAfter.count, 4)
        XCTAssertTrue(identifiers(withPrefix: "staff-", inside: night, of: app).contains(moved),
                      "\(moved) should be on Night")
    }

    @MainActor
    func testTheSurvivorsCloseTheGapLeftBehind() {
        let app = launchDemo("FourByFourViewController")

        let morning = app.otherElements["panel-morning"]
        XCTAssertTrue(morning.waitForExistence(timeout: 5))

        let before = identifiers(withPrefix: "staff-", inside: morning, of: app)
        let firstSlot = app.otherElements[before[0]].frame

        drag(app.otherElements[before[0]], onto: app.otherElements["panel-night"])
        attachScreenshot(app, "rota-after-gap-close")

        let after = identifiers(withPrefix: "staff-", inside: morning, of: app)
        XCTAssertEqual(after, Array(before.dropFirst()),
                       "The order of the survivors should not change")
        XCTAssertEqual(app.otherElements[after[0]].frame, firstSlot,
                       "The next person should move up into the vacated slot")
    }

    // MARK: - Shared Album

    @MainActor
    func testAPhotoMovesIntoTheNestedAlbum() {
        let app = launchDemo("EmbeddedViewController")

        let album = app.otherElements["panel-album"]
        let roll = app.otherElements["panel-roll"]
        XCTAssertTrue(album.waitForExistence(timeout: 5))

        let inAlbum = identifiers(withPrefix: "photo-", inside: album, of: app)
        XCTAssertEqual(inAlbum.count, 3, "The album starts with three")

        // A photo from the roll, which means one not already in the album.
        let inRoll = identifiers(withPrefix: "photo-", inside: roll, of: app)
            .filter { !inAlbum.contains($0) }
        XCTAssertFalse(inRoll.isEmpty, "The roll should hold photos of its own")

        let moved = inRoll[0]
        drag(app.otherElements[moved], onto: album)
        attachScreenshot(app, "album-after-drop")

        XCTAssertTrue(identifiers(withPrefix: "photo-", inside: album, of: app).contains(moved),
                      "\(moved) should now be in the album")
    }

    // MARK: - Widget Composer

    @MainActor
    func testAWidgetDropsIntoTheStackInsideTheDecorativeFrame() {
        let app = launchDemo("DoubleEmbeddedViewController")

        let stack = app.otherElements["panel-stack"]
        let gallery = app.otherElements["panel-gallery"]
        XCTAssertTrue(stack.waitForExistence(timeout: 5))

        let onStack = identifiers(withPrefix: "widget-", inside: stack, of: app)
        XCTAssertEqual(onStack.count, 3)

        let inGallery = identifiers(withPrefix: "widget-", inside: gallery, of: app)
            .filter { !onStack.contains($0) }
        let moved = inGallery[0]

        drag(app.otherElements[moved], onto: stack)
        attachScreenshot(app, "widgets-after-drop")

        let after = identifiers(withPrefix: "widget-", inside: stack, of: app)
        XCTAssertTrue(after.contains(moved),
                      "\(moved) should land on the stack despite the phone frame between them")
        XCTAssertEqual(after.count, 4)
    }

    // MARK: - Files

    @MainActor
    func testDroppingAFileOnTheFolderFilesIt() {
        let app = launchDemo("EmbeddedDropTargetViewController")

        let folder = app.otherElements["folder-projects"]
        let downloads = app.otherElements["panel-downloads"]
        XCTAssertTrue(folder.waitForExistence(timeout: 5))

        let folderBefore = folder.frame
        XCTAssertTrue(identifiers(withPrefix: "file-", inside: folder, of: app).isEmpty,
                      "The folder starts empty")

        let filesBefore = identifiers(withPrefix: "file-", inside: downloads, of: app)
        let firstSlot = app.otherElements[filesBefore[0]].frame

        let moved = filesBefore[0]
        drag(app.otherElements[moved], onto: folder)

        let pip = app.otherElements[moved]
        XCTAssertTrue(pip.exists, "\(moved) should still exist after being filed")
        XCTAssertTrue(folderBefore.contains(CGPoint(x: pip.frame.midX, y: pip.frame.midY)),
                      "\(moved) should sit inside the folder, got \(pip.frame) in \(folderBefore)")
        XCTAssertLessThan(pip.frame.width, 40,
                          "A filed file shrinks to a pip, got \(pip.frame.width)pt")

        // And Downloads closes the gap the filed file left behind.
        let filesAfter = identifiers(withPrefix: "file-", inside: downloads, of: app)
        XCTAssertEqual(filesAfter, Array(filesBefore.dropFirst()))
        XCTAssertEqual(app.otherElements[filesAfter[0]].frame, firstSlot,
                       "The next file should move up into the vacated slot")
        attachScreenshot(app, "files-after-drop")
    }
}
