import AppKit
import PresentInkCore

/// Both scripting interfaces use these same operations; UI and document state stay in sync.
enum MacAutomation {
    static weak var delegate: MacAppDelegate?
    static func onMain<T>(_ body: () throws -> T) rethrows -> T {
        if Thread.isMainThread { return try body() }
        return try DispatchQueue.main.sync(execute: body)
    }
    static func app() throws -> MacAppDelegate {
        guard let app = delegate, app.overlay != nil, app.drawer != nil else { throw AutomationFailure.notReady }
        return app
    }
    static func execute(_ operation: InkAutomationOperation, text: String? = nil, number: Double? = nil,
                        clearExisting: Bool = false, confirmed: Bool = false, positionX: Double? = nil, positionY: Double? = nil) throws -> String {
        precondition(Thread.isMainThread)
        let app = try app()
        func idle() throws {
            guard app.session.active == nil else { throw AutomationFailure.unavailable(inkLocalized("Gerade wird ein Strich gezeichnet. Nach dessen Ende erneut versuchen.")) }
        }
        switch operation {
        case .insertText:
            guard let text else { throw AutomationFailure.invalid(inkLocalized("Text fehlt.")) }
            try app.session.insertText(text,at:InkPoint(x:positionX ?? 0.1,y:positionY ?? 0.1))
        case .showPreferences: app.showPreferences()
        case .getDrawingSettings: return String(decoding: try JSONEncoder().encode(app.session.library), as: UTF8.self)
        case .setDrawingSettings:
            guard let text, let data = text.data(using: .utf8), data.count <= 64_000 else { throw AutomationFailure.invalid(inkLocalized("Zeichen-Einstellungen als JSON angeben (maximal 64 KB).")) }
            try app.session.updateSettings(JSONDecoder().decode(DrawingSettings.self, from: data))
        case .selectProfile:
            guard let text else { throw AutomationFailure.invalid(inkLocalized("Profilname fehlt.")) }
            try app.session.useProfile(text)
        case .setOpacity:
            guard let number, number.isFinite, (0.05...1).contains(number) else { throw AutomationFailure.invalid(inkLocalized("Deckkraft muss zwischen 0.05 und 1 liegen.")) }
            var settings = app.session.settings, style = settings.currentStyle
            style.opacity = number; settings.setStyle(style)
            try app.session.updateSettings(settings)
        case .setPreviewPolicy:
            guard let text, let data = text.data(using: .utf8), data.count <= 1_000, !app.session.token.isEmpty else { throw AutomationFailure.invalid(inkLocalized("Host-Verbindung starten und {trusted: Bool, autoStart: Bool} als JSON angeben.")) }
            let policy = try JSONDecoder().decode(PreviewPolicy.self, from: data)
            guard policy.trusted || !policy.autoStart else { throw AutomationFailure.invalid(inkLocalized("Automatischer Start erfordert ausdrücklich trusted=true.")) }
            app.session.setPreviewTrust(policy.trusted); app.session.setPreviewAutoStart(policy.autoStart)
        case .getStatus: return try status()
        case .listDisplays: return try json(displays())
        case .enableDrawing: app.setDrawing(true)
        case .disableDrawing: app.setDrawing(false)
        case .toggleDrawing: app.toggleDrawing()
        case .showAnnotations: app.session.command(.visibility(true))
        case .hideAnnotations: app.hideOverlay()
        case .toggleAnnotations: app.toggleOverlay()
        case .expandDrawer: NSApp.unhide(nil); app.drawer.show()
        case .compactDrawer: NSApp.unhide(nil); app.drawerState.presentation = .compact; app.drawer.panel.orderFrontRegardless()
        case .hideDrawer: app.drawerState.presentation = .hidden
        case .toggleDrawer: app.drawer.toggle()
        case .setDrawer:
            guard let text else { throw AutomationFailure.invalid(inkLocalized("Drawer-Zustand fehlt.")) }
            switch try AutomationValues.drawer(text) {
            case "expanded": NSApp.unhide(nil); app.drawer.show()
            case "compact": NSApp.unhide(nil); app.drawerState.presentation = .compact; app.drawer.panel.orderFrontRegardless()
            case "invisible": app.drawerState.presentation = .invisible
            default: app.drawerState.presentation = .hidden
            }
        case .setTool:
            try idle()
            guard let text else { throw AutomationFailure.invalid(inkLocalized("Werkzeug fehlt.")) }
            let tool = try AutomationValues.tool(text)
            // Configuration does not implicitly activate drawing, unlike clicking a tool in the drawer.
            try app.session.selectDrawing(DrawingSelection(tool: tool))
        case .setColor:
            guard let text else { throw AutomationFailure.invalid(inkLocalized("Farbe fehlt.")) }
            try app.session.selectDrawing(DrawingSelection(color: try AutomationValues.color(text)))
        case .setWidth:
            guard let number else { throw AutomationFailure.invalid(inkLocalized("Strichstärke fehlt.")) }
            try app.session.selectDrawing(DrawingSelection(width: number))
        case .setDisplay:
            try idle()
            guard let number, number.isFinite, number.rounded() == number,
                  number >= 1, number <= Double(app.screens.count) else { throw AutomationFailure.invalid(inkLocalized("Ungültiger Displayindex. Zuerst ‚list displays‘ ausführen; Zählung beginnt bei 1.")) }
            let screen = app.screens[Int(number)-1]
            if app.id(screen) != app.selectedDisplay {
                guard app.session.snapshot.strokes.isEmpty || clearExisting else {
                    throw AutomationFailure.confirmationRequired(inkLocalized("Displaywechsel würde Annotationen entfernen. ‚clearing annotations true‘ beziehungsweise ‚Vorhandene Annotationen entfernen‘ ausdrücklich setzen."))
                }
                app.selectedDisplay = app.id(screen); app.refreshDisplays(resetDocument: true)
            }
        case .undo:
            try idle(); guard app.session.snapshot.canUndo else { throw AutomationFailure.unavailable(inkLocalized("Keine Aktion zum Rückgängigmachen vorhanden.")) }; app.undoInk()
        case .redo:
            try idle(); guard app.session.snapshot.canRedo else { throw AutomationFailure.unavailable(inkLocalized("Keine Aktion zum Wiederholen vorhanden.")) }; app.redoInk()
        case .clear: try idle(); app.clearInk()
        case .startConnection:
            if app.session.token.isEmpty { app.session.error = nil; app.session.startServer(); try verifySession(app) }
        case .stopConnection: app.session.stopServer()
        case .toggleConnection:
            if app.session.token.isEmpty { app.session.error = nil; app.session.startServer(); try verifySession(app) }
            else { app.session.stopServer() }
        case .startPreview:
            guard app.session.connected else { throw AutomationFailure.unavailable(inkLocalized("Kein iPad verbunden. Zuerst die iPad-Verbindung herstellen.")) }
            app.session.error = nil; app.session.startPreview()
        case .stopPreview: app.session.pausePreview()
        case .togglePreview:
            if app.session.sharing { app.session.pausePreview() }
            else {
                guard app.session.connected else { throw AutomationFailure.unavailable(inkLocalized("Kein iPad verbunden.")) }
                app.session.startPreview()
            }
        case .emergencyHide: app.hideOverlay()
        case .showSettings: app.showCompanion()
        case .resetPairing:
            guard confirmed else { throw AutomationFailure.confirmationRequired(inkLocalized("Kopplungen werden widerrufen. Nur mit ‚confirmed true‘ beziehungsweise aktivierter Bestätigung fortfahren.")) }
            app.session.error = nil; app.session.resetPairing(); try verifySession(app)
        case .showApplication: NSApp.unhide(nil); NSApp.activate(ignoringOtherApps: true); app.drawer.show()
        case .hideApplication: app.setDrawing(false); NSApp.hide(nil)
        case .showHelp: app.shortcuts()
        case .showAbout: app.about()
        case .openDisplaySettings: app.openDisplays()
        case .openCaptureSettings: app.openCaptureSettings()
        case .quit:
            app.setDrawing(false); app.session.stopServer()
            DispatchQueue.main.asyncAfter(deadline: .now()+0.5) { NSApp.terminate(nil) }
        }
        return try status()
    }
    private static func verifySession(_ app: MacAppDelegate) throws {
        if let error = app.session.error { throw AutomationFailure.unavailable(error) }
    }
    static func displays() throws -> [[String: Any]] {
        let app = try app()
        return app.screens.enumerated().map { index, screen in
            ["index": index+1, "id": app.id(screen), "name": screen.localizedName,
             "width": screen.frame.width, "height": screen.frame.height,
             "selected": app.id(screen) == app.selectedDisplay]
        }
    }
    static func status() throws -> String {
        let app = try app()
        let drawer: String
        switch app.drawerState.presentation { case .expanded: drawer = "expanded"; case .compact: drawer = "compact"; case .hidden: drawer = "hidden"; case .invisible: drawer = "invisible" }
        return try json([
            "api_version": 1, "app_hidden": NSApp.isHidden,
            "drawing_enabled": app.drawing, "annotations_visible": !app.hidden,
            "drawer_state": drawer, "mac_drawer_visible": app.drawerState.presentation != .invisible,
            "mac_drawer_window_visible": app.drawer.panel.isVisible, "tool": app.drawerState.tool.rawValue,
            "opacity": app.session.settings.currentStyle.opacity,
            "width_minimum": app.session.settings.currentStyle.minimum, "width_maximum": app.session.settings.currentStyle.maximum,
            "drawing_settings_revision": app.session.settingsRevision,
            "drawing_settings_synced": app.session.settingsSynchronized,
            "active_profile": app.session.library.activeProfile as Any? ?? NSNull(),
            "preview_trusted": app.session.previewPolicy.trusted, "preview_auto_start": app.session.previewPolicy.autoStart,
            "color": AutomationValues.hex(app.drawerState.color), "stroke_width": app.drawerState.width,
            "display_index": app.screens.firstIndex(where: { app.id($0) == app.selectedDisplay }).map { $0+1 } ?? 0,
            "display_name": app.session.snapshot.display.name,
            "connection_enabled": !app.session.token.isEmpty, "ipad_connected": app.session.connected,
            "preview_public_windows": app.session.previewPublicWindowCount,
            "preview_enabled": app.session.sharing, "preview_state": app.session.automationPreviewState,
            "preview_detail": app.session.automationPreviewDetail, "connection_status": app.session.serverStatus,
            "stroke_count": app.session.snapshot.strokes.count, "can_undo": app.session.snapshot.canUndo,
            "can_redo": app.session.snapshot.canRedo, "stroke_in_progress": app.session.active != nil,
            "last_error": app.session.error as Any? ?? NSNull()
        ])
    }
    private static func json(_ value: Any) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
        return String(decoding: data, as: UTF8.self)
    }
}
