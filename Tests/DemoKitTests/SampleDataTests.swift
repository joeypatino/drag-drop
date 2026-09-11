import XCTest
@testable import DemoKit

final class SampleDataTests: XCTestCase {

    func testEverySetHasUniqueIdentifiers() {
        XCTAssertEqual(Set(SampleData.staff.map(\.id)).count, SampleData.staff.count)
        XCTAssertEqual(Set(SampleData.photos.map(\.id)).count, SampleData.photos.count)
        XCTAssertEqual(Set(SampleData.widgets.map(\.id)).count, SampleData.widgets.count)
        XCTAssertEqual(Set(SampleData.files.map(\.id)).count, SampleData.files.count)
        XCTAssertEqual(Set(SampleData.tracks.map(\.id)).count, SampleData.tracks.count)
        XCTAssertEqual(Set(SampleData.palettes.map(\.id)).count, SampleData.palettes.count)
        XCTAssertEqual(Set(SampleData.players.map(\.id)).count, SampleData.players.count)
    }

    /// Each screen's starting counts are fixed by the spec. If a fixture list
    /// is short, a screen silently renders fewer items than the demo claims.
    func testEachScreenHasEnoughContent() {
        XCTAssertGreaterThanOrEqual(SampleData.staff.count, 18,   "rota: 5+4+3+6")
        XCTAssertGreaterThanOrEqual(SampleData.photos.count, 8,   "album: 5+3")
        XCTAssertGreaterThanOrEqual(SampleData.widgets.count, 8,  "widgets: 3+5")
        XCTAssertGreaterThanOrEqual(SampleData.files.count, 8,    "files: 5+3")
        XCTAssertGreaterThanOrEqual(SampleData.tracks.count, 16,  "queue: 10 plus spares to insert")
        XCTAssertGreaterThanOrEqual(SampleData.palettes.count, 12, "moodboard cycles these over 300 cards")
        XCTAssertEqual(SampleData.players.count, 16,              "lineup: 8 starters, 8 bench")
    }

    func testInitialsComeFromTheFirstAndLastName() {
        let member = StaffMember(id: 99, name: "Nadia Okafor", role: "Barista")
        XCTAssertEqual(member.initials, "NO")
    }

    func testInitialsOfASingleNameDoNotCrash() {
        XCTAssertEqual(StaffMember(id: 99, name: "Prince", role: "Floor").initials, "P")
        XCTAssertEqual(StaffMember(id: 99, name: "", role: "Floor").initials, "?")
    }

    func testPositionsAbbreviateToTwoLetters() {
        for position in Player.Position.allCases {
            XCTAssertEqual(position.abbreviation.count, 2, "\(position)")
        }
    }

    func testTheLineupSplitsEvenlyAndHasAKeeperOnEachSide() {
        let starters = Array(SampleData.players.prefix(8))
        let bench = Array(SampleData.players.suffix(8))
        XCTAssertTrue(starters.contains { $0.position == .goalkeeper })
        XCTAssertTrue(bench.contains { $0.position == .goalkeeper })
    }

    func testPaletteHexValuesAreWellFormed() {
        for palette in SampleData.palettes {
            XCTAssertEqual(palette.hex.count, 7, "\(palette.name): \(palette.hex)")
            XCTAssertTrue(palette.hex.hasPrefix("#"), "\(palette.name): \(palette.hex)")
        }
    }

    func testTrackDurationsAreMinutesAndSeconds() {
        for track in SampleData.tracks {
            let parts = track.duration.split(separator: ":")
            XCTAssertEqual(parts.count, 2, track.duration)
            XCTAssertEqual(parts[1].count, 2, track.duration)
            XCTAssertNotNil(Int(parts[1]), track.duration)
        }
    }
}
