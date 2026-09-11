//
//  DoubleCollectionViewController.swift
//  DragDropDemo
//
//  Created by Joey Patino on 11/14/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit
import DragDrop

final class DoubleCollectionViewController: UIViewController {

    private var leftCollectionView: UICollectionView?
    private var leftLayout: UICollectionViewFlowLayout?
    private var leftDataSource: [Int] = []

    private var rightCollectionView: UICollectionView?
    private var rightLayout: UICollectionViewFlowLayout?
    private var rightDataSource: [Int] = []

    private var hasLoadedContent = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !hasLoadedContent else { return }
        hasLoadedContent = true
        loadContent()
    }

    private func loadContent() {
        loadLeftContent()
        loadRightContent()
    }

    private func loadLeftContent() {
        leftDataSource = Array(0..<8)

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        leftLayout = layout

        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0,
                                                            width: view.frame.width / 2,
                                                            height: view.frame.height - 60),
                                              collectionViewLayout: layout)
        // The Objective-C never set this: UICollectionView used to default to a
        // black background, which is what separated the white cells in the
        // original demo. Modern iOS defaults it to the system background, so
        // white cells on a white collection view became invisible. Setting it
        // explicitly restores the original appearance.
        collectionView.backgroundColor = .black

        collectionView.delegate = self
        collectionView.dataSource = self
        view.addSubview(collectionView)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        leftCollectionView = collectionView

        collectionView.reloadData()
    }

    private func loadRightContent() {
        rightDataSource = Array(4..<12)

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        rightLayout = layout

        let collectionView = UICollectionView(frame: CGRect(x: view.frame.width / 2, y: 0,
                                                            width: view.frame.width / 2,
                                                            height: view.frame.height - 60),
                                              collectionViewLayout: layout)
        collectionView.backgroundColor = .black

        collectionView.delegate = self
        collectionView.dataSource = self
        view.addSubview(collectionView)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        rightCollectionView = collectionView

        collectionView.reloadData()
    }

    private func applyLabel(_ string: String, to view: UIView) {
        let label = UILabel()
        label.text = string
        label.sizeToFit()
        label.frame = CGRect(x: 0, y: 0, width: label.frame.width, height: label.frame.height)
        view.addSubview(label)
    }
}

// MARK: -

extension DoubleCollectionViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        CGSize(width: (collectionView.bounds.size.width / 2) - 6, height: 120)
    }
}

// MARK: -

extension DoubleCollectionViewController: UICollectionViewDataSourceCellSwapSupport {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        if collectionView === leftCollectionView { return leftDataSource.count }

        return rightDataSource.count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    // MARK: -

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath)
        collectionView.enableDragAndDrop(for: cell)

        cell.backgroundColor = .white
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let n: Int
        if collectionView === rightCollectionView {
            n = rightDataSource[indexPath.row]
        } else {
            n = leftDataSource[indexPath.row]
        }

        applyLabel("\(n)", to: cell.contentView)

        return cell
    }

    // MARK: -

    func collectionView(_ collectionView: UICollectionView,
                        moveItemAt sourceIndexPath: IndexPath,
                        to destinationCollectionView: UICollectionView,
                        to destinationIndexPath: IndexPath) {
        DLogDemo()

        var item: Int?
        if collectionView === leftCollectionView {
            item = leftDataSource.remove(at: sourceIndexPath.row)
        } else if collectionView === rightCollectionView {
            item = rightDataSource.remove(at: sourceIndexPath.row)
        }

        guard let item else { return }

        if destinationCollectionView === rightCollectionView {
            rightDataSource.insert(item, at: min(destinationIndexPath.row, rightDataSource.count))
        } else if destinationCollectionView === leftCollectionView {
            leftDataSource.insert(item, at: min(destinationIndexPath.row, leftDataSource.count))
        }

        print("L: \(leftDataSource)")
        print("R: \(rightDataSource)")
    }

    func collectionView(_ collectionView: UICollectionView,
                        canMoveItemAt indexPath: IndexPath,
                        to destinationCollectionView: UICollectionView,
                        to toIndexPath: IndexPath) -> Bool {
        DLogDemo()

        let source: [Int]
        let obj: Int

        if collectionView === leftCollectionView {
            source = rightDataSource
            obj = leftDataSource[indexPath.row]
        } else if collectionView === rightCollectionView {
            source = leftDataSource
            obj = rightDataSource[indexPath.row]
        } else {
            return true
        }

        if source.firstIndex(of: obj) == nil {
            return true
        }

        return false
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        DLogDemo()
        //    if (indexPath.row == 0) return NO;

        return true
    }

    func collectionView(_ collectionView: UICollectionView,
                        moveItemAt sourceIndexPath: IndexPath,
                        to destinationIndexPath: IndexPath) {
        DLogDemo()

        if collectionView === leftCollectionView {
            let item = leftDataSource.remove(at: sourceIndexPath.row)
            leftDataSource.insert(item, at: destinationIndexPath.row)
        } else if collectionView === rightCollectionView {
            let item = rightDataSource.remove(at: sourceIndexPath.row)
            rightDataSource.insert(item, at: destinationIndexPath.row)
        }
    }
}

/// The demo's own DLog. The library's is internal to the DragDrop module.
@inline(__always)
func DLogDemo(_ function: StaticString = #function) {
    #if DEBUG
    print("\(function)")
    #endif
}
