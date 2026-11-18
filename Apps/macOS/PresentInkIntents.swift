import AppIntents
import PresentInkCore

enum PresentInkToolChoice: String, AppEnum {
    case pen, marker, line, arrow, rectangle, ellipse, eraser, text
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Zeichenwerkzeug"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .pen: "Stift", .marker: "Marker", .line: "Linie", .arrow: "Pfeil", .rectangle: "Rechteck", .ellipse: "Ellipse", .eraser: "Radierer", .text: "Text"
    ]
}
enum PresentInkColorChoice: String, AppEnum {
    case red, yellow, blue, green, white, graphite
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Stiftfarbe"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .red: "Rot", .yellow: "Gelb", .blue: "Blau", .green: "Grün", .white: "Weiß", .graphite: "Graphit"
    ]
}
enum PresentInkDrawerChoice: String, AppEnum {
    case expanded, compact, hidden, invisible
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Drawer-Zustand"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [.expanded: "Ausgezogen", .compact: "Kompakt", .hidden: "Minimiert (Griff)", .invisible: "Vollständig ausgeblendet"]
}

struct ControlPresentInkIntent: AppIntent {
    static var title: LocalizedStringResource = "PresentInk steuern"
    static var description = IntentDescription("Zeichenmodus, Overlay, Drawer, Bearbeitung, Verbindung und Vorschau steuern. Rückgabe: PresentInk-Status mit auswählbaren Eigenschaften. App muss bereits laufen.")
    static var supportedModes: IntentModes = .background
    static var allowedExecutionTargets: IntentExecutionTargets = .appIntentsExtension
    @Parameter(title: "Aktion", default: .toggleDrawing) var action: PresentInkAction
    static var parameterSummary: some ParameterSummary { Summary("\(\.$action)") }
    init() {}
    init(action: PresentInkAction) { self.action = action }
    @MainActor func perform() async throws -> some IntentResult & ReturnsValue<PresentInkStatusEntity> {
        guard let operation = InkAutomationOperation(rawValue: action.rawValue) else { throw AutomationFailure.invalid("Unbekannte Aktion.") }
        return .result(value: try await ShortcutAutomation.status(operation))
    }
}
struct SetPresentInkToolIntent: AppIntent {
    static var title: LocalizedStringResource = "PresentInk-Werkzeug setzen"
    static var description = IntentDescription("Wählt ein Werkzeug, ohne den Zeichenmodus automatisch zu aktivieren.")
    static var supportedModes: IntentModes = .background
    static var allowedExecutionTargets: IntentExecutionTargets = .appIntentsExtension
    @Parameter(title: "Werkzeug", default: .pen) var tool: PresentInkToolChoice
    static var parameterSummary: some ParameterSummary { Summary("Werkzeug auf \(\.$tool) setzen") }
    @MainActor func perform() async throws -> some IntentResult & ReturnsValue<PresentInkStatusEntity> {
        .result(value: try await ShortcutAutomation.status(.setTool, text: tool.rawValue))
    }
}
struct SetPresentInkColorIntent: AppIntent {
    static var title: LocalizedStringResource = "PresentInk-Farbe setzen"
    static var supportedModes: IntentModes = .background
    static var allowedExecutionTargets: IntentExecutionTargets = .appIntentsExtension
    @Parameter(title: "Farbe", default: .red) var color: PresentInkColorChoice
    static var parameterSummary: some ParameterSummary { Summary("Farbe auf \(\.$color) setzen") }
    @MainActor func perform() async throws -> some IntentResult & ReturnsValue<PresentInkStatusEntity> {
        .result(value: try await ShortcutAutomation.status(.setColor, text: color.rawValue))
    }
}
struct SetPresentInkCustomColorIntent: AppIntent {
    static var title: LocalizedStringResource = "Eigene PresentInk-Farbe setzen"
    static var supportedModes: IntentModes = .background
    static var allowedExecutionTargets: IntentExecutionTargets = .appIntentsExtension
    @Parameter(title: "Hex-Farbe", default: "#FF5533") var hexColor: String
    static var parameterSummary: some ParameterSummary { Summary("Stiftfarbe auf \(\.$hexColor) setzen") }
    @MainActor func perform() async throws -> some IntentResult & ReturnsValue<PresentInkStatusEntity> {
        .result(value: try await ShortcutAutomation.status(.setColor, text: hexColor))
    }
}
struct SetPresentInkWidthIntent: AppIntent {
    static var title: LocalizedStringResource = "PresentInk-Strichstärke setzen"
    static var description = IntentDescription("Gültiger Bereich aus den Mac-Werkzeug-Einstellungen. Ungültige Werte liefern einen Fehler.")
    static var supportedModes: IntentModes = .background
    static var allowedExecutionTargets: IntentExecutionTargets = .appIntentsExtension
    @Parameter(title: "Strichstärke", default: 4) var width: Double
    static var parameterSummary: some ParameterSummary { Summary("Strichstärke auf \(\.$width) setzen") }
    @MainActor func perform() async throws -> some IntentResult & ReturnsValue<PresentInkStatusEntity> {
        .result(value: try await ShortcutAutomation.status(.setWidth, number: width))
    }
}
struct SetPresentInkDrawerIntent: AppIntent {
    static var title: LocalizedStringResource = "PresentInk-Drawer einstellen"
    static var supportedModes: IntentModes = .background
    static var allowedExecutionTargets: IntentExecutionTargets = .appIntentsExtension
    @Parameter(title: "Darstellung", default: .expanded) var presentation: PresentInkDrawerChoice
    static var parameterSummary: some ParameterSummary { Summary("Drawer: \(\.$presentation)") }
    @MainActor func perform() async throws -> some IntentResult & ReturnsValue<PresentInkStatusEntity> {
        .result(value: try await ShortcutAutomation.status(.setDrawer, text: presentation.rawValue))
    }
}
struct SetPresentInkDisplayIntent: AppIntent {
    static var title: LocalizedStringResource = "PresentInk-Zieldisplay wählen"
    static var description = IntentDescription("Displayindex aus ‚PresentInk-Displays auflisten‘, beginnend bei 1. Ein Wechsel pausiert die Vorschau und entfernt die bisherige Zeichenebene.")
    static var supportedModes: IntentModes = .background
    static var allowedExecutionTargets: IntentExecutionTargets = .appIntentsExtension
    @Parameter(title: "Displayindex", default: 1) var index: Int
    @Parameter(title: "Vorhandene Annotationen entfernen", default: false) var clearExisting: Bool
    @MainActor func perform() async throws -> some IntentResult & ReturnsValue<PresentInkStatusEntity> {
        .result(value: try await ShortcutAutomation.status(.setDisplay, number: Double(index), clearExisting: clearExisting))
    }
}
struct ReadPresentInkStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "PresentInk-Status abfragen"
    static var supportedModes: IntentModes = .background
    static var allowedExecutionTargets: IntentExecutionTargets = .appIntentsExtension
    @MainActor func perform() async throws -> some IntentResult & ReturnsValue<PresentInkStatusEntity> {
        .result(value: try await ShortcutAutomation.status(.getStatus))
    }
}
struct ListPresentInkDisplaysIntent: AppIntent {
    static var title: LocalizedStringResource = "PresentInk-Displays auflisten"
    static var supportedModes: IntentModes = .background
    static var allowedExecutionTargets: IntentExecutionTargets = .appIntentsExtension
    @MainActor func perform() async throws -> some IntentResult & ReturnsValue<[PresentInkDisplayEntity]> {
        .result(value: try await ShortcutAutomation.displays())
    }
}
struct ResetPresentInkPairingIntent: AppIntent {
    static var title: LocalizedStringResource = "PresentInk-Kopplung zurücksetzen"
    static var description = IntentDescription("Widerruft ALLE bisherigen Kopplungsschlüssel. Ein iPad muss danach einmalig neu gekoppelt werden. Nur mit ausdrücklich aktivierter Bestätigung ausführbar.")
    static var supportedModes: IntentModes = .background
    static var allowedExecutionTargets: IntentExecutionTargets = .appIntentsExtension
    @Parameter(title: "Alle bisherigen Kopplungen ausdrücklich widerrufen", default: false) var confirmed: Bool
    @MainActor func perform() async throws -> some IntentResult & ReturnsValue<PresentInkStatusEntity> {
        .result(value: try await ShortcutAutomation.status(.resetPairing, confirmed: confirmed))
    }
}

