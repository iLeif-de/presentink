import AppKit
import SwiftUI
import Carbon
import AppIntents
import PresentInkCore
import PresentInkLink

final class MacAppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation, NSMenuDelegate {
    let shortcutServer = MacShortcutServer()
    let helpController = MacHelpController()
    let session = MacSession()
    let drawerState = MacDrawerState()
    lazy var canvas = MacCanvasView(session: session)
    var drawer: MacToolDrawerController!
    var preferencesWindow: NSWindow?
    var colorMenu: NSMenu!
    var widthMenu: NSMenu!
    var companionWindow: NSWindow?
    private var resumeServerAfterSleep = false
    private var sessionActive = true
    var overlay: InkWindow!
    var statusItem: NSStatusItem!
    var displayMenu: NSMenu!
    var screens: [NSScreen] = []
    var selectedDisplay: CGDirectDisplayID?
    var drawing = false
    var hidden = false
    var hotkeys: [EventHotKeyRef] = []
    var hotkeyHandler: EventHandlerRef?
    private var presentationTimer: Timer?
    var localMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        // A custom AppKit entry point and an already-running debug process can retain a placeholder.
        // Load the icon from this exact app bundle rather than relying on a previous process/cache.
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: url) {
            NSApp.applicationIconImage = icon
            NSApp.dockTile.display()
        }
        buildMenu()
        overlay = InkWindow(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        overlay.isReleasedWhenClosed = false; overlay.backgroundColor = .clear; overlay.isOpaque = false
        overlay.hasShadow = false; overlay.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue - 1)
        overlay.hidesOnDeactivate = false
        overlay.becomesKeyOnlyIfNeeded = false
        overlay.collectionBehavior = [.canJoinAllSpaces, .canJoinAllApplications, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        overlay.acceptsMouseMovedEvents = true
        overlay.contentView = canvas; overlay.ignoresMouseEvents = true
        NotificationCenter.default.addObserver(self, selector: #selector(drawingFocusLost), name: NSWindow.didResignKeyNotification, object: overlay)
        session.onSettingsChange = { [weak self] in self?.syncDrawingControls() }
        session.onChange = { [weak self] in self?.documentChanged() }
        session.onShowConnection = { [weak self] in self?.showCompanion() }
        drawerState.selectTool = { [weak self] in self?.chooseTool($0) }
        drawerState.selectColor = { [weak self] in self?.chooseColor($0) }
        drawerState.selectWidth = { [weak self] in self?.chooseWidth($0) }
        drawerState.toggleAnnotations = { [weak self] in self?.toggleOverlay() }
        session.canNavigateSlide = { [weak self] in self?.canvas.isEditingText == false }
        drawerState.clear = { [weak self] in self?.clearInk() }
        drawerState.previousSlide = { [weak self] in self?.navigateSlide(.previous) }
        drawerState.nextSlide = { [weak self] in self?.navigateSlide(.next) }
        drawerState.operate = { [weak self] in self?.setDrawing(false) }
        drawer = MacToolDrawerController(state: drawerState)
        drawerState.presentationChanged = { [weak self] in
            guard let self else { return }
            self.session.sendDrawerVisibility(self.drawerState.presentation != .invisible)
        }
        session.onDrawerVisibilityRequest = { [weak self] visible in
            self?.drawerState.presentation = visible ? .expanded : .invisible
        }
        syncDrawingControls()
        refreshDisplays()
        NotificationCenter.default.addObserver(self, selector: #selector(displaysChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resigned), name: NSApplication.didResignActiveNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleeping), name: NSWorkspace.screensDidSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sessionActivated), name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(waking), name: NSWorkspace.screensDidWakeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sessionResigned), name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(activeSpaceChanged), name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)
        installHotkeys()
        // Keynote presentation windows can be above the menu/status-bar level.
        // Keep a presentation overlay nonactivating; do not change Keynote preferences.
        presentationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updatePresentationLevels()
        }
        updatePresentationLevels()
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.drawing, !self.canvas.isEditingText, NSApp.keyWindow === self.overlay else { return event }
            guard event.modifierFlags.intersection([.command, .control, .option]).isEmpty else { return event }
            if event.keyCode == 53 || event.charactersIgnoringModifiers?.lowercased() == "v" {
                self.setDrawing(false); return nil
            }
            if event.keyCode == 123 || event.keyCode == 124 {
                guard self.session.active == nil, !self.session.navigatingSlide else { return nil }
                self.navigateSlide(event.keyCode == 124 ? .next : .previous); return nil
            }
            let keys: [String: InkTool] = ["p": .pen, "h": .marker, "a": .arrow, "e": .eraser, "r": .rectangle, "o": .ellipse, "l": .line, "t": .text]
            guard let key = event.charactersIgnoringModifiers?.lowercased(), let tool = keys[key] else { return event }
            self.chooseTool(tool); return nil
        }
        MacAutomation.delegate = self
        shortcutServer.start()
        PresentInkShortcuts.updateAppShortcutParameters()
        drawer.show()
        NSApp.activate(ignoringOtherApps: true)
    }
    private func updatePresentationLevels() {
        session.slides.observeFrontmost()
        let presentationPIDs = Set(NSWorkspace.shared.runningApplications.filter {
            PresentationWindowPolicy.supports(bundleIdentifier:$0.bundleIdentifier)
        }.map { $0.processIdentifier })
        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        let reportedLevel = windows.compactMap { item -> Int? in
            guard let pid = item[kCGWindowOwnerPID as String] as? NSNumber,
                  presentationPIDs.contains(pid.int32Value), let level = item[kCGWindowLayer as String] as? NSNumber,
                  level.intValue >= NSWindow.Level.statusBar.rawValue else { return nil }
            return level.intValue
        }.max()
        // Some slideshow surfaces are grouped by WindowServer but report an
        // ordinary layer. A display-filling window from a known presentation app
        // still needs to clear the public display-shield level.
        let displayBounds = selectedDisplay.map { CGDisplayBounds($0) }
        let hasFullscreenSurface = windows.contains { item in
            guard let displayBounds,
                  let pid = item[kCGWindowOwnerPID as String] as? NSNumber,
                  presentationPIDs.contains(pid.int32Value),
                  let raw = item[kCGWindowBounds as String] as? [String:Any],
                  let bounds = CGRect(dictionaryRepresentation:raw as CFDictionary) else { return false }
            return PresentationWindowPolicy.coversDisplay(window:bounds,display:displayBounds)
        }
        let presentationLevel = hasFullscreenSurface ? max(reportedLevel ?? 0,Int(CGShieldingWindowLevel())) : reportedLevel
        let levels = PresentationWindowPolicy.levels(
            presentation:presentationLevel,
            normal:NSWindow.Level.statusBar.rawValue-1,
            minimumPresentation:NSWindow.Level.screenSaver.rawValue+1,
            maximum:Int(CGWindowLevelForKey(.maximumWindow)))
        if overlay.level.rawValue != levels.overlay { overlay.level = NSWindow.Level(rawValue:levels.overlay) }
        if drawer.panel.level.rawValue != levels.drawer { drawer.panel.level = NSWindow.Level(rawValue:levels.drawer) }
        // Reassert ordering even when the numeric level is unchanged: presentation
        // apps can create/reorder fullscreen windows between polling intervals.
        if !hidden && sessionActive { overlay.orderFrontRegardless() }
        if drawerState.presentation != .invisible && sessionActive { drawer.panel.orderFrontRegardless() }
    }
    private func navigateSlide(_ direction: SlideDirection) {
        do { _ = try session.navigateSlide(direction) }
        catch { session.error = error.localizedDescription; drawerState.error = error.localizedDescription }
    }
    func documentChanged() {
        drawerState.canClear = !session.snapshot.strokes.isEmpty && session.active == nil && !session.navigatingSlide
        drawerState.canNavigate = session.active == nil && !session.navigatingSlide

        canvas.documentChanged()
        hidden = !session.snapshot.overlayVisible
        drawerState.annotationsVisible = !hidden
        if hidden {
            overlay.orderOut(nil); overlay.ignoresMouseEvents = true
            if drawing {
                drawing = false; releaseDrawingFocus()
            }
        } else { overlay.orderFrontRegardless() }
        drawerState.drawing = drawing
    }
    func id(_ screen: NSScreen) -> CGDirectDisplayID {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }
    func refreshDisplays(resetDocument: Bool = false) {
        setDrawing(false)
        screens = NSScreen.screens
        let index = screens.firstIndex { id($0) == selectedDisplay } ?? 0
        guard screens.indices.contains(index) else { overlay.orderOut(nil); drawer.panel.orderOut(nil); return }
        let screen = screens[index]
        selectedDisplay = id(screen)
        overlay.setFrame(screen.frame, display: true)
        canvas.frame = NSRect(origin: .zero, size: screen.frame.size)
        session.configure(display: DisplayInfo(name: screen.localizedName, width: screen.frame.width, height: screen.frame.height), id: id(screen), reset: resetDocument)
        canvas.needsDisplay = true
        drawer.move(to: screen)
        rebuildDisplayMenu()
    }
    func setDrawing(_ enabled: Bool) {
        guard canvas.finishText() else { return }
        let wasDrawing = drawing
        if enabled {
            NSApp.unhideWithoutActivation()
            if hidden { session.command(.visibility(true)); guard !hidden else { return } }
        }
        updatePresentationLevels()
        drawing = enabled
        canvas.cancel()
        overlay?.ignoresMouseEvents = !enabled
        if enabled {
            // A nonactivating panel takes drawing focus without activating our app or leaving a foreign fullscreen Space.
            overlay.makeKeyAndOrderFront(nil); overlay.makeFirstResponder(canvas)
        } else if wasDrawing { releaseDrawingFocus() }
        drawerState.drawing = drawing
    }
    private func releaseDrawingFocus() {
        // Ordering out releases a nonactivating panel's keyboard focus through AppKit.
        overlay?.orderOut(nil)
        if !hidden { overlay?.orderFrontRegardless() }
    }
    func syncDrawingControls() {
        let settings = session.settings, style = settings.currentStyle
        if canvas.tool != settings.tool { canvas.tool = settings.tool }
        canvas.ink = style.color; canvas.width = style.width
        drawerState.tool = settings.tool; drawerState.color = style.color; drawerState.width = style.width
        drawerState.settings = settings
        rebuildDrawingMenus()
    }
    func chooseTool(_ tool: InkTool) {
        guard canvas.finishText() else { return }
        do { try session.selectDrawing(DrawingSelection(tool: tool)); setDrawing(true) }
        catch { session.error = error.localizedDescription }
    }
    func chooseColor(_ color: InkColor) {
        guard canvas.finishText() else { return }
        do { try session.selectDrawing(DrawingSelection(color: color)) }
        catch { session.error = error.localizedDescription }
    }
    func chooseWidth(_ width: Double) {
        guard canvas.finishText() else { return }
        let style = session.settings.currentStyle
        do { try session.selectDrawing(DrawingSelection(width: min(style.maximum, max(style.minimum, width)))) }
        catch { session.error = error.localizedDescription }
    }
    @objc func operate() { setDrawing(false) }
    @objc func toggleDrawing() { setDrawing(!drawing) }
    @objc func hideOverlay() { setDrawing(false); session.command(.visibility(false)) }
    @objc func toggleOverlay() { if hidden { session.command(.visibility(true)) } else { hideOverlay() } }
    @objc func togglePalette() { drawer.toggle() }
    @objc func fullyHideDrawer() { drawerState.presentation = .invisible }
    @objc func compactDrawer() { drawerState.presentation = drawerState.presentation == .compact ? .expanded : .compact }
    @objc func selectTool(_ sender: NSMenuItem) {
        guard InkTool.allCases.indices.contains(sender.tag) else { return }; chooseTool(InkTool.allCases[sender.tag])
    }
    @objc func selectColor(_ sender: NSMenuItem) {
        guard session.settings.palette.indices.contains(sender.tag) else { return }; chooseColor(session.settings.palette[sender.tag])
    }
    @objc func selectWidth(_ sender: NSMenuItem) { chooseWidth(sender.representedObject as? Double ?? Double(sender.tag)) }
    @objc func thinner() { chooseWidth(drawerState.width - 1) }
    @objc func thicker() { chooseWidth(drawerState.width + 1) }
    @objc func selectDisplay(_ sender: NSMenuItem) {
        guard screens.indices.contains(sender.tag), id(screens[sender.tag]) != selectedDisplay else { return }
        if !session.snapshot.strokes.isEmpty {
            let alert = NSAlert(); alert.messageText = inkLocalized("Zieldisplay wechseln?")
            alert.informativeText = inkLocalized("Beim Displaywechsel werden die bisherigen Annotationen entfernt und die Bildschirmvorschau pausiert.")
            alert.addButton(withTitle: inkLocalized("Display wechseln")); alert.addButton(withTitle: inkLocalized("Abbrechen"))
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }
        selectedDisplay = id(screens[sender.tag]); refreshDisplays(resetDocument: true)
    }
    @objc func undoInk() { if canvas.isEditingText { canvas.undoText(); return }; canvas.cancel(); session.command(.undo) }
    @objc func redoInk() { if canvas.isEditingText { canvas.redoText(); return }; canvas.cancel(); session.command(.redo) }
    @objc func clearInk() { guard canvas.finishText() else { return }; canvas.cancel(); session.command(.clear) }
    @objc func displaysChanged() { refreshDisplays() }
    @objc func resigned() { if drawing { setDrawing(false) } }
    @objc func drawingFocusLost() { if drawing { setDrawing(false) } }
    @objc func sleeping() {
        resumeServerAfterSleep = resumeServerAfterSleep || !session.token.isEmpty
        hideOverlay(); session.stopServer()
    }
    @objc func sessionResigned() { sessionActive = false; sleeping() }
    @objc func sessionActivated() { sessionActive = true; waking() }
    @objc func waking() {
        // Resume only the connection that was enabled before sleep or locking.
        guard sessionActive else { return }
        if resumeServerAfterSleep { resumeServerAfterSleep = false; session.startServer() }
        refreshDisplays()
    }
    @objc func openDisplays() { if let url = URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension") { NSWorkspace.shared.open(url) } }
    @objc func toggleConnection() { if session.token.isEmpty { showCompanion(); session.startServer() } else { session.stopServer() } }
    @objc func togglePreview() { if session.sharing { session.pausePreview() } else { session.startPreview() } }
    @objc func openCaptureSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") { NSWorkspace.shared.open(url) }
    }
    @objc func resetPairing() {
        let alert = NSAlert(); alert.messageText = inkLocalized("Kopplung zurücksetzen?")
        alert.informativeText = inkLocalized("Alle bisherigen Kopplungsschlüssel werden ungültig. Das iPad muss einmalig mit dem neuen Schlüssel gekoppelt werden.")
        alert.addButton(withTitle: inkLocalized("Kopplung zurücksetzen")); alert.addButton(withTitle: inkLocalized("Abbrechen"))
        if alert.runModal() == .alertFirstButtonReturn { session.resetPairing(); showCompanion() }
    }
    @objc func about() { setDrawing(false); helpController.showAbout() }
    @objc func showGuide() { setDrawing(false); helpController.showGuide() }
    @objc func shortcuts() { setDrawing(false); helpController.showShortcuts() }
    @objc func activeSpaceChanged() {
        // Never reset the document or preview merely because the user changed Spaces.
        setDrawing(false)
        if !hidden { overlay.orderFrontRegardless() }
        if drawerState.presentation != .invisible { drawer.panel.orderFrontRegardless() }
    }
    func installHotkeys() {
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, data in
            guard let event, let data else { return OSStatus(eventNotHandledErr) }
            var hotkey = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotkey)
            let owner = Unmanaged<MacAppDelegate>.fromOpaque(data).takeUnretainedValue()
            switch hotkey.id {
            case 1: owner.toggleDrawing()
            case 2: owner.hideOverlay()
            case 3: owner.togglePalette()
            default: return OSStatus(eventNotHandledErr)
            }
            return noErr
        }, 1, &type, pointer, &hotkeyHandler)
        for (key, number) in [(UInt32(kVK_ANSI_A), UInt32(1)), (UInt32(kVK_Escape), UInt32(2)), (UInt32(kVK_ANSI_W), UInt32(3))] {
            var reference: EventHotKeyRef?
            let result = RegisterEventHotKey(key, UInt32(controlKey | optionKey), EventHotKeyID(signature: 0x50494E4B, id: number), GetApplicationEventTarget(), 0, &reference)
            if result == noErr, let reference { hotkeys.append(reference) }
            else { let alert = NSAlert(); alert.messageText = inkLocalized("Globaler Shortcut nicht verfügbar"); alert.informativeText = inkLocalized("Eine andere App belegt möglicherweise ⌃⌥%@. Verwende die Werkzeugpalette oder das Menüleistensymbol.", String(describing: (number == 1 ? "A" : (number == 2 ? "Escape" : "W")))); alert.runModal() }
        }
    }
    @objc func showPreferences() {
        setDrawing(false)
        if preferencesWindow == nil {
            let controller = NSHostingController(rootView: MacDrawingSettingsView(session: session))
            let window = NSWindow(contentViewController: controller)
            window.title = inkLocalized("PresentInk · Einstellungen")
            window.identifier = NSUserInterfaceItemIdentifier("presentink.settings")
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.minSize = NSSize(width: 700, height: 640)
            window.setContentSize(NSSize(width: 780, height: 760))
            window.isReleasedWhenClosed = false; window.center(); preferencesWindow = window
        }
        NSApp.unhide(nil); preferencesWindow?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    @objc func showCompanion() {
        setDrawing(false)
        if companionWindow == nil {
            let controller = NSHostingController(rootView: CompanionHostView(session: session))
            let window = NSWindow(contentViewController: controller)
            window.title = inkLocalized("PresentInk · Verbindung & Freigabe")
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false; window.center(); companionWindow = window
        }
        companionWindow?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { drawer.show(); return false }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationWillTerminate(_ notification: Notification) {
        presentationTimer?.invalidate(); presentationTimer = nil
        shortcutServer.stop()
        session.shutdown(); drawer.close()
        hotkeys.forEach { UnregisterEventHotKey($0) }
        if let hotkeyHandler { RemoveEventHandler(hotkeyHandler) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
    }
}
