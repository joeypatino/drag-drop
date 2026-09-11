import XCTest
import UIKit
@testable import DragDrop

@MainActor
final class CollectionViewDragDropTests: XCTestCase {
    private final class Source: NSObject, UICollectionViewDataSource {
        var itemCount = 20
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            itemCount
        }
        func collectionView(_ collectionView: UICollectionView,
                            cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        }
    }

    private var source: Source!

    private func makeCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        let collectionView = UICollectionView(
            frame: CGRect(x: 0, y: 0, width: 200, height: 400),
            collectionViewLayout: layout)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        source = Source()
        collectionView.dataSource = source
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        return collectionView
    }

    func testStateIsCreatedLazilyAndIsStable() {
        let collectionView = makeCollectionView()

        collectionView.cellRearrangeOrigin = IndexPath(row: 3, section: 0)
        XCTAssertEqual(collectionView.cellRearrangeOrigin, IndexPath(row: 3, section: 0))
        XCTAssertNil(collectionView.cellSwapOrigin)
    }

    func testStateIsPerCollectionView() {
        let first = makeCollectionView()
        let second = makeCollectionView()

        first.cellSwapDestination = IndexPath(row: 1, section: 0)
        XCTAssertNil(second.cellSwapDestination)
    }

    /// Objective-C nil-messaging silently yielded CGRectZero for a missing
    /// layout attribute. The Swift helper must reproduce that rather than trap.
    ///
    /// Flow layout extrapolates an out-of-range *row* rather than returning
    /// nil, so the nil case is an out-of-range *section*. That is the only
    /// input for which the fallback actually fires.
    func testFrameForItemReturnsZeroWhenTheLayoutHasNoAttributes() {
        let collectionView = makeCollectionView()

        XCTAssertEqual(collectionView.frameForItem(at: IndexPath(row: 0, section: 5)), .zero)
        XCTAssertEqual(collectionView.sizeForItem(at: IndexPath(row: 0, section: 5)), .zero)
    }

    /// The rearrange algorithm can hand the layout a decremented row. Flow
    /// layout extrapolates rather than trapping, which is what the Objective-C
    /// relied on; this pins that down so a future layout change is caught.
    func testFrameForItemToleratesRowsOutsideTheDataSource() {
        let collectionView = makeCollectionView()

        XCTAssertEqual(collectionView.frameForItem(at: IndexPath(row: -1, section: 0)),
                       CGRect(x: -100, y: 0, width: 100, height: 100))
        XCTAssertEqual(collectionView.frameForItem(at: IndexPath(row: 999, section: 0)),
                       CGRect(x: 100, y: 49_900, width: 100, height: 100))
    }

    func testFrameForItemReturnsTheLayoutFrameWhenPresent() {
        let collectionView = makeCollectionView()

        XCTAssertEqual(collectionView.frameForItem(at: IndexPath(row: 0, section: 0)),
                       CGRect(x: 0, y: 0, width: 100, height: 100))
    }

    func testEnableDragAndDropAttachesOneGesturePerCell() {
        let collectionView = makeCollectionView()
        let cell = UICollectionViewCell()

        collectionView.enableDragAndDrop(for: cell)
        collectionView.enableDragAndDrop(for: cell)

        let gestures = cell.gestureRecognizers?.filter { $0 is DragDropGesture } ?? []
        XCTAssertEqual(gestures.count, 1, "enable must disable first, so a reused cell keeps one gesture")
    }

    func testClosestIndexPathSnapsToTheNearestVisibleCell() {
        let collectionView = makeCollectionView()

        XCTAssertEqual(collectionView.indexPath(at: CGPoint(x: 10, y: 10)), IndexPath(row: 0, section: 0))
        XCTAssertEqual(collectionView.indexPath(at: CGPoint(x: 150, y: 10)), IndexPath(row: 1, section: 0))
    }

    func testClosestIndexPathBelowEveryVisibleCellReturnsTheLastItem() {
        let collectionView = makeCollectionView()

        let found = collectionView.indexPath(at: CGPoint(x: 150, y: 10_000))
        XCTAssertEqual(found, IndexPath(row: source.itemCount - 1, section: 0))
    }
}

// MARK: - Rearrange teardown

@MainActor
final class ResetAfterRearrangeTests: XCTestCase {
    private final class Source: NSObject, UICollectionViewDataSource {
        func collectionView(_ cv: UICollectionView, numberOfItemsInSection s: Int) -> Int { 40 }
        func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
            cv.dequeueReusableCell(withReuseIdentifier: "Cell", for: ip)
        }
    }

    private var source: Source!
    private var window: UIWindow!

    private func makeCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero

        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 200, height: 400),
                                              collectionViewLayout: layout)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        source = Source()
        collectionView.dataSource = source

        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 400))
        window.addSubview(collectionView)
        window.isHidden = false

        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        return collectionView
    }

    /// Regression test. reloadItems defers cell creation to the next layout
    /// pass; without forcing one the collection view was left tracking no cells
    /// at all, orphaning everything already on screen so it kept stale content
    /// and stale frames through every subsequent drag.
    func testResetAfterRearrangeKeepsCellsTracked() {
        let collectionView = makeCollectionView()
        XCTAssertFalse(collectionView.visibleCells.isEmpty, "precondition: cells are tracked")
        let before = collectionView.visibleCells.count

        collectionView.resetAfterRearrange()

        XCTAssertEqual(collectionView.visibleCells.count, before,
                       "reloading must not leave the collection view tracking zero cells")
        XCTAssertFalse(collectionView.indexPathsForVisibleItems.isEmpty)
    }

    /// The vacancy animations assign cell frames directly. Teardown has to put
    /// them back, or cells stay in each other's positions.
    func testResetAfterRearrangeRestoresDisplacedFrames() {
        let collectionView = makeCollectionView()
        let indexPath = IndexPath(row: 0, section: 0)

        guard let cell = collectionView.cellForItem(at: indexPath),
              let expected = collectionView.collectionViewLayout
                  .layoutAttributesForItem(at: indexPath)?.frame
        else { return XCTFail("expected a cell at row 0") }

        // Displace it the way createVacancyForMovement would.
        cell.frame = cell.frame.offsetBy(dx: 137, dy: 211)
        XCTAssertNotEqual(collectionView.cellForItem(at: indexPath)?.frame, expected)

        collectionView.resetAfterRearrange()

        let restored = collectionView.cellForItem(at: indexPath)?.frame
        XCTAssertEqual(restored?.origin.x ?? -1, expected.origin.x, accuracy: 0.5)
        XCTAssertEqual(restored?.origin.y ?? -1, expected.origin.y, accuracy: 0.5)
    }
}
