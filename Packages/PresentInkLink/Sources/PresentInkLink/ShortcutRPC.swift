import Foundation
import Network
import Security
import PresentInkCore

/// A session-only rendezvous shared only with our signed Shortcuts extension. Never shares iPad keys.
public final class ShortcutEndpointStore {
    private let group: String
    public init(group: String) { self.group = group }
    private var query: [String:Any] {
        [kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:"de.presentink.shortcuts.runtime",
         kSecAttrAccount as String:"current",kSecAttrAccessGroup as String:group,kSecUseDataProtectionKeychain as String:true]
    }
    public func read() throws -> ShortcutEndpoint? {
        var q = query; q[kSecReturnData as String] = true; q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?; let status = SecItemCopyMatching(q as CFDictionary,&result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw PairingStorageError(status:status) }
        return try JSONDecoder().decode(ShortcutEndpoint.self,from:data)
    }
    public func write(_ endpoint: ShortcutEndpoint) throws {
        let data = try JSONEncoder().encode(endpoint)
        let attributes: [String:Any] = [kSecValueData as String:data]
        var status = SecItemUpdate(query as CFDictionary,attributes as CFDictionary)
        if status == errSecItemNotFound { status = SecItemAdd(query.merging(attributes) { _,new in new } as CFDictionary,nil) }
        guard status == errSecSuccess else { throw PairingStorageError(status:status) }
    }
    public func remove(pid: Int32) {
        guard let endpoint = try? read(), endpoint.pid == pid else { return }
        SecItemDelete(query as CFDictionary)
    }
}

/// One authenticated request and reply, confined to the main queue. No Bonjour or remote interface.
public final class ShortcutRPCPeer {
    public var onReady: (() -> Void)?
    public var onData: ((Data) -> Void)?
    public var onClose: ((String) -> Void)?
    private let connection: NWConnection
    private var decoder = FrameDecoder()
    private var received = false
    private var closed = false
    private var deadline: DispatchWorkItem?
    public init(connection: NWConnection) { self.connection = connection }
    public func start() {
        let deadline = DispatchWorkItem { [weak self] in self?.close(inkLocalized("PresentInk antwortet nicht. App prüfen und erneut versuchen.")) }
        self.deadline = deadline; DispatchQueue.main.asyncAfter(deadline:.now()+5,execute:deadline)
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .ready: self.onReady?(); self.receive()
            case .failed, .waiting: self.close(inkLocalized("Die laufende PresentInk-App ist nicht erreichbar."))
            case .cancelled: self.close(inkLocalized("Verbindung beendet."))
            default: break
            }
        }
        connection.start(queue:.main)
    }
    public func send<T: Encodable>(_ value: T, closeAfterSending: Bool = false) {
        do {
            let data = try JSONEncoder().encode(value)
            guard data.count <= 256_000 else { close(inkLocalized("Kurzbefehle-Nachricht zu groß.")); return }
            connection.send(content:try FrameDecoder.encode(data),completion:.contentProcessed { [weak self] error in
                if error != nil || closeAfterSending { self?.close(inkLocalized("Verbindung beendet.")) }
            })
        } catch { close(error.localizedDescription) }
    }
    private func receive() {
        connection.receive(minimumIncompleteLength:1,maximumLength:32_768) { [weak self] bytes,_,done,error in
            guard let self, !self.closed else { return }
            do {
                if let bytes {
                    for data in try self.decoder.append(bytes) {
                        guard !self.received, data.count <= 256_000 else { self.close(inkLocalized("Ungültige Kurzbefehle-Nachricht.")); return }
                        self.received = true; self.onData?(data)
                    }
                }
            } catch { self.close(inkLocalized("Ungültige Kurzbefehle-Nachricht.")); return }
            if done || error != nil { self.close(inkLocalized("Verbindung beendet.")) }
            else { self.receive() }
        }
    }
    public func close(_ reason: String) {
        guard !closed else { return }; closed = true
        deadline?.cancel(); connection.stateUpdateHandler = nil; connection.cancel()
        let callback = onClose; onClose = nil; onReady = nil; onData = nil; callback?(reason)
    }
}

@MainActor public final class ShortcutRPCClient {
    private var peer: ShortcutRPCPeer?
    private var continuation: CheckedContinuation<String,Error>?
    public init() {}
    public func request(_ request: ShortcutRequest, endpoint: ShortcutEndpoint) async throws -> String {
        let parameters = try PairingKey.parameters(token:endpoint.token)
        let connection = NWConnection(host:"127.0.0.1",port:NWEndpoint.Port(rawValue:endpoint.port)!,using:parameters)
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let peer = ShortcutRPCPeer(connection:connection); self.peer = peer
            peer.onReady = { peer.send(request) }
            peer.onData = { [weak self] data in
                do {
                    let reply = try JSONDecoder().decode(ShortcutReply.self,from:data)
                    guard reply.id == request.id else { throw AutomationFailure.unavailable(inkLocalized("Falsche Antwort der App.")) }
                    if let error = reply.error { throw AutomationFailure.unavailable(error) }
                    guard let value = reply.value else { throw AutomationFailure.unavailable(inkLocalized("Leere Antwort der App.")) }
                    self?.finish(.success(value))
                } catch { self?.finish(.failure(error)) }
            }
            peer.onClose = { [weak self] message in self?.finish(.failure(AutomationFailure.unavailable(message))) }
            peer.start()
        }
    }
    private func finish(_ result: Result<String,Error>) {
        let continuation = self.continuation; self.continuation = nil
        let peer = self.peer; self.peer = nil; peer?.onClose = nil; peer?.close("Fertig.")
        continuation?.resume(with:result)
    }
}
