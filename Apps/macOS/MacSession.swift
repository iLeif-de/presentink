import AppKit
import Combine
import CryptoKit
import PresentInkCore
import PresentInkLink

final class MacSession: ObservableObject {
    @Published private(set) var library = DrawingLibrary()
    @Published private(set) var previewPolicy = PreviewPolicy()
    var settings: DrawingSettings { library.current }
    var onSettingsChange: (() -> Void)?
    private let preferences = DrawingPreferencesRepository()
    private(set) var settingsRevision: UInt64 = 0
    @Published private(set) var settingsAcknowledgedRevision: UInt64?
    var settingsSynchronized: Bool { connected && settingsAcknowledgedRevision == settingsRevision }
    private var previewPausedByUser = UserDefaults.standard.bool(forKey: "preview-paused-by-user")
    @Published private(set) var snapshot = InkSnapshot()
    @Published private(set) var active: InkStroke?
    @Published private(set) var serverStatus = inkLocalized("Companion-Verbindung aus")
    @Published private(set) var token = ""
    @Published private(set) var previewStatus = inkLocalized("Vorschau aus")
    @Published private(set) var connected = false
    @Published private(set) var sharing = false
    @Published private(set) var previewPublicWindowCount = 0
    @Published var previewRequested = false
    var onDrawerVisibilityRequest: ((Bool) -> Void)?
    private var macDrawerVisible = true
    var onShowConnection: (() -> Void)?
    private var previewPhase: PreviewStatus = .paused(inkLocalized("Am iPad auf ‚Mac-Bildschirm anzeigen‘ tippen."))
    var automationPreviewState: String {
        switch previewPhase { case .paused: "paused"; case .awaitingApproval: "awaitingApproval"; case .starting: "starting"; case .live: "live"; case .failed: "failed" }
    }
    var automationPreviewDetail: String { previewPhase.detail }
    private var firstFrameReceived = false
    @Published var error: String?
    var onChange: (() -> Void)?
    var canNavigateSlide: (() -> Bool)?
    private(set) var navigatingSlide = false
    private var document = InkDocument()
    let slides = MacSlideNavigation()
    private let server = CompanionServer()
    private let capture = ScreenPreviewService()
    private var frameSequence: UInt64 = 0
    private var displayID: CGDirectDisplayID = 0
    private var pendingPreview = false
    private var pendingSnapshot = false
    private var lastSnapshotSent = 0.0
    private var timer: Timer?
    private var previewGeneration = UUID()
    init() {
        do { library = try preferences.load() }
        catch { self.error = error.localizedDescription }
        if let data = UserDefaults.standard.data(forKey: "preview-policy-v1"), let policy = try? JSONDecoder().decode(PreviewPolicy.self, from: data) { previewPolicy = policy }
        snapshot = document.snapshot
        server.onStatus = { [weak self] in self?.serverStatus = $0 }
        server.onCommand = { [weak self] command in self?.apply(command, owner:"ipad") }
        server.onConnect = { [weak self] in
            guard let self else { return }; self.connected = true; self.settingsAcknowledgedRevision = nil
            self.server.send(.snapshot(self.snapshot)); self.server.send(.preview(self.active))
            self.server.previewStatus(self.previewPhase)
            self.server.send(.macDrawerVisible(self.macDrawerVisible))
            self.sendSettings()
            if self.previewPolicy.mayStart(connected: true, requested: false, manuallyPaused: self.previewPausedByUser) { self.startPreview() }
        }
        server.onSettingsApplied = { [weak self] revision in
            guard let self, revision <= self.settingsRevision else { return }
            self.settingsAcknowledgedRevision = revision
        }
        server.onDrawingSelection = { [weak self] selection in
            guard let self else { return }
            do { try self.selectDrawing(selection) }
            catch { self.server.send(.settingsRejected(error.localizedDescription)); self.sendSettings() }
        }
        server.onDrawerVisibilityRequest = { [weak self] visible in self?.onDrawerVisibilityRequest?(visible) }
        server.onSlideNavigation = { [weak self] direction, request in
            guard let self else { return }
            do {
                _ = try self.navigateSlide(direction)
                self.server.send(.slideNavigationFinished(request:request,snapshot:self.snapshot))
            } catch { self.server.send(.slideNavigationFailed(request:request,reason:error.localizedDescription)) }
        }
        server.onPreviewRequest = { [weak self] in
            guard let self else { return }
            if self.sharing { self.server.previewStatus(self.previewPhase) }
            else if self.previewPolicy.mayStart(connected: true, requested: true, manuallyPaused: self.previewPausedByUser) { self.startPreview() }
            else {
                self.previewRequested = true; self.setPreviewStatus(.awaitingApproval)
                self.onShowConnection?()
            }
        }
        server.onDisconnect = { [weak self] in
            guard let self else { return }; self.connected = false; self.settingsAcknowledgedRevision = nil
            self.document.cancel(owner:"ipad"); self.publish(); self.stopPreview()
        }
        capture.onPublicWindowsChanged = { [weak self] in self?.previewPublicWindowCount = $0 }
        capture.onFrame = { [weak self] data, sourceEpoch in
            guard let self, self.sharing, self.connected, sourceEpoch == self.snapshot.sourceEpoch else { return }
            self.firstFrameReceived = true
            self.frameSequence &+= 1
            self.server.sendVideo(VideoFrame(epoch:sourceEpoch,jpeg:data,sequence:self.frameSequence))
        }
        capture.onError = { [weak self] message in self?.error = message; self?.stopPreview(status: .failed(message)) }
        timer = Timer.scheduledTimer(withTimeInterval:1.0/30,repeats:true) { [weak self] _ in
            guard let self else { return }
            let now = ProcessInfo.processInfo.systemUptime
            if self.pendingSnapshot && now-self.lastSnapshotSent >= 0.1 {
                self.pendingSnapshot = false; self.lastSnapshotSent = now
                self.server.send(.snapshot(self.snapshot)); self.server.send(.preview(self.active))
            }
            guard self.pendingPreview else { return }; self.pendingPreview = false
            self.server.send(.preview(self.active),replaceable:true)
        }
    }
    func configure(display: DisplayInfo, id: CGDirectDisplayID, reset: Bool = false) {
        guard reset || displayID != id || snapshot.display != display else { return }
        let resumePreview = sharing && connected && displayID == id && !previewPausedByUser
        stopPreview(status:resumePreview ? .starting : .paused(inkLocalized("Am iPad auf ‚Mac-Bildschirm anzeigen‘ tippen oder am Mac freigeben.")))
        displayID = id
        if reset { document.reset(display:display) } else { document.updateDisplay(display) }
        publish()
        server.send(.snapshot(snapshot)); server.send(.preview(nil)); pendingPreview = false
        if resumePreview { startPreview() }
    }
    @discardableResult func navigateSlide(_ direction: SlideDirection) throws -> Bool {
        guard !navigatingSlide, active == nil, canNavigateSlide?() != false else {
            throw AutomationFailure.unavailable(inkLocalized("Bitte die aktuelle Eingabe oder den Folienwechsel zuerst beenden."))
        }
        navigatingSlide = true; onChange?()
        defer { navigatingSlide = false; onChange?() }
        let epoch = snapshot.epoch
        // AppleScript may pump the run loop while waiting for a permission dialog.
        // Never hold a mutating document access across that external call.
        guard try slides.navigate(direction) else { return false }
        guard snapshot.epoch == epoch else {
            throw AutomationFailure.unavailable(inkLocalized("Die Zeichenfläche wurde während des Folienwechsels geändert. Annotationen bleiben erhalten."))
        }
        guard document.performSlideChange({ true }) else {
            throw AutomationFailure.unavailable(inkLocalized("Bitte die aktuelle Eingabe oder den Folienwechsel zuerst beenden."))
        }
        pendingSnapshot = false; pendingPreview = false
        publish(); server.send(.snapshot(snapshot)); server.send(.preview(nil))
        return true
    }
    func command(_ action: InkAction) {
        if case .visibility(false) = action { document.cancel(owner:"ipad"); document.cancel(owner:"mac") }
        apply(InkCommand(epoch:snapshot.epoch,action:action),owner:"mac")
    }
    private func apply(_ incoming: InkCommand, owner: String) {
        guard !navigatingSlide else {
            let message = inkLocalized("Bitte den Folienwechsel abwarten.")
            if owner == "ipad" { server.send(.rejected(message)) } else { error = message }
            return
        }
        var command = incoming
        if case .visibility(false) = incoming.action {
            document.cancel(owner:"mac"); document.cancel(owner:"ipad")
        }
        // The Mac stamps style at the first sample, then freezes it for that stroke's lifetime.
        if owner == "ipad" {
            func styled(_ stroke: InkStroke) -> InkStroke? {
                settings.authoritativeStroke(stroke, active: document.active, display: snapshot.display)
            }
            switch incoming.action {
            case .preview(let stroke):
                guard let stroke = styled(stroke) else { server.send(.settingsRejected(inkLocalized("Werkzeug geändert. Bitte neu ansetzen."))); sendSettings(); return }
                command.action = .preview(stroke)
            case .commit(let stroke):
                guard let stroke = styled(stroke) else { document.cancel(owner: owner); publish(); server.send(.rejected(inkLocalized("Werkzeug geändert. Bitte neu ansetzen."))); sendSettings(); return }
                command.action = .commit(stroke)
            default: break
            }
        }
        let previousRevision = document.snapshot.revision
        guard document.apply(command,owner:owner) else {
            // A rejected commit must not leave this device holding an invisible stroke lease.
            if command.epoch == snapshot.epoch { document.cancel(owner:owner); publish() }
            let message = inkLocalized("Zeichenfläche geändert, belegt oder Größenlimit erreicht. Bitte neu ansetzen.")
            if owner == "ipad" {
                server.send(.rejected(message)); server.send(.snapshot(snapshot)); server.send(.preview(active))
            } else { error = message }
            return
        }
        guard document.snapshot.revision != previousRevision else { return }
        publish()
        switch command.action {
        case .preview, .previewTransform: pendingPreview = true
        default: pendingSnapshot = true; pendingPreview = false
        }
    }
    func cancelLocal() { document.cancel(owner:"mac"); publish(); pendingPreview = true }
    private func publish() { snapshot = document.snapshot; active = document.active; onChange?() }
    func startServer() {
        do {
            try server.start(); token = server.token
            let digest = SHA256.hash(data: Data(token.utf8)).map { String(format: "%02x", $0) }.joined()
            if UserDefaults.standard.string(forKey: "preview-pairing-digest") != digest {
                previewPolicy = PreviewPolicy(); persistPreviewPolicy()
                UserDefaults.standard.set(digest, forKey: "preview-pairing-digest")
            }
        }
        catch { self.error = error.localizedDescription; token = "" }
    }
    func stopServer() { stopPreview(); server.stop(); token = "" }
    func resetPairing() {
        previewPolicy = PreviewPolicy(); persistPreviewPolicy()
        UserDefaults.standard.removeObject(forKey: "preview-pairing-digest")
        stopPreview()
        do { try server.resetPairing(); token = ""; startServer() }
        catch { self.error = error.localizedDescription }
    }
    private func setPreviewStatus(_ status: PreviewStatus) {
        previewPhase = status; previewStatus = status.title; server.previewStatus(status)
    }
    func declinePreview() { stopPreview(); previewRequested = false; setPreviewStatus(.paused(inkLocalized("Die Bildschirmfreigabe wurde am Mac nicht bestätigt."))) }
    func startPreview() {
        guard connected, !sharing else { return }
        previewPausedByUser = false; UserDefaults.standard.set(false, forKey: "preview-paused-by-user")
        previewRequested = false; error = nil; firstFrameReceived = false
        sharing = true; setPreviewStatus(.starting)
        let generation = UUID(); previewGeneration = generation
        let sourceEpoch = snapshot.sourceEpoch
        Task { @MainActor [self] in
            do {
                try await capture.start(displayID:displayID,sourceEpoch:sourceEpoch)
                guard previewGeneration == generation else { return }
                setPreviewStatus(.live)
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
                    guard let self, self.previewGeneration == generation, self.sharing, !self.firstFrameReceived else { return }
                    let message = inkLocalized("Es kommen keine Bildschirmbilder an. Bildschirmaufnahmezugriff und ausgewähltes Display prüfen.")
                    self.error = message; self.stopPreview(status: .failed(message))
                }
            } catch {
                guard previewGeneration == generation else { return }
                self.error = inkLocalized("Bildschirmvorschau: %@", String(describing: (error.localizedDescription))); stopPreview(status: .failed(error.localizedDescription))
            }
        }
    }
    func stopPreview(status: PreviewStatus = .paused(inkLocalized("Am iPad auf ‚Mac-Bildschirm anzeigen‘ tippen oder am Mac freigeben."))) {
        previewGeneration = UUID(); sharing = false; previewRequested = false
        setPreviewStatus(status)
        Task { @MainActor in await capture.stop() }
    }
    func setPreviewTrust(_ trusted: Bool) {
        guard !token.isEmpty else { return }
        previewPolicy.trusted = trusted
        if !trusted { previewPolicy.autoStart = false; stopPreview() }
        persistPreviewPolicy()
    }
    func setPreviewAutoStart(_ enabled: Bool) {
        previewPolicy.autoStart = enabled && previewPolicy.trusted
        persistPreviewPolicy()
    }
    private func persistPreviewPolicy() {
        if let data = try? JSONEncoder().encode(previewPolicy) { UserDefaults.standard.set(data, forKey: "preview-policy-v1") }
    }
    func pausePreview() {
        previewPausedByUser = true; UserDefaults.standard.set(true, forKey: "preview-paused-by-user")
        stopPreview()
    }
    func sendSettings() { server.send(.drawingSettings(DrawingSyncState(revision: settingsRevision, library: library))) }
    func updateSettings(_ settings: DrawingSettings) throws {
        guard active == nil else { throw AutomationFailure.unavailable(inkLocalized("Erst den aktuellen Strich beenden.")) }
        guard settings.valid else { throw AutomationFailure.invalid(inkLocalized("Farben, Breiten oder Werkzeugreihenfolge ungültig. Breiten: 0,5–100 pt, Deckkraft: 5 bis 100 Prozent. Drei Schnellstärken müssen im Werkzeugbereich liegen.")) }
        guard settings != library.current else { return }
        var next = library; next.current = settings
        var previousStyle = library.current; previousStyle.tool = settings.tool
        if previousStyle != settings { next.activeProfile = nil }
        try commitLibrary(next)
    }
    func insertText(_ text: String, at point: InkPoint, expectedEpoch: UUID? = nil) throws {
        guard expectedEpoch == nil || expectedEpoch == snapshot.epoch else { throw AutomationFailure.unavailable(inkLocalized("Die Zeichenfläche wurde inzwischen geändert. Text neu platzieren.")) }
        guard active == nil else { throw AutomationFailure.unavailable(inkLocalized("Erst den aktuellen Strich beenden.")) }
        let stroke = try settings.textStroke(text, at: point, display: snapshot.display)
        if !snapshot.overlayVisible { command(.visibility(true)) }
        let previous = snapshot.revision
        command(.commit(stroke))
        guard snapshot.revision != previous else { throw AutomationFailure.unavailable(error ?? inkLocalized("Text konnte nicht eingefügt werden.")) }
    }
    func selectDrawing(_ selection: DrawingSelection) throws {
        guard active == nil else { throw AutomationFailure.unavailable(inkLocalized("Erst den aktuellen Strich beenden.")) }
        if let profile = selection.profile { try useProfile(profile); return }
        try updateSettings(selection.applying(to: settings))
    }
    func useProfile(_ name: String) throws {
        guard active == nil else { throw AutomationFailure.unavailable(inkLocalized("Erst den aktuellen Strich beenden.")) }
        guard let profile = library.profiles.first(where: { $0.name == name }) else { throw AutomationFailure.invalid(inkLocalized("Unbekanntes Profil: %@.", String(describing: (name)))) }
        var next = library; next.current = profile.settings; next.activeProfile = name
        try commitLibrary(next)
    }
    func saveProfile(_ name: String, settings: DrawingSettings) throws {
        guard active == nil else { throw AutomationFailure.unavailable(inkLocalized("Erst den aktuellen Strich beenden.")) }
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var next = library
        next.profiles.removeAll { $0.name == name }
        next.profiles.append(DrawingProfile(name: name, settings: settings))
        next.current = settings; next.activeProfile = name
        try commitLibrary(next)
    }
    private func commitLibrary(_ next: DrawingLibrary) throws {
        try preferences.save(next)
        library = next; settingsRevision &+= 1
        onSettingsChange?(); sendSettings()
    }
    func sendDrawerVisibility(_ visible: Bool) {
        macDrawerVisible = visible
        server.send(.macDrawerVisible(visible))
    }
    func shutdown() { timer?.invalidate(); stopServer() }
}


