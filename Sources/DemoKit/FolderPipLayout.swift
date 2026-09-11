import UIKit

/// Where a file sits once it has been dropped on the Files screen's folder
/// tile. A 2x2 grid of pips, centred, holding four; past that the folder's
/// badge keeps counting and the extra files are not drawn.
///
/// Like `SlotLayout`, this has to answer the same question the same way for
/// three callers -- the frame an arriving file is given, the frames the
/// remaining files take when one is dragged back out, and the frames used when
/// the folder re-packs itself.
public enum FolderPipLayout {

    public static let capacity = 4
    public static let pipSize: CGFloat = 24
    public static let gap: CGFloat = 4

    /// The frame of the `index`-th pip inside a folder of `bounds`, or nil if
    /// the folder is already full.
    public static func frame(at index: Int, in bounds: CGRect) -> CGRect? {
        guard index >= 0, index < capacity else { return nil }

        let block = pipSize * 2 + gap
        let originX = (bounds.width - block) / 2
        let originY = (bounds.height - block) / 2

        let column = CGFloat(index % 2)
        let row = CGFloat(index / 2)

        return CGRect(x: originX + column * (pipSize + gap),
                      y: originY + row * (pipSize + gap),
                      width: pipSize,
                      height: pipSize)
    }
}
