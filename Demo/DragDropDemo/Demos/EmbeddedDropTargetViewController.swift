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

final class EmbeddedDropTargetViewController: UIViewController {

    private var containerController: DragDropController?
    private var outerEmbeddedController: DragDropController?
    private var innerEmbeddedController: DragDropController?

    private var upperView: UIView?
    private var lowerView: UIView?

    private var hasLoadedContent = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !hasLoadedContent else { return }
        hasLoadedContent = true
        loadContent()
    }

    private func loadContent() {
        containerController = controller()
        outerEmbeddedController = controller()
        innerEmbeddedController = controller()

        let frame = CGRect(x: 10, y: 10,
                           width: view.frame.width - 20,
                           height: view.frame.height / 2 - 32 - 20)

        let upperView = UIView(frame: frame)
        upperView.backgroundColor = .white
        view.addSubview(upperView)
        containerController?.dropTargetView = upperView
        applyLabel("Upper View", to: upperView)

        upperView.layer.borderColor = UIColor.black.cgColor
        upperView.layer.borderWidth = 2.0
        self.upperView = upperView

        let lowerView = UIView(frame: frame.offsetBy(dx: 0, dy: frame.height + 20))
        lowerView.backgroundColor = .white
        view.addSubview(lowerView)
        outerEmbeddedController?.dropTargetView = lowerView
        applyLabel("Lower View \n(Contains Embedded Drop Target)", to: lowerView)

        lowerView.layer.borderColor = UIColor.black.cgColor
        lowerView.layer.borderWidth = 2.0
        self.lowerView = lowerView

        populate(upperView, withCount: 5, andDragDropController: containerController)
        populate(lowerView, withCount: 3, andDragDropController: outerEmbeddedController)

        innerEmbeddedController?.dropTargetView = lowerView.subviews[1]
    }

    private func controller() -> DragDropController {
        let controller = DragDropController()
        controller.dragDropDataSource = self
        controller.dragDropDelegate = self
        return controller
    }

    private func applyLabel(_ string: String, to view: UIView) {
        let label = UILabel()
        label.numberOfLines = 2
        label.textAlignment = .center
        label.text = string
        label.sizeToFit()
        label.center = CGPoint(x: view.frame.size.width / 2, y: view.frame.size.height / 2)
        view.addSubview(label)
    }

    private func populate(_ view: UIView, withCount viewCount: Int, andDragDropController dragDropController: DragDropController?) {
        SlotPopulator.fill(view, count: viewCount, controller: dragDropController) { _ in
            let square = UIView()
            square.backgroundColor = .black
            return square
        }
    }
}

// MARK: - DragDropController Delegate

extension EmbeddedDropTargetViewController: DragDropControllerDelegate {

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
        if destination.dropTargetView === upperView || destination.dropTargetView === lowerView {
            destination.dropTargetView?.layer.borderColor = UIColor.black.cgColor
        } else {
            destination.dropTargetView?.layer.borderColor = UIColor.clear.cgColor
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

extension EmbeddedDropTargetViewController: DragDropControllerDataSource {

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

        if destination === innerEmbeddedController {
            return dropTargetView.bounds
        }

        // The arriving view takes the first free slot. `draggableViews` counts
        // only the squares, so neither the title label nor the embedded drop
        // target shifts it.
        return SlotLayout.frame(at: destination.draggableViews.count,
                                size: view.frame.size,
                                in: dropTargetView)
    }

    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            at index: Int) -> CGRect? {
        guard let dropTargetView = controller.dropTargetView else { return nil }

        // The inner target holds a single view filling it, so there is never a
        // gap to close.
        if controller === innerEmbeddedController { return nil }

        return SlotLayout.frame(at: index, size: view.frame.size, in: dropTargetView)
    }
}
