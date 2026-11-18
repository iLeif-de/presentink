import Foundation

public struct ToolStyle: Codable, Equatable, Sendable, Identifiable {
    public var tool: InkTool
    public var color: InkColor
    public var width: Double
    public var minimum: Double
    public var maximum: Double
    public var quickWidths: [Double]
    public var opacity: Double
    public var id: InkTool { tool }
    public init(tool: InkTool) {
        self.tool = tool; color = .red
        width = tool == .text ? 28 : (tool == .marker ? 16 : 4)
        minimum = tool == .text ? 8 : (tool == .marker ? 4 : 2); maximum = tool == .text ? 96 : (tool == .marker ? 48 : 12)
        quickWidths = tool == .text ? [20,28,40] : (tool == .marker ? [8,16,48] : [2,4,12])
        opacity = tool == .marker ? 0.3 : 1
    }
    public var valid: Bool {
        color.valid && [width,minimum,maximum,opacity].allSatisfy(\.isFinite) &&
        minimum >= 0.5 && maximum <= 100 && minimum < maximum &&
        (minimum...maximum).contains(width) && (0.05...1).contains(opacity) &&
        quickWidths.count == 3 && quickWidths.allSatisfy { $0.isFinite && (minimum...maximum).contains($0) }
    }
}

public struct DrawingSettings: Codable, Equatable, Sendable {
    public var tool: InkTool = .pen
    public var palette = InkColor.palette
    public var visibleTools = InkTool.allCases
    public var styles = InkTool.allCases.map(ToolStyle.init)
    public var pressureEnabled = true
    public var pressureSensitivity = 1.0
    public init() {}
    private enum CodingKeys: String, CodingKey { case tool, palette, visibleTools, styles, pressureEnabled, pressureSensitivity }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        tool = try values.decode(InkTool.self,forKey:.tool)
        palette = try values.decode([InkColor].self,forKey:.palette)
        visibleTools = try values.decode([InkTool].self,forKey:.visibleTools)
        styles = try values.decode([ToolStyle].self,forKey:.styles)
        pressureEnabled = try values.decode(Bool.self,forKey:.pressureEnabled)
        pressureSensitivity = try values.decode(Double.self,forKey:.pressureSensitivity)
        // Migrate complete v0.7 configurations without losing custom styles or named profiles.
        let previousTools = Set(InkTool.allCases.filter { $0 != .text })
        if styles.count == previousTools.count && Set(styles.map(\.tool)) == previousTools {
            styles.append(ToolStyle(tool:.text))
            if !visibleTools.contains(.text) { visibleTools.append(.text) }
        }
    }
    public func style(for tool: InkTool) -> ToolStyle { styles.first { $0.tool == tool } ?? ToolStyle(tool: tool) }
    public var currentStyle: ToolStyle { style(for: tool) }
    public mutating func setStyle(_ style: ToolStyle) {
        if let i = styles.firstIndex(where: { $0.tool == style.tool }) { styles[i] = style }
    }
    public var valid: Bool {
        (1...8).contains(palette.count) && palette.allSatisfy(\.valid) &&
        !visibleTools.isEmpty && visibleTools.count <= InkTool.allCases.count && Set(visibleTools).count == visibleTools.count &&
        styles.count == InkTool.allCases.count && Set(styles.map(\.tool)) == Set(InkTool.allCases) && styles.allSatisfy(\.valid) &&
        pressureSensitivity.isFinite && (0...1).contains(pressureSensitivity)
    }
    public func authoritativeStroke(_ incoming: InkStroke, active: InkStroke?, display: DisplayInfo) -> InkStroke? {
        guard incoming.valid, let first = incoming.points.first else { return nil }
        var result: InkStroke
        if let active, active.id == incoming.id { result = active }
        else {
            guard incoming.tool == tool else { return nil }
            result = stroke(at: first, display: display); result.id = incoming.id
        }
        result.points = incoming.points
        result.text = incoming.text
        return result
    }
    public func textStroke(_ text: String, at point: InkPoint, display: DisplayInfo) throws -> InkStroke {
        guard point.valid, InkTextLayout.valid(text) else { throw AutomationFailure.invalid(inkLocalized("Text: 1–2000 Zeichen, maximal 20 Zeilen. Position muss innerhalb des Displays liegen.")) }
        var settings = self; settings.tool = .text
        var stroke = settings.stroke(at:point,display:display); stroke.text = text
        return stroke
    }
    public func stroke(at point: InkPoint, display: DisplayInfo) -> InkStroke {
        let style = currentStyle, edge = max(1, min(display.width, display.height))
        return InkStroke(tool: tool, color: style.color, width: style.width/edge, points: [point],
                         opacity: style.opacity, pressureSensitivity: pressureEnabled ? pressureSensitivity : 0,
                         minimumWidth: style.minimum/edge, maximumWidth: style.maximum/edge)
    }
}

