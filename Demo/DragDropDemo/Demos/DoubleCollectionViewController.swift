//
//  DoubleCollectionViewController.swift
//  DragDropDemo
//
//  Created by Joey Patino on 11/14/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit
import DragDrop
import DemoKit

/// Two collection views, and a move between them that the datasource can veto:
/// a player already on the destination list cannot be moved there again.
final class DoubleCollectionViewController: DemoViewController {

    private var leftCollectionView: UICollectionView?
    private var leftDataSource: [Player] = []
    private let leftHeader = UILabel()
    private let leftCount = UILabel()

    private var rightCollectionView: UICollectionView?
    private var rightDataSource: [Player] = []
    private let rightHeader = UILabel()
    private let rightCount = UILabel()

    private let divider = UIView()

    override func loadContent() {
        title = "Lineup"

        loadLeftContent()
        loadRightContent()
        refreshCounts()
    }

    private func columnFrame(x: CGFloat) -> CGRect {
        let top = view.safeAreaInsets.top + 36
        return CGRect(x: x, y: top,
                      width: view.bounds.width / 2,
                      height: view.bounds.height - top)
    }

    private func header(_ label: UILabel, _ count: UILabel, title: String, x: CGFloat) {
        label.text = title
        label.font = DemoTheme.Font.title
        label.textColor = DemoTheme.Text.primary
        label.frame = CGRect(x: x + 14, y: view.safeAreaInsets.top + 8,
                             width: view.bounds.width / 2 - 52, height: 22)
        view.addSubview(label)

        count.font = DemoTheme.Font.number(13)
        count.textColor = DemoTheme.Text.secondary
        count.textAlignment = .right
        count.frame = CGRect(x: x + view.bounds.width / 2 - 42,
                             y: view.safeAreaInsets.top + 8,
                             width: 28, height: 22)
        view.addSubview(count)
    }

    private func makeCollectionView(frame: CGRect, identifier: String) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        let collectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        collectionView.backgroundColor = DemoTheme.Surface.background
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.accessibilityIdentifier = identifier
        collectionView.register(UICollectionViewCell.self,
                                forCellWithReuseIdentifier: "CollectionViewCell")
        view.addSubview(collectionView)
        return collectionView
    }

    private func loadLeftContent() {
        leftDataSource = Array(SampleData.players.prefix(8))
        header(leftHeader, leftCount, title: "Starters", x: 0)
        leftCollectionView = makeCollectionView(frame: columnFrame(x: 0), identifier: "starters")
        leftCollectionView?.reloadData()
    }

    private func loadRightContent() {
        rightDataSource = Array(SampleData.players.suffix(8))
        header(rightHeader, rightCount, title: "Bench", x: view.bounds.width / 2)
        rightCollectionView = makeCollectionView(frame: columnFrame(x: view.bounds.width / 2),
                                                 identifier: "bench")
        rightCollectionView?.reloadData()

        divider.backgroundColor = DemoTheme.Surface.hairline
        divider.frame = CGRect(x: view.bounds.width / 2 - 0.5,
                               y: view.safeAreaInsets.top + 36,
                               width: 1,
                               height: view.bounds.height - view.safeAreaInsets.top - 36)
        view.addSubview(divider)
    }

    private func refreshCounts() {
        leftCount.text = "\(leftDataSource.count)"
        rightCount.text = "\(rightDataSource.count)"
    }
}

// MARK: -

extension DoubleCollectionViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: (collectionView.bounds.size.width / 2) - 12, height: 120)
    }
}

// MARK: -

extension DoubleCollectionViewController: UICollectionViewDataSourceCellSwapSupport {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === leftCollectionView { return leftDataSource.count }
        return rightDataSource.count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    // MARK: -

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell",
                                                      for: indexPath)
        collectionView.enableDragAndDrop(for: cell)

        cell.backgroundColor = .clear
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let player = collectionView === rightCollectionView
            ? rightDataSource[indexPath.row]
            : leftDataSource[indexPath.row]

        let card = PlayerCardView(player: player, identifier: "player-\(player.id)")
        card.frame = cell.contentView.bounds
        card.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cell.contentView.addSubview(card)

        return cell
    }

    // MARK: -

    func collectionView(_ collectionView: UICollectionView,
                        moveItemAt sourceIndexPath: IndexPath,
                        to destinationCollectionView: UICollectionView,
                        to destinationIndexPath: IndexPath) {

        var moved: Player?
        if collectionView === leftCollectionView {
            moved = leftDataSource.remove(at: sourceIndexPath.row)
        } else if collectionView === rightCollectionView {
            moved = rightDataSource.remove(at: sourceIndexPath.row)
        }

        guard let moved else { return }

        if destinationCollectionView === rightCollectionView {
            rightDataSource.insert(moved, at: min(destinationIndexPath.row, rightDataSource.count))
        } else if destinationCollectionView === leftCollectionView {
            leftDataSource.insert(moved, at: min(destinationIndexPath.row, leftDataSource.count))
        }

        refreshCounts()
    }

    /// A player already on the destination list cannot be moved there again.
    func collectionView(_ collectionView: UICollectionView,
                        canMoveItemAt indexPath: IndexPath,
                        to destinationCollectionView: UICollectionView,
                        to toIndexPath: IndexPath) -> Bool {

        let destination: [Player]
        let player: Player

        if collectionView === leftCollectionView {
            destination = rightDataSource
            player = leftDataSource[indexPath.row]
        } else if collectionView === rightCollectionView {
            destination = leftDataSource
            player = rightDataSource[indexPath.row]
        } else {
            return true
        }

        return !destination.contains(player)
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        true
    }

    func collectionView(_ collectionView: UICollectionView,
                        moveItemAt sourceIndexPath: IndexPath,
                        to destinationIndexPath: IndexPath) {

        if collectionView === leftCollectionView {
            let player = leftDataSource.remove(at: sourceIndexPath.row)
            leftDataSource.insert(player, at: destinationIndexPath.row)
        } else if collectionView === rightCollectionView {
            let player = rightDataSource.remove(at: sourceIndexPath.row)
            rightDataSource.insert(player, at: destinationIndexPath.row)
        }
    }
}
