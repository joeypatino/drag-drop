import XCTest
import UIKit
@testable import DragDrop

/// A cell dragged out of one collection view and dropped into another leaves a
/// hole behind. The source collection view has one fewer item and must lay the
/// survivors out against its own layout rather than leaving them in the
/// positions the drag animations put them in.
@MainActor
final class SourceCollectionViewGapTests: XCTestCase {

    private final class TwoListSource: NSObject, UICollectionViewDataSourceCellSwapSupport {
        var left: [Int] = Array(0..<8)
        var right: [Int] = Array(100..<104)

        weak var leftCollectionView: UICollectionView?

        private func items(for collectionView: UICollectionView) -> [Int] {
            collectionView === leftCollectionView ? left : right
        }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            items(for: collectionView).count
        }

        func collectionView(_ collectionView: UICollectionView,
                            cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
            cell.accessibilityLabel = "\(items(for: collectionView)[indexPath.row])"
            return cell
        }

        func collectionView(_ collectionView: UICollectionView,
                            moveItemAt sourceIndexPath: IndexPath,
                            to destinationCollectionView: UICollectionView,
                            to destinationIndexPath: IndexPath) {

            let item: Int
            if collectionView === leftCollectionView {
                item = left.remove(at: sourceIndexPath.row)
            } else {
                item = right.remove(at: sourceIndexPath.row)
            }

            if destinationCollectionView === leftCollectionView {
                left.insert(item, at: min(destinationIndexPath.row, left.count))
            } else {
                right.insert(item, at: min(destinationIndexPath.row, right.count))
            }
        }
    }

    private var dataSource: TwoListSource!
    private var window: UIWindow!
    private var left: UICollectionView!
    private var right: UICollectionView!

    /// Built per test rather than in setUp: setUp is not main-actor isolated,
    /// and these are all UIKit objects.
    private func makeCollectionViews() {
        dataSource = TwoListSource()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 400))

        left = makeCollectionView(x: 0)
        right = makeCollectionView(x: 200)
        dataSource.leftCollectionView = left

        window.addSubview(left)
        window.addSubview(right)
        window.isHidden = false

        left.reloadData()
        right.reloadData()
        left.layoutIfNeeded()
        right.layoutIfNeeded()
    }

    private func makeCollectionView(x: CGFloat) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero

        let collectionView = UICollectionView(frame: CGRect(x: x, y: 0, width: 200, height: 400),
                                              collectionViewLayout: layout)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.dataSource = dataSource
        return collectionView
    }

    /// Replays what CollectionViewDragDropState does to the source collection
    /// view over one drag: pick a cell up, leave for the other collection view,
    /// and complete the move.
    private func dragItem(at row: Int, ontoRow destinationRow: Int) {
        let pickup = left.frameForItem(at: IndexPath(row: row, section: 0))
        let drop = right.frameForItem(at: IndexPath(row: destinationRow, section: 0))

        left.startedDragging(in: left, at: CGPoint(x: pickup.midX, y: pickup.midY))
        left.endedDragging(in: left, at: CGPoint(x: pickup.midX, y: pickup.midY))
        left.startedDragging(in: right, at: CGPoint(x: drop.midX, y: drop.midY))
        left.didMoveCell(to: right)
    }

    func testTheSourceLosesExactlyTheItemThatWasDragged() {
        makeCollectionViews()
        dragItem(at: 1, ontoRow: 0)

        XCTAssertEqual(dataSource.left, [0, 2, 3, 4, 5, 6, 7])
        XCTAssertEqual(left.numberOfItems(inSection: 0), 7)
    }

    /// The hole. Every surviving cell has to sit where the layout says its new
    /// index path belongs.
    func testTheSurvivingCellsCloseTheGap() {
        makeCollectionViews()
        dragItem(at: 1, ontoRow: 0)
        left.layoutIfNeeded()

        for indexPath in left.indexPathsForVisibleItems.sorted() {
            guard let cell = left.cellForItem(at: indexPath) else { continue }
            XCTAssertEqual(cell.frame, left.frameForItem(at: indexPath),
                           "cell at \(indexPath) was left in a stale position")
        }
    }

    /// Frames alone would pass if the collection view simply stopped tracking
    /// cells, so pin the contents too: row 1 must now be the item that was row 2.
    func testTheSurvivingCellsShowTheRightItems() {
        makeCollectionViews()
        dragItem(at: 1, ontoRow: 0)
        left.layoutIfNeeded()

        let labels = left.indexPathsForVisibleItems.sorted().compactMap {
            left.cellForItem(at: $0)?.accessibilityLabel
        }

        XCTAssertEqual(labels, ["0", "2", "3", "4", "5", "6", "7"])
    }
}
