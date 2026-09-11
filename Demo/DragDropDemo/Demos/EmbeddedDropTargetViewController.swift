//
//  EmbeddedDropTargetViewController.swift
//  DragDropDemo
//
//  Created by Joey Patino on 11/4/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit
import DragDrop
import DemoKit

/// The capability here is an item that is itself a drop target: dropping a
/// file onto a folder. The folder is a 72pt tile parked at the trailing edge
/// of Documents; a file that lands in it shrinks to a pip on
/// `FolderPipLayout`'s 2x2 grid and the folder's badge counts what it holds.
final class EmbeddedDropTargetViewController: DemoViewController {

    private var downloadsController: DragDropController?
    private var documentsController: DragDropController?
    private var folderController: DragDropController?

    private var downloadsPanel: PanelView?
    private var documentsPanel: PanelView?
    private var folderTile: TileChip?

    /// The folder's square. Its chip is taller, because the name sits
    /// underneath as it does on every other item here.
    private static let folderSize: CGFloat = 72
    private static let folderCaptionHeight: CGFloat = 21

    private func hue(for kind: FileItem.Kind) -> DemoTheme.Hue {
        switch kind {
        case .pdf: .rose
        case .image: .mint
        case .archive: .slate
        case .sheet: .teal
        case .text: .amber
        }
    }

    override func loadContent() {
        title = "Files"

        downloadsController = makeController()
        documentsController = makeController()
        folderController = makeController()

        let top = view.safeAreaInsets.top + 12
        let available = view.bounds.height - top - view.safeAreaInsets.bottom - 12
        // Capped: two rows of tiles need nowhere near half a screen, and a
        // panel twice the height of its content reads as a layout mistake.
        let half = CGRect(x: 16, y: top,
                          width: view.bounds.width - 32,
                          height: min(250, available / 2 - 8))

        let downloads = PanelView(title: "Downloads",
                                  subtitle: "Recent",
                                  symbolName: "arrow.down.circle.fill",
                                  hue: .teal)
        downloads.emptyMessage = "Nothing downloaded"
        let downloadsTarget = install(downloads, in: view, frame: half)
        downloadsTarget.accessibilityIdentifier = "panel-downloads"
        downloadsController?.dropTargetView = downloadsTarget
        downloadsPanel = downloads

        let documents = PanelView(title: "Documents",
                                  subtitle: "Drop a file on the folder to file it",
                                  symbolName: "folder.fill",
                                  hue: .indigo)
        let documentsTarget = install(documents, in: view,
                                      frame: half.offsetBy(dx: 0, dy: half.height + 16))
        documentsTarget.accessibilityIdentifier = "panel-documents"
        documentsController?.dropTargetView = documentsTarget
        documentsPanel = documents

        // Five in Downloads, three in Documents -- the demo's original counts.
        fill(downloadsTarget, controller: downloadsController,
             files: Array(SampleData.files.prefix(5)))
        fill(documentsTarget, controller: documentsController,
             files: Array(SampleData.files.dropFirst(5).prefix(3)))

        installFolder(in: documentsTarget)
        refreshCounts()
    }

    private func fill(_ target: UIView, controller: DragDropController?, files: [FileItem]) {
        SlotPopulator.fill(target,
                           count: files.count,
                           metrics: .labelledTile,
                           controller: controller) { index in
            let file = files[index]
            return TileChip(symbolName: file.symbol,
                            hue: self.hue(for: file.kind),
                            caption: file.name,
                            captionPlacement: .below,
                            identifier: "file-\(file.id)")
        }
    }

    /// The folder is placed by hand at the trailing edge, not by `SlotLayout`,
    /// so the ordinary tiles keep their run and flow around it.
    private func installFolder(in target: UIView) {
        let size = Self.folderSize
        let height = size + Self.folderCaptionHeight
        let tile = TileChip(symbolName: "folder.fill",
                            hue: .indigo,
                            caption: "Projects",
                            captionPlacement: .below,
                            identifier: "folder-projects")
        tile.frame = CGRect(x: target.bounds.width - size - DemoTheme.Space.s,
                            y: target.bounds.height - height - DemoTheme.Space.s,
                            width: size,
                            height: height)
        target.addSubview(tile)

        folderController?.dropTargetView = tile
        folderTile = tile
    }

