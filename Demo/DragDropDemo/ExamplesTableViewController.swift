//
//  ExamplesTableViewController.swift
//  DragDropDemo
//
//  Created by Joey Patino on 11/4/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit
import DemoKit

final class ExamplesTableViewController: UITableViewController {

    /// One row of the index. The subtitle names the library capability the
    /// screen demonstrates, so the technical mapping stays discoverable
    /// underneath the product name.
    ///
    /// One array of these rather than two arrays indexed by the same row
    /// number, which is a bug waiting for someone to insert a demo.
    private struct DemoEntry {
        let title: String
        let capability: String
        let symbol: String
        let hue: DemoTheme.Hue
        let segue: String
    }

    private let entries: [DemoEntry] = [
        DemoEntry(title: "Shift Rota",
                  capability: "Four peer drop targets",
                  symbol: "calendar.badge.clock",
                  hue: .amber,
                  segue: "FourByFourViewController"),
        DemoEntry(title: "Shared Album",
                  capability: "A drop target inside a drop target",
                  symbol: "photo.on.rectangle.angled",
                  hue: .teal,
                  segue: "EmbeddedViewController"),
        DemoEntry(title: "Widget Composer",
                  capability: "A target inset in a non-target container",
                  symbol: "square.stack.3d.up.fill",
                  hue: .violet,
                  segue: "DoubleEmbeddedViewController"),
        DemoEntry(title: "Files",
                  capability: "An item that is itself a drop target",
                  symbol: "folder.fill",
                  hue: .indigo,
                  segue: "EmbeddedDropTargetViewController"),
        DemoEntry(title: "Up Next",
                  capability: "Table rows dragging out and dropping in",
                  symbol: "list.bullet",
                  hue: .rose,
                  segue: "NormalTableViewController"),
        DemoEntry(title: "Moodboard",
                  capability: "Reordering a masonry collection view",
                  symbol: "square.grid.3x3.fill",
                  hue: .mint,
                  segue: "NormalCollectionViewController"),
        DemoEntry(title: "Lineup",
                  capability: "Moving between two collection views",
                  symbol: "person.2.fill",
                  hue: .coral,
                  segue: "DoubleCollectionViewController")
    ]

    private var hasFollowedLaunchArgument = false

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Drag & Drop"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ExampleCell")
        // Two lines of text plus breathing room: at 64 the subtitle's
        // descenders were being clipped.
        tableView.rowHeight = 74
    }

    /// Jumps straight to a demo when launched with `-demo <SegueIdentifier>`.
    /// Screenshots and UI tests would otherwise pay for a tap and a push
    /// animation on every run.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !hasFollowedLaunchArgument,
              let index = ProcessInfo.processInfo.arguments.firstIndex(of: "-demo"),
              index + 1 < ProcessInfo.processInfo.arguments.count else { return }

        // Only a name that actually matches a row: an unknown or empty
        // identifier would otherwise take the app down on launch.
        let requested = ProcessInfo.processInfo.arguments[index + 1]
        guard entries.contains(where: { $0.segue == requested }) else { return }

        hasFollowedLaunchArgument = true
        performSegue(withIdentifier: requested, sender: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        entries.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let entry = entries[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath)

        var configuration = cell.defaultContentConfiguration()
        configuration.text = entry.title
        configuration.textProperties.font = DemoTheme.Font.title
        configuration.secondaryText = entry.capability
        configuration.secondaryTextProperties.font = DemoTheme.Font.caption
        configuration.secondaryTextProperties.color = DemoTheme.Text.secondary
        configuration.image = UIImage(systemName: entry.symbol)
        configuration.imageProperties.tintColor = DemoTheme.color(entry.hue)
        configuration.imageProperties.maximumSize = CGSize(width: 26, height: 26)
        configuration.imageToTextPadding = DemoTheme.Space.m
        cell.contentConfiguration = configuration
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityIdentifier = "demo-\(entry.segue)"

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: entries[indexPath.row].segue, sender: nil)
    }
}
