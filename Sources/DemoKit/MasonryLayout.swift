//
//  MasonryLayout.swift
//  DemoKit
//

import UIKit

/// Packs items of differing heights into columns, each item going into
/// whichever column is currently shortest.
///
/// This is what `UICollectionViewFlowLayout` cannot do. Flow lays out in
/// *lines*: it fills a row, drops below the tallest item in it, and centres
/// shorter items within the line -- which leaves a gap above and below every
/// short item. Masonry has no gaps, because the columns advance independently.
///
/// Pure geometry, like `SlotLayout`: no collection view, no state, so the
/// packing can be asserted exactly rather than eyeballed on a screenshot.
public enum MasonryLayout {

    public struct Metrics: Sendable {
        public var columns: Int
        public var spacing: CGFloat
        public var inset: UIEdgeInsets

        public init(columns: Int, spacing: CGFloat, inset: UIEdgeInsets) {
            self.columns = columns
            self.spacing = spacing
            self.inset = inset
        }
    }

    /// The frames for `heights`, in order.
    ///
    /// The result depends only on the *sequence* of heights, which is what lets
    /// Moodboard reorder cards without the mosaic moving: heights there are
    /// indexed by position, so reordering leaves the sequence -- and therefore
    /// every frame -- untouched. Cards move between fixed tiles and take the
    /// size of the one they land in.
    public static func frames(for heights: [CGFloat],
                              in width: CGFloat,
                              metrics: Metrics) -> [CGRect] {
        guard !heights.isEmpty, metrics.columns > 0 else { return [] }

        let available = width - metrics.inset.left - metrics.inset.right
        let gutters = metrics.spacing * CGFloat(metrics.columns - 1)
        let columnWidth = max(0, (available - gutters) / CGFloat(metrics.columns))

        // How far down each column has been filled so far.
        var bottoms = [CGFloat](repeating: metrics.inset.top, count: metrics.columns)
        var frames: [CGRect] = []
        frames.reserveCapacity(heights.count)

        for height in heights {
            // Ties go leftmost, so the packing is deterministic and a
            // screenshot taken today matches one taken tomorrow.
            var column = 0
            for candidate in 1..<metrics.columns where bottoms[candidate] < bottoms[column] {
                column = candidate
            }

            let x = metrics.inset.left + CGFloat(column) * (columnWidth + metrics.spacing)
            frames.append(CGRect(x: x, y: bottoms[column], width: columnWidth, height: height))
            bottoms[column] += height + metrics.spacing
        }

        return frames
    }

    /// How tall the packed result is: the lowest edge reached, plus the bottom
    /// inset. Taken from the frames rather than recomputed, so it cannot
    /// disagree with them.
    public static func contentHeight(of frames: [CGRect], metrics: Metrics) -> CGFloat {
        guard let lowest = frames.map(\.maxY).max() else { return 0 }
        return lowest + metrics.inset.bottom
    }
}
