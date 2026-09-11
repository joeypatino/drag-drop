//
//  NormalCollectionViewController.swift
//  DragDropDemo
//
//  Created by Joey Patino on 11/4/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit
import DragDrop

final class NormalCollectionViewController: UIViewController {

    private var collection: UICollectionView?
    private var layout: UICollectionViewFlowLayout?
    private var collectionSource: [Int] = []
    private var collectionHeights: [Int] = []

    private var hasLoadedContent = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !hasLoadedContent else { return }
        hasLoadedContent = true
        loadContent()
    }

    private func loadContent() {

        collectionSource = []
        collectionHeights = []

        for i in 0..<300 {
            collectionSource.append(i)
            var n = Int(arc4random() % 120)
            if n < 40 { n = 40 }
            collectionHeights.append(n)
        }

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        self.layout = layout

        let collection = UICollectionView(frame: CGRect(x: 0, y: 20,
                                                        width: view.bounds.size.width,
                                                        height: view.bounds.size.height - 20),
                                          collectionViewLayout: layout)
        // The Objective-C never set this: UICollectionView used to default to a
        // black background, which is what separated the white cells in the
        // original demo. Modern iOS defaults it to the system background, so
        // white cells on a white collection view became invisible. Setting it
        // explicitly restores the original appearance.
        collection.backgroundColor = .black

        collection.delegate = self
        collection.dataSource = self
        view.addSubview(collection)
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        self.collection = collection

        collection.reloadData()
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

extension NormalCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionSource.count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath)
        cell.backgroundColor = .white

        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        let n = collectionSource[indexPath.row]
        applyLabel("\(n)", to: cell.contentView)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        collectionView.enableDragAndDrop(for: cell)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        CGSize(width: (view.bounds.size.width / 2) - 6,
               height: CGFloat(collectionHeights[indexPath.row]))
    }

    func collectionView(_ collectionView: UICollectionView,
                        moveItemAt sourceIndexPath: IndexPath,
                        to destinationIndexPath: IndexPath) {

        let item = collectionSource.remove(at: sourceIndexPath.row)
        collectionSource.insert(item, at: destinationIndexPath.row)
    }
}
