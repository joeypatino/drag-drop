//
//  DragDropGesture.swift
//  DragDrop
//
//  Created by Joey Patino on 11/3/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

@MainActor
public final class DragDropGesture: UIGestureRecognizer {
    public private(set) var touchBeginOffset: CGPoint = .zero
    public var gestureBeginDelay: TimeInterval = 0

    private var touchBeginTimestamp: TimeInterval = 0

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        state = .possible
        touchBeginTimestamp = event.timestamp
        touchBeginOffset = location(in: view)
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        let touchMoveDelay = event.timestamp - touchBeginTimestamp

        if state == .possible {
            state = (touchMoveDelay > gestureBeginDelay) ? .began : .failed
        } else {
            state = .changed
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        state = .ended
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        state = .cancelled
    }

    public override func reset() {
        // The Objective-C did not call super here. UIGestureRecognizer requires
        // subclasses to, or internal recognizer state goes stale between
        // gestures. That is an API contract, not a change to the algorithm.
        super.reset()
        touchBeginTimestamp = 0
        state = .possible
    }
}
