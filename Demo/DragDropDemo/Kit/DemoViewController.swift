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

    /// Every panel this screen installed. Held so a drag that ends anywhere --
    /// including a refused drop, which never reports a move -- can put all of
    /// them back to rest. Without this a refused drop leaves the panel it was
    /// over stuck in its hover state.
    private(set) var panels: [PanelView] = []

    /// Every drop target this screen set up, with the panel that owns it.
    ///
    /// Resolved at registration rather than by walking the hierarchy later: the
    /// Files folder is a target inside the Documents panel, and a walk upward
    /// would call Documents its owner. The screen knows better, so it says.
    private(set) var targets: [(view: UIView, panel: PanelView?)] = []

    /// Records a drop target, and assigns it to `controller` when one is given.
    ///
    /// Every screen routes through this instead of setting `dropTargetView`
    /// directly, because "is this panel a drop target?" has to be derived from
    /// somewhere and this is the only place that knows. The flag it replaced
    /// was hand-set, and wrong on Camera Roll.
    ///
    /// `panel` defaults to whichever installed panel owns `target` as its
    /// content. Pass it explicitly when the target is something else -- the
    /// Lineup grids sit *inside* a panel's content view -- or leave both nil
    /// for a target that is not a panel at all, like the Files folder.
    func register(_ target: UIView,
                  with controller: DragDropController? = nil,
                  in panel: PanelView? = nil) {
        controller?.dropTargetView = target

        let owner = panel ?? panels.first { $0.contentView === target }
        targets.append((target, owner))
        owner?.isDropTarget = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DemoTheme.Surface.background
    }

    /// What this screen proves, in the words the index already uses. Shown
    /// under the bar so the capability travels with the demo instead of being
    /// left behind on the row you tapped.
    private let propositionLabel = UILabel()

    /// Height the caption takes off the top, or zero when there is none.
    private var propositionHeight: CGFloat {
        propositionLabel.superview == nil ? 0 : 34
    }

    /// Where a demo's content starts: below the bar, and below the caption.
    /// Screens lay out from this rather than from `safeAreaInsets.top`.
    var contentTop: CGFloat {
        view.safeAreaInsets.top + propositionHeight
    }

    private func installProposition() {
        let name = String(describing: type(of: self))
        guard let entry = DemoCatalog.entry(forSegue: name) else { return }

        propositionLabel.text = entry.capability
        propositionLabel.font = DemoTheme.Font.caption
        propositionLabel.textColor = DemoTheme.Text.secondary
        propositionLabel.textAlignment = .center
        propositionLabel.numberOfLines = 2
        propositionLabel.adjustsFontSizeToFitWidth = true
        propositionLabel.minimumScaleFactor = 0.85
        propositionLabel.accessibilityIdentifier = "demo-proposition"
        view.addSubview(propositionLabel)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if propositionLabel.superview != nil {
            propositionLabel.frame = CGRect(x: DemoTheme.Space.l,
                                            y: view.safeAreaInsets.top + DemoTheme.Space.xs,
                                            width: max(0, view.bounds.width - DemoTheme.Space.l * 2),
                                            height: 26)
        }

        guard !hasLoadedContent else { return }
        hasLoadedContent = true
        installProposition()
        view.setNeedsLayout()
        defer {
            // A screen that adds a full-bleed subview would otherwise bury the
            // caption -- Moodboard's grid did exactly that. Cheaper to make
            // that impossible than to remember it in each demo.
            view.bringSubviewToFront(propositionLabel)
        }
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

    /// The panel a controller drops into -- and only when the panel itself is
    /// the destination.
    ///
    /// Deliberately not a walk up the superview chain. The Files folder is a
    /// drop target nested inside the Documents panel, and walking up would
    /// light Documents when the drop is actually going into the folder,
    /// promising the wrong destination.
    func panel(for controller: DragDropController) -> PanelView? {
        guard let target = controller.dropTargetView else { return nil }
        return panels.first { $0.contentView === target }
    }

    /// Adds a panel to `parent` at `frame` and returns the drop target inside
    /// it. The `layoutIfNeeded` matters: `SlotLayout` measures the container it
    /// is given, and `contentView` has no size until the panel has laid out.
    @discardableResult
    func install(_ panel: PanelView, in parent: UIView, frame: CGRect) -> UIView {
        panel.frame = frame
        parent.addSubview(panel)
        panel.layoutIfNeeded()
        panels.append(panel)
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

    func dragDropController(_ controller: DragDropController, didEndDrag drag: DragAction) {
        clearDropStates()
    }

    /// Returns every panel to rest. Safe to call more than once.
    func clearDropStates() {
        highlight(armed: nil)
    }

    /// Puts every panel into the state the armed target implies: the winner
    /// lit, anything containing the winner drained, everything else at rest.
    ///
    /// The whole screen is updated at once rather than one panel in isolation,
    /// because the interesting state belongs to a panel that is *not* under the
    /// finger -- the one that just lost to a target inside itself.
    private func highlight(armed: UIView?, refusing: Bool = false) {
        for (target, panel) in targets {
            guard let panel else { continue }

            switch DropTargetHighlight.state(of: target, whenArmed: armed) {
            case .armed:   panel.setDropState(refusing ? .refusing : .accepting)
            case .drained: panel.setDropState(.drained)
            case .idle:    panel.setDropState(.idle)
            }
        }
    }

    /// Whether this screen's datasource would accept `view` into `destination`.
    /// The panel shows what will actually happen rather than assuming a drop
    /// under the finger is a drop that lands.
    private func wouldAccept(_ view: UIView?,
                             from controller: DragDropController,
                             into destination: DragDropController) -> Bool {
        guard let view,
              let dataSource = self as? any DragDropControllerDataSource else { return true }
        return dataSource.dragDropController(controller, canDrop: view, to: destination)
    }

    func dragDropController(_ controller: DragDropController,
                            dragDidEnter drag: DragAction,
                            destinationController destination: DragDropController) {
        panel(for: destination)?.setDropState(
            wouldAccept(drag.view, from: controller, into: destination) ? .accepting : .refusing)
    }

    func dragDropController(_ controller: DragDropController,
                            dragDidMove drag: DragAction,
                            destinationController destination: DragDropController) {}

    func dragDropController(_ controller: DragDropController,
                            dragDidExit drag: DragAction,
                            destinationController destination: DragDropController) {
        panel(for: destination)?.setDropState(.idle)
    }

    func dragDropController(_ controller: DragDropController,
                            didMove view: UIView,
                            to destination: DragDropController) {
        clearDropStates()
    }

    // MARK: - Feedback for drags that started somewhere else
    //
    // `dragDidEnter` and `dragDidExit` go to the *source* controller's
    // delegate. When a drag starts inside a table or collection view, that
    // source is the controller the library built for the scroll view, whose
    // delegate is its own state object -- so a plain panel would get no hover
    // feedback at all for a row dragged out of the queue.
    //
    // These two are the destination's own side of the same events, and they
    // arrive whatever the drag came out of.

    func dragDropController(_ controller: DragDropController,
                            dragDidHover drag: DragAction,
                            from source: DragDropController) {
        highlight(armed: controller.dropTargetView,
                  refusing: !wouldAccept(drag.view, from: source, into: controller))
    }

    func dragDropController(_ controller: DragDropController,
                            dragDidLeave drag: DragAction,
                            from source: DragDropController) {
        highlight(armed: nil)
    }

    /// The destination's notice that a drop landed. Also the only end-of-drag
    /// signal a destination gets when the drag began in a scroll view, since
    /// `didEndDrag` goes to the source.
    func dragDropController(_ controller: DragDropController,
                            didReceive view: UIView,
                            from source: DragDropController) {
        clearDropStates()
    }
}
