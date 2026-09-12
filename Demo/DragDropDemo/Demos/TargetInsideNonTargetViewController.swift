//
//  DoubleEmbeddedViewController.swift
//  DragDropDemo
//
//  Created by Joey Patino on 11/4/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit
import DragDrop
import DemoKit

/// A drop target inset inside a container that is not a target. The phone
/// frame receives nothing; the widget stack drawn inside it does. This is the
/// arrangement that requires the library to translate coordinates through a
/// view that knows nothing about dragging.
final class DoubleEmbeddedViewController: DemoViewController {

    private var stackController: DragDropController?
    private var galleryController: DragDropController?

    private var stackPanel: PanelView?
    private var galleryPanel: PanelView?

    override func loadContent() {
        title = "Widget Composer"

        stackController = makeController()
        galleryController = makeController()

        let top = contentTop + 12
        let available = view.bounds.height - top - view.safeAreaInsets.bottom - 12
        // The phone frame keeps more height than the gallery below it -- a
        // phone is tall, and the wallpaper needs room to read as wallpaper.
        let half = CGRect(x: 16, y: top,
                          width: view.bounds.width - 32,
                          height: min(300, available / 2 - 8))

        // Upper: the decorative frame, with the real drop target inset in it.
        let phone = PhoneFrameView(frame: half)
        view.addSubview(phone)

        let stack = PanelView(title: "Widget Stack",
                              subtitle: "On your home screen",
                              symbolName: "square.stack.3d.up.fill",
                              hue: .violet)
        stack.emptyMessage = "Empty stack"
        // Inset generously so the wallpaper shows on every side: that margin
        // is the only thing saying the stack is *on* a home screen.
        let stackFrame = CGRect(x: 28, y: 52,
                                width: phone.bounds.width - 56,
                                height: phone.bounds.height - 52 - 28)
        let stackTarget = install(stack, in: phone, frame: stackFrame)
        stackTarget.accessibilityIdentifier = "panel-stack"
        register(stackTarget, with: stackController)
        stackPanel = stack

        // Lower: an ordinary panel, the second target.
        let gallery = PanelView(title: "Widget Gallery",
                                subtitle: "Everything available",
                                symbolName: "square.grid.2x2.fill",
                                hue: .teal)
        gallery.emptyMessage = "Nothing left to add"
        let galleryTarget = install(gallery, in: view,
                                    frame: half.offsetBy(dx: 0, dy: half.height + 16))
        galleryTarget.accessibilityIdentifier = "panel-gallery"
        register(galleryTarget, with: galleryController)
        galleryPanel = gallery

        // Three on the stack, five in the gallery -- the demo's original counts.
        fill(stackTarget, controller: stackController,
             widgets: Array(SampleData.widgets.prefix(3)))
        fill(galleryTarget, controller: galleryController,
             widgets: Array(SampleData.widgets.dropFirst(3).prefix(5)))

        refreshCounts()
    }

    private func fill(_ target: UIView, controller: DragDropController?, widgets: [Widget]) {
        SlotPopulator.fill(target,
                           count: widgets.count,
                           metrics: .chip,
                           controller: controller) { index in
            let widget = widgets[index]
            return TileChip(symbolName: widget.symbol,
                            hue: DemoTheme.hue(for: widget.name),
                            caption: widget.name,
                            identifier: "widget-\(widget.id)")
        }
    }

    private func refreshCounts() {
        stackPanel?.count = stackController?.draggableViews.count
        galleryPanel?.count = galleryController?.draggableViews.count
        stackPanel?.updateEmptyState()
        galleryPanel?.updateEmptyState()
    }

    override func dragDropController(_ controller: DragDropController,
                                     didMove view: UIView,
                                     to destination: DragDropController) {
        super.dragDropController(controller, didMove: view, to: destination)
        refreshCounts()
    }
}

// MARK: - DragDropController Datasource

extension DoubleEmbeddedViewController: DragDropControllerDataSource {

    func dragDropController(_ controller: DragDropController, shouldDrag view: UIView) -> Bool {
        true
    }

    func dragDropController(_ controller: DragDropController,
                            canDrop view: UIView,
                            to destination: DragDropController?) -> Bool {
        controller !== destination
    }

    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            in destination: DragDropController) -> CGRect {
        guard let target = destination.dropTargetView else { return .zero }
        // Not `view.frame.size`: the lift scales the tile for the duration of
        // the drag, and `frame` is the transformed box, which is wide enough to
        // wrap the arrival onto a row of its own.
        return SlotLayout.frame(at: destination.draggableViews.count,
                                size: SlotLayout.Metrics.chip.itemSize,
                                in: target,
                                metrics: .chip)
    }

    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            at index: Int) -> CGRect? {
        guard let target = controller.dropTargetView else { return nil }
        return SlotLayout.frame(at: index,
                                size: SlotLayout.Metrics.chip.itemSize,
                                in: target,
                                metrics: .chip)
    }
}
