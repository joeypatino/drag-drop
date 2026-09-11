//
//  SlotPopulator.swift
//  DragDropDemo
//

import UIKit
import DragDrop
import DemoKit

/// Fills a drop target with draggable chips laid out on `SlotLayout`'s run.
///
/// This cannot live in `DemoKit` -- it needs `DragDropController`, and keeping
/// `DemoKit` free of the library dependency is what makes its tests fast.
@MainActor
enum SlotPopulator {

    /// Adds `count` views to `container`, each built by `makeView` and each
    /// enabled for dragging through `controller`.
    static func fill(_ container: UIView,
                     count: Int,
                     metrics: SlotLayout.Metrics = .standard,
                     controller: DragDropController?,
                     makeView: (Int) -> UIView) {

        for index in 0..<count {
            let view = makeView(index)
            controller?.enableDragAction(for: view)
            view.frame = SlotLayout.frame(at: index,
                                          size: metrics.itemSize,
                                          in: container,
                                          metrics: metrics)
            container.addSubview(view)
        }
    }
}
