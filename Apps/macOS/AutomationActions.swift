import AppIntents
import PresentInkCore

enum PresentInkAction: String, AppEnum {
    case toggleDrawing
    case enableDrawing
    case disableDrawing
    case showAnnotations
    case hideAnnotations
    case toggleAnnotations
    case expandDrawer
    case compactDrawer
    case hideDrawer
    case toggleDrawer
    case undo
    case redo
    case clear
    case startConnection
    case stopConnection
    case toggleConnection
    case startPreview
    case stopPreview
    case togglePreview
    case emergencyHide
    case showPreferences
    case showSettings
    case showApplication
    case hideApplication
    case quit
    case showHelp
    case showAbout
    case openDisplaySettings
    case openCaptureSettings
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "PresentInk-Aktion"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .toggleDrawing: "Zeichenmodus umschalten",
        .enableDrawing: "Zeichnen einschalten",
        .disableDrawing: "Bedienmodus aktivieren",
        .showAnnotations: "Annotationen zeigen",
        .hideAnnotations: "Annotationen ausblenden",
        .toggleAnnotations: "Annotationen umschalten",
        .expandDrawer: "Drawer ausziehen",
        .compactDrawer: "Drawer kompakt",
        .hideDrawer: "Drawer verstecken",
        .toggleDrawer: "Drawer umschalten",
        .undo: "Rückgängig",
        .redo: "Wiederholen",
        .clear: "Alle Annotationen löschen",
        .startConnection: "iPad-Verbindung starten",
        .stopConnection: "iPad-Verbindung stoppen",
        .toggleConnection: "iPad-Verbindung umschalten",
        .startPreview: "Bildschirmvorschau starten",
        .stopPreview: "Bildschirmvorschau pausieren",
        .togglePreview: "Bildschirmvorschau umschalten",
        .emergencyHide: "Notfall: Eingabe freigeben",
        .showPreferences: "Zeichen-Einstellungen öffnen",
        .showSettings: "Verbindung und Freigabe öffnen",
        .showApplication: "PresentInk zeigen",
        .hideApplication: "PresentInk ausblenden",
        .quit: "PresentInk beenden",
        .showHelp: "Tastaturkürzel anzeigen",
        .showAbout: "Über PresentInk anzeigen",
        .openDisplaySettings: "Anzeigeeinstellungen öffnen",
        .openCaptureSettings: "Aufnahmeberechtigungen öffnen",
    ]
}
