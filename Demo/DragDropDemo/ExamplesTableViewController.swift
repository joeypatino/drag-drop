//
//  ExamplesTableViewController.swift
//  DragDropDemo
//
//  Created by Joey Patino on 11/4/15.
//  Copyright © 2015 Joseph Patino. All rights reserved.
//

import UIKit

final class ExamplesTableViewController: UITableViewController {

    private var titles: [String] = []
    private var segues: [String] = []

    /// Jumps straight to a demo when launched with `-demo <SegueIdentifier>`.
    /// Screenshots and UI tests would otherwise pay for a tap and a push
    /// animation on every run.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !hasFollowedLaunchArgument,
              let index = ProcessInfo.processInfo.arguments.firstIndex(of: "-demo"),
              index + 1 < ProcessInfo.processInfo.arguments.count else { return }

        hasFollowedLaunchArgument = true
        performSegue(withIdentifier: ProcessInfo.processInfo.arguments[index + 1], sender: nil)
    }

    private var hasFollowedLaunchArgument = false

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ExampleCell")

        titles = [
            "4x4",
            "Container-Embedded",
            "Container-2xEmbedded",
            "Drop Target Embedded",
            "Table View",
            "Collection View",
            "Double Collection View"
        ]

        segues = [
            "FourByFourViewController",
            "EmbeddedViewController",
            "DoubleEmbeddedViewController",
            "EmbeddedDropTargetViewController",
            "NormalTableViewController",
            "NormalCollectionViewController",
            "DoubleCollectionViewController"
        ]
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        titles.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let title = titles[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath)
        var configuration = cell.defaultContentConfiguration()
        configuration.text = title
        cell.contentConfiguration = configuration

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let segueName = segues[indexPath.row]

        performSegue(withIdentifier: segueName, sender: nil)
    }
}
