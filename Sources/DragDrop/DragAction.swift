//
//  DragAction.swift
//  DragDrop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit

@MainActor
public final class DragAction {
    /// this is the view that is being dragged.
    public weak var view: UIView?

    /// this is the current position of the view as it is being dragged.
    public var currentLocation: CGPoint = .zero

    /// the offset (in the views coordinates) of the touch that started the drag.
    public var firstTouchOffset: CGPoint = .zero

    /// this is the views frame in its original superviews coordinate.
    public private(set) var frame: CGRect

    /// The view's superview when the drag began.
    ///
    /// `startDrag` reparents the dragged view into the interaction view before
    /// `willStartDrag` fires, so a delegate cannot reach the container the view
    /// came from through `view.superview`. This is that container.
    public internal(set) weak var sourceView: UIView?

    public init(view: UIView) {
        self.view = view
        self.frame = view.frame
        self.sourceView = view.superview
    }
}