struct SelectPresentInkProfileIntent: AppIntent {
    static var title: LocalizedStringResource = "PresentInk-Profil auswählen"
    static var supportedModes: IntentModes = .background
    static var allowedExecutionTargets: IntentExecutionTargets = .appIntentsExtension
    @Parameter(title: "Profilname", default: "Helle Folien") var name: String
    @MainActor func perform() async throws -> some IntentResult & ReturnsValue<PresentInkStatusEntity> {
        .result(value: try await ShortcutAutomation.status(.selectProfile, text: name))
    }
}
struct SetPresentInkOpacityIntent: AppIntent {
    static var title: LocalizedStringResource = "PresentInk-Deckkraft setzen"
    static var supportedModes: IntentModes = .background
    static var allowedExecutionTargets: IntentExecutionTargets = .appIntentsExtension
    @Parameter(title: "Deckkraft in Prozent (5–100)", default: 30) var percent: Double
    @MainActor func perform() async throws -> some IntentResult & ReturnsValue<PresentInkStatusEntity> {
        .result(value: try await ShortcutAutomation.status(.setOpacity, number: percent/100))
    }
}
struct ReadPresentInkSettingsIntent: AppIntent {
    static var title: LocalizedStringResource = "PresentInk-Zeichen-Einstellungen lesen"
    static var supportedModes: IntentModes = .background
    static var allowedExecutionTargets: IntentExecutionTargets = .appIntentsExtension
    @MainActor func perform() async throws -> some IntentResult & ReturnsValue<PresentInkSettingsEntity> {
        .result(value: try await ShortcutAutomation.settings())
    }
}
struct ApplyPresentInkSettingsIntent: AppIntent {
    static var title: LocalizedStringResource = "PresentInk-Zeichen-Einstellungen anwenden"
    static var description = IntentDescription("Übernimmt die typisierte Ausgabe aus „Zeichen-Einstellungen lesen“. Ändert keine Freigaberechte.")
    static var supportedModes: IntentModes = .background
    static var allowedExecutionTargets: IntentExecutionTargets = .appIntentsExtension
    @Parameter(title: "Zeichen-Einstellungen") var settings: PresentInkSettingsEntity
    @MainActor func perform() async throws -> some IntentResult & ReturnsValue<PresentInkStatusEntity> {
        let value = try settings.settings()
        let json = String(decoding:try JSONEncoder().encode(value),as:UTF8.self)
        return .result(value: try await ShortcutAutomation.status(.setDrawingSettings, text: json))
    }
}
struct ConfigurePresentInkSharingIntent: AppIntent {
    static var title: LocalizedStringResource = "PresentInk-Freigabe merken"
    static var description = IntentDescription("Steuert die PresentInk-Zustimmung für die aktuelle Kopplung. macOS-Systemfreigaben bleiben erforderlich. Zuerst die Host-Verbindung starten.")
    static var supportedModes: IntentModes = .background
    static var allowedExecutionTargets: IntentExecutionTargets = .appIntentsExtension
    @Parameter(title: "Anfragen der Kopplung ohne Rückfrage erlauben", default: false) var trusted: Bool
    @Parameter(title: "Nach dem Verbinden automatisch starten", default: false) var autoStart: Bool
    @MainActor func perform() async throws -> some IntentResult & ReturnsValue<PresentInkStatusEntity> {
        let policy = "{\"trusted\":\(trusted),\"autoStart\":\(autoStart)}"
        return .result(value: try await ShortcutAutomation.status(.setPreviewPolicy, text: policy))
    }
}

