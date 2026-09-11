//
//  AnimationTrace.swift
//  DragDropDemo
//
//  Diagnostic harness, active only under `-animation-trace`. The position
//  variant of `Tools/animation-trace/template/AnimationTrace.swift`: the bug
//  under test is about *where* rows sit over time rather than how tall they
//  are, so every sample is a y coordinate.
//
//  Three parts, used together:
//
//  * `event` records a named moment in the drag, and bumps the clapperboard.
//  * `MarkerView` is that clapperboard: high-contrast blocks encoding the event
//    counter in binary, redrawn with actions disabled so the marker itself can
//    never animate. `simctl io recordVideo` starts at an unknown offset, so
//    host wall-clock cannot date a frame; the strip can.
//  * `startSampling` logs, every display-link tick, the model and presentation
//    y of every visible cell -- Core Animation's intent, against which the
//    recorded pixels are compared.
//

import UIKit
import QuartzCore
import DemoKit

@MainActor
enum AnimationTrace {

    static let isEnabled = ProcessInfo.processInfo.arguments.contains("-animation-trace")

    static let markerBits = 6
    static let markerBlock: CGFloat = 24

    private(set) static var eventIndex = 0
    private static var lines: [String] = []
    private static var pending = 0
    private static weak var markerView: MarkerView?
    private static weak var table: UITableView?

    // MARK: - Marker

    final class MarkerView: UIView {
        private var blocks: [UIView] = []

        init() {
            super.init(frame: .zero)
            backgroundColor = .green
            isUserInteractionEnabled = false
            for _ in 0..<AnimationTrace.markerBits {
                let block = UIView()
                block.backgroundColor = .black
                addSubview(block)
                blocks.append(block)
            }
        }

        required init?(coder: NSCoder) { fatalError() }

        override func layoutSubviews() {
            super.layoutSubviews()
            for (index, block) in blocks.enumerated() {
                block.frame = CGRect(x: CGFloat(index) * AnimationTrace.markerBlock, y: 0,
                                     width: AnimationTrace.markerBlock,
                                     height: AnimationTrace.markerBlock)
            }
        }

        /// White block = 1, black = 0, least significant bit on the left.
        func show(_ value: Int) {
            for (index, block) in blocks.enumerated() {
                block.backgroundColor = (value >> index) & 1 == 1 ? .white : .black
            }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.displayIfNeeded()
            CATransaction.commit()
        }
    }

    static func installMarker(in window: UIWindow) {
        guard isEnabled, markerView == nil else { return }
        let view = MarkerView()
        view.frame = CGRect(x: 0, y: 0,
                            width: markerBlock * CGFloat(markerBits),
                            height: markerBlock)
        window.addSubview(view)
        markerView = view
        view.show(0)
    }

    // MARK: - Fiducials
    //
    // Four pure colours the interface never uses, one per track worth
    // following, so the video can be measured by lookup rather than by
    // segmenting real content. The first four tracks are the ones the repro
    // moves; everything below them keeps its ordinary look.

    private static let palette: [UIColor] = [
        UIColor(red: 1, green: 0, blue: 0, alpha: 1),   // red
        UIColor(red: 0, green: 1, blue: 1, alpha: 1),   // cyan
        UIColor(red: 1, green: 1, blue: 0, alpha: 1),   // yellow
        UIColor(red: 1, green: 0, blue: 1, alpha: 1),   // magenta
    ]

    /// Marks `view` if `track` is one of the followed ones. The border is drawn
    /// inside bounds, so nothing about the layout changes.
    static func mark(_ view: UIView, for track: Track) {
        guard isEnabled,
              let index = SampleData.tracks.firstIndex(where: { $0.id == track.id }),
              index < palette.count else { return }

        view.layer.borderColor = palette[index].cgColor
        view.layer.borderWidth = 4
        // A corner radius would round the fiducial away from the true bounds.
        view.layer.cornerRadius = 0
    }

    // MARK: - Events