/// Absolute, ordered requests. The Mac validates each request and returns its authoritative state.
public struct DrawingSelection: Codable, Sendable {
    public var tool: InkTool?
    public var color: InkColor?
    public var width: Double?
    public var profile: String?
    public init(tool: InkTool? = nil, color: InkColor? = nil, width: Double? = nil, profile: String? = nil) {
        self.tool = tool; self.color = color; self.width = width; self.profile = profile
    }
    public func applying(to original: DrawingSettings) throws -> DrawingSettings {
        var settings = original
        if let tool { settings.tool = tool }
        var style = settings.currentStyle
        if let color { style.color = color }
        if let width { style.width = width }
        settings.setStyle(style)
        guard settings.valid else { throw AutomationFailure.invalid(inkLocalized("Einstellung ungültig. Breite muss im Werkzeugbereich %@–%@ pt liegen.", String(describing: (style.minimum)), String(describing: (style.maximum)))) }
        return settings
    }
}
public struct DrawingProfile: Codable, Equatable, Sendable, Identifiable {
    public var name: String
    public var settings: DrawingSettings
    public var id: String { name }
    public init(name: String, settings: DrawingSettings) { self.name = name; self.settings = settings }
    public var valid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count <= 40 && settings.valid }
}
public struct DrawingLibrary: Codable, Equatable, Sendable {
    public var current = DrawingSettings()
    public var profiles: [DrawingProfile] = []
    public var activeProfile: String?
    public init() {
        var dark = DrawingSettings()
        for index in dark.styles.indices { dark.styles[index].color = dark.styles[index].tool == .marker ? InkColor.palette[1] : InkColor.palette[4] }
        var whiteboard = DrawingSettings()
        for index in whiteboard.styles.indices { whiteboard.styles[index].color = InkColor.palette[5] }
        profiles = [DrawingProfile(name:"Helle Folien",settings:current), DrawingProfile(name:"Dunkle Folien",settings:dark), DrawingProfile(name:"Whiteboard",settings:whiteboard)]
        activeProfile = "Helle Folien"
    }
    public var valid: Bool { current.valid && profiles.count <= 12 && profiles.allSatisfy(\.valid) && Set(profiles.map(\.name)).count == profiles.count && (activeProfile == nil || profiles.contains { $0.name == activeProfile }) }
}
public struct DrawingSyncState: Codable, Sendable {
    public var revision: UInt64
    public var settings: DrawingSettings
    public var profiles: [String]
    public var activeProfile: String?
    public init(revision: UInt64, library: DrawingLibrary) {
        self.revision = revision; settings = library.current; profiles = library.profiles.map(\.name); activeProfile = library.activeProfile
    }
    public var valid: Bool { settings.valid && profiles.count <= 12 && profiles.allSatisfy { !$0.isEmpty && $0.count <= 40 } && Set(profiles).count == profiles.count && (activeProfile == nil || profiles.contains(activeProfile!)) }
}

/// Trust applies to the existing pairing, never to discovery alone. Pausing wins over auto-start.
public struct PreviewPolicy: Codable, Equatable, Sendable {
    public var trusted = false
    public var autoStart = false
    public init() {}
    public func mayStart(connected: Bool, requested: Bool, manuallyPaused: Bool) -> Bool {
        connected && trusted && (requested || (autoStart && !manuallyPaused))
    }
}
