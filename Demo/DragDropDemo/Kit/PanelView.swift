//
//  PanelView.swift
//  DragDropDemo
//

import UIKit
import DemoKit

/// A titled card. The chrome -- title, symbol, count badge -- is decoration;
/// `contentView` is the part that gets handed to a controller's
/// `dropTargetView`, so items land in the body and never under the title.
///
/// A drop target nested inside a non-target parent is an arrangement the
/// library already supports; `DoubleEmbeddedViewController` has relied on it
/// since the Objective-C original.
final class PanelView: UIView {

    /// The drop target. Everything else on this view is chrome.
    let contentView = UIView()

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let badgeLabel = PaddedLabel()
    private let emptyLabel = UILabel()

    private let hue: DemoTheme.Hue
    private let hasHeader: Bool

    /// Drawn with a heavier accent border, for a panel that exists to receive
    /// things rather than to hold them.
    var isReceivingZone = false { didSet { applyBorder() } }

    var count: Int? {
        didSet {
            badgeLabel.text = count.map(String.init)
            badgeLabel.isHidden = count == nil
            updateEmptyState()
            setNeedsLayout()
        }
    }

    var emptyMessage: String? {
        didSet {
            emptyLabel.text = emptyMessage
            updateEmptyState()
        }
    }

    init(title: String?,
         subtitle: String? = nil,
         symbolName: String? = nil,
         hue: DemoTheme.Hue = .slate) {

        self.hue = hue
        self.hasHeader = title != nil
        super.init(frame: .zero)

        backgroundColor = DemoTheme.Surface.card
        layer.cornerRadius = DemoTheme.Radius.large
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 2)

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = DemoTheme.color(hue)
        iconView.image = symbolName.flatMap { UIImage(systemName: $0) }
        iconView.isHidden = symbolName == nil
        addSubview(iconView)

        titleLabel.text = title
        titleLabel.font = DemoTheme.Font.title
        titleLabel.textColor = DemoTheme.Text.primary
        addSubview(titleLabel)

        subtitleLabel.text = subtitle
        subtitleLabel.font = DemoTheme.Font.caption
        subtitleLabel.textColor = DemoTheme.Text.secondary
        subtitleLabel.isHidden = subtitle == nil
        addSubview(subtitleLabel)

        badgeLabel.font = DemoTheme.Font.number(12)
        badgeLabel.textColor = DemoTheme.Text.onAccent
        badgeLabel.backgroundColor = DemoTheme.color(hue)
        badgeLabel.textAlignment = .center
        badgeLabel.insets = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)
        badgeLabel.layer.masksToBounds = true
        badgeLabel.isHidden = true
        addSubview(badgeLabel)

        contentView.clipsToBounds = false
        addSubview(contentView)

        emptyLabel.font = DemoTheme.Font.caption
        emptyLabel.textColor = DemoTheme.Text.tertiary
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 2
        emptyLabel.isHidden = true
        contentView.addSubview(emptyLabel)

        applyBorder()

        // CGColor does not resolve dynamically: without this, toggling dark
        // mode while the app is running leaves the border at its old value.
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (panel: PanelView, _) in
            panel.applyBorder()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        let inset = DemoTheme.Space.m
        var top = inset

        if hasHeader {
            let iconSize: CGFloat = iconView.isHidden ? 0 : 22
            iconView.frame = CGRect(x: inset, y: inset, width: iconSize, height: iconSize)

            let badgeSize = badgeLabel.intrinsicContentSize
            badgeLabel.frame = CGRect(x: bounds.width - inset - badgeSize.width,
                                      y: inset,
                                      width: badgeSize.width,
                                      height: badgeSize.height)
            badgeLabel.layer.cornerRadius = badgeSize.height / 2

            let textX = iconView.isHidden ? inset : iconView.frame.maxX + DemoTheme.Space.s
            let textRight = badgeLabel.isHidden ? bounds.width - inset
                                                : badgeLabel.frame.minX - DemoTheme.Space.s
            let textWidth = max(0, textRight - textX)

            titleLabel.frame = CGRect(x: textX, y: inset,
                                      width: textWidth,
                                      height: titleLabel.font.lineHeight)
            subtitleLabel.frame = CGRect(x: textX, y: titleLabel.frame.maxY,
                                         width: textWidth,
                                         height: subtitleLabel.isHidden ? 0 : subtitleLabel.font.lineHeight)

            top = max(subtitleLabel.frame.maxY, iconView.frame.maxY) + DemoTheme.Space.s
        }

        contentView.frame = CGRect(x: inset,
                                   y: top,
                                   width: max(0, bounds.width - inset * 2),
                                   height: max(0, bounds.height - top - inset))
        emptyLabel.frame = contentView.bounds
    }

    // MARK: - State

    /// What a panel looks like while a drag is over it.
    enum DropState {
        /// Nothing is hovering.
        case idle
        /// A drop here would land. The panel lifts and takes the accent.
        case accepting
        /// A drop here would be refused -- the rota's "they are already on
        /// this shift". Saying nothing would be a lie; saying "yes" would be
        /// worse, so the panel visibly stands down.
        case refusing
    }

    private(set) var dropState: DropState = .idle

    /// Replaces the red 2pt border every demo used to set by hand in
    /// `dragDidEnter`, and distinguishes a target that will accept from one
    /// that will not.
    func setDropState(_ state: DropState) {
        guard state != dropState else { return }
        dropState = state

        switch state {
        case .idle:
            applyBorder()
            backgroundColor = DemoTheme.Surface.card
            layer.shadowOpacity = 0.06
            layer.shadowRadius = 8
            contentView.alpha = 1

        case .accepting:
            layer.borderColor = DemoTheme.color(hue).cgColor
            layer.borderWidth = DemoTheme.highlightWidth
            backgroundColor = DemoTheme.tint(hue)
            // Lifted, so "this one will take it" reads even peripherally,
            // with the finger and the dragged view covering the middle.
            layer.shadowOpacity = 0.18
            layer.shadowRadius = 14
            contentView.alpha = 1

        case .refusing:
            applyBorder()
            backgroundColor = DemoTheme.Surface.card
            layer.shadowOpacity = 0.06
            layer.shadowRadius = 8
            contentView.alpha = 0.45
        }
    }

    private var borderWidthAtRest: CGFloat {
        isReceivingZone ? 1.5 : DemoTheme.hairlineWidth
    }

    private func applyBorder() {
        layer.borderWidth = borderWidthAtRest
        layer.borderColor = isReceivingZone
            ? DemoTheme.color(hue).withAlphaComponent(0.4).cgColor
            : DemoTheme.Surface.hairline.cgColor
    }

    /// Call after any drop or removal so the placeholder tracks reality.
    func updateEmptyState() {
        guard emptyMessage != nil else {
            emptyLabel.isHidden = true
            return
        }
        emptyLabel.isHidden = contentView.subviews.contains { $0 !== emptyLabel }
    }
}

/// A label with padding, for count badges and position pills.
final class PaddedLabel: UILabel {

    var insets: UIEdgeInsets = .zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right,
                      height: size.height + insets.top + insets.bottom)
    }
}
