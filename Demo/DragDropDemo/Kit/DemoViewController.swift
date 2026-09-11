//
//  DemoViewController.swift
//  DragDropDemo
//

import UIKit
import DragDrop
import DemoKit

/// What every demo screen shares: the one-shot content load, the controller
/// factory, and the two pieces of drag feedback that used to be copied into
/// each screen by hand -- lifting the dragged chip, and highlighting the panel
/// it is over.
///
/// The load happens in `viewDidLayoutSubviews` rather than `viewDidLoad`
/// because these screens compute frames from `view.bounds`, which is not yet
/// sized when `viewDidLoad` runs under iOS 26.
///
/// The delegate conformance is declared on the class itself and its methods
/// live in the class body, not in an extension. Swift gives extension methods
/// no vtable entry, so a subclass cannot override them -- and several screens
/// need to extend `didMove(view:to:)` to update a count badge.
class DemoViewController: UIViewController, DragDropControllerDelegate {

    private var hasLoadedContent = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DemoTheme.Surface.background
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !hasLoadedContent else { return }
        hasLoadedContent = true
        loadContent()
    }

    /// Override. Called once, after `view.bounds` is real.
    func loadContent() {}

    func makeController() -> DragDropController {
        let controller = DragDropController()
        controller.dragDropDataSource = self as? any DragDropControllerDataSource
        controller.dragDropDelegate = self
        return controller
    }

    /// The panel a controller drops into, if its target is a panel's
    /// `contentView` -- or is nested somewhere inside one.
    func panel(for controller: DragDropController) -> PanelView? {
        var candidate: UIView? = controller.dropTargetView
        while let view = candidate {
            if let panel = view as? PanelView { return panel }
            candidate = view.superview
        }
        return nil
    }

    /// Adds a panel to `parent` at `frame` and returns the drop target inside
    /// it. The `layoutIfNeeded` matters: `SlotLayout` measures the container it
    /// is given, and `contentView` has no size until the panel has laid out.
    @discardableResult
    func install(_ panel: PanelView, in parent: UIView, frame: CGRect) -> UIView {
        panel.frame = frame
        parent.addSubview(panel)
        panel.layoutIfNeeded()
        return panel.contentView
    }

    // MARK: - Shared drag feedback
    //
    // In the class body so subclasses can override. Any override must call
    // super, or it loses the lift and the panel highlight.

    /// The library calls this inside a `UIView.animate` block, so setting the
    /// lifted state here is all the animation this needs.
    func dragDropController(_ controller: DragDropController,
                            willStartDrag drag: DragAction,
                            animated: Bool) {
        (drag.view as? any Liftable)?.setLifted(true)
    }

    func dragDropController(_ controller: DragDropController, didStartDrag drag: DragAction) {}

    func dragDropController(_ controller: DragDropController,
                            willEndDrag drag: DragAction,
                            animated: Bool) {
        (drag.view as? any Liftable)?.setLifted(false)
    }

    func dragDropController(_ controller: DragDropController, didEndDrag drag: DragAction) {}

    func dragDropController(_ controller: DragDropController,
                            dragDidEnter drag: DragAction,
                            destinationController destination: DragDropController) {
        panel(for: destination)?.setHighlighted(true)
    }

    func dragDropController(_ controller: DragDropController,
                            dragDidMove drag: DragAction,
                            destinationController destination: DragDropController) {}

    func dragDropController(_ controller: DragDropController,
                            dragDidExit drag: DragAction,
                            destinationController destination: DragDropController) {
        panel(for: destination)?.setHighlighted(false)
    }

    func dragDropController(_ controller: DragDropController,
                            didMove view: UIView,
                            to destination: DragDropController) {
        panel(for: destination)?.setHighlighted(false)
    }
}
