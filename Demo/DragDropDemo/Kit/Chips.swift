//
//  Chips.swift
//  DragDropDemo
//

import UIKit
import DemoKit

/// Something that can show it has been picked up. The library wraps its
/// `willStartDrag` and `willEndDrag` delegate calls in a `UIView.animate`
/// block, so a chip only has to set its properties -- the animation is the
/// library's.
protocol Liftable: UIView {
    func setLifted(_ lifted: Bool)
}

extension Liftable {
    func setLifted(_ lifted: Bool) {
        transform = lifted ? CGAffineTransform(scaleX: 1.08, y: 1.08) : .identity
        layer.shadowOpacity = lifted ? 0.28 : 0.10
        layer.shadowRadius = lifted ? 10 : 3
    }
}

// MARK: - Avatar

/// A person. Initials over a colour derived from their name, so the same
/// person is the same colour everywhere and across launches.
final class AvatarChip: UIView, Liftable {

    private let label = UILabel()

    /// `hue` defaults to one derived from the name, which is what the rota
    /// wants -- there, colour is only identity. Pass one to make the colour
    /// mean something instead, as the lineup does with position.
    init(name: String, hue: DemoTheme.Hue? = nil, identifier: String) {
        super.init(frame: .zero)

        backgroundColor = DemoTheme.color(hue ?? DemoTheme.hue(for: name))

        label.text = StaffMember(id: 0, name: name, role: "").initials
        label.font = DemoTheme.Font.number(15, weight: .bold)
        label.textColor = DemoTheme.Text.onAccent
        label.textAlignment = .center
        addSubview(label)

        // A ring, so two avatars overlapping mid-drag stay separable.
        layer.borderWidth = 2
        layer.borderColor = DemoTheme.Surface.card.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.10
        layer.shadowRadius = 3
        layer.shadowOffset = CGSize(width: 0, height: 1)

        accessibilityIdentifier = identifier
        isAccessibilityElement = true
        accessibilityLabel = name

        // CGColor does not resolve dynamically, so the ring has to be redrawn
        // when the appearance changes.
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (chip: AvatarChip, _) in
            chip.layer.borderColor = DemoTheme.Surface.card.cgColor
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        label.frame = bounds
    }
}

// MARK: - Tile

/// A widget, a file, a folder. A symbol on a tinted rounded square.
final class TileChip: UIView, Liftable {

    private let iconView = UIImageView()
    private let captionLabel = UILabel()
    private let badgeLabel = PaddedLabel()

    /// Shown top-trailing when non-nil. The Files folder uses it to count what
    /// it holds.
    var badge: Int? {
        didSet {
            badgeLabel.text = badge.map(String.init)
            badgeLabel.isHidden = badge == nil || badge == 0
            setNeedsLayout()
        }
    }

    init(symbolName: String,
         hue: DemoTheme.Hue,
         caption: String? = nil,
         identifier: String) {

        super.init(frame: .zero)

        backgroundColor = DemoTheme.tint(hue)
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.10
        layer.shadowRadius = 3
        layer.shadowOffset = CGSize(width: 0, height: 1)

        iconView.image = UIImage(systemName: symbolName)
        iconView.tintColor = DemoTheme.color(hue)
        iconView.contentMode = .scaleAspectFit
        addSubview(iconView)

        captionLabel.text = caption
        captionLabel.font = UIFont.systemFont(ofSize: 8, weight: .medium)
        captionLabel.numberOfLines = 1
        captionLabel.textColor = DemoTheme.Text.secondary
        captionLabel.textAlignment = .center
        captionLabel.adjustsFontSizeToFitWidth = true
        captionLabel.minimumScaleFactor = 0.7
        captionLabel.isHidden = caption == nil
        addSubview(captionLabel)

        badgeLabel.font = DemoTheme.Font.number(11, weight: .bold)
        badgeLabel.textColor = DemoTheme.Text.onAccent
        badgeLabel.backgroundColor = DemoTheme.color(hue)
        badgeLabel.textAlignment = .center
        badgeLabel.insets = UIEdgeInsets(top: 1, left: 5, bottom: 1, right: 5)
        badgeLabel.layer.masksToBounds = true
        badgeLabel.isHidden = true
        addSubview(badgeLabel)

        accessibilityIdentifier = identifier
        isAccessibilityElement = true
        accessibilityLabel = caption ?? identifier
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = min(DemoTheme.Radius.medium, bounds.height / 4)

        // Proportional, so a 44pt file tile and a 72pt folder are both labelled
        // at a size that suits them.
        let captionSize = min(11, max(8, bounds.height * 0.135))
        captionLabel.font = UIFont.systemFont(ofSize: captionSize, weight: .medium)
        let captionHeight: CGFloat = captionLabel.isHidden ? 0 : captionSize + 2
        let iconInset = bounds.height * 0.20
        iconView.frame = CGRect(x: iconInset,
                                y: iconInset,
                                width: max(0, bounds.width - iconInset * 2),
                                height: max(0, bounds.height - captionHeight - iconInset * 2))
        captionLabel.frame = CGRect(x: 2,
                                    y: bounds.height - captionHeight - 2,
                                    width: max(0, bounds.width - 4),
                                    height: captionHeight)

        let size = badgeLabel.intrinsicContentSize
        badgeLabel.frame = CGRect(x: bounds.width - size.width + 4,
                                  y: -4,
                                  width: size.width,
                                  height: size.height)
        badgeLabel.layer.cornerRadius = size.height / 2
    }
}

