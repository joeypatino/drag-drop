//
//  NormalTableViewController.swift
//  DragDropDemo
//
//  Created by Joey Patino on 11/4/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit
import DragDrop
import DemoKit

/// The play queue. A row dragged out is removed and the table closes the gap;
/// a card dropped onto the table inserts a row.
final class NormalTableViewController: DemoViewController {

    private var savedController: DragDropController?
    private var table: UITableView?
    private var savedPanel: PanelView?

    /// The table is exactly as long as this.
    private var rows: [Track] = Array(SampleData.tracks.prefix(10))

    /// Where an inserted row's content comes from, so a dropped card is a real
    /// song rather than a running integer.
    private var nextTrackIndex = 10

    override func loadContent() {
        title = "Up Next"

        savedController = makeController()

        let top = view.safeAreaInsets.top
        // The queue gets the larger share: it holds the text, and an even
        // split left track titles truncating mid-word.
        let queueWidth = (view.bounds.width * 0.58).rounded()
        let column = CGRect(x: 0, y: top,
                            width: queueWidth,
                            height: view.bounds.height - top)

        let table = UITableView(frame: column, style: .plain)
        table.backgroundColor = DemoTheme.Surface.background
        table.separatorStyle = .none
        table.rowHeight = 90
        table.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 24, right: 0)
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        table.delegate = self
        table.dataSource = self
        table.accessibilityIdentifier = "queue-table"
        view.addSubview(table)
        table.reloadData()
        self.table = table

        // No subtitle: the column is too narrow for one, and the badge
        // already says how many are in here.
        let saved = PanelView(title: "Saved",
                              symbolName: "bookmark.fill",
                              hue: .indigo)
        saved.emptyMessage = "Drag a track here"
        let panelFrame = CGRect(x: queueWidth, y: top,
                                width: view.bounds.width - queueWidth,
                                height: view.bounds.height - top)
        let target = install(saved, in: view, frame: panelFrame.insetBy(dx: 10, dy: 12))
        target.accessibilityIdentifier = "panel-saved"
        register(target, with: savedController)
        savedPanel = saved

        refreshCount()

        if AnimationTrace.isEnabled, let window = view.window {
            AnimationTrace.reset()
            AnimationTrace.installMarker(in: window)
            AnimationTrace.startSampling(table)
        }
    }

    private func refreshCount() {
        savedPanel?.count = savedController?.draggableViews.count
        savedPanel?.updateEmptyState()
    }

    override func dragDropController(_ controller: DragDropController,
                                     didMove view: UIView,
                                     to destination: DragDropController) {
        super.dragDropController(controller, didMove: view, to: destination)
        AnimationTrace.event("didMove")
        refreshCount()
    }

    // MARK: - Trace hooks
    //
    // Only reached under `-animation-trace`; `event` is a no-op otherwise.

    override func dragDropController(_ controller: DragDropController,
                                     willEndDrag drag: DragAction,
                                     animated: Bool) {
        super.dragDropController(controller, willEndDrag: drag, animated: animated)
        AnimationTrace.event("willEndDrag")
    }

    override func dragDropController(_ controller: DragDropController,
                                     didEndDrag drag: DragAction) {
        super.dragDropController(controller, didEndDrag: drag)
        AnimationTrace.event("didEndDrag")
    }
}

// MARK: - UITableView

extension NormalTableViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        90
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension NormalTableViewController: UITableViewDataSourceRowMoveSupport {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let track = rows[indexPath.row]
        let row = TrackRowView(track: track, identifier: "track-\(track.id)")
        row.frame = CGRect(x: 8, y: 6, width: tableView.frame.width - 16, height: 78)

        // The Objective-C added this straight to the cell, which worked in 2015
        // because a directly-added subview sat above contentView. Modern UIKit
        // keeps UITableViewCellContentView on top, so the view still rendered
        // (contentView is transparent) but contentView swallowed every touch and
        // the drag never started.
        cell.contentView.addSubview(row)
        AnimationTrace.mark(row, for: track)

        // That is the whole wiring. The table works out which row this view is
        // in when a drag begins, and calls the two methods below.
        tableView.enableDragAndDrop(for: row)

        return cell
    }

    func tableView(_ tableView: UITableView, didRemoveRowAt indexPath: IndexPath) {
        AnimationTrace.event("didRemoveRow-\(indexPath.row)")
        rows.remove(at: indexPath.row)
    }

    func tableView(_ tableView: UITableView, didInsertRowAt indexPath: IndexPath, for view: UIView) {
        // A row that came from this table keeps its own track; anything else
        // takes the next unused one.
        AnimationTrace.event("didInsertRow-\(indexPath.row)")
        let track = (view as? TrackRowView)?.track ?? nextTrack()
        rows.insert(track, at: indexPath.row)
    }

    private func nextTrack() -> Track {
        let track = SampleData.tracks[nextTrackIndex % SampleData.tracks.count]
        nextTrackIndex += 1
        return track
    }
}

// MARK: - DragDropController Datasource
//
// Only for the Saved panel, which is a plain view: it has no layout of its own,
// so the demo places arriving views and closes the gap when one leaves.

extension NormalTableViewController: DragDropControllerDataSource {

    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            in destination: DragDropController) -> CGRect {
        guard let target = destination.dropTargetView else { return .zero }
        return panelSlot(at: destination.draggableViews.count,
                         height: view.frame.height,
                         in: target)
    }

    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            at index: Int) -> CGRect? {
        guard let target = controller.dropTargetView else { return nil }
        return panelSlot(at: index, height: view.frame.height, in: target)
    }

    /// The panel is one slot wide, so each card gets its own row.
    private func panelSlot(at index: Int, height: CGFloat, in panel: UIView) -> CGRect {
        SlotLayout.frame(at: index,
                         size: CGSize(width: panel.frame.width - 10, height: height),
                         in: panel)
    }
}