struct InsertPresentInkTextIntent: AppIntent {
    static var title: LocalizedStringResource = "PresentInk-Text einfügen"
    static var description = IntentDescription("Fügt Text mit dem zentralen Mac-Textstil ein. Position in Prozent des Zieldisplays; Umbruch innerhalb des Displays.")
    static var supportedModes: IntentModes = .background
    static var allowedExecutionTargets: IntentExecutionTargets = .appIntentsExtension
    @Parameter(title: "Text") var text: String
    @Parameter(title: "Horizontal (0 bis 100 Prozent)", default: 10) var x: Double
    @Parameter(title: "Vertikal (0 bis 100 Prozent)", default: 10) var y: Double
    @MainActor func perform() async throws -> some IntentResult & ReturnsValue<PresentInkStatusEntity> {
        .result(value: try await ShortcutAutomation.status(.insertText,text:text,positionX:x/100,positionY:y/100))
    }
}

struct PresentInkShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: ControlPresentInkIntent(action: .toggleDrawing),
            phrases: ["Zeichenmodus in \(.applicationName) umschalten"], shortTitle: "Zeichenmodus umschalten", systemImageName: "pencil.tip")
        AppShortcut(intent: ControlPresentInkIntent(action: .toggleDrawer),
            phrases: ["Werkzeuge in \(.applicationName) umschalten"], shortTitle: "Drawer umschalten", systemImageName: "slider.horizontal.3")
        AppShortcut(intent: ControlPresentInkIntent(action: .emergencyHide),
            phrases: ["Annotationen in \(.applicationName) ausblenden"], shortTitle: "Annotationen ausblenden", systemImageName: "eye.slash")
        AppShortcut(intent: ReadPresentInkStatusIntent(),
            phrases: ["Status von \(.applicationName) abfragen"], shortTitle: "Status abfragen", systemImageName: "info.circle")
        AppShortcut(intent: SetPresentInkToolIntent(),
            phrases: ["Werkzeug in \(.applicationName) einstellen"], shortTitle: "Werkzeug setzen", systemImageName: "pencil.and.outline")
        AppShortcut(intent: SetPresentInkColorIntent(),
            phrases: ["Farbe in \(.applicationName) einstellen"], shortTitle: "Farbe setzen", systemImageName: "paintpalette")
        AppShortcut(intent: SetPresentInkWidthIntent(),
            phrases: ["Strichstärke in \(.applicationName) einstellen"], shortTitle: "Strichstärke setzen", systemImageName: "lineweight")
        AppShortcut(intent: ListPresentInkDisplaysIntent(),
            phrases: ["Displays in \(.applicationName) auflisten"], shortTitle: "Displays auflisten", systemImageName: "display.2")
    }
}
