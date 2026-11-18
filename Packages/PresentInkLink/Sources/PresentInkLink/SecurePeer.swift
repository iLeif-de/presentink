import PresentInkCore
import Foundation
import Network
import Security
import CryptoKit

public enum PairingKey {
    public static func generate() -> String { UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased() }
    public static func normalized(_ string: String) -> String { string.lowercased().filter { !$0.isWhitespace && $0 != "-" } }
    public static func isValid(_ token: String) -> Bool {
        let token = normalized(token)
        return token.count == 32 && token.allSatisfy { $0.isHexDigit && $0.isASCII }
    }
    public static func parameters(token: String) throws -> NWParameters {
        let token = normalized(token)
        guard isValid(token) else { throw LinkError.invalidToken }
        let tls = NWProtocolTLS.Options()
        // High-entropy pairing key, stored in the app keychain. TLS-PSK authenticates both ends without a self-signed-cert bypass.
        let secret = Data(SHA256.hash(data: Data(("PresentInk-v1:" + token).utf8)))
        let identity = Data("PresentInk-v1".utf8)
        secret.withUnsafeBytes { key in
            identity.withUnsafeBytes { id in
                sec_protocol_options_add_pre_shared_key(tls.securityProtocolOptions, DispatchData(bytes: key) as __DispatchData, DispatchData(bytes: id) as __DispatchData)
            }
        }
        sec_protocol_options_set_min_tls_protocol_version(tls.securityProtocolOptions, .TLSv12)
        sec_protocol_options_set_max_tls_protocol_version(tls.securityProtocolOptions, .TLSv12)
        sec_protocol_options_append_tls_ciphersuite(tls.securityProtocolOptions, tls_ciphersuite_t(rawValue: 0x00A8)!)
        let tcp = NWProtocolTCP.Options(); tcp.noDelay = true
        let parameters = NWParameters(tls: tls, tcp: tcp)
        parameters.includePeerToPeer = true
        return parameters
    }
}

/// All state and callbacks are confined to the main queue. Video encoding occurs outside this class.
public final class SecurePeer {
    public let id = UUID()
    public var onMessage: ((WireMessage) -> Void)?
    public var onReady: (() -> Void)?
    public var onClose: ((String) -> Void)?
    private let connection: NWConnection
    private var decoder = FrameDecoder()
    private var closed = false
    private var pendingBytes = 0
    private var snapshotInFlight = false
    private var latestSnapshot: WireMessage?
    private var replaceableInFlight = false
    private var latestReplaceable: WireMessage?
    private var deadline: DispatchWorkItem?
    public init(connection: NWConnection) { self.connection = connection }
    public func start() {
        let timeout = DispatchWorkItem { [weak self] in self?.close(inkLocalized("Verbindungsaufbau abgelaufen. Schlüssel und Netzwerk prüfen.")) }
        deadline = timeout; DispatchQueue.main.asyncAfter(deadline: .now()+12, execute: timeout)
        connection.stateUpdateHandler = { [weak self] state in
            guard let self, !self.closed else { return }
            switch state {
            case .ready: self.deadline?.cancel(); self.onReady?(); self.receive()
            case .failed(let error): self.close(error.localizedDescription)
            case .waiting(let error): self.close(inkLocalized("Netzwerk nicht erreichbar: %@", String(describing: (error.localizedDescription))))
            case .cancelled: self.close(inkLocalized("Verbindung beendet."))
            default: break
            }
        }
        connection.start(queue: .main)
    }
    public func send(_ message: WireMessage, replaceable: Bool = false) {
        guard !closed else { return }
        let isSnapshot: Bool
        if case .snapshot = message { isSnapshot = true } else { isSnapshot = false }
        if isSnapshot && snapshotInFlight { latestSnapshot = message; return }
        if replaceable && replaceableInFlight { latestReplaceable = message; return }
        do {
            let bytes = try FrameDecoder.encode(JSONEncoder().encode(message))
            guard pendingBytes + bytes.count <= FrameDecoder.maximumLength * 2 else { close(inkLocalized("Verbindung überlastet. Bitte neu verbinden.")); return }
            pendingBytes += bytes.count
            if isSnapshot { snapshotInFlight = true }
            if replaceable { replaceableInFlight = true }
            connection.send(content: bytes, completion: .contentProcessed { [weak self] error in
                guard let self, !self.closed else { return }
                self.pendingBytes -= bytes.count
                if let error { self.close(error.localizedDescription); return }
                if isSnapshot {
                    self.snapshotInFlight = false
                    if let latest = self.latestSnapshot { self.latestSnapshot = nil; self.send(latest) }
                }
                if replaceable {
                    self.replaceableInFlight = false
                    if let latest = self.latestReplaceable { self.latestReplaceable = nil; self.send(latest, replaceable: true) }
                }
            })
        } catch { close(error.localizedDescription) }
    }
    public func discardReplaceable() { latestReplaceable = nil }
    private func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64*1024) { [weak self] bytes, _, done, error in
            guard let self, !self.closed else { return }
            do {
                if let bytes { for data in try self.decoder.append(bytes) { self.onMessage?(try JSONDecoder().decode(WireMessage.self, from: data)) } }
            } catch { self.close(inkLocalized("Ungültiges Protokoll: %@", String(describing: (error.localizedDescription)))); return }
            if let error { self.close(error.localizedDescription) }
            else if done { self.close(inkLocalized("Gegenstelle hat die Verbindung beendet.")) }
            else { self.receive() }
        }
    }
    public func close(_ reason: String = inkLocalized("Verbindung beendet.")) {
        guard !closed else { return }; closed = true
        deadline?.cancel(); latestReplaceable = nil; latestSnapshot = nil
        connection.stateUpdateHandler = nil; connection.cancel()
        let callback = onClose; onMessage = nil; onReady = nil; onClose = nil
        callback?(reason)
    }
}
