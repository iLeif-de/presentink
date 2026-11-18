import AppIntents
import PresentInkCore

struct PresentInkStatusEntity: TransientAppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "PresentInk-Status"
    @Property(title:"Zeichenmodus aktiv") var drawingEnabled: Bool
    @Property(title:"Annotationen sichtbar") var annotationsVisible: Bool
    @Property(title:"Drawer-Zustand") var drawer: PresentInkDrawerChoice
    @Property(title:"Mac-Drawer sichtbar") var drawerVisible: Bool
    @Property(title:"Werkzeug") var tool: PresentInkToolChoice
    @Property(title:"Farbe (Hex)") var color: String
    @Property(title:"Strichstärke / Schriftgröße") var width: Double
    @Property(title:"Deckkraft in Prozent") var opacity: Double
    @Property(title:"Minimale Breite") var minimumWidth: Double
    @Property(title:"Maximale Breite") var maximumWidth: Double
    @Property(title:"Aktives Profil") var profile: String
    @Property(title:"Displaynummer") var displayIndex: Int
    @Property(title:"Displayname") var displayName: String
    @Property(title:"iPad-Verbindung eingeschaltet") var connectionEnabled: Bool
    @Property(title:"iPad verbunden") var ipadConnected: Bool
    @Property(title:"Vorschau eingeschaltet") var previewEnabled: Bool
    @Property(title:"Vorschauzustand") var previewState: String
    @Property(title:"Vorschauhinweis") var previewDetail: String
    @Property(title:"Freigabe gemerkt") var previewTrusted: Bool
    @Property(title:"Vorschau-Autostart") var previewAutoStart: Bool
    @Property(title:"Anzahl Annotationen") var strokeCount: Int
    @Property(title:"Rückgängig möglich") var canUndo: Bool
    @Property(title:"Wiederholen möglich") var canRedo: Bool
    @Property(title:"Strich wird gezeichnet") var strokeInProgress: Bool
    @Property(title:"Einstellungen am iPad bestätigt") var settingsSynced: Bool
    @Property(title:"Letzter App-Hinweis") var lastError: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title:"PresentInk-Status",subtitle:"\(displayName)") }
    init() {
        drawingEnabled = false
        annotationsVisible = false
        drawer = .expanded
        drawerVisible = false
        tool = .pen
        color = ""
        width = 0
        opacity = 0
        minimumWidth = 0
        maximumWidth = 0
        profile = ""
        displayIndex = 0
        displayName = ""
        connectionEnabled = false
        ipadConnected = false
        previewEnabled = false
        previewState = ""
        previewDetail = ""
        previewTrusted = false
        previewAutoStart = false
        strokeCount = 0
        canUndo = false
        canRedo = false
        strokeInProgress = false
        settingsSynced = false
        lastError = ""
    }
    init(_ value: AutomationStatus) {
        self.init()
        drawingEnabled = value.drawingEnabled
        annotationsVisible = value.annotationsVisible
        drawer = PresentInkDrawerChoice(rawValue:value.drawerState) ?? .expanded
        drawerVisible = value.macDrawerVisible
        tool = PresentInkToolChoice(rawValue:value.tool.rawValue) ?? .pen
        color = value.color
        width = value.strokeWidth
        opacity = value.opacity*100
        minimumWidth = value.widthMinimum
        maximumWidth = value.widthMaximum
        profile = value.activeProfile ?? inkLocalized("Individuell")
        displayIndex = value.displayIndex
        displayName = value.displayName
        connectionEnabled = value.connectionEnabled
        ipadConnected = value.ipadConnected
        previewEnabled = value.previewEnabled
        previewState = value.previewState
        previewDetail = value.previewDetail
        previewTrusted = value.previewTrusted
        previewAutoStart = value.previewAutoStart
        strokeCount = value.strokeCount
        canUndo = value.canUndo
        canRedo = value.canRedo
        strokeInProgress = value.strokeInProgress
        settingsSynced = value.drawingSettingsSynced
        lastError = value.lastError ?? ""
    }
}

struct PresentInkDisplayEntity: TransientAppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "PresentInk-Display"
    @Property(title:"Displaynummer") var index: Int
    @Property(title:"Display-ID") var nativeID: Int
    @Property(title:"Name") var name: String
    @Property(title:"Breite") var width: Double
    @Property(title:"Höhe") var height: Double
    @Property(title:"Ausgewählt") var selected: Bool
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title:"\(name)",subtitle:"Display \(index)") }
    init() { index = 0; nativeID = 0; name = ""; width = 0; height = 0; selected = false }
    init(_ value: AutomationDisplay) {
        self.init(); index = value.index; nativeID = Int(value.id); name = value.name; width = value.width; height = value.height; selected = value.selected
    }
}

