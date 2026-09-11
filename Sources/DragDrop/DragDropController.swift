//
//  DragDropController.swift
//  DragDrop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit

/// DragDropController manages the drag actions of registered views and the drop
/// actions within its own dropTargetView. It uses a datasource and delegate
/// pattern to allow your code to customize the drag and drop behaviours and
/// respond to drag and drop actions.
@MainActor
public final class DragDropController {

    /// The duration of the animation when the icon is released
    /// and moves to its next position.
    public static let dropAnimationDuration: TimeInterval = 0.25

    /// The duration of the drag pickup animation.
    public static let dragDropPickupAnimationDuration: TimeInterval = 0.15

    /// The delay in seconds before the drag operation begins.
    /// This is used when the view being dragged is contained
    /// within a UIScrollView, UITableView, or UICollectionView.
    public static let dragPickupBeginDelay: TimeInterval = 0.12

    public weak var dragDropDataSource: (any DragDropControllerDataSource)?
    public weak var dragDropDelegate: (any DragDropControllerDelegate)?

    /// This is a drop target for views. If set, this view will be able to
    /// receive dropped views.
    public weak var dropTargetView: UIView?

    /// the view that our drag representations are translated across.
    private var _dragInteractionView: DragInteractionView?

    /// populated when the drag operation is above a drop target. otherwise nil
    private weak var currentDragDestination: DragDropController?

    private var isDragging = false
    private var isDropping = false

    /// the source view that the drag came from.
    private weak var sourceView: UIView?

    /// the source frame of the view being dragged.
    private var sourceFrame: CGRect = .zero

    public init() {
        DragDropControllerRegistry.shared.add(self)
    }

    // MARK: -

