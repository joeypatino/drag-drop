import SwiftUI

/// The SwiftUI arrangements the integration tests drive. Reached only with
/// `-swiftui <rawValue>`; never listed in the demo index.
enum HarnessConfiguration: String, CaseIterable {
    case baseline, siblings, sheet, detent, scroll, list, table, collection, pushed, tabs

    static var requested: HarnessConfiguration? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-swiftui"),
              index + 1 < arguments.count else { return nil }
        return HarnessConfiguration(rawValue: arguments[index + 1])
    }
}

struct HarnessRoot: View {
    let configuration: HarnessConfiguration
    @State private var log = HarnessLog()

    var body: some View {
        VStack(spacing: 8) {
            Text(log.probe).accessibilityIdentifier("probe")
            Text(log.summary).accessibilityIdentifier("counts")
            content
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var content: some View {
        switch configuration {
        case .baseline:
            PanelBoard(panels: [PanelSpec(id: "a", chips: 3), PanelSpec(id: "b", chips: 0)],
                       axis: .horizontal,
                       log: log)
        case .siblings:
            siblingBoards
        default:
            Text("Not built yet")
        }
    }

    /// Two representables, each with its own coordinator.
    var siblingBoards: some View {
        HStack(spacing: 12) {
            PanelBoard(panels: [PanelSpec(id: "a", chips: 3)], axis: .vertical, log: log)
            PanelBoard(panels: [PanelSpec(id: "b", chips: 0)], axis: .vertical, log: log)
        }
    }
}
