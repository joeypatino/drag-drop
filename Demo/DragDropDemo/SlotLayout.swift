//
//  SlotLayout.swift
//  DragDropDemo
//

import UIKit
import DragDrop

/// The flow every demo lays its draggable views out in: a left-to-right run of
/// fixed-size slots that wraps when a row runs out of room.
///
/// One rule, three callers -- the initial population, the frame a view arriving
/// from another container is given, and the frames the survivors take when a
/// view is dragged away. They have to agree, or a container is left with a hole
/// where a view used to be, or two views in the same slot.
@MainActor
enum SlotLayout {

    private static let squareSize = CGSize(width: 40, height: 40)
    private static let margin: CGFloat = 5
    private static let spacing: CGFloat = 5

    /// The frame of the `index`-th slot for a view of `size` in `container`.
    static func frame(at index: Int, size: CGSize, in container: UIView) -> CGRect {
        var x = margin
        var y = margin
        var frame = CGRect.zero

        for _ in 0...max(index, 0) {
            if x + size.width > container.frame.width {
                x = margin
                y += size.height + spacing
            }

            frame = CGRect(x: x, y: y, width: size.width, height: size.height)
            x += size.width + spacing
        }

        return frame
    }

    /// Fills `container` with `count` black squares, each draggable through
    /// `controller`.
    static func populate(_ container: UIView,
                         withCount count: Int,
                         controller: DragDropController?) {

        for index in 0..<count {
            let dragView = UIView()
            controller?.enableDragAction(for: dragView)
            dragView.frame = frame(at: index, size: squareSize, in: container)
            dragView.backgroundColor = .black
            container.addSubview(dragView)
        }
    }
}
