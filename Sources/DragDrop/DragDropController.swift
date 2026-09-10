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
    public weak var dragDropDataSource: (any DragDropControllerDataSource)?
    public weak var dragDropDelegate: (any DragDropControllerDelegate)?

    /// This is a drop target for views. If set, this view will be able to
    /// receive dropped views.
    public weak var dropTargetView: UIView?

    public init() {
        DragDropControllerRegistry.shared.add(self)
    }
}
