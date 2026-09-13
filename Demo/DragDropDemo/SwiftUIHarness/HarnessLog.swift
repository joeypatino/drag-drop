import Observation

/// What the SwiftUI side of the harness can see of a drag, shown as text so a
/// UI test can read it after the drop.
@MainActor
@Observable
final class HarnessLog {
    /// Draggable views per panel id, as each coordinator last reported them.
    var counts: [String: Int] = [:]

    /// `ok` until a hover finds the dragged view away from the finger
    /// (`offset`) or under another view (`covered`). Never reset, so one bad
    /// frame anywhere in the drag survives to the end of the test.
    var probe = "ok"

    /// `a:3 b:0`, sorted by panel id.
    var summary: String {
        counts.keys.sorted().map { "\($0):\(counts[$0] ?? 0)" }.joined(separator: " ")
    }

    func publish(_ id: String, _ count: Int) {
        counts[id] = count
    }
}