struct PresentInkColorEntity: TransientAppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "PresentInk-Farbe"
    @Property(title:"Rot (0–1)") var red: Double
    @Property(title:"Grün (0–1)") var green: Double
    @Property(title:"Blau (0–1)") var blue: Double
    @Property(title:"Hex-Farbe") var hex: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title:"\(hex)") }
    init() { red = 1; green = 0.22; blue = 0.28; hex = "#FF3847" }
    init(_ color: InkColor) {
        self.init(); red = color.r; green = color.g; blue = color.b; hex = AutomationValues.hex(color)
    }
    func color() throws -> InkColor {
        let color = InkColor(red,green,blue)
        guard color.valid else { throw AutomationFailure.invalid("Ungültige RGB-Farbe.") }
        return color
    }
}

struct PresentInkStyleEntity: TransientAppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "PresentInk-Werkzeugstil"
    @Property(title:"Werkzeug") var tool: PresentInkToolChoice
    @Property(title:"Farbe") var color: PresentInkColorEntity
    @Property(title:"Strichstärke / Schriftgröße") var width: Double
    @Property(title:"Minimale Breite") var minimum: Double
    @Property(title:"Maximale Breite") var maximum: Double
    @Property(title:"Schnellstärken") var quickWidths: [Double]
    @Property(title:"Deckkraft in Prozent") var opacity: Double
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title:"\(InkTool(rawValue:tool.rawValue)?.title ?? tool.rawValue)") }
    init() { tool = .pen; color = PresentInkColorEntity(); width = 4; minimum = 2; maximum = 12; quickWidths = [2,4,12]; opacity = 100 }
    init(_ style: ToolStyle) {
        self.init(); tool = PresentInkToolChoice(rawValue:style.tool.rawValue) ?? .pen
        color = PresentInkColorEntity(style.color); width = style.width; minimum = style.minimum; maximum = style.maximum
        quickWidths = style.quickWidths; opacity = style.opacity*100
    }
    func style() throws -> ToolStyle {
        var value = ToolStyle(tool:InkTool(rawValue:tool.rawValue)!)
        value.color = try color.color(); value.width = width; value.minimum = minimum; value.maximum = maximum
        value.quickWidths = quickWidths; value.opacity = opacity/100
        guard value.valid else { throw AutomationFailure.invalid("Ungültiger Werkzeugstil.") }
        return value
    }
}

struct PresentInkSettingsEntity: TransientAppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "PresentInk-Zeichen-Einstellungen"
    @Property(title:"Werkzeug") var tool: PresentInkToolChoice
    @Property(title:"Farbpalette") var palette: [PresentInkColorEntity]
    @Property(title:"Sichtbare Werkzeuge") var visibleTools: [PresentInkToolChoice]
    @Property(title:"Werkzeugstile") var styles: [PresentInkStyleEntity]
    @Property(title:"Pencil-Druck eingeschaltet") var pressureEnabled: Bool
    @Property(title:"Pencil-Druckwirkung in Prozent") var pressureSensitivity: Double
    @Property(title:"Verfügbare Profile") var profiles: [String]
    @Property(title:"Aktives Profil") var profile: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title:"Zeichen-Einstellungen",subtitle:"\(profile)") }
    init() {
        let library = DrawingLibrary()
        tool = .pen; palette = library.current.palette.map(PresentInkColorEntity.init)
        visibleTools = library.current.visibleTools.compactMap { PresentInkToolChoice(rawValue:$0.rawValue) }
        styles = library.current.styles.map(PresentInkStyleEntity.init)
        pressureEnabled = true; pressureSensitivity = 100; profiles = library.profiles.map(\.name); profile = library.activeProfile ?? inkLocalized("Individuell")
    }
    init(_ library: DrawingLibrary) {
        self.init(); tool = PresentInkToolChoice(rawValue:library.current.tool.rawValue) ?? .pen
        palette = library.current.palette.map(PresentInkColorEntity.init)
        visibleTools = library.current.visibleTools.compactMap { PresentInkToolChoice(rawValue:$0.rawValue) }
        styles = library.current.styles.map(PresentInkStyleEntity.init)
        pressureEnabled = library.current.pressureEnabled; pressureSensitivity = library.current.pressureSensitivity*100
        profiles = library.profiles.map(\.name); profile = library.activeProfile ?? inkLocalized("Individuell")
    }
    func settings() throws -> DrawingSettings {
        var value = DrawingSettings(); value.tool = InkTool(rawValue:tool.rawValue)!
        value.palette = try palette.map { try $0.color() }
        value.visibleTools = visibleTools.compactMap { InkTool(rawValue:$0.rawValue) }
        value.styles = try styles.map { try $0.style() }
        value.pressureEnabled = pressureEnabled; value.pressureSensitivity = pressureSensitivity/100
        guard value.valid else { throw AutomationFailure.invalid("Ungültige Zeichen-Einstellungen.") }
        return value
    }
}
