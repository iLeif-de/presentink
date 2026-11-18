import Foundation
import Network
import PresentInkCore
import PresentInkLink

final class CompanionServer {
    var onSettingsApplied: ((UInt64) -> Void)?
    var onDrawingSelection: ((DrawingSelection) -> Void)?
    var onCommand: ((InkCommand) -> Void)?
    var onConnect: (() -> Void)?
    var onDrawerVisibilityRequest: ((Bool) -> Void)?
    var onSlideNavigation: ((SlideDirection, UUID) -> Void)?
    var onPreviewRequest: (() -> Void)?
    var onDisconnect: (() -> Void)?
    var onStatus: ((String) -> Void)?
    private var listener: NWListener?
    private var pending: [UUID:SecurePeer] = [:]
    private var control: SecurePeer?
    private var video: SecurePeer?
    private var client: UUID?
    private var relay = PreviewRelay()
    private var heartbeat: Timer?
    private var lastControlMessage = ProcessInfo.processInfo.systemUptime
    private let pairing = PairingRepository()
    private(set) var token = ""
    var connected: Bool { control != nil }
    func start() throws {
        stop(); token = try pairing.hostKey()
        let listener = try NWListener(using: PairingKey.parameters(token: token))
        self.listener = listener
        listener.service = NWListener.Service(name: "PresentInk · \(Host.current().localizedName ?? "Mac")", type: WireMessage.serviceType)
        listener.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready: self.onStatus?(inkLocalized("Bereit für iPad · lokales Netzwerk"))
            case .failed(let error): self.stop(); self.onStatus?(error.localizedDescription)
            default: break
            }
        }
        listener.newConnectionHandler = { [weak self] connection in self?.accept(connection) }
        listener.start(queue:.main)
    }
    private func accept(_ connection: NWConnection) {
        guard pending.count < 4 else { connection.cancel(); return }
        let peer = SecurePeer(connection:connection); pending[peer.id] = peer
        peer.onMessage = { [weak self, weak peer] message in
            guard let self, let peer else { return }; self.receive(message, from:peer)
        }
        peer.onClose = { [weak self, weak peer] _ in
            guard let self, let peer else { return }
            self.pending[peer.id] = nil
            if self.control === peer {
                self.heartbeat?.invalidate(); self.heartbeat = nil
                self.control = nil; self.client = nil
                let oldVideo = self.video; self.video = nil; oldVideo?.close()
                self.onDisconnect?(); self.onStatus?(inkLocalized("iPad getrennt · erneutes Verbinden möglich"))
            }
            if self.video === peer { self.video = nil }
        }
        peer.start()
        DispatchQueue.main.asyncAfter(deadline:.now()+15) { [weak self, weak peer] in
            guard let self, let peer, self.pending[peer.id] != nil else { return }
            peer.close(inkLocalized("Protokoll-Handshake abgelaufen."))
        }
    }
    private func receive(_ message: WireMessage, from peer: SecurePeer) {
        if pending[peer.id] != nil {
            guard case .hello(let version, let id, let channel) = message, version == WireMessage.version else { peer.close(inkLocalized("Nicht unterstützte Protokollversion.")); return }
            switch channel {
            case .control:
                guard control == nil else { peer.close(inkLocalized("Bereits ein iPad verbunden.")); return }
                pending[peer.id] = nil; client = id; control = peer
                lastControlMessage = ProcessInfo.processInfo.systemUptime
                heartbeat?.invalidate()
                heartbeat = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
                    guard let self else { return }
                    if ProcessInfo.processInfo.systemUptime - self.lastControlMessage > 12 {
                        self.control?.close(inkLocalized("iPad antwortet nicht. Erneutes Verbinden möglich."))
                    }
                }
                onStatus?(inkLocalized("iPad verbunden · TLS verschlüsselt")); onConnect?()
            case .video:
                guard client == id, control != nil, video == nil else { peer.close(inkLocalized("Zuerst Steuerverbindung herstellen.")); return }
                pending[peer.id] = nil; video = peer
                for message in relay.subscriberMessages { video?.send(message) }
            }
            return
        }
        guard control === peer else { return }
        lastControlMessage = ProcessInfo.processInfo.systemUptime
        switch message {
        case .settingsApplied(let revision): onSettingsApplied?(revision)
        case .selectDrawing(let selection): onDrawingSelection?(selection)
        case .command(let command): onCommand?(command)
        case .setMacDrawerVisible(let visible): onDrawerVisibilityRequest?(visible)
        case .navigateSlide(let direction, let request): onSlideNavigation?(direction,request)
        case .requestPreview: onPreviewRequest?()
        case .ping(let id): peer.send(.pong(id))
        default: peer.close(inkLocalized("Unerwartete Nachricht."))
        }
    }
    func send(_ message: WireMessage, replaceable: Bool = false) {
        if !replaceable { control?.discardReplaceable() }
        control?.send(message, replaceable: replaceable)
    }
    func sendVideo(_ frame: VideoFrame) {
        relay.cache(frame)
        if relay.status.isStreaming { video?.send(.frame(frame), replaceable:true) }
    }
    func previewStatus(_ status: PreviewStatus) {
        relay.setStatus(status); video?.discardReplaceable()
        video?.send(.previewStatus(relay.update)); control?.send(.previewStatus(relay.update))
        if status.isStreaming, let frame = relay.latestFrame { video?.send(.frame(frame), replaceable:true) }
    }
    func resetPairing() throws { stop(); try pairing.rotateHostKey() }
    func stop() {
        heartbeat?.invalidate(); heartbeat = nil
        listener?.stateUpdateHandler = nil; listener?.newConnectionHandler = nil; listener?.cancel(); listener = nil
        let peers = Array(pending.values) + [control,video].compactMap { $0 }
        pending.removeAll(); control = nil; video = nil; client = nil
        for peer in peers { peer.onClose = nil; peer.close() }
        token = ""; relay = PreviewRelay(); onDisconnect?(); onStatus?(inkLocalized("Companion-Verbindung aus"))
    }
}