    /// Pips belong in the folder's square, not in its whole chip. The chip now
    /// includes the name underneath, and centring the grid in that would push
    /// the files down across their own label.
    private func folderPipArea(of target: UIView) -> CGRect {
        (target as? TileChip)?.tileBounds ?? target.bounds
    }

    private func refreshCounts() {
        downloadsPanel?.count = downloadsController?.draggableViews.count
        downloadsPanel?.updateEmptyState()

        // Documents counts only the loose tiles; what is in the folder is the
        // folder's own badge.
        documentsPanel?.count = documentsController?.draggableViews.count
        folderTile?.badge = folderController?.draggableViews.count
    }

    override func dragDropController(_ controller: DragDropController,
                                     didMove view: UIView,
                                     to destination: DragDropController) {
        super.dragDropController(controller, didMove: view, to: destination)
        refreshCounts()
    }

    /// The folder is a tile, not a panel, so the base class's panel feedback
    /// does not reach it -- and must not: lighting the whole Documents panel
    /// when the drop is going into the folder would promise the wrong
    /// destination.
    override func dragDropController(_ controller: DragDropController,
                                     dragDidEnter drag: DragAction,
                                     destinationController destination: DragDropController) {
        super.dragDropController(controller, dragDidEnter: drag, destinationController: destination)
        guard destination === folderController else { return }

        let accepted = dragDropController(controller, canDrop: drag.view ?? UIView(), to: destination)
        UIView.animate(withDuration: 0.15) {
            self.folderTile?.setDropState(accepted)
        }
    }

    override func dragDropController(_ controller: DragDropController,
                                     dragDidExit drag: DragAction,
                                     destinationController destination: DragDropController) {
        super.dragDropController(controller, dragDidExit: drag, destinationController: destination)
        guard destination === folderController else { return }
        UIView.animate(withDuration: 0.15) {
            self.folderTile?.setDropState(false)
        }
    }

    override func dragDropController(_ controller: DragDropController, didEndDrag drag: DragAction) {
        super.dragDropController(controller, didEndDrag: drag)
        // The folder is not in `panels`, so clearing those does not reach it.
        folderTile?.setDropState(false)
    }
}

// MARK: - DragDropController Datasource

extension EmbeddedDropTargetViewController: DragDropControllerDataSource {

    func dragDropController(_ controller: DragDropController, shouldDrag view: UIView) -> Bool {
        // The folder itself stays put.
        view !== folderTile
    }

    func dragDropController(_ controller: DragDropController,
                            canDrop view: UIView,
                            to destination: DragDropController?) -> Bool {
        guard controller !== destination else { return false }
        // Past four, the folder keeps counting but has nowhere to draw.
        if destination === folderController {
            return (folderController?.draggableViews.count ?? 0) < FolderPipLayout.capacity
        }
        return true
    }

    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            in destination: DragDropController) -> CGRect {
        guard let target = destination.dropTargetView else { return .zero }

        if destination === folderController {
            return FolderPipLayout.frame(at: destination.draggableViews.count,
                                         in: folderPipArea(of: target)) ?? .zero
        }

        // Not `view.frame.size`: a file dragged out of the folder is 24pt at
        // that moment, and would land as a 24pt tile in a full-size slot.
        return SlotLayout.frame(at: destination.draggableViews.count,
                                size: SlotLayout.Metrics.labelledTile.itemSize,
                                in: target,
                                metrics: .labelledTile)
    }

    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            at index: Int) -> CGRect? {
        guard let target = controller.dropTargetView else { return nil }

        if controller === folderController {
            return FolderPipLayout.frame(at: index, in: folderPipArea(of: target))
        }

        return SlotLayout.frame(at: index,
                                size: SlotLayout.Metrics.labelledTile.itemSize,
                                in: target,
                                metrics: .labelledTile)
    }
}
