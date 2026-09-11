import UIKit

public extension UIColor {

    /// Parses `#RRGGBB` (the leading hash optional).
    ///
    /// The moodboard's cards name a colour and print its hex, so the card has
    /// to actually be that colour -- a gradient picked from a hash of the name
    /// would make the label a lie.
    convenience init?(hex: String) {
        var value = hex
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6, let rgb = UInt32(value, radix: 16) else { return nil }

        self.init(red: CGFloat((rgb >> 16) & 0xFF) / 255,
                  green: CGFloat((rgb >> 8) & 0xFF) / 255,
                  blue: CGFloat(rgb & 0xFF) / 255,
                  alpha: 1)
    }

    /// A second stop for a two-stop gradient: the same colour carried darker
    /// and a little further round the wheel, so a swatch reads as one material
    /// lit unevenly rather than as two colours meeting.
    var gradientPartner: UIColor {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        guard getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return self
        }
        return UIColor(hue: (hue + 0.05).truncatingRemainder(dividingBy: 1),
                       saturation: min(1, saturation * 1.15),
                       brightness: max(0, brightness * 0.68),
                       alpha: alpha)
    }
}
