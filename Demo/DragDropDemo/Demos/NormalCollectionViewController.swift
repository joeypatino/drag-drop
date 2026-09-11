//
//  NormalCollectionViewController.swift
//  DragDropDemo
//
//  Created by Joey Patino on 11/4/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit
import DragDrop
import DemoKit

/// A curation grid: masonry cards reordered by dragging. One collection view,
/// one section, 300 items -- the reorder path at a scale where a wrong frame is
/// visible immediately.
final class NormalCollectionViewController: DemoViewController {

    private var collection: UICollectionView?
    private var cards: [Int] = []
    private var heights: [CGFloat] = []

    override func loadContent() {
        title = "Moodboard"

        cards = Array(0..<300)
        // Seeded, not random: the same position always gets the same height, so
        // a screenshot taken today matches one taken tomorrow, and a reorder
        // leaves the masonry rhythm alone rather than dragging a card's height
        // around with it.
        //
        // `stableMix` rather than `stableHash("card-\(index)")`: the string
        // hash's low bits track their input, so consecutive cards came out one
        // pixel apart -- a fixed-height grid wearing a masonry's clothes. The
        // spread is the whole point of the screen, because the slots keep
        // their heights and a card visibly resizes into the one it is dragged
        // over.
        heights = cards.map { index in
            80 + CGFloat(DemoTheme.stableMix(index) % 121)
        }

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        let collection = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        // The Objective-C never set this: UICollectionView used to default to a
        // black background, which is what separated the white cells in the
        // original demo. The cards now carry their own hairline and shadow, so
        // the background can be the ordinary grouped one.
        collection.backgroundColor = DemoTheme.Surface.background
        collection.delegate = self
        collection.dataSource = self
        collection.accessibilityIdentifier = "moodboard"
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        view.addSubview(collection)
        self.collection = collection

        collection.reloadData()
    }

    private func palette(for card: Int) -> Palette {
        SampleData.palettes[card % SampleData.palettes.count]
    }
}

// MARK: -

extension NormalCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cards.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell",
                                                      for: indexPath)
        cell.backgroundColor = .clear
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let card = cards[indexPath.row]
        let palette = palette(for: card)
        let swatch = SwatchChip(color: UIColor(hex: palette.hex) ?? .systemGray,
                                caption: palette.name,
                                detail: palette.hex,
                                identifier: "swatch-\(card)")
        swatch.frame = cell.contentView.bounds
        swatch.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cell.contentView.addSubview(swatch)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        // On the cell, not the swatch: the collection view resolves an index
        // path from the cell.
        collectionView.enableDragAndDrop(for: cell)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: (view.bounds.width / 2) - 17, height: heights[indexPath.row])
    }

    func collectionView(_ collectionView: UICollectionView,
                        moveItemAt sourceIndexPath: IndexPath,
                        to destinationIndexPath: IndexPath) {
        let card = cards.remove(at: sourceIndexPath.row)
        cards.insert(card, at: destinationIndexPath.row)
    }
}
