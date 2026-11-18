import Foundation

/// Validation is shared by AppleScript and Shortcuts; neither entry point silently clamps invalid input.
public enum AutomationValues {
    public static func tool(_ value: String) throws -> InkTool {
        let value = normalized(value)
        let aliases: [String: InkTool] = ["pen": .pen, "stift": .pen, "marker": .marker, "highlighter": .marker, "textmarker": .marker,
            "line": .line, "linie": .line, "arrow": .arrow, "pfeil": .arrow, "rectangle": .rectangle, "rechteck": .rectangle,
            "ellipse": .ellipse, "oval": .ellipse, "text": .text, "beschriftung": .text, "eraser": .eraser, "radierer": .eraser]
        guard let tool = aliases[value] else { throw AutomationFailure.invalid(inkLocalized("Unbekanntes Werkzeug: %@.", String(describing: (value)))) }
        return tool
    }
    public static func color(_ value: String) throws -> InkColor {
        let value = normalized(value)
        let names = ["red": 0, "rot": 0, "yellow": 1, "gelb": 1, "blue": 2, "blau": 2, "green": 3, "grün": 3,
                     "white": 4, "weiß": 4, "weiss": 4, "black": 5, "schwarz": 5, "graphite": 5, "graphit": 5]
        if let index = names[value] { return InkColor.palette[index] }
        guard value.hasPrefix("#"), value.count == 7, let rgb = UInt32(value.dropFirst(), radix: 16) else {
            throw AutomationFailure.invalid(inkLocalized("Farbe als Name oder #RRGGBB angeben, z. B. rot oder #FF5533."))
        }
        let parsed = InkColor(Double((rgb >> 16) & 255)/255, Double((rgb >> 8) & 255)/255, Double(rgb & 255)/255)
        // Preserve native preset identity when a script reads a hex color and writes it back.
        return InkColor.palette.first { hex($0).lowercased() == value } ?? parsed
    }
    public static func hex(_ color: InkColor) -> String {
        String(format: "#%02X%02X%02X", Int((color.r*255).rounded()), Int((color.g*255).rounded()), Int((color.b*255).rounded()))
    }
    public static func width(_ value: Double) throws -> Double {
        guard value.isFinite, (2...12).contains(value) else { throw AutomationFailure.invalid(inkLocalized("Strichstärke muss zwischen 2 und 12 liegen.")) }
        return value
    }
    public static func drawer(_ value: String) throws -> String {
        switch normalized(value) {
        case "expanded", "full", "ausgezogen": return "expanded"
        case "compact", "kompakt": return "compact"
        case "hidden", "versteckt": return "hidden"
        case "invisible", "unsichtbar", "vollständig ausgeblendet": return "invisible"
        default: throw AutomationFailure.invalid(inkLocalized("Drawer-Zustand: expanded, compact, hidden (Griff) oder invisible (vollständig aus)."))
        }
    }
    private static func normalized(_ value: String) -> String { value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
}
public enum AutomationFailure: LocalizedError {
    case invalid(String), unavailable(String), confirmationRequired(String), notReady
    public var errorDescription: String? {
        switch self {
        case .invalid(let message), .unavailable(let message), .confirmationRequired(let message): message
        case .notReady: inkLocalized("PresentInk ist noch nicht bereit. App starten und den Befehl erneut ausführen.")
        }
    }
    public var scriptError: Int {
        switch self { case .invalid: -1700; case .unavailable: -2700; case .confirmationRequired: -128; case .notReady: -1712 }
    }
}
