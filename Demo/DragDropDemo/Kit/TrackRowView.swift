//
//  TrackRowView.swift
//  DragDropDemo
//

import UIKit
import DemoKit

/// One row of the play queue, and the thing that actually gets dragged. The
/// library reframes it directly, so it lays out from `layoutSubviews` and holds
/// no cached geometry.
final class TrackRowView: UIView, Liftable {

    let track: Track

    private let art: SwatchChip
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let durationLabel = UILabel()
    private let grip = UIImageView()

    init(track: Track, identifier: String) {
        self.track = track
        // Prefixed so it cannot answer a query meant for the row itself:
        // "track-1-art" would match a search for "track-".
        self.art = SwatchChip(seed: track.seed, identifier: "art-\(identifier)")
        super.init(frame: .zero)

        backgroundColor = DemoTheme.Surface.card
        layer.cornerRadius = DemoTheme.Radius.medium
        layer.cornerCurve = .continuous
        layer.borderWidth = DemoTheme.hairlineWidth
        layer.borderColor = DemoTheme.Surface.hairline.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.10
        layer.shadowRadius = 3
        layer.shadowOffset = CGSize(width: 0, height: 1)

        // The art is decoration inside the row, never separately draggable and
        // never a match for a query meant for the row.
        art.isAccessibilityElement = false
        addSubview(art)

        titleLabel.text = track.title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = DemoTheme.Text.primary
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.75
        addSubview(titleLabel)

        artistLabel.text = track.artist
        artistLabel.font = DemoTheme.Font.caption
        artistLabel.textColor = DemoTheme.Text.secondary
        addSubview(artistLabel)

        durationLabel.text = track.duration
        durationLabel.font = DemoTheme.Font.number(11, weight: .regular)
        durationLabel.textColor = DemoTheme.Text.tertiary
        durationLabel.textAlignment = .left
        addSubview(durationLabel)

        grip.image = UIImage(systemName: "line.3.horizontal")
        grip.tintColor = DemoTheme.Text.tertiary
        grip.contentMode = .scaleAspectFit
        addSubview(grip)

        accessibilityIdentifier = identifier
        isAccessibilityElement = true
        accessibilityLabel = "\(track.title), \(track.artist)"

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (row: TrackRowView, _) in
            row.layer.borderColor = DemoTheme.Surface.hairline.cgColor
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()

        let inset = DemoTheme.Space.s
        // Square, and smaller than the row, so the text column keeps its width.
        let artSize = min(56, max(0, bounds.height - inset * 2))
        art.frame = CGRect(x: inset,
                           y: (bounds.height - artSize) / 2,
                           width: artSize,
                           height: artSize)

        let gripWidth: CGFloat = 12
        grip.frame = CGRect(x: bounds.width - inset - gripWidth,
                            y: (bounds.height - gripWidth) / 2,
                            width: gripWidth,
                            height: gripWidth)

        let textX = art.frame.maxX + DemoTheme.Space.s
        let textWidth = max(0, grip.frame.minX - DemoTheme.Space.s - textX)

        let titleHeight = titleLabel.font.lineHeight
        let artistHeight = artistLabel.font.lineHeight
        let durationHeight = durationLabel.font.lineHeight
        let block = titleHeight + artistHeight + durationHeight
        let top = (bounds.height - block) / 2

        titleLabel.frame = CGRect(x: textX, y: top, width: textWidth, height: titleHeight)
        artistLabel.frame = CGRect(x: textX, y: titleLabel.frame.maxY,
                                   width: textWidth, height: artistHeight)
        durationLabel.frame = CGRect(x: textX, y: artistLabel.frame.maxY,
                                     width: textWidth, height: durationHeight)
    }
}
