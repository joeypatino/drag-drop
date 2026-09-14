import SwiftUI
import UIKit
import DragDrop

/// Both collection views' items. Deliberately not observable: SwiftUI must not
/// reload a collection view while the library is part-way through a swap.
@MainActor
final class LineupModel {
    var items: [String: [String]] = [
        "starters": (0..<4).map { "player-\($0)" },
        "bench": (4..<6).map { "player-\($0)" }
    ]

    func publish(to log: HarnessLog) {
        for (id, list) in items {
            log.publish(id, list.count)
        }
    }
}

/// A `UICollectionView` using the cell-swap extension, wrapped for SwiftUI.
struct HarnessCollection: UIViewRepresentable {
    let id: String
    let model: LineupModel
    let log: HarnessLog

    func makeCoordinator() -> Coordinator {
        Coordinator(id: id, model: model, log: log)
    }

    func makeUIView(context: Context) -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 60, height: 60)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.accessibilityIdentifier = id
        collectionView.backgroundColor = .secondarySystemBackground
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Player")
        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator

        let model = model
        let log = log
        DispatchQueue.main.async { model.publish(to: log) }
        return collectionView
    }

    func updateUIView(_ uiView: UICollectionView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, UICollectionViewDataSourceCellSwapSupport, UICollectionViewDelegate {
        let id: String
        let model: LineupModel
        let log: HarnessLog

        init(id: String, model: LineupModel, log: HarnessLog) {
            self.id = id
            self.model = model
            self.log = log
        }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            model.items[id, default: []].count
        }

        /// The identifier sits on a card inside the cell: a cell reports itself
        /// to XCUITest as a `cell`, and the shared helpers query `other`.
        func collectionView(_ collectionView: UICollectionView,
                            cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Player", for: indexPath)
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }

            let card = UIView(frame: cell.contentView.bounds)
            card.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            card.backgroundColor = .systemOrange
            card.layer.cornerRadius = 8
            card.accessibilityIdentifier = model.items[id, default: []][indexPath.item]
            card.isAccessibilityElement = true
            cell.contentView.addSubview(card)
            return cell
        }

        func collectionView(_ collectionView: UICollectionView,
                            willDisplay cell: UICollectionViewCell,
                            forItemAt indexPath: IndexPath) {
            collectionView.enableDragAndDrop(for: cell)
        }

        /// Within one collection view, while a transfer is being previewed.
        func collectionView(_ collectionView: UICollectionView,
                            moveItemAt sourceIndexPath: IndexPath,
                            to destinationIndexPath: IndexPath) {
            var list = model.items[id, default: []]
            let item = list.remove(at: sourceIndexPath.item)
            list.insert(item, at: min(destinationIndexPath.item, list.count))
            model.items[id] = list
        }

        /// Called on the source's datasource, naming the destination.
        func collectionView(_ collectionView: UICollectionView,
                            moveItemAt sourceIndexPath: IndexPath,
                            to destinationCollectionView: UICollectionView,
                            to destinationIndexPath: IndexPath) {
            guard let destination = destinationCollectionView.accessibilityIdentifier else { return }

            let item = model.items[id, default: []].remove(at: sourceIndexPath.item)
            var arriving = model.items[destination, default: []]
            arriving.insert(item, at: min(destinationIndexPath.item, arriving.count))
            model.items[destination] = arriving

            model.publish(to: log)
        }
    }
}