    /// Call this to enable drag actions for the view.
    public func enableDragAction(for view: UIView) {

        // The DragDropGesture is responsible for translating the view across the
        // screen in response to the users touch
        let gesture = DragDropGesture(target: self, action: #selector(handleDragDropGesture(_:)))
        view.addGestureRecognizer(gesture)

        // Add a delay on the gesture begin when embedded in a tableview, or tableview cell.
        // This prevents the table from scrolling before the drag has begun..
        if scrollingSuperView(of: view) != nil {
            gesture.gestureBeginDelay = Self.dragPickupBeginDelay
        }
    }

    /// The drop target's subviews that this controller has enabled dragging
    /// for, in subview order.
    ///
    /// A drop target usually holds furniture the controller does not manage --
    /// the demos each put a title label in theirs. Carrying a DragDropGesture
    /// is what separates the two, and it is the same test `disableDragAction`
    /// already uses, so the answer stays correct as views come and go.
    public var draggableViews: [UIView] {
        (dropTargetView?.subviews ?? []).filter(isDraggable)
    }

    private func isDraggable(_ view: UIView) -> Bool {
        (view.gestureRecognizers ?? []).contains { $0 is DragDropGesture }
    }

    /// Call this to disable drag actions for the view.
    public func disableDragAction(for view: UIView) {

        // Remove any existing drag gestures.
        let dragAndDrop = (view.gestureRecognizers ?? []).filter { $0 is DragDropGesture }

        for recognizer in dragAndDrop {
            view.removeGestureRecognizer(recognizer)
        }
    }

    // MARK: -

    /// Moves the views still in the drop target into the frames the datasource
    /// gives for their new positions, closing the gap left by a view that was
    /// dragged away.
    ///
    /// The datasource decides whether anything happens at all: the default
    /// `frameFor:at:` returns nil, and one nil abandons the whole pass rather
    /// than moving some views and stranding others.
    internal func closeGapInDropTarget(animated: Bool) {
        guard let dataSource = dragDropDataSource else { return }

        let views = draggableViews
        guard !views.isEmpty else { return }

        var frames: [CGRect] = []
        for (index, view) in views.enumerated() {
            guard let frame = dataSource.dragDropController(self, frameFor: view, at: index) else { return }
            frames.append(frame)
        }

        UIView.animate(withDuration: animated ? Self.dropAnimationDuration : 0.0) {
            for (view, frame) in zip(views, frames) {
                view.frame = frame
            }
        }
    }

    @objc private func handleDragDropGesture(_ gesture: DragDropGesture) {

        switch gesture.state {
        case .began:
            touchBegan(gesture)
        case .changed:
            touchMoved(gesture)
        case .ended:
            touchEnded(gesture)
        case .cancelled:
            touchEnded(gesture)
        default:
            break
        }
    }

    private func touchBegan(_ gesture: DragDropGesture) {
        guard let view = gesture.view else { return }

        let drag = DragAction(view: view)
        drag.currentLocation = gesture.location(in: nil)

        sourceView = view.superview
        sourceFrame = view.frame

        startDrag(drag)
    }

    private func touchMoved(_ gesture: DragDropGesture) {
        guard let drag = dragAction(with: gesture) else { return }
        dragMoved(drag)
    }

    private func touchEnded(_ gesture: DragDropGesture) {
        guard let drag = dragAction(with: gesture) else { return }
        endDrag(drag)
    }

    /// Helper method to create DragAction on touch move/end
    private func dragAction(with gesture: DragDropGesture) -> DragAction? {
        guard let view = gesture.view else { return nil }

        let drag = DragAction(view: view)

        // Set the drags current location to the location of the drag in the window's coordinates..
        drag.currentLocation = gesture.location(in: nil)

        // Copy over the existing drag touch begin offset
        // This was originally set when the drag began.
        drag.firstTouchOffset = gesture.touchBeginOffset

        return drag
    }

    // MARK: -

    private func startDrag(_ drag: DragAction) {
        if isDragging || isDropping { return }
        guard let view = drag.view else { return }

        // make sure the datasource allows dragging this view..
        // This check allows the datasource to have more granular control
        let canDrag = dragDropDataSource?.dragDropController(self, shouldDrag: view) ?? true

        if canDrag {
            isDragging = true
            isDropping = false

            // convert the drag representation's frame to our interaction view,
            // then add it as a subview.

            // All drag movement actually occurs on the interaction view..
            view.frame = dragInteractionView.convert(view.frame, from: view.superview)
            dragInteractionView.addSubview(view)

            // Allow the delegate to respond to the start of the drag sequence.
            //
            // The Objective-C asked respondsToSelector: of the datasource here and
            // then messaged the delegate, which only worked because every demo
            // assigned the same object to both. With protocol defaults there is no
            // guard, and the call goes where it was always meant to.
            UIView.animate(withDuration: Self.dragDropPickupAnimationDuration,
                           delay: 0,
                           options: .curveEaseIn) {
                self.dragDropDelegate?.dragDropController(self, willStartDrag: drag, animated: true)
            } completion: { _ in

                self.notifyDropTarget(self.controllerForDrop(at: drag.currentLocation), of: drag)

                // In case we have already dropped the view....
                if self.isDragging && !self.isDropping {
                    // if not, notify the delegate that the start of the drag has begun..
                    self.dragDropDelegate?.dragDropController(self, didStartDrag: drag)
                }
            }
        }
    }

    private func dragMoved(_ drag: DragAction) {
        if !isDragging || isDropping { return }

        let location = drag.currentLocation

        // look for a draggable view within our drag interaction view. If one is not found, then something is wrong..
        if let subview = dragInteractionView.hitTest(location, with: nil) {

            // notify any drop targets that the drag is occuring..
            notifyDropTarget(controllerForDrop(at: drag.currentLocation), of: drag)

            let adjustmentForTransform = CGPoint.zero

            // Apply an additional adjustment if the frame of our drag representation has been transformed.
            // This is non standard. It is added since the typical style when dragging and dropping is to scale
            // the view when it's picked up. I thinkk this only works for scale and transform
            if let view = drag.view, view.transform != .identity {
                //
                //            CGRect r = CGRectApplyAffineTransform(drag.view.frame, drag.view.transform);
                //
                //            adjustmentForTransform = CGPointMake((r.size.width - CGRectGetWidth(drag.view.frame)) / 2,
                //                                                 (r.size.height - CGRectGetHeight(drag.view.frame)) / 2);
            }

            // udpate the frame of the drag representation view based on the new location,
            // the adjustment above, and the offset of where we first touched the view.
            subview.center = CGPoint(x: location.x - drag.firstTouchOffset.x
                                     - adjustmentForTransform.x + subview.frame.width / 2,
                                     y: location.y - drag.firstTouchOffset.y
                                     - adjustmentForTransform.y + subview.frame.height / 2)
        }
    }

    private func endDrag(_ drag: DragAction) {
        if !isDragging || isDropping { return }
        isDropping = true

        var firstStepFrame = CGRect.zero
        let secondStepFrame: CGRect
        var animationCompletionBlock: ((Bool) -> Void)?

        // Look for a dropTarget at our current drag location.
        let dropDestination = controllerForDrop(at: drag.currentLocation)

        // Check if we can drop to the found reciever. The default behaviour is YES.
        let canDrop: Bool
        if let view = drag.view {
            canDrop = dragDropDataSource?.dragDropController(self, canDrop: view, to: dropDestination) ?? true
        } else {
            canDrop = true
        }

        if let dropDestination, canDrop, let dataSource = dragDropDataSource, let view = drag.view {
            // In this case, we are moving the view to a different superview,
            // and to a different DragDropController.. Take the nesessary steps....

            // call the datasource and have them return the proper frames
            firstStepFrame = dataSource.dragDropController(self, frameFor: view, in: dropDestination)

            // The correct frame for the view in it's new superviews coordinates
            secondStepFrame = firstStepFrame

            // The correct frame but adjusted to be in the current drag interaction views coordinates.
            // Used to animate the drag representation..
            firstStepFrame = dropDestination.dropTargetView?.convert(firstStepFrame, to: nil) ?? firstStepFrame

            // After animating the drag representation view..
            animationCompletionBlock = { [weak self] _ in
                guard let self else { return }

                self.completeDrop(of: view, into: dropDestination, frame: secondStepFrame)

                self.isDragging = false
                self.isDropping = false
            }
        } else {
            // Here we are just animating the view back to it's original spot. No other changes take place..

            let nextFrame = sourceFrame

            // the frame for the view is just it's original frame..
            firstStepFrame = sourceView?.convert(nextFrame, to: dragInteractionView) ?? nextFrame

            // After animating the drag representation view back to it's spot..
            animationCompletionBlock = { [weak self] _ in
                guard let self else { return }

                if let view = drag.view {
                    view.frame = self.sourceFrame
                    self.sourceView?.addSubview(view)
                }

                self.sourceView = nil
                self.sourceFrame = .zero

                self.isDragging = false
                self.isDropping = false
            }
        }

        let targetFrame = firstStepFrame
        UIView.animate(withDuration: Self.dropAnimationDuration,
                       delay: 0,
                       options: .curveEaseIn) {

            // set the frame..
            drag.view?.frame = targetFrame

            // notify the delegate if they are listening..
            self.dragDropDelegate?.dragDropController(self, willEndDrag: drag, animated: true)

        } completion: { finished in

            self.notifyDropTarget(nil, of: drag)

            // call the animation complete block we set above..
            animationCompletionBlock?(finished)

            // notify the delegate if they are listening..
            self.dragDropDelegate?.dragDropController(self, didEndDrag: drag)

            // On completion of a drag action we should clean up our mess by
            // removing our drag interaction view since it's purpose is now fulfilled..
            self._dragInteractionView?.removeFromSuperview()
            self._dragInteractionView = nil
        }
    }

    /// Hands a dragged view over to the controller it was dropped on: the view
    /// takes the frame the datasource asked for, the drag gesture follows it,
    /// the delegate hears about the move, and the drop target it left closes
    /// the gap.
    ///
    /// The delegate runs before the gap closes, so a delegate that rearranges
    /// the container itself is not fighting the re-flow for the last word.
    internal func completeDrop(of view: UIView,
                               into destination: DragDropController,
                               frame: CGRect) {

        // when the animation of the drag representation view is complete,
        // set the real view's frame to that specified by our datasource,
        // andn then add the view as a subview.
        if let dropTargetView = destination.dropTargetView {
            view.frame = frame
            dropTargetView.addSubview(view)
        }

        // now that the view belongs to another DragDropController,
        // we also should hand over responsiblity of drag/drop operations
        disableDragAction(for: view)
        destination.enableDragAction(for: view)

        // and notify the delegate if they are listening..
        dragDropDelegate?.dragDropController(self, didMove: view, to: destination)

        closeGapInDropTarget(animated: true)
    }

    // MARK: - Helpers

    /// Notifys the datasource when we start, continue, or end dragging above a valid dropTargetView.
    private func notifyDropTarget(_ dropTarget: DragDropController?, of drag: DragAction) {

        if let currentDragDestination, currentDragDestination === dropTarget {

            if let dropTargetView = dropTarget?.dropTargetView {
                drag.currentLocation = dropTargetView.convert(drag.currentLocation, from: nil)
            }

            dragDropDelegate?.dragDropController(self, dragDidMove: drag, destinationController: currentDragDestination)
        } else {

            if let currentDragDestination {

                if let dropTargetView = currentDragDestination.dropTargetView {
                    drag.currentLocation = dropTargetView.convert(drag.currentLocation, from: nil)
                }
                dragDropDelegate?.dragDropController(self, dragDidExit: drag, destinationController: currentDragDestination)

                self.currentDragDestination = nil
            }

            if let dropTarget {
                currentDragDestination = dropTarget

                if let dropTargetView = dropTarget.dropTargetView {
                    drag.currentLocation = dropTargetView.convert(drag.currentLocation, from: nil)
                }
                dragDropDelegate?.dragDropController(self, dragDidEnter: drag, destinationController: dropTarget)
            }
        }
    }

    // MARK: -

    /// Looks for a valid dropTarget at the specified point.
    ///
    /// The Objective-C intended the innermost target to win when several
    /// overlap, but compared each candidate against itself with
    /// isDescendantOfView:, which is true for a view and itself — so the inner
    /// loop matched on its first iteration and the result was arbitrary. Depth
    /// of the superview chain gives the intended answer.
    func controllerForDrop(at point: CGPoint,
                           in coordinateSpace: UIView?,
                           among candidates: [DragDropController]) -> DragDropController? {

        let controllers = candidates.filter { candidate in
            guard let targetView = candidate.dropTargetView else { return false }
            let rect = targetView.convert(targetView.bounds, to: coordinateSpace)
            return rect.contains(point)
        }

        // when we have more than one available, we should give the inner most one priority
        return controllers.max { lhs, rhs in
            Self.viewDepth(of: lhs.dropTargetView) < Self.viewDepth(of: rhs.dropTargetView)
        }
    }

    private func controllerForDrop(at point: CGPoint) -> DragDropController? {
        controllerForDrop(at: point,
                          in: dragInteractionView,
                          among: DragDropControllerRegistry.shared.allControllers)
    }

    private static func viewDepth(of view: UIView?) -> Int {
        var depth = 0
        var current = view?.superview
        while let candidate = current {
            depth += 1
            current = candidate.superview
        }
        return depth
    }

    private func scrollingSuperView(of view: UIView) -> UIView? {

        if view is UITableView || view is UICollectionView
            || view is UITableViewCell || view is UICollectionViewCell
            || view is UIScrollView {
            return view
        }

        guard let superview = view.superview else { return nil }

        return scrollingSuperView(of: superview)
    }

    // MARK: -

    private var dragInteractionView: DragInteractionView {

        if let _dragInteractionView { return _dragInteractionView }

        let top = Self.topMostViewController
        let interactionView = DragInteractionView(frame: top?.view.frame ?? .zero)
        interactionView.hitTestHandler = { [weak interactionView] _, _ in

            var hitView: UIView?
            for subview in interactionView?.subviews ?? [] {
                hitView = subview
            }

            return hitView
        }

        top?.view.addSubview(interactionView)
        _dragInteractionView = interactionView

        return interactionView
    }

    /// The Objective-C used [UIApplication sharedApplication].keyWindow, which
    /// is deprecated and returns nil in a scene-based application.
    static var topMostViewController: UIViewController? {

        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = windowScenes.first { $0.activationState == .foregroundActive } ?? windowScenes.first

        var topViewController = scene?.keyWindow?.rootViewController

        while let presented = topViewController?.presentedViewController {
            topViewController = presented
        }

        return topViewController
    }
}
