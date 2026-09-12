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
        guard DemoCatalog.entries.contains(where: { $0.segue == requested }) else { return }

        hasFollowedLaunchArgument = true
        performSegue(withIdentifier: requested, sender: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        DemoCatalog.entries.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let entry = DemoCatalog.entries[indexPath.row]
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
        performSegue(withIdentifier: DemoCatalog.entries[indexPath.row].segue, sender: nil)
    }
}
