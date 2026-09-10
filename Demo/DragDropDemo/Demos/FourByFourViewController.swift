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

final class FourByFourViewController: UIViewController {

    private var topLeftView: UIView?
    private var bottomRightView: UIView?

    private var topRightView: UIView?
    private var bottomLeftView: UIView?

    private var topLeftController: DragDropController?
    private var bottomRightController: DragDropController?

    private var topRightController: DragDropController?
    private var bottomLeftController: DragDropController?

    private var hasLoadedContent = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .gray
    }

    /// The Objective-C loaded content in viewDidLoad and read self.view.frame,
    /// which is not yet sized under iOS 26. The arithmetic below is unchanged;
    /// only the moment it runs has moved.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !hasLoadedContent else { return }
        hasLoadedContent = true
        loadContent()
    }

    private func loadContent() {

        topLeftController = controller()
        bottomRightController = controller()
        topRightController = controller()
        bottomLeftController = controller()

        var frame = CGRect(x: 0, y: 0,
                           width: view.bounds.width / 2,
                           height: view.bounds.height / 2 - 32)
        frame = frame.insetBy(dx: 10, dy: 10)

        let topLeftView = UIView(frame: frame.offsetBy(dx: 0, dy: 0))
        topLeftView.backgroundColor = .white
        view.addSubview(topLeftView)
        topLeftController?.dropTargetView = topLeftView
        applyLabel("TopLeft", to: topLeftView)
        self.topLeftView = topLeftView

        let topRightView = UIView(frame: frame.offsetBy(dx: frame.width + 20, dy: 0))
        topRightView.backgroundColor = .white
        view.addSubview(topRightView)
        topRightController?.dropTargetView = topRightView
        applyLabel("TopRight", to: topRightView)
        self.topRightView = topRightView

        let bottomLeftView = UIView(frame: frame.offsetBy(dx: 0, dy: frame.height + 20))
        bottomLeftView.backgroundColor = .white
        view.addSubview(bottomLeftView)
        bottomLeftController?.dropTargetView = bottomLeftView
        applyLabel("BottomLeft", to: bottomLeftView)
        self.bottomLeftView = bottomLeftView

        let bottomRightView = UIView(frame: frame.offsetBy(dx: frame.width + 20,
                                                           dy: frame.height + 20))
        bottomRightView.backgroundColor = .white
        view.addSubview(bottomRightView)
        bottomRightController?.dropTargetView = bottomRightView
        applyLabel("BottomRight", to: bottomRightView)
        self.bottomRightView = bottomRightView

        populate(topLeftView, withCount: 5, andDragDropController: topLeftController)
        populate(bottomRightView, withCount: 6, andDragDropController: bottomRightController)

        populate(topRightView, withCount: 4, andDragDropController: topRightController)
        populate(bottomLeftView, withCount: 3, andDragDropController: bottomLeftController)
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

    private func populate(_ view: UIView, withCount viewCount: Int, andDragDropController dragDropController: DragDropController?) {
        let width: CGFloat = 40
        let height: CGFloat = 40
        var xMargin: CGFloat = 5
        var yMargin: CGFloat = 5

        for _ in 0..<viewCount {
            if xMargin + width > view.frame.size.width {
                xMargin = 5
                yMargin += height + 5
            }

            let dragView = UIView()
            dragDropController?.enableDragAction(for: dragView)
            dragView.frame = CGRect(x: xMargin, y: yMargin, width: width, height: height)
            dragView.backgroundColor = .black
            view.addSubview(dragView)

            xMargin += width + 5
        }
    }

    private func frame(forCount count: Int, in view: UIView) -> CGRect {
        let width: CGFloat = 40
        let height: CGFloat = 40
        var xMargin: CGFloat = 5
        var yMargin: CGFloat = 5
        var frame = CGRect.zero

        for _ in 0...count {
            if xMargin + width > view.frame.size.width {
                xMargin = 5
                yMargin += height + 5
            }

            frame = CGRect(x: xMargin, y: yMargin, width: width, height: height)

            xMargin += width + 5
        }
        return frame
    }
}

// MARK: - DragDropController Delegate

extension FourByFourViewController: DragDropControllerDelegate {

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
        destination.dropTargetView?.layer.borderColor = UIColor.clear.cgColor
        destination.dropTargetView?.layer.borderWidth = 0.0
    }

    // MARK: -

    func dragDropController(_ controller: DragDropController,
                            didMove view: UIView,
                            to destination: DragDropController) {
    }
}

// MARK: - DragDropController Datasource

extension FourByFourViewController: DragDropControllerDataSource {

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
        let count = dropTargetView.subviews.count - 1
        return frame(forCount: count, in: dropTargetView)
    }
}
