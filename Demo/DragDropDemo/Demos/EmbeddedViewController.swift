//
//  EmbeddedViewController.swift
//  DragDropDemo
//
//  Created by Joey Patino on 11/4/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit
import DragDrop
import DemoKit

/// A drop target nested directly inside another drop target: photos move
/// between the roll and an album that lives inside it.
final class EmbeddedViewController: DemoViewController {

    private var rollController: DragDropController?
    private var albumController: DragDropController?

    private var rollPanel: PanelView?
    private var albumPanel: PanelView?

    override func loadContent() {
        title = "Shared Album"

        rollController = makeController()
        albumController = makeController()

        let outer = CGRect(x: 16,
                           y: view.safeAreaInsets.top + 12,
                           width: view.bounds.width - 32,
                           height: min(500, view.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom - 24))

        let roll = PanelView(title: "Camera Roll",
                             subtitle: "All photos on this device",
                             symbolName: "photo.on.rectangle",
                             hue: .teal)
        let rollTarget = install(roll, in: view, frame: outer)
        rollTarget.accessibilityIdentifier = "panel-roll"
        rollController?.dropTargetView = rollTarget
        rollPanel = roll

        // The album is a subview of the roll's own drop target, which is what
        // makes this a target inside a target.
        let album = PanelView(title: "Iceland 2024",
                              subtitle: "Shared with 3 people",
                              symbolName: "person.2.fill",
                              hue: .indigo)
        album.isReceivingZone = true
        album.emptyMessage = "Drag photos here to share them"

        // Starts just below the roll's first row of thumbnails, leaving the
        // roll a second row to grow into rather than a dead band.
        let albumTop: CGFloat = 132
        let albumFrame = CGRect(x: 0,
                                y: albumTop,
                                width: rollTarget.bounds.width,
                                height: rollTarget.bounds.height - albumTop)
        let albumTarget = install(album, in: rollTarget, frame: albumFrame)
        albumTarget.accessibilityIdentifier = "panel-album"
        albumController?.dropTargetView = albumTarget
        albumPanel = album

        // Three in the album, five in the roll -- the demo's original counts.
        fill(albumTarget, controller: albumController,
             photos: Array(SampleData.photos.prefix(3)))
        fill(rollTarget, controller: rollController,
             photos: Array(SampleData.photos.dropFirst(3).prefix(5)))

        refreshCounts()
    }

    private func fill(_ target: UIView, controller: DragDropController?, photos: [Photo]) {
        SlotPopulator.fill(target,
                           count: photos.count,
                           metrics: .thumbnail,
                           controller: controller) { index in
            let photo = photos[index]
            return SwatchChip(seed: photo.seed, identifier: "photo-\(photo.id)")
        }
    }

    private func refreshCounts() {
        rollPanel?.count = rollController?.draggableViews.count
        albumPanel?.count = albumController?.draggableViews.count
        albumPanel?.updateEmptyState()
    }

    override func dragDropController(_ controller: DragDropController,
                                     didMove view: UIView,
                                     to destination: DragDropController) {
        super.dragDropController(controller, didMove: view, to: destination)
        refreshCounts()
    }
}

// MARK: - DragDropController Datasource

extension EmbeddedViewController: DragDropControllerDataSource {

    func dragDropController(_ controller: DragDropController, shouldDrag view: UIView) -> Bool {
        true
    }

    func dragDropController(_ controller: DragDropController,
                            canDrop view: UIView,
                            to destination: DragDropController?) -> Bool {
        controller !== destination
    }

    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            in destination: DragDropController) -> CGRect {
        guard let target = destination.dropTargetView else { return .zero }
        // Not `view.frame.size`: the lift scales the thumbnail for the duration
        // of the drag, and `frame` is the transformed box, which is wide enough
        // to wrap the arrival onto a row of its own.
        return SlotLayout.frame(at: destination.draggableViews.count,
                                size: SlotLayout.Metrics.thumbnail.itemSize,
                                in: target,
                                metrics: .thumbnail)
    }

    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            at index: Int) -> CGRect? {
        guard let target = controller.dropTargetView else { return nil }
        return SlotLayout.frame(at: index,
                                size: SlotLayout.Metrics.thumbnail.itemSize,
                                in: target,
                                metrics: .thumbnail)
    }
}
