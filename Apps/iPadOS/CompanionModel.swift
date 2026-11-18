import SwiftUI
import Network
import PresentInkCore
import PresentInkLink

struct TextPlacement: Identifiable {
    let id = UUID()
    let point: InkPoint
    let epoch: UUID
    var original: InkStroke? = nil
}

struct DiscoveredMac: Identifiable {
    let id: String
    let name: String
    let endpoint: NWEndpoint
}

final class CompanionModel: ObservableObject {
    @Published var hosts: [DiscoveredMac] = []
    var finishText: (() -> Bool)?
    var cancelText: (() -> Void)?
    @Published var textPlacement: TextPlacement?
    @Published var token = ""
    @Published var status = inkLocalized("Nicht verbunden")
    @Published var error: String?
    @Published private(set) var macDrawerVisible: Bool?
    @Published private(set) var connected = false
    @Published private(set) var connecting = false
    @Published private(set) var snapshot = InkSnapshot()
    @Published private(set) var remoteActive: InkStroke?
    @Published private(set) var draft: InkStroke?
    @Published private(set) var pending: [InkStroke] = []
    @Published private(set) var image: UIImage?
    @Published private(set) var previewState: PreviewStatus = .paused(inkLocalized("Mac verbinden und Bildschirmvorschau anfordern."))
    var previewStatus: String { previewState.title }
    @Published private(set) var trustedHosts: [TrustedMac] = []
    @Published private(set) var rtt: Int?
    @Published private(set) var lastFrame: Date?
    @Published private(set) var drawingState: DrawingSyncState?
    @Published private var demoSettings = DrawingSettings()
    var settings: DrawingSettings { drawingState?.settings ?? demoSettings }
    var tool: InkTool {
        get { settings.tool }
        set { selectDrawing(DrawingSelection(tool: newValue)) }
    }
    var color: InkColor {
        get { settings.currentStyle.color }
        set { selectDrawing(DrawingSelection(color: newValue)) }
    }
    var width: Double {
        get { settings.currentStyle.width }
        set { selectDrawing(DrawingSelection(width: newValue)) }
    }
    func selectDrawing(_ selection: DrawingSelection) {
        guard finishText?() != false else { return }
        if connected, drawingState != nil { control?.send(.selectDrawing(selection)) }
        else if demo {
            do { demoSettings = try selection.applying(to: demoSettings) }
            catch { self.error = error.localizedDescription }
        }
    }
    @Published var constrainShapes = false
    @Published var demo = true
    @Published var showTools = true
    @Published private(set) var navigatingSlide = false
    private var navigationRequest: UUID?
    var canNavigateSlide: Bool { connected && draft == nil && pending.isEmpty && remoteActive == nil && textPlacement == nil && !navigatingSlide }
    var canClearAnnotations: Bool { drawable && !snapshot.strokes.isEmpty && draft == nil && pending.isEmpty && remoteActive == nil && textPlacement == nil && !navigatingSlide }
    func clearAnnotations() {
        guard canClearAnnotations else { return }
        action(.clear)
    }
    private let pairing = PairingRepository()
    private var connectingHost: DiscoveredMac?
    private var connectionKey = ""
    private var allowAutoReconnect = true
    private var browser: NWBrowser?
    private var control: SecurePeer?
    private var video: SecurePeer?
    private var endpoint: NWEndpoint?
    private var clientID = UUID()
    private var manipulation: InkManipulation?
    private var previousTool: InkTool = .pen
    private var lastPreviewSent = 0.0
    private var timer: Timer?
    private var lastPong = Date()
    private var lastSequence: UInt64 = 0
    private var localDocument = InkDocument()
    private let decodeQueue = DispatchQueue(label:"de.presentink.companion.jpeg",qos:.userInitiated)
    private var decodeBusy = false
    private var acceptFrames = false
    private var lastPreviewRevision: UInt64?
    private var previewGeneration = UUID()
    private var generation = UUID()
    init() {
        do { trustedHosts = try pairing.trustedMacs() }
        catch { self.error = error.localizedDescription }
    }
    func isTrusted(_ host: DiscoveredMac) -> Bool { trustedHosts.contains { $0.id == host.id } }
    func forgetHost(_ id: String) {
        do {
            try pairing.forget(id: id); trustedHosts = try pairing.trustedMacs(); token = ""
            if connectingHost?.id == id { disconnect() }
        } catch { self.error = error.localizedDescription }
    }
    private func reconnectIfPossible() {
        guard allowAutoReconnect, !connected, !connecting, let preferred = trustedHosts.first,
              let host = hosts.first(where: { $0.id == preferred.id }) else { return }
        allowAutoReconnect = false; connect(to: host)
    }
    func setMacDrawerVisible(_ visible: Bool) {
        guard connected, macDrawerVisible != nil else { return }
        // Keep the Mac as the authority; the switch updates when its acknowledgement arrives.
        control?.send(.setMacDrawerVisible(visible))
    }
    func requestPreview() {
        guard connected else { return }
        if video == nil { startVideo() }
        if !previewState.isStreaming { previewState = .awaitingApproval }
        control?.send(.requestPreview)
    }
    var drawable: Bool { (connected && drawingState != nil) || demo }
    var strokesToDraw: [InkStroke] {
        var list = snapshot.strokes
        for stroke in [remoteActive].compactMap({ $0 }) + pending + [draft].compactMap({ $0 }) {
            if let index = list.firstIndex(where: { $0.id == stroke.id }) { list[index] = stroke }
            else { list.append(stroke) }
        }
        return list
    }
    func navigateSlide(_ direction: SlideDirection) {
        guard canNavigateSlide else { return }
        let request = UUID(); navigationRequest = request; navigatingSlide = true
        control?.discardReplaceable()
        control?.send(.navigateSlide(direction,request:request))
        DispatchQueue.main.asyncAfter(deadline:.now()+10) { [weak self] in
            guard let self, self.navigationRequest == request else { return }
            self.navigationRequest = nil; self.navigatingSlide = false
            self.error = inkLocalized("Keine Bestätigung des Folienwechsels erhalten. Verbindung und Präsentation prüfen.")
        }
    }
    func browse() {
        guard browser == nil else { return }
        allowAutoReconnect = true
        let browser = NWBrowser(for:.bonjour(type:WireMessage.serviceType,domain:nil),using:.tcp)
        self.browser = browser
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            self?.hosts = results.compactMap { result in
                guard case .service(let name,let type,let domain,_) = result.endpoint else { return nil }
                return DiscoveredMac(id:"\(name).\(type).\(domain)",name:name,endpoint:result.endpoint)
            }.sorted { $0.name < $1.name }
            self?.reconnectIfPossible()
        }
        browser.stateUpdateHandler = { [weak self] state in
            if case .failed(let error) = state { self?.error = "Mac-Suche: \(error.localizedDescription)" }
        }
        browser.start(queue:.main)
    }
    private var reconnectDeadline = Date.distantPast
    func connect(to host: DiscoveredMac, automatic: Bool = false) {
        if !automatic { reconnectDeadline = Date().addingTimeInterval(30) }
        let key = PairingKey.normalized(token).isEmpty ? (trustedHosts.first(where: { $0.id == host.id })?.key ?? "") : token
        disconnect()
        do {
            let params = try PairingKey.parameters(token:key)
            connectionKey = PairingKey.normalized(key); connectingHost = host
            demo = false; connecting = true; generation = UUID(); endpoint = host.endpoint
            let peer = SecurePeer(connection:NWConnection(to:host.endpoint,using:params)); control = peer
            let current = generation
            status = inkLocalized("Verbinde mit %@ …", String(describing: (host.name)))
            peer.onReady = { [weak self] in
                guard let self, self.generation == current else { return }
                peer.send(.hello(version:WireMessage.version,client:self.clientID,channel:.control))
            }
            peer.onMessage = { [weak self] message in self?.receive(message) }
            peer.onClose = { [weak self] reason in
                guard let self, self.generation == current else { return }
                let retryHost = self.connectingHost
                self.disconnect(); self.status = inkLocalized("Verbindung getrennt"); self.error = reason
                if let retryHost {
                    self.allowAutoReconnect = true
                    guard Date() < self.reconnectDeadline else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now()+3) { [weak self] in
                        guard let self, self.allowAutoReconnect, !self.connected, !self.connecting else { return }
                        if let host = self.hosts.first(where: { $0.id == retryHost.id }) { self.connect(to: host, automatic: true) }
                    }
                }
            }
            peer.start()
        } catch { self.error = error.localizedDescription }
    }
    private func startVideo() {
        guard let endpoint, video == nil else { return }
        lastPreviewRevision = nil
        do {
            let peer = SecurePeer(connection:NWConnection(to:endpoint,using:try PairingKey.parameters(token:connectionKey)))
            video = peer
            peer.onReady = { [weak self] in
                guard let self else { return }; peer.send(.hello(version:WireMessage.version,client:self.clientID,channel:.video))
            }
            peer.onMessage = { [weak self] in self?.receive($0) }
            peer.onClose = { [weak self] reason in
                self?.image = nil; self?.acceptFrames = false; self?.previewGeneration = UUID()
                self?.previewState = .failed(inkLocalized("Videokanal getrennt: %@", String(describing: (reason)))); self?.video = nil
            }
            peer.start()
        } catch { self.error = error.localizedDescription }
    }
    private func receive(_ message: WireMessage) {
        switch message {
        case .snapshot(let state):
            guard state.valid else { control?.close(inkLocalized("Ungültiger Zeichenstatus.")); return }
            if state.epoch == snapshot.epoch, state.revision < snapshot.revision { return }
            if state.epoch != snapshot.epoch { textPlacement = nil; manipulation = nil; draft = nil; pending = []; remoteActive = nil }
            if state.sourceEpoch != snapshot.sourceEpoch {
                image = nil; lastFrame = nil; lastSequence = 0; previewGeneration = UUID()
            }
            snapshot = state
            pending.removeAll { item in state.strokes.contains(item) }
            if !connected {
                connected = true; connecting = false; status = inkLocalized("Mit Mac verbunden · TLS")
                if let host = connectingHost {
                    do {
                        try pairing.remember(id: host.id, name: host.name, key: connectionKey)
                        trustedHosts = try pairing.trustedMacs(); token = ""
                    } catch { self.error = inkLocalized("Verbunden, aber die Kopplung konnte nicht gemerkt werden: %@", String(describing: (error.localizedDescription))) }
                }
                lastPong = Date(); startVideo()
                timer = Timer.scheduledTimer(withTimeInterval:2,repeats:true) { [weak self] _ in
                    guard let self else { return }
                    guard Date().timeIntervalSince(self.lastPong) < 10 else { self.control?.close(inkLocalized("Mac antwortet nicht. Bitte erneut verbinden.")); return }
                    self.control?.send(.ping(DispatchTime.now().uptimeNanoseconds))
                }
            }
        case .drawingSettings(let state):
            guard state.valid else { control?.close(inkLocalized("Ungültige Zeichen-Einstellungen.")); return }
            if let previous = drawingState, state.revision < previous.revision { return }
            drawingState = state
            control?.send(.settingsApplied(state.revision))
        case .settingsRejected(let reason): error = reason
        case .slideNavigationFinished(let request, let state):
            guard request == navigationRequest else { return }
            receive(.snapshot(state)); navigationRequest = nil; navigatingSlide = false
        case .slideNavigationFailed(let request, let reason):
            guard request == navigationRequest else { return }
            navigationRequest = nil; navigatingSlide = false; error = reason
        case .macDrawerVisible(let visible): macDrawerVisible = visible
        case .preview(let stroke):
            guard stroke == nil || stroke?.valid == true else { return }; remoteActive = stroke
        case .frame(let frame):
            guard acceptFrames, frame.belongs(to:snapshot), frame.sequence > lastSequence, frame.jpeg.count <= 1_500_000, !decodeBusy else { return }
            lastSequence = frame.sequence; decodeBusy = true
            let current = generation, epoch = snapshot.sourceEpoch, preview = previewGeneration
            decodeQueue.async { [weak self] in
                let image = UIImage(data:frame.jpeg)
                DispatchQueue.main.async {
                    guard let self else { return }; self.decodeBusy = false
                    guard self.generation == current, self.snapshot.sourceEpoch == epoch, self.previewGeneration == preview, self.acceptFrames, self.connected else { return }
                    self.image = image; self.lastFrame = Date()
                }
            }
        case .previewStatus(let update):
            // Control and video are independent TCP streams; never apply an older phase over a newer one.
            if let previous = lastPreviewRevision, update.revision <= previous { return }
            lastPreviewRevision = update.revision
            let status = update.status
            previewState = status
            acceptFrames = status.isStreaming
            if !acceptFrames { previewGeneration = UUID() }
            if !acceptFrames { image = nil; lastFrame = nil }
        case .pong(let sent):
            let now = DispatchTime.now().uptimeNanoseconds
            if now >= sent { rtt = Int((now-sent)/1_000_000) }; lastPong = Date()
        case .rejected(let reason): manipulation = nil; draft = nil; pending = []; remoteActive = nil; error = reason
        default: break
        }
    }
    func begin(_ point: InkPoint) {
        guard drawable, !navigatingSlide, draft == nil, pending.isEmpty, remoteActive == nil else { return }
        if tool == .text { textPlacement = TextPlacement(point:point,epoch:snapshot.epoch); return }
        if tool == .eraser { action(.erase(point)); return }
        if let edit = InkManipulation.hit(snapshot.strokes,at:point,display:snapshot.display,tolerance:18) {
            manipulation = edit; draft = edit.original
        } else { draft = settings.stroke(at: point, display: snapshot.display) }
        sendPreview(force:true)
    }
    func editText(at point: InkPoint) -> Bool {
        guard drawable, draft == nil, pending.isEmpty, remoteActive == nil,
              let original = snapshot.strokes.reversed().first(where: { $0.tool == .text && InkGeometry.hits($0,at:point,display:snapshot.display) }) else { return false }
        textPlacement = TextPlacement(point:original.points[0],epoch:snapshot.epoch,original:original)
        return true
    }
    func insertText(_ text: String, placement: TextPlacement) throws {
        guard drawable, placement.epoch == snapshot.epoch, (tool == .text || placement.original != nil), draft == nil, pending.isEmpty, remoteActive == nil else {
            throw AutomationFailure.unavailable(inkLocalized("Zeichenfläche oder Werkzeug geändert/belegt. Bitte Text neu platzieren."))
        }
        if let original = placement.original {
            guard InkTextLayout.valid(text), snapshot.strokes.contains(original) else { throw AutomationFailure.unavailable(inkLocalized("Zeichenfläche oder Werkzeug geändert/belegt. Bitte Text neu platzieren.")) }
            action(.editText(original:original,text:text)); textPlacement = nil; return
        }
        let stroke = try settings.textStroke(text,at:placement.point,display:snapshot.display)
        if !snapshot.overlayVisible { action(.visibility(true)) }
        if connected { pending = [stroke] }
        action(.commit(stroke)); textPlacement = nil
    }
    func append(_ points: [InkPoint], shift: Bool = false) {
        guard drawable else { return }
        if tool == .eraser { for p in points.suffix(1) { action(.erase(p)) }; return }
        guard var stroke = draft else { return }
        if let manipulation, let last = points.last {
            draft = manipulation.updated(to:last,proportional:shift || constrainShapes); sendPreview(force:false); return
        }
        if stroke.tool.isShape, let first = stroke.points.first, let last = points.last {
            stroke.points = [first,InkGeometry.constrained(last,from:first,tool:stroke.tool,display:snapshot.display,shift:shift || constrainShapes)]
        } else { stroke.points.append(contentsOf:points.prefix(max(0,8_000-stroke.points.count))) }
        draft = stroke; sendPreview(force:false)
    }
    private func sendPreview(force: Bool) {
        guard let draft, connected else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard force || now-lastPreviewSent >= 1.0/30 else { return }; lastPreviewSent = now
        let action: InkAction = manipulation.map { .previewTransform(original:$0.original,replacement:draft) } ?? .preview(draft)
        control?.send(.command(InkCommand(epoch:snapshot.epoch,action:action)),replaceable:true)
    }
    func end() {
        guard let stroke = draft else { return }; draft = nil
        control?.discardReplaceable()
        if connected { pending = [stroke] }
        let command: InkAction = manipulation.map { .commitTransform(original:$0.original,replacement:stroke) } ?? .commit(stroke)
        manipulation = nil; action(command)
    }
    func cancel() {
        manipulation = nil; draft = nil; control?.discardReplaceable()
        if connected { action(.cancel) }
    }
    func action(_ action: InkAction) {
        if connected { control?.send(.command(InkCommand(epoch:snapshot.epoch,action:action))) }
        else if demo {
            _ = localDocument.apply(InkCommand(epoch:localDocument.snapshot.epoch,action:action),owner:"demo")
            snapshot = localDocument.snapshot
        }
    }
    func setTool(_ tool: InkTool) { guard finishText?() != false else { return }; cancel(); previousTool = self.tool; self.tool = tool }
    func pencilAction(_ preference: UIPencilPreferredAction) {
        switch preference {
        case .switchEraser: setTool(tool == .eraser ? (previousTool == .eraser ? .pen : previousTool) : .eraser)
        case .switchPrevious: let old = previousTool; setTool(old)
        case .showColorPalette, .showInkAttributes, .showContextualPalette: showTools.toggle()
        default: break
        }
    }
    func enableDemo() { disconnect(); demo = true; localDocument = InkDocument(); snapshot = localDocument.snapshot; status = inkLocalized("Lokale Testfläche · nicht am Mac") }
    func disconnect() {
        navigationRequest = nil; navigatingSlide = false
        allowAutoReconnect = false; connectingHost = nil; connectionKey = ""; lastPreviewRevision = nil
        generation = UUID(); previewGeneration = UUID(); acceptFrames = false; timer?.invalidate(); timer = nil
        let oldControl = control, oldVideo = video; control = nil; video = nil
        oldControl?.onClose = nil; oldVideo?.onClose = nil; oldControl?.close(); oldVideo?.close()
        textPlacement = nil
        drawingState = nil
        macDrawerVisible = nil
        connected = false; connecting = false; manipulation = nil; draft = nil; pending = []; remoteActive = nil
        image = nil; lastFrame = nil; rtt = nil; lastSequence = 0; snapshot = InkSnapshot()
        previewState = .paused(inkLocalized("Mac verbinden und Bildschirmvorschau anfordern.")); status = inkLocalized("Nicht verbunden"); demo = false
    }
    func suspend() { disconnect(); browser?.cancel(); browser = nil; hosts = [] }
}
