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
    private var leftPanel: PanelView?

    private var rightCollectionView: UICollectionView?
    private var rightDataSource: [Player] = []
    private var rightPanel: PanelView?

    override func loadContent() {
        title = "Lineup"

        leftDataSource = Array(SampleData.players.prefix(8))
        rightDataSource = Array(SampleData.players.suffix(8))

        // Each side is its own titled card. Two bare collection views side by
        // side read as one grid with a line down it; a card with its own
        // header, hue and count reads as two lists, which is what they are.
        let (leftPanel, leftGrid) = installSide(title: "Starters",
                                                subtitle: "On the pitch",
                                                symbol: "figure.soccer",
                                                hue: .mint,
                                                identifier: "starters",
                                                x: 0)
        self.leftPanel = leftPanel
        self.leftCollectionView = leftGrid

        let (rightPanel, rightGrid) = installSide(title: "Bench",
                                                 subtitle: "Available",
                                                 symbol: "chair.lounge.fill",
                                                 hue: .slate,
                                                 identifier: "bench",
                                                 x: view.bounds.width / 2)
        self.rightPanel = rightPanel
        self.rightCollectionView = rightGrid

        leftGrid.reloadData()
        rightGrid.reloadData()
        refreshCounts()
    }

    private func installSide(title: String,
                             subtitle: String,
                             symbol: String,
                             hue: DemoTheme.Hue,
                             identifier: String,
                             x: CGFloat) -> (PanelView, UICollectionView) {

        let top = contentTop + 8
        let panel = PanelView(title: title, subtitle: subtitle, symbolName: symbol, hue: hue)
        let frame = CGRect(x: x + 8, y: top,
                           width: view.bounds.width / 2 - 16,
                           height: view.bounds.height - top - view.safeAreaInsets.bottom - 8)
        let content = install(panel, in: view, frame: frame)

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 6
        layout.minimumLineSpacing = 6
        layout.sectionInset = UIEdgeInsets(top: 2, left: 0, bottom: 8, right: 0)

        let grid = UICollectionView(frame: content.bounds, collectionViewLayout: layout)
        grid.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        grid.backgroundColor = .clear
        grid.delegate = self
        grid.dataSource = self
        grid.accessibilityIdentifier = identifier
        grid.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        content.addSubview(grid)

        // The grid is the drop target, not the card's content view that holds
        // it, so the owning panel has to be named rather than looked up. No
        // controller to pass: a collection view builds its own internally.
        register(grid, in: panel)

        // The grid fills the card, so the card is what should light up -- the
        // same accepting state the panel screens use, rather than a border
        // drawn around a scroll view inside it.
        grid.dropHighlight = { [weak panel] accepting in
            panel?.setDropState(accepting ? .accepting : .idle)
        }

        return (panel, grid)
    }

    private func refreshCounts() {
        leftPanel?.count = leftDataSource.count
        rightPanel?.count = rightDataSource.count
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
