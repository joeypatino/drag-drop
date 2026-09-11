//
//  FourByFourViewController.swift
//  DragDropDemo
//
//  Created by Joey Patino on 11/4/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//
//  Was 4x4ViewController.m, whose class was named _x4ViewController because
//  the file name is not a legal identifier.
//

import UIKit
import DragDrop
import DemoKit

/// Four peer drop targets. The capability on show is that a controller can
/// refuse a drop: a person cannot be dropped back onto the shift they are
/// already on.
final class FourByFourViewController: DemoViewController {

    private struct Shift {
        let title: String
        let hours: String
        let symbol: String
        let hue: DemoTheme.Hue
        let headcount: Int
        let slug: String
    }

    /// Headcounts are the demo's original 5 / 4 / 3 / 6, in the original
    /// top-left, top-right, bottom-left, bottom-right order.
    private let shifts: [Shift] = [
        Shift(title: "Morning",   hours: "06:00 – 14:00", symbol: "sunrise.fill",    hue: .amber,  headcount: 5, slug: "morning"),
        Shift(title: "Afternoon", hours: "14:00 – 22:00", symbol: "sun.max.fill",    hue: .coral,  headcount: 4, slug: "afternoon"),
        Shift(title: "Evening",   hours: "22:00 – 02:00", symbol: "sunset.fill",     hue: .violet, headcount: 3, slug: "evening"),
        Shift(title: "Night",     hours: "02:00 – 06:00", symbol: "moon.stars.fill", hue: .indigo, headcount: 6, slug: "night")
    ]

    private var controllers: [DragDropController] = []

    override func loadContent() {
        title = "Shift Rota"

        let cellWidth = view.bounds.width / 2
        let cellHeight = (view.bounds.height - view.safeAreaInsets.top) / 2
        var nextStaffIndex = 0

        for (index, shift) in shifts.enumerated() {
            let controller = makeController()
            controllers.append(controller)

            let panel = PanelView(title: shift.title,
                                  subtitle: shift.hours,
                                  symbolName: shift.symbol,
                                  hue: shift.hue)
            panel.emptyMessage = "No cover"

            let cell = CGRect(x: CGFloat(index % 2) * cellWidth,
                              y: view.safeAreaInsets.top + CGFloat(index / 2) * cellHeight,
                              width: cellWidth,
                              height: cellHeight)
            let target = install(panel, in: view, frame: cell.insetBy(dx: 8, dy: 8))
            target.accessibilityIdentifier = "panel-\(shift.slug)"
            controller.dropTargetView = target

            // Read out of the mutating cursor before the closure captures it.
            let first = nextStaffIndex
            SlotPopulator.fill(target,
                               count: shift.headcount,
                               metrics: .chip,
                               controller: controller) { offset in
                let member = SampleData.staff[first + offset]
                return AvatarChip(name: member.name, identifier: "staff-\(member.id)")
            }
            nextStaffIndex += shift.headcount

            panel.count = shift.headcount
            panel.updateEmptyState()
        }
    }

    /// Badges and the "No cover" placeholder track the panels after every move.
    /// `panels` comes from the base class and is in install order, which is the
    /// order the controllers were made in.
    private func refreshCounts() {
        for (panel, controller) in zip(panels, controllers) {
            panel.count = controller.draggableViews.count
            panel.updateEmptyState()
        }
    }

    override func dragDropController(_ controller: DragDropController,
                                     didMove view: UIView,
                                     to destination: DragDropController) {
        super.dragDropController(controller, didMove: view, to: destination)
        refreshCounts()
    }
}

// MARK: - DragDropController Datasource

extension FourByFourViewController: DragDropControllerDataSource {

    func dragDropController(_ controller: DragDropController, shouldDrag view: UIView) -> Bool {
        true
    }

    /// A person cannot be dropped onto the shift they are already on.
    func dragDropController(_ controller: DragDropController,
                            canDrop view: UIView,
                            to destination: DragDropController?) -> Bool {
        controller !== destination
    }

    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            in destination: DragDropController) -> CGRect {
        guard let target = destination.dropTargetView else { return .zero }
        // `draggableViews` counts only the avatars, so the panel's own chrome
        // does not shift the slot index.
        return SlotLayout.frame(at: destination.draggableViews.count,
                                size: view.frame.size,
                                in: target,
                                metrics: .chip)
    }

    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            at index: Int) -> CGRect? {
        guard let target = controller.dropTargetView else { return nil }
        return SlotLayout.frame(at: index, size: view.frame.size, in: target, metrics: .chip)
    }
}
