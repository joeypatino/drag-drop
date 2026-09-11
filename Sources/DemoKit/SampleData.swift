import Foundation

// MARK: - Types

public struct StaffMember: Sendable, Equatable {
    public let id: Int
    public let name: String
    public let role: String

    public init(id: Int, name: String, role: String) {
        self.id = id
        self.name = name
        self.role = role
    }

    /// First letter of the first and last word. A one-word name gives one
    /// letter; an empty name gives a placeholder rather than an empty circle.
    public var initials: String {
        let words = name.split(separator: " ")
        guard let first = words.first?.first else { return "?" }
        guard words.count > 1, let last = words.last?.first else { return String(first) }
        return "\(first)\(last)"
    }
}

public struct Photo: Sendable, Equatable {
    public let id: Int
    public let caption: String
    /// Seeds the gradient. Held separately from the caption so renaming a
    /// photo does not recolour it.
    public let seed: String

    public init(id: Int, caption: String, seed: String) {
        self.id = id
        self.caption = caption
        self.seed = seed
    }
}

public struct Widget: Sendable, Equatable {
    public let id: Int
    public let name: String
    public let symbol: String

    public init(id: Int, name: String, symbol: String) {
        self.id = id
        self.name = name
        self.symbol = symbol
    }
}

public struct FileItem: Sendable, Equatable {
    public enum Kind: String, Sendable, CaseIterable {
        case pdf, image, archive, sheet, text
    }

    public let id: Int
    public let name: String
    public let symbol: String
    public let kind: Kind

    public init(id: Int, name: String, symbol: String, kind: Kind) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.kind = kind
    }
}

public struct Track: Sendable, Equatable {
    public let id: Int
    public let title: String
    public let artist: String
    public let duration: String
    public let seed: String

    public init(id: Int, title: String, artist: String, duration: String, seed: String) {
        self.id = id
        self.title = title
        self.artist = artist
        self.duration = duration
        self.seed = seed
    }
}

public struct Palette: Sendable, Equatable {
    public let id: Int
    public let name: String
    public let hex: String

    public init(id: Int, name: String, hex: String) {
        self.id = id
        self.name = name
        self.hex = hex
    }
}

public struct Player: Sendable, Equatable {
    public enum Position: String, Sendable, CaseIterable {
        case goalkeeper, defender, midfielder, forward

        public var abbreviation: String {
            switch self {
            case .goalkeeper: "GK"
            case .defender: "DF"
            case .midfielder: "MF"
            case .forward: "FW"
            }
        }
    }

    public let id: Int
    public let number: Int
    public let name: String
    public let position: Position

    public init(id: Int, number: Int, name: String, position: Position) {
        self.id = id
        self.number = number
        self.name = name
        self.position = position
    }
}

// MARK: - Content

/// Fixture content for the demo screens. Deterministic on purpose: a colour
/// derived from a name must survive a relaunch, and a screenshot taken today
/// must match one taken tomorrow.
public enum SampleData {

    /// Shift Rota. Eighteen, which is 5 + 4 + 3 + 6.
    public static let staff: [StaffMember] = [
        StaffMember(id: 1,  name: "Nadia Okafor",  role: "Barista"),
        StaffMember(id: 2,  name: "Marco Bellini", role: "Kitchen"),
        StaffMember(id: 3,  name: "Priya Raman",   role: "Floor"),
        StaffMember(id: 4,  name: "Tom Hale",      role: "Bar"),
        StaffMember(id: 5,  name: "Amara Diallo",  role: "Barista"),
        StaffMember(id: 6,  name: "Ines Vargas",   role: "Floor"),
        StaffMember(id: 7,  name: "Jonas Lind",    role: "Kitchen"),
        StaffMember(id: 8,  name: "Mei Chen",      role: "Bar"),
        StaffMember(id: 9,  name: "Rafael Souza",  role: "Floor"),
        StaffMember(id: 10, name: "Hanna Bauer",   role: "Barista"),
        StaffMember(id: 11, name: "Omar Haddad",   role: "Kitchen"),
        StaffMember(id: 12, name: "Lucy Grant",    role: "Floor"),
        StaffMember(id: 13, name: "Kwame Mensah",  role: "Bar"),
        StaffMember(id: 14, name: "Sofia Rossi",   role: "Barista"),
        StaffMember(id: 15, name: "Dev Patel",     role: "Kitchen"),
        StaffMember(id: 16, name: "Elin Nyberg",   role: "Floor"),
        StaffMember(id: 17, name: "Yusuf Demir",   role: "Bar"),
        StaffMember(id: 18, name: "Clara Moreau",  role: "Barista")
    ]

