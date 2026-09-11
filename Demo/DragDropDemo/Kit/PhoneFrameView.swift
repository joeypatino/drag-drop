//
//  PhoneFrameView.swift
//  DragDropDemo
//

import UIKit
import DemoKit

/// A mock home screen: rounded frame, a wallpaper gradient, a status bar row.
/// Purely decorative -- it is never a drop target. The widget stack that sits
/// inside it is.
final class PhoneFrameView: UIView {

    private let wallpaper = CAGradientLayer()
    private let timeLabel = UILabel()
    private let indicators = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.cornerRadius = 28
        layer.cornerCurve = .continuous
        layer.masksToBounds = true

        wallpaper.colors = [DemoTheme.color(.indigo).cgColor, DemoTheme.color(.violet).cgColor]
        wallpaper.startPoint = CGPoint(x: 0, y: 0)
        wallpaper.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(wallpaper)

        timeLabel.text = "9:41"
        timeLabel.font = DemoTheme.Font.number(13, weight: .semibold)
        timeLabel.textColor = .white
        addSubview(timeLabel)

        indicators.text = "5G  100%"
        indicators.font = DemoTheme.Font.number(11, weight: .medium)
        indicators.textColor = UIColor.white.withAlphaComponent(0.9)
        indicators.textAlignment = .right
        addSubview(indicators)

        isAccessibilityElement = false
        accessibilityIdentifier = "phone-frame"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Latent rather than observed: this frame is built once and never
        // resized, so the sublayer can never be caught mid-animation. Kept in
        // step with `SwatchChip` all the same, because the pattern is the trap
        // -- a sublayer does not inherit a UIView animation, and suppressing
        // its implicit one unconditionally means the visible content snaps
        // while the bounds animate.
        let inherited = UIView.inheritedAnimationDuration
        CATransaction.begin()
        CATransaction.setDisableActions(inherited == 0)
        if inherited > 0 {
            CATransaction.setAnimationDuration(inherited)
        }
        wallpaper.frame = bounds
        CATransaction.commit()

        timeLabel.frame = CGRect(x: 20, y: 12, width: 60, height: 18)
        indicators.frame = CGRect(x: bounds.width - 80, y: 12, width: 60, height: 18)
    }
}
