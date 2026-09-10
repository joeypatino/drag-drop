//
//  DragDropControllerRegistry.swift
//  DragDrop
//
//  Created by Joey Patino on 11/1/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import Foundation

/// DragDropControllerRegistry automatically tracks all created
/// DragDropControllers. You should not use this type yourself; the
/// DragDropController uses it internally.
///
/// Ported from DragDropControllerManager. The original stored controllers in a
/// CFMutableArray with NULL retain/release callbacks, which is
/// unsafe-unretained rather than weak: a deallocated controller left a dangling
/// pointer behind that controllerForDropAtPoint: would later message.
///
/// NSHashTable.weakObjects() was the obvious replacement, but it only compacts
/// on mutation, so allObjects can still report a controller that has gone away.
/// A registry that is read on every drag movement should not have that
/// ambiguity, so entries are boxed weakly and filtered on read instead. There
/// is deliberately no remove(_:) and no deinit counterpart, which also sidesteps
/// Swift 6's prohibition on main-actor-isolated work in a deinitializer.
@MainActor
final class DragDropControllerRegistry {
    static let shared = DragDropControllerRegistry()

    private struct WeakBox {
        weak var controller: DragDropController?
    }

    private var controllers: [WeakBox] = []

    private init() {}

    func add(_ controller: DragDropController) {
        // Compact on write so the array cannot grow without bound.
        controllers.removeAll { $0.controller == nil }
        controllers.append(WeakBox(controller: controller))
    }

    var allControllers: [DragDropController] {
        controllers.compactMap(\.controller)
    }
}
