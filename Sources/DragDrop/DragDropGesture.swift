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

    /// For a gesture `DragDropController` creates, this is recalculated when
    /// each touch lands, from whether the view is then inside a scroll view,
    /// so a value set directly here does not persist.
    public var gestureBeginDelay: TimeInterval = 0

    private var touchBeginTimestamp: TimeInterval = 0

    /// Works `gestureBeginDelay` out from where the view is when a touch
    /// lands, rather than when dragging was enabled. A SwiftUI representable
    /// enables dragging before its view has a superview, so an enable-time
    /// answer never sees the scroll view it later sits in.
    var beginDelayProvider: (@MainActor (UIView) -> TimeInterval)?

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        // Only the first finger starts a drag, and only while nothing is under
        // way. A second one used to re-arm the recognizer: `location(in:)`
        // answers the centroid of every touch, so the offset stopped
        // describing the finger that picked the view up and it jumped; and the
        // timestamp went back to now, so the next move read as inside
        // `gestureBeginDelay` and failed the gesture. A failed gesture sends no
        // action at all, so the controller never hears `.ended`, the drag never
        // finishes, and the interaction view is left over the whole screen
        // swallowing every touch in the app. `reset()` re-arms us instead.
        guard state == .possible, numberOfTouches <= 1 else { return }

        if let view, let beginDelayProvider {
            gestureBeginDelay = beginDelayProvider(view)
        }

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
