import UIKit

/// The vocabulary every demo screen draws from. No view logic lives here --
/// this file answers "what colour, what size, what font", and nothing else.
///
/// Every colour is exposed as a computed property rather than a stored one.
/// `UIColor` is not `Sendable`, so a `static let` holding one is rejected under
/// the Swift 6 language mode this package builds in.
public enum DemoTheme {

    // MARK: - Hues

    /// The accent ramp. Eight hues is enough that a rota of a dozen people
    /// rarely repeats a colour adjacently, and few enough that the app still
    /// looks like one product.
    public enum Hue: String, CaseIterable, Sendable {
        case indigo, teal, coral, amber, mint, violet, rose, slate

        var light: UIColor {
            switch self {
            case .indigo: UIColor(red: 0.35, green: 0.37, blue: 0.84, alpha: 1)
            case .teal:   UIColor(red: 0.06, green: 0.51, blue: 0.55, alpha: 1)
            case .coral:  UIColor(red: 0.89, green: 0.38, blue: 0.29, alpha: 1)
            case .amber:  UIColor(red: 0.80, green: 0.55, blue: 0.08, alpha: 1)
            case .mint:   UIColor(red: 0.15, green: 0.58, blue: 0.38, alpha: 1)
            case .violet: UIColor(red: 0.55, green: 0.32, blue: 0.80, alpha: 1)
            case .rose:   UIColor(red: 0.82, green: 0.26, blue: 0.45, alpha: 1)
            case .slate:  UIColor(red: 0.35, green: 0.41, blue: 0.49, alpha: 1)
            }
        }

        var dark: UIColor {
            switch self {
            case .indigo: UIColor(red: 0.55, green: 0.57, blue: 0.97, alpha: 1)
            case .teal:   UIColor(red: 0.29, green: 0.75, blue: 0.78, alpha: 1)
            case .coral:  UIColor(red: 1.00, green: 0.55, blue: 0.45, alpha: 1)
            case .amber:  UIColor(red: 0.97, green: 0.74, blue: 0.28, alpha: 1)
            case .mint:   UIColor(red: 0.35, green: 0.81, blue: 0.58, alpha: 1)
            case .violet: UIColor(red: 0.72, green: 0.53, blue: 0.95, alpha: 1)
            case .rose:   UIColor(red: 0.97, green: 0.47, blue: 0.64, alpha: 1)
            case .slate:  UIColor(red: 0.58, green: 0.64, blue: 0.72, alpha: 1)
            }
        }
    }

    /// The solid form of a hue: avatar fills, badges, pills, highlight borders.
    public static func color(_ hue: Hue) -> UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? hue.dark : hue.light }
    }

    /// The same hue as a background wash. Carried at a higher alpha in dark
    /// mode, where a 14% wash over a dark surface is invisible.
    public static func tint(_ hue: Hue) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? hue.dark.withAlphaComponent(0.24)
                : hue.light.withAlphaComponent(0.14)
        }
    }

    /// A hue chosen from a seed string. The same name always gets the same
    /// colour, across launches and across screens.
    public static func hue(for seed: String) -> Hue {
        let all = Hue.allCases
        return all[Int(stableHash(seed) % UInt64(all.count))]
    }

    /// FNV-1a. `String.hashValue` is seeded per process and would give a
    /// person a different colour on every launch.
    public static func stableHash(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }

    /// The same idea for content indexed by a number rather than named, and
    /// the reason it is not just `stableHash("\(index)")`.
    ///
    /// FNV-1a ends on a multiply, so two seeds differing only in their last
    /// byte come out a fixed distance apart -- and taking that modulo a small
    /// number turns a run of consecutive indices into a run of evenly spaced
    /// results. The moodboard's card heights were seeded that way and came out
    /// one pixel apart, which is a fixed-height grid with extra steps.
    ///
    /// This is splitmix64's finaliser, which avalanches: neighbouring indices
    /// share nothing.
    public static func stableMix(_ index: Int) -> UInt64 {
        var z = UInt64(bitPattern: Int64(index)) &+ 0x9E3779B97F4A7C15
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    // MARK: - Surfaces

    public enum Surface {
        /// What a screen sits on.
        public static var background: UIColor { .systemGroupedBackground }
        /// A card on that background.
        public static var card: UIColor { .secondarySystemGroupedBackground }
        /// A card on a card.
        public static var raised: UIColor { .tertiarySystemGroupedBackground }
        public static var hairline: UIColor { .separator }

        /// The landing area inside a card that receives drops. A recess rather
        /// than another surface: nesting then reads as depth, which is what
        /// tells a target inside a target apart from a target inside scenery.
        public static var well: UIColor {
            UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(white: 1, alpha: 0.06)
                    : UIColor(white: 0, alpha: 0.045)
            }
        }

        /// The hairline around a well. Carries the recess where the fill alone
        /// is too faint, notably over the Widget Composer wallpaper.
        public static var wellEdge: UIColor {
            UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(white: 1, alpha: 0.10)
                    : UIColor(white: 0, alpha: 0.07)
            }
        }
    }

    public enum Text {
        public static var primary: UIColor { .label }
        public static var secondary: UIColor { .secondaryLabel }
        public static var tertiary: UIColor { .tertiaryLabel }
        /// Text that sits on a solid hue.
        public static var onAccent: UIColor { .white }
    }

    // MARK: - Metrics

    public enum Radius {
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 12
        public static let large: CGFloat = 16
        /// Slightly tighter than the card that holds it, so the recess looks
        /// cut into the card rather than stuck on top of it.
        public static let well: CGFloat = 10
    }

    public enum Space {
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 8
        public static let m: CGFloat = 12
        public static let l: CGFloat = 16
    }

    /// Half a point. Thinner than this disappears on a 2x screen.
    public static let hairlineWidth: CGFloat = 0.5
    public static let highlightWidth: CGFloat = 2.0

    // MARK: - Type

    public enum Font {
        public static var title: UIFont { .systemFont(ofSize: 17, weight: .semibold) }
        public static var headline: UIFont { .systemFont(ofSize: 15, weight: .semibold) }
        public static var body: UIFont { .systemFont(ofSize: 14, weight: .regular) }
        public static var caption: UIFont { .systemFont(ofSize: 12, weight: .regular) }

        /// Counts and durations. Rounded so they read as part of the chrome,
        /// monospaced so a badge does not twitch as it counts.
        public static func number(_ size: CGFloat, weight: UIFont.Weight = .semibold) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            let descriptor = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
            return UIFont(descriptor: descriptor, size: size).monospacedDigits
        }
    }
}

private extension UIFont {
    var monospacedDigits: UIFont {
        let settings = [[UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                         UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector]]
        return UIFont(descriptor: fontDescriptor.addingAttributes([.featureSettings: settings]),
                      size: 0)
    }
}
