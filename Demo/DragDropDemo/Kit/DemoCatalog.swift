//
//  DemoCatalog.swift
//  DragDropDemo
//

import UIKit
import DemoKit

/// The seven demos, in the order the index lists them.
///
/// Held here rather than inside `ExamplesTableViewController` because a demo is
/// reached two ways -- tapping a row, and the `-demo <SegueIdentifier>` launch
/// argument -- so handing the entry to the screen through
/// `prepare(for:sender:)` would cover only one of them. Both paths can read a
/// list; neither has to be told.
enum DemoCatalog {

    /// One row of the index. `capability` names the library capability the
    /// screen demonstrates, so the technical mapping stays discoverable
    /// underneath the product name.
    ///
    /// One array of these rather than two arrays indexed by the same row
    /// number, which is a bug waiting for someone to insert a demo.
    struct Entry {
        let title: String
        let capability: String
        let symbol: String
        let hue: DemoTheme.Hue
        let segue: String
    }

    static let entries: [Entry] = [
        Entry(title: "Shift Rota",
              capability: "Four peer drop targets",
              symbol: "calendar.badge.clock",
              hue: .amber,
              segue: "SeparateTargetsViewController"),
        Entry(title: "Shared Album",
              capability: "A drop target inside a drop target",
              symbol: "photo.on.rectangle.angled",
              hue: .teal,
              segue: "TargetInsideTargetViewController"),
        Entry(title: "Widget Composer",
              capability: "A target inset in a non-target container",
              symbol: "square.stack.3d.up.fill",
              hue: .violet,
              segue: "TargetInsideNonTargetViewController"),
        Entry(title: "Files",
              capability: "An item that is itself a drop target",
              symbol: "folder.fill",
              hue: .indigo,
              segue: "TargetOnAnItemViewController"),
        Entry(title: "Up Next",
              capability: "Table rows dragging out and dropping in",
              symbol: "list.bullet",
              hue: .rose,
              segue: "TableRowMoveViewController"),
        Entry(title: "Moodboard",
              capability: "Reordering a masonry collection view",
              symbol: "square.grid.3x3.fill",
              hue: .mint,
              segue: "CollectionRearrangeViewController"),
        Entry(title: "Lineup",
              capability: "Moving between two collection views",
              symbol: "person.2.fill",
              hue: .coral,
              segue: "CollectionSwapViewController")
    ]

    /// The segue identifier is also the demo's class name, which is what lets a
    /// screen look itself up without being handed anything.
    static func entry(forSegue segue: String) -> Entry? {
        entries.first { $0.segue == segue }
    }
}
