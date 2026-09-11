//
//  AnimationTrace.swift
//  DragDrop
//
//  Diagnostic harness for proving whether an animation actually reached the
//  screen. Two halves that have to be used together:
//
//  * `AnimationTrace.event` records, per interaction, the model bounds, the
//    presentation bounds and the animation keys of whichever layers matter.
//  * `AnimationTrace.marker` is a clapperboard: a high-contrast strip that
//    encodes the event counter in binary and is re-drawn on every event. It
//    exists because `simctl io recordVideo` starts at an unknown offset, so
//    host wall-clock cannot map a log line to a video frame. The strip can.
//
//  Compiled in only when DRAGDROP_TRACE is defined, so release builds and the
//  ordinary test runs carry none of it.
//

import UIKit
import QuartzCore

@MainActor
public enum AnimationTrace {

    /// Number of blocks in the marker strip; 6 gives 64 distinct events before
    /// the counter wraps, which is more than one drag produces.
    public static let markerBits = 6
    /// Each block is this many points square. Large enough to survive the
    /// video's scaling and any compression.
    public static let markerBlock: CGFloat = 24

    public private(set) static var eventIndex = 0
    private static var lines: [String] = []
    private static weak var markerView: MarkerView?

    // MARK: - Marker

    /// The clapperboard. Add it once, on top of everything.
    public final class MarkerView: UIView {
        private var blocks: [UIView] = []

        public init() {
            super.init(frame: .zero)
            backgroundColor = .green      // never used by the demos, easy to find
            isUserInteractionEnabled = false
            for _ in 0..<AnimationTrace.markerBits {
                let block = UIView()
                block.backgroundColor = .black
                addSubview(block)
                blocks.append(block)
            }
        }

        required init?(coder: NSCoder) { fatalError() }

        public override func layoutSubviews() {
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
            // The marker must never animate, or it cannot date a frame.
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.displayIfNeeded()
            CATransaction.commit()
        }
    }

    public static func installMarker(in window: UIWindow) {
        guard markerView == nil else { return }
        let view = MarkerView()
        view.frame = CGRect(x: 0, y: 0,
                            width: markerBlock * CGFloat(markerBits),
                            height: markerBlock)
        window.addSubview(view)
        markerView = view
        view.show(0)
    }

    // MARK: - Events

    /// Records one interaction. `layers` is label -> view, and every one of them
    /// is sampled for model bounds, presentation bounds and animation keys.
    public static func event(_ name: String, layers: [(String, UIView?)]) {
        eventIndex += 1

        // The marker goes up first, so the frame that shows index N is at or
        // before the state this line records.
        markerView?.superview?.bringSubviewToFront(markerView!)
        markerView?.show(eventIndex)

        var parts: [String] = []
        parts.append("event=\(eventIndex)")
        parts.append("name=\(name)")
        parts.append(String(format: "t=%.6f", CACurrentMediaTime()))

        for (label, view) in layers {
            guard let view else {
                parts.append("\(label)=nil")
                continue
            }
            let model = view.bounds.size
            // Deliberately NOT defaulted to the model value: "no presentation
            // layer" and "presentation equals model" are different findings.
            let presented = view.layer.presentation()?.bounds.size
            let keys = view.layer.animationKeys() ?? []

            parts.append(String(format: "%@.model=%.2fx%.2f", label, model.width, model.height))
            if let presented {
                parts.append(String(format: "%@.pres=%.2fx%.2f", label, presented.width, presented.height))
            } else {
                parts.append("\(label).pres=nil")
            }
            parts.append("\(label).keys=[\(keys.joined(separator: ","))]")
        }

        lines.append(parts.joined(separator: " "))
        flush()
    }

    // MARK: - Fiducials
    //
    // Segmenting a real interface out of a video is guesswork -- a card's dark
    // gradient end matches another card's base colour, text matches a fill, and
    // the measurement silently tracks the wrong object. So the harness marks
    // its own subjects: a hairline in a colour the interface never uses, one
    // per layer of interest. Measuring then means finding pure magenta, and
    // cannot be confused by anything the app draws.
    //
    // Border width does not affect layout -- CALayer draws it inside bounds --
    // so the thing measured is the thing that would have been there anyway.

