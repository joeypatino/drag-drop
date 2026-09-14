import SwiftUI
import UIKit
import DragDrop

struct PanelSpec: Hashable {
    let id: String
    let chips: Int
}

/// Plain-view drop targets inside one representable.
///
/// Written the way an app would write it: the coordinator owns every
/// controller, `makeUIView` builds the views and enables dragging once, and
/// `updateUIView` never touches the draggable views. Rebuilding them there
/// would fight the library, which re-parents them itself.
struct PanelBoard: UIViewRepresentable {
    let panels: [PanelSpec]
    let axis: Axis
    let log: HarnessLog

    static let chipSize: CGFloat = 44
    static let gap: CGFloat = 8

    /// The `index`-th slot of a panel, in the panel's own coordinates.
    static func slotFrame(at index: Int, in bounds: CGRect) -> CGRect {
        let step = chipSize + gap
        let perRow = max(Int((bounds.width - gap) / step), 1)
        return CGRect(x: gap + CGFloat(index % perRow) * step,
                      y: gap + CGFloat(index / perRow) * step,
                      width: chipSize,
                      height: chipSize)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(log: log)
    }

    func makeUIView(context: Context) -> BoardView {
        let board = BoardView(axis: axis)
        let coordinator = context.coordinator

        for spec in panels {
            let panel = UIView()
            panel.backgroundColor = .secondarySystemBackground
            panel.layer.cornerRadius = 12
            panel.accessibilityIdentifier = "panel-\(spec.id)"

            let controller = DragDropController()
            controller.dropTargetView = panel
            controller.dragDropDataSource = coordinator
            controller.dragDropDelegate = coordinator
            coordinator.controllers[spec.id] = controller

            var chips: [UIView] = []
            for n in 0..<spec.chips {
                let chip = UIView()
                chip.backgroundColor = .systemTeal
                chip.layer.cornerRadius = Self.chipSize / 2
                chip.accessibilityIdentifier = "chip-\(spec.id)-\(n)"
                chip.isAccessibilityElement = true
                panel.addSubview(chip)
                // Deliberately here, while the board has no superview: this is
                // where a representable enables dragging, and defect F3 lives
                // in exactly this timing.
                controller.enableDragAction(for: chip)
                chips.append(chip)
            }

            board.add(panel: panel, chips: chips)
        }

        // Publishing inside makeUIView would modify state during a view update.
        DispatchQueue.main.async { coordinator.publishCounts() }
        return board
    }

    func updateUIView(_ uiView: BoardView, context: Context) {}

    @MainActor
    final class Coordinator: DragDropControllerDataSource, DragDropControllerDelegate {
        let log: HarnessLog
        var controllers: [String: DragDropController] = [:]

        init(log: HarnessLog) {
            self.log = log
        }

        func publishCounts() {
            for (id, controller) in controllers {
                log.publish(id, controller.draggableViews.count)
            }
        }

        // MARK: Datasource

        func dragDropController(_ controller: DragDropController,
                                frameFor view: UIView,
                                in destination: DragDropController) -> CGRect {
            guard let target = destination.dropTargetView else { return .zero }
            return PanelBoard.slotFrame(at: destination.draggableViews.count, in: target.bounds)
        }

        func dragDropController(_ controller: DragDropController,
                                frameFor view: UIView,
                                at index: Int) -> CGRect? {
            guard let target = controller.dropTargetView else { return nil }
            return PanelBoard.slotFrame(at: index, in: target.bounds)
        }

        // MARK: Delegate

        /// Source side. A destination in another representable reports
        /// through its own coordinator's `didReceive`.
        func dragDropController(_ controller: DragDropController,
                                didMove view: UIView,
                                to destination: DragDropController) {
            publishCounts()
        }

        func dragDropController(_ controller: DragDropController,
                                didReceive view: UIView,
                                from source: DragDropController) {
            publishCounts()
        }

        func dragDropController(_ controller: DragDropController,
                                dragDidHover drag: DragAction,
                                from source: DragDropController) {
            guard let target = controller.dropTargetView,
                  let window = target.window,
                  let view = drag.view else { return }

            // Hover locations arrive in the target's own coordinates.
            let finger = target.convert(drag.currentLocation, to: nil)

            if !view.convert(view.bounds, to: nil).contains(finger) {
                log.probe = "offset"
            } else if let hit = window.hitTest(finger, with: nil),
                      hit !== view, !hit.isDescendant(of: view) {
                log.probe = "covered"
            }
        }
    }
}

/// Lays the panels out along one axis and places each panel's chips once,
/// on the first pass that has a size. After that the library owns the chips.
@MainActor
final class BoardView: UIView {
    private let axis: Axis
    private var panels: [UIView] = []
    private var chipsByPanel: [[UIView]] = []
    private var hasPlacedChips = false

    init(axis: Axis) {
        self.axis = axis
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    func add(panel: UIView, chips: [UIView]) {
        addSubview(panel)
        panels.append(panel)
        chipsByPanel.append(chips)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !panels.isEmpty, !bounds.isEmpty else { return }

        let gap: CGFloat = 12
        let count = CGFloat(panels.count)
        for (index, panel) in panels.enumerated() {
            let i = CGFloat(index)
            switch axis {
            case .horizontal:
                let width = (bounds.width - gap * (count - 1)) / count
                panel.frame = CGRect(x: i * (width + gap), y: 0, width: width, height: bounds.height)
            case .vertical:
                let height = (bounds.height - gap * (count - 1)) / count
                panel.frame = CGRect(x: 0, y: i * (height + gap), width: bounds.width, height: height)
            }
        }

        guard !hasPlacedChips else { return }
        hasPlacedChips = true
        for (panel, chips) in zip(panels, chipsByPanel) {
            for (index, chip) in chips.enumerated() {
                chip.frame = PanelBoard.slotFrame(at: index, in: panel.bounds)
            }
        }
    }
}
