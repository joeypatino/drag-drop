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

final class NormalTableViewController: UIViewController {

    private var targetController: DragDropController?
    private var table: UITableView?
    private var targetView: UIView?

    /// The table is exactly as long as this. Dragging a row's view away removes
    /// an item; dropping one on the table adds one.
    private var rows: [Int] = Array(0..<10)
    private var nextItem = 10

    private var hasLoadedContent = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !hasLoadedContent else { return }
        hasLoadedContent = true
        loadContent()
    }

    private func loadContent() {
        targetController = controller()

        let frame = CGRect(x: 0, y: 0,
                           width: view.frame.width / 2,
                           height: view.frame.height - 64)

        let table = UITableView(frame: frame, style: .plain)

        table.separatorColor = .black
        table.separatorStyle = .singleLine
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        table.delegate = self
        table.dataSource = self
        view.addSubview(table)
        table.reloadData()
        self.table = table

        let targetView = UIView(frame: frame.insetBy(dx: 20, dy: 20).offsetBy(dx: frame.width, dy: 0))
        targetView.backgroundColor = .white
        view.addSubview(targetView)
        targetController?.dropTargetView = targetView
        applyLabel("Drop Target", to: targetView)

        targetView.layer.borderColor = UIColor.black.cgColor
        targetView.layer.borderWidth = 2.0
        self.targetView = targetView
    }

    /// Only the panel needs one of these now. The table builds and owns its own.
    private func controller() -> DragDropController {
        let controller = DragDropController()
        controller.dragDropDataSource = self
        return controller
    }

    fileprivate func applyLabel(_ string: String, to view: UIView) {
        let label = UILabel()
        label.text = string
        label.textColor = .white
        label.sizeToFit()
        label.center = CGPoint(x: view.frame.size.width / 2, y: view.frame.size.height / 2)
        view.addSubview(label)
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

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.selectionStyle = .none
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let dragView = UIView()
        dragView.frame = CGRect(x: 10, y: 10, width: tableView.frame.width - 20, height: 70)
        dragView.backgroundColor = .blue

        // Numbered like the collection view demos, so it is visible which row
        // went where rather than just that something moved.
        applyLabel("\(rows[indexPath.row])", to: dragView)

        // The Objective-C added this straight to the cell, which worked in 2015
        // because a directly-added subview sat above contentView. Modern UIKit
        // keeps UITableViewCellContentView on top, so the view still rendered
        // (contentView is transparent) but contentView swallowed every touch and
        // the drag never started.
        cell.contentView.addSubview(dragView)

        // That is the whole wiring. The table works out which row this view is
        // in when a drag begins, and calls the two methods below.
        tableView.enableDragAndDrop(for: dragView)

        return cell
    }

    func tableView(_ tableView: UITableView, didRemoveRowAt indexPath: IndexPath) {
        rows.remove(at: indexPath.row)
    }

    func tableView(_ tableView: UITableView, didInsertRowAt indexPath: IndexPath, for view: UIView) {
        rows.insert(nextItem, at: indexPath.row)
        nextItem += 1
    }
}

// MARK: - DragDropController Datasource
//
// Only for the Drop Target panel, which is a plain view: it has no layout of
// its own, so the demo places arriving views and closes the gap when one leaves.

extension NormalTableViewController: DragDropControllerDataSource {

    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            in destination: DragDropController) -> CGRect {
        guard let dropTargetView = destination.dropTargetView else { return .zero }

        return panelSlot(at: destination.draggableViews.count,
                         height: view.frame.height,
                         in: dropTargetView)
    }

    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            at index: Int) -> CGRect? {
        guard let dropTargetView = controller.dropTargetView else { return nil }

        return panelSlot(at: index, height: view.frame.height, in: dropTargetView)
    }

    /// The panel is one slot wide, so each view gets its own row.
    private func panelSlot(at index: Int, height: CGFloat, in panel: UIView) -> CGRect {
        SlotLayout.frame(at: index,
                         size: CGSize(width: panel.frame.width - 10, height: height),
                         in: panel)
    }
}
