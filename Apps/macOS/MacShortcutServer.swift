import AppKit
import Network
import PresentInkCore
import PresentInkLink

/// Keeps native Shortcuts out of the GUI process when the app is stopped.
final class MacShortcutServer {
    private var listener: NWListener?
    private var peers: [UUID:ShortcutRPCPeer] = [:]
    private var store: ShortcutEndpointStore?
    func start() {
        do {
            guard let group = Bundle.main.object(forInfoDictionaryKey:"PresentInkShortcutsKeychainGroup") as? String else {
                throw AutomationFailure.unavailable(inkLocalized("Kurzbefehle-Verbindung ist nicht konfiguriert."))
            }
            let store = ShortcutEndpointStore(group:group); self.store = store
            let token = PairingKey.generate()
            let parameters = try PairingKey.parameters(token:token)
            parameters.requiredLocalEndpoint = .hostPort(host:"127.0.0.1",port:.any)
            let listener = try NWListener(using:parameters); self.listener = listener
            listener.stateUpdateHandler = { [weak self] state in
                guard let self else { return }
                if case .ready = state, let port = listener.port {
                    do { try store.write(ShortcutEndpoint(pid:ProcessInfo.processInfo.processIdentifier,port:port.rawValue,token:token)) }
                    catch { self.stop(); MacAutomation.delegate?.session.error = inkLocalized("Kurzbefehle konnten nicht verbunden werden: %@", String(describing: (error.localizedDescription))) }
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                guard let self, self.peers.count < 8 else { connection.cancel(); return }
                let id = UUID(), peer = ShortcutRPCPeer(connection:connection)
                self.peers[id] = peer
                peer.onData = { data in
                    do {
                        let request = try JSONDecoder().decode(ShortcutRequest.self,from:data)
                        do {
                            let value = try MacAutomation.execute(request.operation,text:request.text,number:request.number,
                                clearExisting:request.clearExisting,confirmed:request.confirmed,positionX:request.positionX,positionY:request.positionY)
                            peer.send(ShortcutReply(id:request.id,value:value),closeAfterSending:true)
                        } catch { peer.send(ShortcutReply(id:request.id,error:error.localizedDescription),closeAfterSending:true) }
                    } catch { peer.close(inkLocalized("Ungültiger Auftrag.")) }
                }
                peer.onClose = { [weak self] _ in self?.peers[id] = nil }
                peer.start()
            }
            listener.start(queue:.main)
        } catch { MacAutomation.delegate?.session.error = inkLocalized("Kurzbefehle konnten nicht verbunden werden: %@", String(describing: (error.localizedDescription))) }
    }
    func stop() {
        listener?.stateUpdateHandler = nil; listener?.newConnectionHandler = nil; listener?.cancel(); listener = nil
        let peers = Array(peers.values); self.peers.removeAll()
        for peer in peers { peer.onClose = nil; peer.close(inkLocalized("App beendet.")) }
        store?.remove(pid:ProcessInfo.processInfo.processIdentifier)
    }
}
