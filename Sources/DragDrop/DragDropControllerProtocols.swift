//
//  DragDropControllerProtocols.swift
//  DragDrop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit

/// Every member here was @optional in Objective-C and guarded by
/// respondsToSelector: at each call site. The default implementations below
/// carry that intent, and the guards disappear.
@MainActor
public protocol DragDropControllerDelegate: AnyObject {

    // MARK: - Drag callbacks

    func dragDropController(_ controller: DragDropController,
                            willStartDrag drag: DragAction,
                            animated: Bool)

    func dragDropController(_ controller: DragDropController,
                            didStartDrag drag: DragAction)

    func dragDropController(_ controller: DragDropController,
                            willEndDrag drag: DragAction,
                            animated: Bool)

    func dragDropController(_ controller: DragDropController,
                            didEndDrag drag: DragAction)

    func dragDropController(_ controller: DragDropController,
                            dragDidEnter drag: DragAction,
                            destinationController destination: DragDropController)

    func dragDropController(_ controller: DragDropController,
                            dragDidMove drag: DragAction,
                            destinationController destination: DragDropController)

    func dragDropController(_ controller: DragDropController,
                            dragDidExit drag: DragAction,
                            destinationController destination: DragDropController)

    // MARK: -

    func dragDropController(_ controller: DragDropController,
                            didMove view: UIView,
                            to destination: DragDropController)
}

public extension DragDropControllerDelegate {
    func dragDropController(_ controller: DragDropController, willStartDrag drag: DragAction, animated: Bool) {}
    func dragDropController(_ controller: DragDropController, didStartDrag drag: DragAction) {}
    func dragDropController(_ controller: DragDropController, willEndDrag drag: DragAction, animated: Bool) {}
    func dragDropController(_ controller: DragDropController, didEndDrag drag: DragAction) {}
    func dragDropController(_ controller: DragDropController, dragDidEnter drag: DragAction, destinationController destination: DragDropController) {}
    func dragDropController(_ controller: DragDropController, dragDidMove drag: DragAction, destinationController destination: DragDropController) {}
    func dragDropController(_ controller: DragDropController, dragDidExit drag: DragAction, destinationController destination: DragDropController) {}
    func dragDropController(_ controller: DragDropController, didMove view: UIView, to destination: DragDropController) {}
}

@MainActor
public protocol DragDropControllerDataSource: AnyObject {

    /// Was @optional. Defaults to true.
    func dragDropController(_ controller: DragDropController,
                            shouldDrag view: UIView) -> Bool

    /// Was @optional. Defaults to true. The destination is optional because
    /// the controller calls this with no destination when the drag ends
    /// outside every drop target.
    func dragDropController(_ controller: DragDropController,
                            canDrop view: UIView,
                            to destination: DragDropController?) -> Bool

    /// Was @required. Only reached when a destination exists and the drop is
    /// permitted, so the destination is non-optional here.
    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            in destination: DragDropController) -> CGRect

    /// Optional. Defaults to nil.
    ///
    /// The frame `view` should occupy as the `index`-th of the controller's
    /// `draggableViews`. Implement it and a drop target closes the gap when one
    /// of its views is dragged away: the controller walks the views that are
    /// left and moves each one to the frame you return for its new index.
    ///
    /// Return nil -- as the default does -- to leave the remaining views where
    /// they are. A nil for any one view abandons the whole re-flow, so a
    /// partial answer cannot pile views on top of each other.
    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            at index: Int) -> CGRect?
}

public extension DragDropControllerDataSource {
    func dragDropController(_ controller: DragDropController, shouldDrag view: UIView) -> Bool { true }
    func dragDropController(_ controller: DragDropController, canDrop view: UIView, to destination: DragDropController?) -> Bool { true }
    func dragDropController(_ controller: DragDropController, frameFor view: UIView, at index: Int) -> CGRect? { nil }
}
