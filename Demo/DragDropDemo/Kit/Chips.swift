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

    /// Where the name goes.
    ///
    /// `.inside` overlays it on the bottom of the square, which only works for
    /// a word or two on a large tile. `.below` gives it the item's full width
    /// underneath, which is how a file manager has always labelled a document
    /// and the only way a 44pt tile can carry a name like "Moodboard" at a
    /// size anyone can read.
    enum CaptionPlacement {
        case inside
        case below
    }

    /// The tinted square. Separate from the chip itself so `.below` can label
    /// the item without the label sitting on the colour, and so a folder's
    /// contents can be laid out in the square rather than in the whole item.
    private let tileView = UIView()
    private let iconView = UIImageView()
    private let captionLabel = UILabel()
    private let badgeLabel = PaddedLabel()

    private let captionPlacement: CaptionPlacement
    private let hasCaption: Bool

    /// The square's frame in this chip's coordinates. What a drop target nested
    /// in a tile should lay its contents out in -- `bounds` would include the
    /// caption and push the contents down over it.
    var tileBounds: CGRect { tileView.frame }

    /// Shown top-trailing when non-nil. The Files folder uses it to count what
    /// it holds.
    var badge: Int? {
        didSet {
            badgeLabel.text = badge.map(String.init)
            badgeLabel.isHidden = badge == nil || badge == 0
            setNeedsLayout()
        }
    }

    private let hue: DemoTheme.Hue

    init(symbolName: String,
         hue: DemoTheme.Hue,
         caption: String? = nil,
         captionPlacement: CaptionPlacement = .inside,
         identifier: String) {

        self.hue = hue
        self.captionPlacement = captionPlacement
        self.hasCaption = caption != nil
        super.init(frame: .zero)

        tileView.backgroundColor = DemoTheme.tint(hue)
        tileView.layer.cornerCurve = .continuous
        tileView.layer.shadowColor = UIColor.black.cgColor
        tileView.layer.shadowOpacity = 0.10
        tileView.layer.shadowRadius = 3
        tileView.layer.shadowOffset = CGSize(width: 0, height: 1)
        addSubview(tileView)

        iconView.image = UIImage(systemName: symbolName)
        iconView.tintColor = DemoTheme.color(hue)
        iconView.contentMode = .scaleAspectFit
        tileView.addSubview(iconView)

        captionLabel.text = caption
        captionLabel.textAlignment = .center
        captionLabel.isHidden = caption == nil
        captionLabel.adjustsFontSizeToFitWidth = true

        switch captionPlacement {
        case .inside:
            captionLabel.font = UIFont.systemFont(ofSize: 8, weight: .medium)
            captionLabel.numberOfLines = 1
            captionLabel.textColor = DemoTheme.Text.secondary
            captionLabel.minimumScaleFactor = 0.7
        case .below:
            // Full item width and the body text colour, so the name reads as
            // content rather than as a watermark on the icon. Two lines for a
            // name that wraps, and a floor of 0.85 rather than 0.7 -- a long
            // single word should end up a little smaller, never unreadable.
            captionLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
            captionLabel.numberOfLines = 2
            captionLabel.textColor = DemoTheme.Text.primary
            captionLabel.minimumScaleFactor = 0.85
        }
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

    /// For a tile that is itself a drop target -- the Files folder. The
    /// dragged tile sits on top of it, so the feedback has to live at the
    /// edges: a ring and a size change, not a fill the finger covers.
    func setDropState(_ accepting: Bool) {
        // On the square, not the chip: with the caption below, a ring around
        // the whole item would enclose the name as well and read as a text
        // field rather than as a folder about to take a drop.
        tileView.layer.borderWidth = accepting ? DemoTheme.highlightWidth : 0
        tileView.layer.borderColor = accepting ? DemoTheme.color(hue).cgColor : nil
        transform = accepting ? CGAffineTransform(scaleX: 1.14, y: 1.14) : .identity
        tileView.layer.shadowOpacity = accepting ? 0.3 : 0.10
        tileView.layer.shadowRadius = accepting ? 10 : 3
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        switch captionPlacement {
        case .inside:
            tileView.frame = bounds

            // Proportional, so a 44pt tile and a 72pt one are both labelled at
            // a size that suits them.
            let captionSize = min(11, max(8, bounds.height * 0.135))
            captionLabel.font = UIFont.systemFont(ofSize: captionSize, weight: .medium)
            let captionHeight: CGFloat = captionLabel.isHidden ? 0 : captionSize + 2
            let iconInset = bounds.height * 0.20
            iconView.frame = CGRect(x: iconInset,
                                    y: iconInset,
                                    width: max(0, tileView.bounds.width - iconInset * 2),
                                    height: max(0, tileView.bounds.height - captionHeight - iconInset * 2))
            captionLabel.frame = CGRect(x: 2,
                                        y: bounds.height - captionHeight - 2,
                                        width: max(0, bounds.width - 4),
                                        height: captionHeight)

        case .below:
            // The name is measured first and the square takes what is left,
            // rather than the other way round. Sizing the square first leaves
            // the caption whatever remains, which is how you end up with an
            // 11pt font in an 11pt box and the descenders shaved off.
            var captionHeight: CGFloat = 0
            if hasCaption {
                let fits = captionLabel.sizeThatFits(CGSize(width: bounds.width,
                                                            height: .greatestFiniteMagnitude))
                captionHeight = min(ceil(captionLabel.font.lineHeight * 2), ceil(fits.height))
            }

            // Below a certain size there is no room for both, and a name
            // crushed onto a pip is worse than no name: the item shrinks to a
            // pip precisely when it has been filed somewhere that identifies
            // it. Drop the caption and let the mark have the whole item.
            if bounds.height - captionHeight - Self.captionGap < Self.minimumSquare {
                captionHeight = 0
            }
            captionLabel.isHidden = !hasCaption || captionHeight == 0

            let gap = captionHeight > 0 ? Self.captionGap : 0
            let square = min(bounds.width, max(0, bounds.height - captionHeight - gap))
            tileView.frame = CGRect(x: (bounds.width - square) / 2, y: 0,
                                    width: square, height: square)

            let iconInset = square * 0.22
            iconView.frame = tileView.bounds.insetBy(dx: iconInset, dy: iconInset)

            captionLabel.frame = CGRect(x: 0,
                                        y: tileView.frame.maxY + gap,
                                        width: bounds.width,
                                        height: captionHeight)
        }

        tileView.layer.cornerRadius = min(DemoTheme.Radius.medium, tileView.bounds.height / 4)

        let size = badgeLabel.intrinsicContentSize
        badgeLabel.frame = CGRect(x: tileView.frame.maxX - size.width + 4,
                                  y: tileView.frame.minY - 4,
                                  width: size.width,
                                  height: size.height)
        badgeLabel.layer.cornerRadius = size.height / 2
    }

    private static let captionGap: CGFloat = 5
    /// Under this, an item shows its mark and nothing else.
    private static let minimumSquare: CGFloat = 34
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
        //
        // These are sublayers rather than views, so they do not inherit a
        // UIView animation -- they take CALayer's own implicit one, which is
        // wrong during a cell reuse and has to be suppressed. Suppressing it
        // unconditionally was worse: the gradient and the scrim *are* the
        // visible card, so a resize animated the bounds while the thing anyone
        // can see jumped straight to its final size. Inherit the ambient
        // duration when there is one, and suppress only when there is not.
        let inherited = UIView.inheritedAnimationDuration
        CATransaction.begin()
        CATransaction.setDisableActions(inherited == 0)
        if inherited > 0 {
            CATransaction.setAnimationDuration(inherited)
        }
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
