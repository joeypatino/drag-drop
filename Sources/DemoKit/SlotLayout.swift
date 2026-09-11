import UIKit

/// The flow every free-form demo lays its draggable views out in: a
/// left-to-right run of fixed-size slots that wraps when a row runs out of
/// room.
///
/// One rule, three callers -- the initial population, the frame a view
/// arriving from another container is given, and the frames the survivors take
/// when a view is dragged away. They have to agree, or a container is left
/// with a hole where a view used to be, or two views in the same slot.
public enum SlotLayout {

    public struct Metrics: Sendable {
        public var itemSize: CGSize
        public var margin: CGFloat
        public var spacing: CGFloat

        public init(itemSize: CGSize, margin: CGFloat, spacing: CGFloat) {
            self.itemSize = itemSize
            self.margin = margin
            self.spacing = spacing
        }

        /// The original demo geometry. Kept so the pre-existing call sites
        /// behave identically.
        public static let standard = Metrics(itemSize: CGSize(width: 40, height: 40),
                                             margin: 5, spacing: 5)

        /// Avatars, widget tiles and file tiles.
        public static let chip = Metrics(itemSize: CGSize(width: 44, height: 44),
                                         margin: 8, spacing: 8)

        /// Photo thumbnails.
        public static let thumbnail = Metrics(itemSize: CGSize(width: 56, height: 56),
                                              margin: 8, spacing: 8)

        /// A tile that carries its name underneath: a 44pt square plus room for
        /// two lines of caption. Wider than the square so a file name has
        /// somewhere to go -- 60pt still fits five across a full-width panel.
        public static let labelledTile = Metrics(itemSize: CGSize(width: 60, height: 76),
                                                 margin: 8, spacing: 8)
    }

    /// The frame of the `index`-th slot for a view of `size` in `container`.
    ///
    /// `size` is passed separately from `metrics.itemSize` because two callers
    /// need a slot sized to the view they already hold rather than to the
    /// metrics -- the table demo's panel is one slot wide, and an arriving view
    /// keeps the size it had in its old home.
    @MainActor
    public static func frame(at index: Int,
                             size: CGSize,
                             in container: UIView,
                             metrics: Metrics = .standard) -> CGRect {
        var x = metrics.margin
        var y = metrics.margin
        var frame = CGRect.zero

        for _ in 0...max(index, 0) {
            if x + size.width > container.frame.width {
                x = metrics.margin
                y += size.height + metrics.spacing
            }

            frame = CGRect(x: x, y: y, width: size.width, height: size.height)
            x += size.width + metrics.spacing
        }

        return frame
    }
}
