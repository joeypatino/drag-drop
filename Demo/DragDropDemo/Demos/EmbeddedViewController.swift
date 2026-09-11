//
//  EmbeddedViewController.swift
//  DragDropDemo
//
//  Created by Joey Patino on 11/4/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit
import DragDrop

final class EmbeddedViewController: UIViewController {

    private var containerController: DragDropController?
    private var embeddedController: DragDropController?

    private var containerView: UIView?
    private var embeddedView: UIView?

    private var hasLoadedContent = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !hasLoadedContent else { return }
        hasLoadedContent = true
        loadContent()
    }

    private func loadContent() {
        containerController = controller()
        embeddedController = controller()

        let frame = CGRect(x: 20, y: 20,
                           width: view.frame.width - 40,
                           height: view.frame.height - 64 - 40)

        let containerView = UIView(frame: frame)
        containerView.backgroundColor = .white
        view.addSubview(containerView)
        containerController?.dropTargetView = containerView
        applyLabel("Container", to: containerView, atOffset: CGPoint(x: 0, y: -120))

        containerView.layer.borderColor = UIColor.black.cgColor
        containerView.layer.borderWidth = 2.0
        self.containerView = containerView

        let embeddedView = UIView(frame: CGRect(x: 10, y: frame.height / 2 + 10,
                                                width: frame.width - 20,
                                                height: frame.height / 2 - 20))
        embeddedView.backgroundColor = .white
        containerView.addSubview(embeddedView)
        embeddedController?.dropTargetView = embeddedView
        applyLabel("Embedded", to: embeddedView, atOffset: CGPoint(x: 0, y: 0))

        embeddedView.layer.borderColor = UIColor.black.cgColor
        embeddedView.layer.borderWidth = 2.0
        self.embeddedView = embeddedView

        populate(embeddedView, withCount: 3, andDragDropController: embeddedController)
        populate(containerView, withCount: 5, andDragDropController: containerController)
    }

    private func controller() -> DragDropController {
        let controller = DragDropController()
        controller.dragDropDataSource = self
        controller.dragDropDelegate = self
        return controller
    }

    private func applyLabel(_ string: String, to view: UIView, atOffset offset: CGPoint) {
        let label = UILabel()
        label.text = string
        label.sizeToFit()
        label.center = CGPoint(x: view.frame.size.width / 2 + offset.x,
                               y: view.frame.size.height / 2 + offset.y)
        view.addSubview(label)
    }

    private func populate(_ view: UIView, withCount viewCount: Int, andDragDropController dragDropController: DragDropController?) {
        SlotLayout.populate(view, withCount: viewCount, controller: dragDropController)
    }
}

// MARK: - DragDropController Delegate

extension EmbeddedViewController: DragDropControllerDelegate {

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
    }

    func dragDropController(_ controller: DragDropController,
                            dragDidMove drag: DragAction,
                            destinationController destination: DragDropController) {
    }

    func dragDropController(_ controller: DragDropController,
                            dragDidExit drag: DragAction,
                            destinationController destination: DragDropController) {
        destination.dropTargetView?.layer.borderColor = UIColor.clear.cgColor
    }

    // MARK: -

    func dragDropController(_ controller: DragDropController,
                            didMove view: UIView,
                            to destination: DragDropController) {
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
        if controller === destination { return false }
        return true
    }

    func dragDropController(_ controller: DragDropController,
                            frameFor view: UIView,
                            in destination: DragDropController) -> CGRect {
        guard let dropTargetView = destination.dropTargetView else { return .zero }

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
        return SlotLayout.frame(at: index, size: view.frame.size, in: dropTargetView)
    }
}