/// Native presentation commands work inside App Sandbox with narrowly scoped
/// Apple-event exceptions; no System Events or global keyboard injection.
final class MacSlideNavigation {
    private let identifiers = Set(["com.apple.iWork.Keynote", "com.apple.Keynote", "com.microsoft.Powerpoint"])
    private var lastTarget: NSRunningApplication?
    private var lastSent = -Double.infinity
    func observeFrontmost() {
        if let app = NSWorkspace.shared.frontmostApplication, identifiers.contains(app.bundleIdentifier ?? "") { lastTarget = app }
    }
    func navigate(_ direction: SlideDirection) throws -> Bool {
        observeFrontmost()
        let apps = NSWorkspace.shared.runningApplications.filter { identifiers.contains($0.bundleIdentifier ?? "") }
        guard let target = (lastTarget?.isTerminated == false ? lastTarget : nil) ?? (apps.count == 1 ? apps.first : nil), let identifier = target.bundleIdentifier else {
            throw AutomationFailure.unavailable(inkLocalized("Bitte Keynote oder PowerPoint am Mac in den Vordergrund bringen und die Präsentation starten."))
        }
        let now = ProcessInfo.processInfo.systemUptime
        guard now-lastSent > 0.2 else { return false }; lastSent = now
        let command: String
        if identifier == "com.microsoft.Powerpoint" {
            command = "go to \(direction == .next ? "next" : "previous") slide (slideshow view of slide show window 1)"
        } else {
            command = "if not playing then error \"Start the slideshow first.\"\nshow \(direction == .next ? "next" : "previous")"
        }
        let source = "with timeout of 5 seconds\ntell application id \"\(identifier)\"\n\(command)\nend tell\nend timeout"
        guard let script = NSAppleScript(source:source) else { throw AutomationFailure.unavailable(inkLocalized("Foliensteuerung fehlgeschlagen.")) }
        var details: NSDictionary?
        _ = script.executeAndReturnError(&details)
        if let details {
            let message = details[NSAppleScript.errorMessage] as? String ?? inkLocalized("Foliensteuerung fehlgeschlagen.")
            throw AutomationFailure.unavailable(inkLocalized("Foliensteuerung: %@. PresentInk bei Bedarf unter Datenschutz & Sicherheit → Automation erlauben.",message))
        }
        return true
    }
}
