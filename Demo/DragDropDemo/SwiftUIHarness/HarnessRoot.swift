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
    @State private var lineup = LineupModel()

    var body: some View {
        VStack(spacing: 8) {
            if configuration != .sheet {
                HarnessStatus(log: log)
            }
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
        case .sheet:
            PageSheetHost(log: log)
        case .detent:
            DetentSheetHost(log: log)
        case .scroll:
            ScrollView {
                VStack(spacing: 16) {
                    Text("Top").accessibilityIdentifier("scroll-top")
                    boardForScrolling
                    Color.clear.frame(height: 1200)
                }
            }
        case .list:
            List {
                Text("Top").accessibilityIdentifier("scroll-top")
                boardForScrolling
                ForEach(0..<30, id: \.self) { Text("Row \($0)") }
            }
        case .table:
            HStack(spacing: 12) {
                HarnessTable(log: log)
                PanelBoard(panels: [PanelSpec(id: "saved", chips: 0)], axis: .vertical, log: log)
            }
        case .collection:
            HStack(spacing: 12) {
                HarnessCollection(id: "starters", model: lineup, log: log)
                HarnessCollection(id: "bench", model: lineup, log: log)
            }
        case .pushed:
            PushedHost(log: log)
        case .tabs:
            TabsHost(log: log)
        }
    }

    /// Two representables, each with its own coordinator.
    var siblingBoards: some View {
        HStack(spacing: 12) {
            PanelBoard(panels: [PanelSpec(id: "a", chips: 3)], axis: .vertical, log: log)
            PanelBoard(panels: [PanelSpec(id: "b", chips: 0)], axis: .vertical, log: log)
        }
    }

    /// C5: the panels inside a `ScrollView` or `List`, where a swipe starting
    /// on a chip should scroll rather than drag.
    private var boardForScrolling: some View {
        PanelBoard(panels: [PanelSpec(id: "a", chips: 3), PanelSpec(id: "b", chips: 0)],
                   axis: .vertical,
                   log: log)
            .frame(height: 400)
    }
}

/// The two texts a UI test reads. A page sheet is modal, so the texts under it
/// are not reachable; that configuration shows its own copy inside the sheet
/// and the root hides its copy, keeping each identifier unique on screen.
struct HarnessStatus: View {
    let log: HarnessLog

    var body: some View {
        VStack(spacing: 4) {
            Text(log.probe).accessibilityIdentifier("probe")
            Text(log.summary).accessibilityIdentifier("counts")
        }
    }
}

/// C3: the panels inside a page sheet, whose hosting view starts well below
/// the window's top edge.
struct PageSheetHost: View {
    let log: HarnessLog
    @State private var isPresented = true

    var body: some View {
        Color.clear
            .sheet(isPresented: $isPresented) {
                VStack(spacing: 8) {
                    HarnessStatus(log: log)
                    PanelBoard(panels: [PanelSpec(id: "a", chips: 3), PanelSpec(id: "b", chips: 0)],
                               axis: .vertical,
                               log: log)
                        .frame(height: 232)
                    Spacer()
                }
                .padding(16)
                .interactiveDismissDisabled()
            }
    }
}

/// C4: the panels on the root screen, with a medium-detent sheet up that
/// leaves the screen underneath usable. The drag happens *under* a presented
/// controller.
struct DetentSheetHost: View {
    let log: HarnessLog
    @State private var isPresented = true

    var body: some View {
        VStack {
            PanelBoard(panels: [PanelSpec(id: "a", chips: 3), PanelSpec(id: "b", chips: 0)],
                       axis: .horizontal,
                       log: log)
                .frame(height: 160)
            Spacer()
        }
        .sheet(isPresented: $isPresented) {
            Text("Inspector")
                .presentationDetents([.medium])
                .presentationBackgroundInteraction(.enabled)
                .interactiveDismissDisabled()
        }
    }
}

/// C8: a target on the root of a navigation stack, under a pushed screen.
struct PushedHost: View {
    let log: HarnessLog

    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink("Open") {
                    VStack {
                        PanelBoard(panels: [PanelSpec(id: "a", chips: 3)], axis: .vertical, log: log)
                            .frame(height: 200)
                        Spacer()
                    }
                }
                Spacer()
                PanelBoard(panels: [PanelSpec(id: "home", chips: 0)], axis: .vertical, log: log)
                    .frame(height: 300)
            }
        }
    }
}

/// C8: a target on a tab that has been shown and then left.
struct TabsHost: View {
    let log: HarnessLog
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            Tab("First", systemImage: "1.circle", value: 0) {
                VStack {
                    Spacer()
                    PanelBoard(panels: [PanelSpec(id: "hidden", chips: 0)], axis: .vertical, log: log)
                        .frame(height: 300)
                }
            }
            Tab("Second", systemImage: "2.circle", value: 1) {
                VStack {
                    PanelBoard(panels: [PanelSpec(id: "a", chips: 3)], axis: .vertical, log: log)
                        .frame(height: 200)
                    Spacer()
                }
            }
        }
    }
}
