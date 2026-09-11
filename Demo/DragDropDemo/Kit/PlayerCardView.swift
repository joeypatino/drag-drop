//
//  PlayerCardView.swift
//  DragDropDemo
//

import UIKit
import DemoKit

/// One player. Jersey number, avatar, name, and a position pill tinted by
/// position so a lineup can be read at a glance.
final class PlayerCardView: UIView {

    private let numberLabel = UILabel()
    private let nameLabel = UILabel()
    private let pill = PaddedLabel()
    private let avatar: AvatarChip

    static func hue(for position: Player.Position) -> DemoTheme.Hue {
        switch position {
        case .goalkeeper: .amber
        case .defender: .teal
        case .midfielder: .indigo
        case .forward: .coral
        }
    }

    init(player: Player, identifier: String) {
        // Tinted by position, not by name: on this card colour carries the
        // position, and the pill below repeats it rather than competing.
        self.avatar = AvatarChip(name: player.name,
                                 hue: Self.hue(for: player.position),
                                 identifier: "face-\(identifier)")
        super.init(frame: .zero)

        // Raised, not card: these sit inside a panel that is already
        // Surface.card, and white on white needs more than a hairline.
        backgroundColor = DemoTheme.Surface.raised
        layer.cornerRadius = DemoTheme.Radius.medium
        layer.cornerCurve = .continuous
        layer.borderWidth = DemoTheme.hairlineWidth
        layer.borderColor = DemoTheme.Surface.hairline.cgColor

        // Decoration inside the card, never a match for a query meant for it.
        avatar.isAccessibilityElement = false
        addSubview(avatar)

        numberLabel.text = "\(player.number)"
        numberLabel.font = DemoTheme.Font.number(22, weight: .bold)
        numberLabel.textColor = DemoTheme.Text.primary
        numberLabel.textAlignment = .center
        addSubview(numberLabel)

        nameLabel.text = player.name
        nameLabel.font = DemoTheme.Font.caption
        nameLabel.textColor = DemoTheme.Text.secondary
        nameLabel.textAlignment = .center
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.75
        addSubview(nameLabel)

        let hue = Self.hue(for: player.position)
        pill.text = player.position.abbreviation
        pill.font = DemoTheme.Font.number(10, weight: .bold)
        pill.textColor = DemoTheme.Text.onAccent
        pill.backgroundColor = DemoTheme.color(hue)
        pill.textAlignment = .center
        pill.insets = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
        pill.layer.masksToBounds = true
        addSubview(pill)

        accessibilityIdentifier = identifier
        isAccessibilityElement = true
        accessibilityLabel = "\(player.name), number \(player.number), \(player.position.rawValue)"

        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (card: PlayerCardView, _) in
            card.layer.borderColor = DemoTheme.Surface.hairline.cgColor
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()

        let inset = DemoTheme.Space.s
        let avatarSize: CGFloat = 32
        avatar.frame = CGRect(x: (bounds.width - avatarSize) / 2,
                              y: inset,
                              width: avatarSize,
                              height: avatarSize)
        avatar.layoutIfNeeded()

        numberLabel.frame = CGRect(x: 0, y: avatar.frame.maxY + 2,
                                   width: bounds.width, height: 26)
        nameLabel.frame = CGRect(x: 4, y: numberLabel.frame.maxY,
                                 width: max(0, bounds.width - 8),
                                 height: nameLabel.font.lineHeight)

        let size = pill.intrinsicContentSize
        pill.frame = CGRect(x: (bounds.width - size.width) / 2,
                            y: bounds.height - size.height - inset,
                            width: size.width,
                            height: size.height)
        pill.layer.cornerRadius = size.height / 2
    }
}
