import UIKit

/// Ported from NSIndexPath+Additions. These read better than the bare
/// Comparable operators at the call sites in the rearrange and swap
/// algorithms, which is why they are kept as named methods.
extension IndexPath {
    var incrementingRow: IndexPath {
        IndexPath(row: row + 1, section: section)
    }

    var decrementingRow: IndexPath {
        IndexPath(row: row - 1, section: section)
    }

    func isBetween(_ indexPath1: IndexPath, and indexPath2: IndexPath) -> Bool {
        compare(indexPath1) == .orderedDescending && compare(indexPath2) == .orderedAscending
    }

    func isBefore(_ indexPath: IndexPath) -> Bool {
        compare(indexPath) == .orderedAscending
    }

    func isAfter(_ indexPath: IndexPath) -> Bool {
        compare(indexPath) == .orderedDescending
    }

    func isSame(as indexPath: IndexPath) -> Bool {
        compare(indexPath) == .orderedSame
    }
}