// MARK: - Swatch

/// Photographic content without a photograph: a two-stop gradient seeded from
/// a string, so the same photo or album art is always the same image.
final class SwatchChip: UIView, Liftable {

    private let gradient = CAGradientLayer()
    private let scrim = CAGradientLayer()
    private let captionLabel = UILabel()
    private let detailLabel = UILabel()

    /// Seeded from a string: for content that has no colour of its own, like a
    /// photo thumbnail or album art.
    convenience init(seed: String,
                     caption: String? = nil,
                     detail: String? = nil,
                     identifier: String) {
        // Two hues a third of the way apart on the ramp, so a swatch reads as
        // one image rather than two colours fighting.
        let all = DemoTheme.Hue.allCases
        let index = Int(DemoTheme.stableHash(seed) % UInt64(all.count))
        self.init(base: DemoTheme.color(all[index]),
                  partner: DemoTheme.color(all[(index + 3) % all.count]),
                  caption: caption,
                  detail: detail,
                  identifier: identifier)
    }

    /// Built from an actual colour: for content that names one. A moodboard
    /// card printing "#E86A4A" has to be that colour, or the label is a lie.
    convenience init(color: UIColor,
                     caption: String? = nil,
                     detail: String? = nil,
                     identifier: String) {
        self.init(base: color,
                  partner: color.gradientPartner,
                  caption: caption,
                  detail: detail,
                  identifier: identifier)
    }

    private init(base: UIColor,
                 partner: UIColor,
                 caption: String?,
                 detail: String?,
                 identifier: String) {
        super.init(frame: .zero)

        gradient.colors = [base.cgColor, partner.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(gradient)

        // Only needed when there is text to keep legible.
        if caption != nil || detail != nil {
            scrim.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.5).cgColor]
            scrim.startPoint = CGPoint(x: 0.5, y: 0.4)
            scrim.endPoint = CGPoint(x: 0.5, y: 1)
            layer.addSublayer(scrim)
        }

        captionLabel.text = caption
        captionLabel.font = DemoTheme.Font.headline
        captionLabel.textColor = .white
        captionLabel.isHidden = caption == nil
        addSubview(captionLabel)

        detailLabel.text = detail
        detailLabel.font = DemoTheme.Font.number(11)
        detailLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        detailLabel.isHidden = detail == nil
        addSubview(detailLabel)

        clipsToBounds = false
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.10
        layer.shadowRadius = 3
        layer.shadowOffset = CGSize(width: 0, height: 1)

        accessibilityIdentifier = identifier
        isAccessibilityElement = true
        accessibilityLabel = caption ?? identifier
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()

        let radius = min(DemoTheme.Radius.medium, bounds.height / 4)
        layer.cornerRadius = radius

        // The gradient is clipped by its own corner radius rather than the
        // view's, so the view can keep a shadow outside its bounds.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradient.frame = bounds
        gradient.cornerRadius = radius
        gradient.masksToBounds = true
        scrim.frame = bounds
        scrim.cornerRadius = radius
        scrim.masksToBounds = true
        CATransaction.commit()

        let inset = DemoTheme.Space.s
        let detailHeight: CGFloat = detailLabel.isHidden ? 0 : detailLabel.font.lineHeight
        detailLabel.frame = CGRect(x: inset,
                                   y: bounds.height - inset - detailHeight,
                                   width: max(0, bounds.width - inset * 2),
                                   height: detailHeight)

        let captionHeight: CGFloat = captionLabel.isHidden ? 0 : captionLabel.font.lineHeight
        captionLabel.frame = CGRect(x: inset,
                                    y: detailLabel.frame.minY - captionHeight,
                                    width: max(0, bounds.width - inset * 2),
                                    height: captionHeight)
    }
}
