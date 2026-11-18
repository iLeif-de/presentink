import AppKit
import PresentInkCore

extension MacAppDelegate {
    @discardableResult
    private func item(_ title: String, _ action: Selector, key: String = "", modifiers: NSEvent.ModifierFlags = .command, tag: Int = 0, in menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self; item.keyEquivalentModifierMask = modifiers; item.tag = tag
        menu.addItem(item); return item
    }
    private func section(_ title: String, in menu: NSMenu) -> NSMenu {
        let root = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: title); root.submenu = submenu; menu.addItem(root); return submenu
    }
    func buildMenu() {
        let menu = NSMenu()
        let app = section("PresentInk", in: menu)
        item(inkLocalized("Über PresentInk"), #selector(about), in: app)
        app.addItem(.separator())
        item(inkLocalized("Einstellungen …"), #selector(showPreferences), key: ",", in: app)
        item(inkLocalized("Verbindung & Freigabe …"), #selector(showCompanion), in: app)
        app.addItem(.separator())
        let hide = NSMenuItem(title: inkLocalized("PresentInk ausblenden"), action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        hide.target = NSApp; app.addItem(hide)
        let quit = NSMenuItem(title: inkLocalized("PresentInk beenden"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp; app.addItem(quit)

        let edit = section(inkLocalized("Bearbeiten"), in: menu)
        item(inkLocalized("Rückgängig"), #selector(undoInk), key: "z", in: edit)
        item(inkLocalized("Wiederholen"), #selector(redoInk), key: "z", modifiers: [.command, .shift], in: edit)
        edit.addItem(.separator())
        item(inkLocalized("Ausschneiden"), #selector(NSText.cut(_:)), key:"x", in:edit).target = nil
        item(inkLocalized("Kopieren"), #selector(NSText.copy(_:)), key:"c", in:edit).target = nil
        item(inkLocalized("Einsetzen"), #selector(NSText.paste(_:)), key:"v", in:edit).target = nil
        item(inkLocalized("Alles auswählen"), #selector(NSText.selectAll(_:)), key:"a", in:edit).target = nil
        edit.addItem(.separator())
        item(inkLocalized("Alle Annotationen löschen"), #selector(clearInk), key: "\u{8}", modifiers: [.command, .shift], in: edit)

        let tools = section(inkLocalized("Werkzeuge"), in: menu)
        item(inkLocalized("Zeichnen / Bedienen"), #selector(toggleDrawing), key: "a", modifiers: [.control, .option], in: tools)
        item(inkLocalized("Bedienen"), #selector(operate), key: "v", modifiers: [.command, .option], in: tools)
        tools.addItem(.separator())
        let keys: [InkTool: String] = [.pen: "p", .marker: "h", .line: "l", .arrow: "a", .rectangle: "r", .ellipse: "o", .eraser: "e", .text: "t"]
        for (index, tool) in InkTool.allCases.enumerated() {
            item(tool.title, #selector(selectTool(_:)), key: keys[tool] ?? "", modifiers: [.command, .option], tag: index, in: tools)
        }
        tools.addItem(.separator())
        colorMenu = section(inkLocalized("Farbe"), in: tools)
        widthMenu = section(inkLocalized("Breite / Schriftgröße"), in: tools)
        rebuildDrawingMenus()

        let view = section(inkLocalized("Darstellung"), in: menu)
        item(inkLocalized("Drawer zeigen / verstecken"), #selector(togglePalette), key: "w", modifiers: [.control, .option], in: view)
        item(inkLocalized("Mac-Drawer vollständig ausblenden"), #selector(fullyHideDrawer), in: view)
        item(inkLocalized("Drawer kompakt"), #selector(compactDrawer), key: "d", modifiers: [.command, .shift], in: view)
        item(inkLocalized("Annotationen ausblenden"), #selector(toggleOverlay), key: "h", modifiers: [.command, .shift], in: view)
        item(inkLocalized("Notfall: Eingabe freigeben und Annotationen ausblenden"), #selector(hideOverlay), key: "\u{1b}", modifiers: [.control, .option], in: view)
        view.addItem(.separator())
        displayMenu = section(inkLocalized("Zieldisplay"), in: view)
        item(inkLocalized("macOS-Anzeigeeinstellungen …"), #selector(openDisplays), in: view)

        let connection = section(inkLocalized("Verbindung"), in: menu)
        item(inkLocalized("iPad verbinden …"), #selector(showCompanion), key: "i", in: connection)
        item(inkLocalized("iPad-Verbindung starten"), #selector(toggleConnection), key: "i", modifiers: [.command, .shift], in: connection)
        item(inkLocalized("Bildschirmvorschau starten"), #selector(togglePreview), key: "s", modifiers: [.command, .shift], in: connection)
        connection.addItem(.separator())
        item(inkLocalized("Bildschirmaufnahme-Einstellungen …"), #selector(openCaptureSettings), in: connection)
        item(inkLocalized("Kopplung zurücksetzen …"), #selector(resetPairing), key: "\u{8}", modifiers: [.command, .option], in: connection)

        let help = section(inkLocalized("Hilfe"), in: menu)
        item(inkLocalized("PresentInk-Anleitung"), #selector(showGuide), key: "?", in: help)
        item(inkLocalized("Tastaturkürzel …"), #selector(shortcuts), key: "?", modifiers: [.command, .option], in: help)
        NSApp.helpMenu = help
        NSApp.mainMenu = menu

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "pencil.tip.crop.circle", accessibilityDescription: "PresentInk")
        let status = NSMenu()
        item(inkLocalized("Zeichnen / Bedienen"), #selector(toggleDrawing), key: "a", modifiers: [.control, .option], in: status)
        item(inkLocalized("Drawer zeigen / verstecken"), #selector(togglePalette), key: "w", modifiers: [.control, .option], in: status)
        status.addItem(.separator())
        item(inkLocalized("iPad verbinden …"), #selector(showCompanion), key: "i", in: status)
        item(inkLocalized("iPad-Verbindung starten"), #selector(toggleConnection), key: "i", modifiers: [.command, .shift], in: status)
        item(inkLocalized("Bildschirmvorschau starten"), #selector(togglePreview), key: "s", modifiers: [.command, .shift], in: status)
        status.addItem(.separator())
        item(inkLocalized("Notfall: Annotationen ausblenden"), #selector(hideOverlay), key: "\u{1b}", modifiers: [.control, .option], in: status)
        item(inkLocalized("PresentInk-Anleitung"), #selector(showGuide), in: status)
        item(inkLocalized("Mac-Drawer vollständig ausblenden"), #selector(fullyHideDrawer), in: status)
        item(inkLocalized("Tastaturkürzel …"), #selector(shortcuts), in: status)
        let statusQuit = NSMenuItem(title: inkLocalized("PresentInk beenden"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusQuit.target = NSApp; status.addItem(statusQuit)
        statusItem.menu = status
    }
    func rebuildDrawingMenus() {
        guard let colorMenu, let widthMenu else { return }
        colorMenu.removeAllItems(); widthMenu.removeAllItems()
        for (index, color) in session.settings.palette.enumerated() {
            item(AutomationValues.hex(color), #selector(selectColor(_:)), key: String(index+1), tag: index, in: colorMenu)
        }
        item(inkLocalized("Breiter"), #selector(thicker), key: "+", in: widthMenu)
        item(inkLocalized("Schmaler"), #selector(thinner), key: "-", in: widthMenu)
        widthMenu.addItem(.separator())
        for value in Array(Set(session.settings.currentStyle.quickWidths)).sorted() {
            let menuItem = item("\(value.formatted()) pt", #selector(selectWidth(_:)), in: widthMenu)
            menuItem.representedObject = value
        }
        item(inkLocalized("Breiten und Schnellstärken einstellen …"), #selector(showPreferences), in: widthMenu)
    }
    func rebuildDisplayMenu() {
        guard let displayMenu else { return }
        displayMenu.removeAllItems()
        for (index, screen) in screens.enumerated() {
            item("\(screen.localizedName) · \(Int(screen.frame.width)) × \(Int(screen.frame.height))", #selector(selectDisplay(_:)),
                 key: index < 9 ? String(index+1) : "", modifiers: [.command, .control], tag: index, in: displayMenu)
        }
    }
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(toggleDrawing): menuItem.title = drawing ? inkLocalized("Bedienmodus aktivieren") : inkLocalized("Zeichnen aktivieren")
        case #selector(operate): menuItem.state = drawing ? .off : .on
        case #selector(selectTool(_:)):
            guard InkTool.allCases.indices.contains(menuItem.tag) else { return false }
            menuItem.state = drawing && drawerState.tool == InkTool.allCases[menuItem.tag] ? .on : .off
        case #selector(selectColor(_:)):
            guard session.settings.palette.indices.contains(menuItem.tag) else { return false }
            menuItem.state = drawerState.color == session.settings.palette[menuItem.tag] ? .on : .off
        case #selector(selectWidth(_:)): menuItem.state = drawerState.width == (menuItem.representedObject as? Double ?? Double(menuItem.tag)) ? .on : .off
        case #selector(thinner): return drawerState.width > session.settings.currentStyle.minimum
        case #selector(thicker): return drawerState.width < session.settings.currentStyle.maximum
        case #selector(undoInk): return canvas.isEditingText ? canvas.canUndoText : session.snapshot.canUndo && session.active == nil
        case #selector(redoInk): return canvas.isEditingText ? canvas.canRedoText : session.snapshot.canRedo && session.active == nil
        case #selector(clearInk): return !session.snapshot.strokes.isEmpty
        case #selector(togglePalette): menuItem.title = (drawerState.presentation == .hidden || drawerState.presentation == .invisible) ? inkLocalized("Drawer zeigen") : inkLocalized("Drawer verstecken")
        case #selector(compactDrawer):
            menuItem.title = drawerState.presentation == .compact ? inkLocalized("Drawer ausziehen") : inkLocalized("Drawer kompakt")
            return drawerState.presentation != .hidden && drawerState.presentation != .invisible
        case #selector(toggleOverlay): menuItem.title = hidden ? inkLocalized("Annotationen zeigen") : inkLocalized("Annotationen ausblenden")
        case #selector(selectDisplay(_:)):
            guard screens.indices.contains(menuItem.tag) else { return false }
            menuItem.state = id(screens[menuItem.tag]) == selectedDisplay ? .on : .off
        case #selector(toggleConnection): menuItem.title = session.token.isEmpty ? inkLocalized("iPad-Verbindung starten") : inkLocalized("iPad-Verbindung stoppen")
        case #selector(togglePreview):
            menuItem.title = session.sharing ? inkLocalized("Bildschirmvorschau pausieren") : inkLocalized("Bildschirmvorschau starten")
            return session.connected
        default: break
        }
        return true
    }
}
