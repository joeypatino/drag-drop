//
//  DragInteractionView.swift
//  DragDrop
//
//  Created by Joey Patino on 11/2/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit

@MainActor
final class DragInteractionView: UIView {
    var hitTestHandler: ((CGPoint, UIEvent?) -> UIView?)?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hitTestHandler, let hitView = hitTestHandler(point, event) {
            return hitView
        }

        return super.hitTest(point, with: event)
    }
}