    /// Shared Album. Eight, which is 5 in the roll and 3 in the album.
    public static let photos: [Photo] = [
        Photo(id: 1, caption: "Glacier Lagoon",  seed: "glacier"),
        Photo(id: 2, caption: "Black Sand",      seed: "blacksand"),
        Photo(id: 3, caption: "Kirkjufell",      seed: "kirkjufell"),
        Photo(id: 4, caption: "Blue Hour",       seed: "bluehour"),
        Photo(id: 5, caption: "Puffin Cliff",    seed: "puffin"),
        Photo(id: 6, caption: "Northern Lights", seed: "aurora"),
        Photo(id: 7, caption: "Moss Field",      seed: "moss"),
        Photo(id: 8, caption: "Harbour Boats",   seed: "harbour")
    ]

    /// Widget Composer. Eight, which is 3 in the stack and 5 in the gallery.
    public static let widgets: [Widget] = [
        Widget(id: 1, name: "Calendar",    symbol: "calendar"),
        Widget(id: 2, name: "Weather",     symbol: "cloud.sun.fill"),
        Widget(id: 3, name: "Now Playing", symbol: "music.note"),
        Widget(id: 4, name: "Activity",    symbol: "figure.walk"),
        Widget(id: 5, name: "Battery",     symbol: "bolt.fill"),
        Widget(id: 6, name: "Stocks",      symbol: "chart.line.uptrend.xyaxis"),
        Widget(id: 7, name: "Clock",       symbol: "clock.fill"),
        Widget(id: 8, name: "Reminders",   symbol: "checklist")
    ]

    /// Files. Eight, which is 5 in Downloads and 3 in Documents.
    public static let files: [FileItem] = [
        FileItem(id: 1, name: "Q3 Report",  symbol: "doc.richtext",  kind: .pdf),
        FileItem(id: 2, name: "Moodboard",  symbol: "photo",         kind: .image),
        FileItem(id: 3, name: "Invoices",   symbol: "doc.zipper",    kind: .archive),
        FileItem(id: 4, name: "Budget",     symbol: "tablecells",    kind: .sheet),
        FileItem(id: 5, name: "Contract",   symbol: "doc.richtext",  kind: .pdf),
        FileItem(id: 6, name: "Notes",      symbol: "doc.plaintext", kind: .text),
        FileItem(id: 7, name: "Logo",       symbol: "photo",         kind: .image),
        FileItem(id: 8, name: "Archive",    symbol: "doc.zipper",    kind: .archive)
    ]