    static func event(_ name: String) {
        guard isEnabled else { return }
        eventIndex += 1

        // The marker goes up first, so the frame showing index N is at or
        // before the state this line records.
        if let markerView {
            markerView.superview?.bringSubviewToFront(markerView)
            markerView.show(eventIndex)
        }

        var parts = ["event=\(eventIndex)", "name=\(name)"]
        parts.append(contentsOf: shared())
        lines.append(parts.joined(separator: " "))
        flush(force: true)
    }

    // MARK: - Per-frame sampling

    private static var link: CADisplayLink?
    private static var frameIndex = 0

    static func startSampling(_ tableView: UITableView) {
        guard isEnabled else { return }
        stopSampling()
        table = tableView
        frameIndex = 0
        let link = CADisplayLink(target: Proxy.shared, selector: #selector(Proxy.tick))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    static func stopSampling() {
        link?.invalidate()
        link = nil
        flush(force: true)
    }

    @MainActor
    private final class Proxy: NSObject {
        @MainActor static let shared = Proxy()
        @objc func tick() { AnimationTrace.sample() }
    }

    private static func sample() {
        frameIndex += 1
        var parts = ["frame=\(frameIndex)", "marker=\(eventIndex)"]
        parts.append(contentsOf: shared())
        lines.append(parts.joined(separator: " "))
        flush(force: false)
    }

    /// The state every line carries: the clock, every visible row, and any
    /// track that is not in a row at all -- which is the one being dragged.
    ///
    /// The cell is what the table animates, so the cell is what is sampled;
    /// the row view inside it is pinned to the cell and would report nothing.
    /// Presentation is deliberately not defaulted to the model value: "no
    /// presentation layer" and "presentation equals model" are different
    /// findings, and conflating them hides a snap.
    private static func shared() -> [String] {
        var parts = [String(format: "t=%.6f", CACurrentMediaTime())]
        guard let table else { return parts }

        parts.append(String(format: "offset=%.2f", table.contentOffset.y))
        parts.append("rows=\(table.numberOfRows(inSection: 0))")

        for (slot, indexPath) in (table.indexPathsForVisibleRows ?? []).enumerated() {
            guard let cell = table.cellForRow(at: indexPath) else { continue }
            let identifier = cell.contentView.subviews
                .compactMap(\.accessibilityIdentifier).first ?? "?"
            let model = cell.frame.minY
            let presented = cell.layer.presentation()?.frame.minY
            let keys = (cell.layer.animationKeys() ?? []).joined(separator: ",")
            parts.append(String(format: "cell.%d=%@:%d:%.2f:%@:[%@]",
                                slot, identifier, indexPath.row, model,
                                presented.map { String(format: "%.2f", $0) } ?? "nil",
                                keys))
        }

        // The dragged view lives in the library's interaction view, above the
        // window. Found by looking rather than by reaching into the library.
        if let window = table.window {
            for (slot, view) in loose(in: window, excluding: table).enumerated() {
                let inWindow = view.superview?.convert(view.frame.origin, to: window) ?? .zero
                let presented = view.layer.presentation()?.frame.minY
                parts.append(String(format: "loose.%d=%@:%@:%.2f:%@",
                                    slot,
                                    view.accessibilityIdentifier ?? "?",
                                    view.superview.map { String(describing: type(of: $0)) } ?? "none",
                                    inWindow.y,
                                    presented.map { String(format: "%.2f", $0) } ?? "nil"))
            }
        }

        return parts
    }

    /// Every followed row view that is not inside one of the table's cells.
    private static func loose(in root: UIView, excluding table: UITableView) -> [UIView] {
        guard root !== table else { return [] }

        if let identifier = root.accessibilityIdentifier, identifier.hasPrefix("track-") {
            return [root]
        }

        return root.subviews.flatMap { loose(in: $0, excluding: table) }
    }

    // MARK: -

    private static func flush(force: Bool) {
        pending += 1
        guard force || pending >= 30 else { return }
        pending = 0

        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("animation-trace.log")
        try? lines.joined(separator: "\n").appending("\n").data(using: .utf8)?.write(to: url)
    }

    static func reset() {
        guard isEnabled else { return }
        eventIndex = 0
        lines = []
        flush(force: true)
    }
}
