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
