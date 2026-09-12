//
//  MasonryCollectionViewLayout.swift
//  DragDropDemo
//

import UIKit
import DemoKit

@MainActor
protocol MasonryCollectionViewLayoutDelegate: AnyObject {
    /// The height of the item at `index`. Asked by position, not by item: that
    /// is what keeps the mosaic still while cards move through it.
    func masonryLayout(_ layout: MasonryCollectionViewLayout,
                       heightAt index: Int) -> CGFloat
}

/// The UIKit shell around `MasonryLayout`. Holds the cache and the invalidation
/// rules; the packing itself is pure geometry in DemoKit, where it is tested.
final class MasonryCollectionViewLayout: UICollectionViewLayout {

    weak var delegate: (any MasonryCollectionViewLayoutDelegate)?

    var metrics = MasonryLayout.Metrics(columns: 2,
                                        spacing: 10,
                                        inset: UIEdgeInsets(top: 12, left: 12,
                                                            bottom: 12, right: 12))

    private var attributes: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0
    private var packedWidth: CGFloat = 0

    override var collectionViewContentSize: CGSize {
        CGSize(width: collectionView?.bounds.width ?? 0, height: contentHeight)
    }

    override func prepare() {
        super.prepare()

        guard let collectionView, let delegate else { return }
        let width = collectionView.bounds.width

        // One pass over the items is cheap, but not once per invalidation: a
        // drag invalidates constantly, and the packing only depends on the
        // width and the heights, neither of which a drag changes.
        guard attributes.isEmpty || width != packedWidth else { return }

        let count = collectionView.numberOfItems(inSection: 0)
        let heights = (0..<count).map { delegate.masonryLayout(self, heightAt: $0) }
        let frames = MasonryLayout.frames(for: heights, in: width, metrics: metrics)

        attributes = frames.enumerated().map { index, frame in
            let item = UICollectionViewLayoutAttributes(
                forCellWith: IndexPath(item: index, section: 0))
            item.frame = frame
            return item
        }
        contentHeight = MasonryLayout.contentHeight(of: frames, metrics: metrics)
        packedWidth = width
    }

    override func invalidateLayout() {
        super.invalidateLayout()
        attributes = []
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        attributes.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        // The library resolves every drop through this, so an out-of-range
        // index path has to answer nil rather than trap: it asks for the row
        // after the last one while working out where an append lands.
        guard indexPath.section == 0, indexPath.item < attributes.count else { return nil }
        return attributes[indexPath.item]
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        newBounds.width != packedWidth
    }
}
