import SwiftUI
import UIKit
import DragDrop

/// A `UITableView` using the row-move extension, wrapped for SwiftUI.
struct HarnessTable: UIViewRepresentable {
    let log: HarnessLog

    func makeCoordinator() -> Coordinator {
        Coordinator(log: log)
    }

    func makeUIView(context: Context) -> UITableView {
        let table = UITableView(frame: .zero, style: .plain)
        table.accessibilityIdentifier = "harness-table"
        table.rowHeight = 56
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Row")
        table.dataSource = context.coordinator

        let coordinator = context.coordinator
        DispatchQueue.main.async { coordinator.publish() }
        return table
    }

    func updateUIView(_ uiView: UITableView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, UITableViewDataSourceRowMoveSupport {
        let log: HarnessLog

        /// Each row's draggable view carries its item as its identifier, which
        /// is how a view dropped in from a panel becomes a row again.
        var rows = (0..<5).map { "row-\($0)" }

        init(log: HarnessLog) {
            self.log = log
        }

        func publish() {
            log.publish("table", rows.count)
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            rows.count
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Row", for: indexPath)
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }

            let item = UIView(frame: cell.contentView.bounds.insetBy(dx: 16, dy: 6))
            item.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            item.backgroundColor = .systemIndigo
            item.layer.cornerRadius = 8
            item.accessibilityIdentifier = rows[indexPath.row]
            item.isAccessibilityElement = true
            cell.contentView.addSubview(item)

            tableView.enableDragAndDrop(for: item)
            return cell
        }

        func tableView(_ tableView: UITableView, didRemoveRowAt indexPath: IndexPath) {
            rows.remove(at: indexPath.row)
            publish()
        }

        func tableView(_ tableView: UITableView, didInsertRowAt indexPath: IndexPath, for view: UIView) {
            rows.insert(view.accessibilityIdentifier ?? "row-dropped", at: indexPath.row)
            publish()
        }
    }
}