    /// Up Next. Ten start in the queue; the rest are what a row dropped onto
    /// the table becomes, so an inserted row is a real song rather than a
    /// running integer.
    public static let tracks: [Track] = [
        Track(id: 1,  title: "Fever Dream",       artist: "Lila Sound",    duration: "3:42", seed: "fever"),
        Track(id: 2,  title: "Paper Lanterns",    artist: "Kestrel",       duration: "4:05", seed: "lanterns"),
        Track(id: 3,  title: "Slow Tide",         artist: "Moss & Vine",   duration: "3:18", seed: "tide"),
        Track(id: 4,  title: "Neon Quiet",        artist: "Aster Bloom",   duration: "5:01", seed: "neon"),
        Track(id: 5,  title: "Halfway House",     artist: "The Gallery",   duration: "3:55", seed: "halfway"),
        Track(id: 6,  title: "Cold Open",         artist: "Vantage",       duration: "2:47", seed: "coldopen"),
        Track(id: 7,  title: "Long Way Round",    artist: "Marla Fields",  duration: "4:22", seed: "longway"),
        Track(id: 8,  title: "Static Bloom",      artist: "Nine Rivers",   duration: "3:09", seed: "static"),
        Track(id: 9,  title: "Everything Softer", artist: "Hale",          duration: "4:48", seed: "softer"),
        Track(id: 10, title: "Low Sun",           artist: "Corvid",        duration: "3:31", seed: "lowsun"),
        Track(id: 11, title: "Iron Lung",         artist: "Pale Motion",   duration: "3:58", seed: "iron"),
        Track(id: 12, title: "Driftwood",         artist: "Ora",           duration: "4:12", seed: "driftwood"),
        Track(id: 13, title: "Small Hours",       artist: "Beacon Street", duration: "3:26", seed: "smallhours"),
        Track(id: 14, title: "Last Ferry",        artist: "Vela",          duration: "5:14", seed: "ferry"),
        Track(id: 15, title: "Glasshouse",        artist: "Tern",          duration: "3:47", seed: "glasshouse"),
        Track(id: 16, title: "After Rain",        artist: "Solen",         duration: "4:33", seed: "afterrain")
    ]

    /// Moodboard. Twelve, cycled across the 300 cards.
    public static let palettes: [Palette] = [
        Palette(id: 1,  name: "Dusk Coral",  hex: "#E86A4A"),
        Palette(id: 2,  name: "Sea Glass",   hex: "#7FC8B8"),
        Palette(id: 3,  name: "Ink Blue",    hex: "#22345C"),
        Palette(id: 4,  name: "Warm Sand",   hex: "#E3C9A0"),
        Palette(id: 5,  name: "Moss",        hex: "#4F7A52"),
        Palette(id: 6,  name: "Plum Smoke",  hex: "#6B4A7A"),
        Palette(id: 7,  name: "Clay",        hex: "#B5633F"),
        Palette(id: 8,  name: "Slate Mist",  hex: "#8C97A3"),
        Palette(id: 9,  name: "Saffron",     hex: "#E0A02E"),
        Palette(id: 10, name: "Fern",        hex: "#3F8A63"),
        Palette(id: 11, name: "Blush",       hex: "#E7A5B0"),
        Palette(id: 12, name: "Deep Teal",   hex: "#10535B")
    ]

    /// Lineup. The first eight start, the last eight are on the bench, and
    /// there is a keeper on each side so a swap is always legal.
    public static let players: [Player] = [
        Player(id: 1,  number: 1,  name: "Ana Kovač",   position: .goalkeeper),
        Player(id: 2,  number: 4,  name: "Leah Osei",   position: .defender),
        Player(id: 3,  number: 5,  name: "Ida Berg",    position: .defender),
        Player(id: 4,  number: 6,  name: "Rosa Marín",  position: .midfielder),
        Player(id: 5,  number: 8,  name: "Nia Clarke",  position: .midfielder),
        Player(id: 6,  number: 9,  name: "Sara Lund",   position: .forward),
        Player(id: 7,  number: 11, name: "Tess Moreau", position: .forward),
        Player(id: 8,  number: 3,  name: "Zoe Haddad",  position: .defender),
        Player(id: 9,  number: 12, name: "Mira Falk",   position: .goalkeeper),
        Player(id: 10, number: 2,  name: "June Park",   position: .defender),
        Player(id: 11, number: 7,  name: "Ava Nilsen",  position: .midfielder),
        Player(id: 12, number: 10, name: "Kaya Roth",   position: .midfielder),
        Player(id: 13, number: 14, name: "Lena Duarte", position: .forward),
        Player(id: 14, number: 16, name: "Fay Okonkwo", position: .defender),
        Player(id: 15, number: 17, name: "Iris Bauer",  position: .midfielder),
        Player(id: 16, number: 19, name: "Noor Aziz",   position: .forward)
    ]
}
