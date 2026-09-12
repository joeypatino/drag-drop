import XCTest
import UIKit
@testable import DragDrop

/// The swap support reaches for the slot after an item, and asks the
/// datasource how many items a section holds. Both have an edge the happy
/// path never touches: the last item in a section, and a section the model
/// has already emptied.
@MainActor
final class CollectionSwapEdgeTests: XCTestCase {

    private final class Source: NSObject, UICollectionViewDataSource {
        var itemCount: Int

        init(itemCount: Int) {
            self.itemCount = itemCount
        }

        func collectionView(_ collectionView: UICollectionView,
                            numberOfItemsInSection section: Int) -> Int {
            itemCount
        }

        func collectionView(_ collectionView: UICollectionView,
                            cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        }
    }

    /// A layout that answers only for items that exist. `UICollectionViewFlowLayout`
    /// extrapolates a slot past the last item, which hides this; the demos'
    /// own layouts -- masonry, slots, folder pips -- do not, and neither does
    /// any layout that builds its attributes from the model.
    private final class StrictLayout: UICollectionViewFlowLayout {
        override func layoutAttributesForItem(at indexPath: IndexPath)
            -> UICollectionViewLayoutAttributes? {

            let items = collectionView?.numberOfItems(inSection: indexPath.section) ?? 0
            guard indexPath.row < items else { return nil }
            return super.layoutAttributesForItem(at: indexPath)
        }
    }

    private var window: UIWindow!
    private var source: Source!

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 400))
        window.isHidden = false
    }

    override func tearDown() {
        source = nil
        window = nil
        super.tearDown()
    }

    private func makeCollectionView(items: Int,
                                    layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout())
        -> UICollectionView {
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero

        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 200, height: 400),
                                              collectionViewLayout: layout)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        source = Source(itemCount: items)
        collectionView.dataSource = source
        window.addSubview(collectionView)
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        return collectionView
    }

    /// Hovering a swap over the last cell asked the layout for the slot after
    /// it, got nil, and `frameForItem` answered .zero -- so the cell was
    /// collapsed into the corner instead of sliding.
    func testMakingRoomAtTheLastItemDoesNotCollapseIt() {
        let collectionView = makeCollectionView(items: 5, layout: StrictLayout())
        let last = IndexPath(row: 4, section: 0)

        XCTAssertNotNil(collectionView.cellForItem(at: last))
        let before = collectionView.frameForItem(at: last)
        XCTAssertFalse(before.isEmpty)

        // Confirms the premise: there is no slot after the last item to
        // slide into, so the frame for it reads as empty.
        XCTAssertTrue(collectionView.frameForItem(at: last.incrementingRow).isEmpty)

        collectionView.insertVacancy(at: last, animated: false)

        let frame = collectionView.cellForItem(at: last)?.frame
        XCTAssertNotEqual(frame, .zero, "the last cell was collapsed into the corner")
        XCTAssertEqual(frame, before)
    }

    /// Mid-swap the model is mutated before the collection view is told, so a
    /// section can report no items while its cells are still on screen. The
    /// row worked out from that count went to -1, which throws on the way
    /// into insertItems(at:).
    func testTheClosestIndexPathBelowAnEmptiedSectionIsNotNegative() {
        let collectionView = makeCollectionView(items: 3)
        XCTAssertFalse(collectionView.indexPathsForVisibleItems.isEmpty)

        // Emptied without a reload: the cells are still there.
        source.itemCount = 0

        let below = CGPoint(x: 50, y: 390)
        let found = collectionView.findClosestIndexPath(to: below)

        XCTAssertEqual(found, IndexPath(row: 0, section: 0))
        XCTAssertGreaterThanOrEqual(found?.row ?? -1, 0)
    }
}
