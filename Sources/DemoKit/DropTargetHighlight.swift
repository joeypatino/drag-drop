//
//  DropTargetHighlight.swift
//  DemoKit
//

import UIKit

/// How a drop target should look while a drag is somewhere on screen.
///
/// Separated from any view so it can be tested directly: the interesting case
/// is a target that loses to a target *inside itself*, which is exactly the
/// arrangement the Shared Album demo exists to show and exactly the one that is
/// easiest to get backwards.
@MainActor
public enum DropTargetHighlight {

    public enum State: Equatable {
        /// Not involved: nothing is hovering, or the winner is elsewhere.
        case idle
        /// This target would take the drop if the finger lifted now.
        case armed
        /// A legal target, beaten by one nested inside it. Distinct from
        /// refusing, which means the drop would be rejected outright.
        case drained
    }

    public static func state(of target: UIView, whenArmed armed: UIView?) -> State {
        guard let armed else { return .idle }
        if target === armed { return .armed }
        return contains(target, armed) ? .drained : .idle
    }

    /// Is `inner` inside `outer`? Walks the real view hierarchy rather than
    /// comparing frames, because the two can be in different coordinate spaces
    /// -- and walks all the way up rather than checking the immediate
    /// superview, since a nested panel's target sits under its own chrome.
    private static func contains(_ outer: UIView, _ inner: UIView) -> Bool {
        var candidate = inner.superview
        while let view = candidate {
            if view === outer { return true }
            candidate = view.superview
        }
        return false
    }
}