    public enum Fiducial: CaseIterable {
        case cell, content, inner, render

        public var colour: UIColor {
            switch self {
            case .cell:    return UIColor(red: 1, green: 0, blue: 1, alpha: 1)   // magenta
            case .content: return UIColor(red: 0, green: 1, blue: 1, alpha: 1)   // cyan
            case .inner:   return UIColor(red: 1, green: 1, blue: 0, alpha: 1)   // yellow
            case .render:  return UIColor(red: 1, green: 0, blue: 0, alpha: 1)   // red
            }
        }
    }

    /// A view's own bounds. Note what this can and cannot tell you: a border is
    /// drawn from `bounds`, so it follows a bounds animation even when the
    /// layers that draw the visible content do not. Use `.render` for those.
    public static func outline(_ view: UIView?, as fiducial: Fiducial, width: CGFloat = 3) {
        guard let view else { return }
        view.layer.borderColor = fiducial.colour.cgColor
        view.layer.borderWidth = width
        // A corner radius would round the fiducial away from the true bounds.
        view.layer.cornerRadius = 0
        view.clipsToBounds = false
    }

    /// The sublayer that actually draws. This is the only fiducial that answers
    /// "did what I can see move", because it is attached to the drawing layer's
    /// own geometry rather than to its view's bounds.
    /// Every drawing sublayer, not just the first: they are stacked, so marking
    /// only the bottom one hides the fiducial under the ones above it.
    public static func outlineRenderLayer(of view: UIView?, width: CGFloat = 3) {
        guard let view, let sublayers = view.layer.sublayers else { return }
        // Subviews draw above sublayers, so a label sitting over the drawing
        // layer eats part of the fiducial and the height reads short. The
        // geometry under test is the layer's, not the label's.
        for subview in view.subviews { subview.isHidden = true }
        for layer in sublayers {
            layer.borderColor = Fiducial.render.colour.cgColor
            layer.borderWidth = width
        }
    }

    // MARK: - Per-frame sampling
    //
    // Runs alongside the event log so the two can be compared: Core Animation's
    // own interpolation on one side, the recorded pixels on the other. If they
    // disagree, the layer is animating somewhere the viewer cannot see it.

    private static var link: CADisplayLink?
    private static var sampled: [(String, () -> UIView?)] = []
    private static var frameIndex = 0

    public static func startSampling(_ views: [(String, () -> UIView?)]) {
        stopSampling()
        sampled = views
        frameIndex = 0
        let link = CADisplayLink(target: Proxy.shared, selector: #selector(Proxy.tick))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    public static func stopSampling() {
        link?.invalidate()
        link = nil
    }

    @MainActor
    private final class Proxy: NSObject {
        @MainActor static let shared = Proxy()
        @objc func tick() { AnimationTrace.sample() }
    }

    fileprivate static func sample() {
        frameIndex += 1
        var parts: [String] = []
        parts.append("frame=\(frameIndex)")
        parts.append("marker=\(eventIndex)")
        parts.append(String(format: "t=%.6f", CACurrentMediaTime()))

        for (label, resolve) in sampled {
            guard let view = resolve() else {
                parts.append("\(label)=nil")
                continue
            }
            let model = view.bounds.size
            let presented = view.layer.presentation()?.bounds.size
            parts.append(String(format: "%@.model=%.2fx%.2f", label, model.width, model.height))
            if let presented {
                parts.append(String(format: "%@.pres=%.2fx%.2f", label, presented.width, presented.height))
            } else {
                parts.append("\(label).pres=nil")
            }
        }

        lines.append(parts.joined(separator: " "))
        flush()
    }

    private static func flush() {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("animation-trace.log")
        try? lines.joined(separator: "\n").appending("\n").data(using: .utf8)?.write(to: url)
    }

    public static func reset() {
        eventIndex = 0
        lines = []
        flush()
    }
}
