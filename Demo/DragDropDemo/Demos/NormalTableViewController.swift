//
//  NormalTableViewController.swift
//  DragDropDemo
//
//  Created by Joey Patino on 11/4/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit
import DragDrop

final class NormalTableViewController: UIViewController {

    private var targetController: DragDropController?
    private var table: UITableView?
    private var targetView: UIView?
    private var tableControllers: [DragDropController] = []

    private var hasLoadedContent = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !hasLoadedContent else { return }
        hasLoadedContent = true
        loadContent()
    }

    private func loadContent() {
        targetController = controller()
        tableControllers = []

        let frame = CGRect(x: 0, y: 0,
                           width: view.frame.width / 2,
                           height: view.frame.height - 64)

        let table = UITableView(frame: frame, style: .plain)

        table.separatorColor = .black
        table.separatorStyle = .singleLine

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

    private func controller() -> DragDropController {
        let controller = DragDropController()
        controller.dragDropDataSource = self
        controller.dragDropDelegate = self
        return controller
    }

    private func applyLabel(_ string: String, to view: UIView) {
        let label = UILabel()
        label.text = string
        label.sizeToFit()
        label.center = CGPoint(x: view.frame.size.width / 2, y: view.frame.size.height / 2)
        view.addSubview(label)
    }
}

// MARK: - UITableView

extension NormalTableViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        10
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        90
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none

        let dragView = UIView()
        dragView.frame = CGRect(x: 10, y: 10, width: tableView.frame.width - 20, height: 70)
        dragView.backgroundColor = .blue

        // The Objective-C added this straight to the cell, which worked in 2015
        // because a directly-added subview sat above contentView. Modern UIKit
        // keeps UITableViewCellContentView on top, so the view still rendered
        // (contentView is transparent) but contentView swallowed every touch and
        // the drag never started. contentView is the correct parent, and it is
        // also the correct drop target for a view returning home.
        cell.contentView.addSubview(dragView)

        let cellController = controller()
        cellController.dropTargetView = cell.contentView
        cellController.enableDragAction(for: dragView)
        tableControllers.append(cellController)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - DragDropController Delegate

extension NormalTableViewController: DragDropControllerDelegate {

    func dragDropController(_ controller: DragDropController, willStartDrag drag: DragAction, animated: Bool) {
    }

    func dragDropController(_ controller: DragDropController, didStartDrag drag: DragAction) {
    }

    func dragDropController(_ controller: DragDropController, willEndDrag drag: DragAction, animated: Bool) {
    }

    func dragDropController(_ controller: DragDropController, didEndDrag drag: DragAction) {
    }

    // MARK: -

    func dragDropController(_ controller: DragDropController,
                            dragDidEnter drag: DragAction,
                            destinationController destination: DragDropController) {
        destination.dropTargetView?.layer.borderColor = UIColor.red.cgColor
        destination.dropTargetView?.layer.borderWidth = 2.0
    }

    func dragDropController(_ controller: DragDropController,
                            dragDidMove drag: DragAction,
                            destinationController destination: DragDropController) {
    }

    func dragDropController(_ controller: DragDropController,
                            dragDidExit drag: DragAction,
                            destinationController destination: DragDropController) {

        if destination.dropTargetView === targetView {
            destination.dropTargetView?.layer.borderColor = UIColor.black.cgColor
        } else {
            destination.dropTargetView?.layer.borderWidth = 0.0
        }
    }

    // MARK: -

    func dragDropController(_ controller: DragDropController,
                            didMove view: UIView,
                            to destination: DragDropController) {
    }
}

// MARK: - DragDropController Datasource

extension NormalTableViewController: DragDropControllerDataSource {

    func dragDropController(_ controller: DragDropController, shouldDrag view: UIView) -> Bool {
        true
    }

    func dragDropController(_ controller: DragDropController,
                            canDrop view: UIView,
                            to destination: DragDropController?) -> Bool {
        if controller === destination { return false }
        return true
    }

    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            in destination: DragDropController) -> CGRect {
        guard let dropTargetView = destination.dropTargetView else { return .zero }

        if destination === targetController {
            let count = dropTargetView.subviews.count - 1
            return CGRect(x: 5,
                          y: CGFloat(count) * view.frame.height + (CGFloat(count + 1) * 5),
                          width: dropTargetView.frame.width - 10,
                          height: view.frame.height)
        }

        return dropTargetView.bounds.insetBy(dx: 10, dy: 10)
    }
}
