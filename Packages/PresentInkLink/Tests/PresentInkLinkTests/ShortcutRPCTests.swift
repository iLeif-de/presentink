import XCTest
import Network
import PresentInkCore
@testable import PresentInkLink

private final class ShortcutTestState: @unchecked Sendable {
    var server: ShortcutRPCPeer?
}
@MainActor final class ShortcutRPCTests: XCTestCase {
    func testAuthenticatedLocalRequestReply() async throws {
        let token = PairingKey.generate()
        let parameters = try PairingKey.parameters(token:token)
        parameters.requiredLocalEndpoint = .hostPort(host:"127.0.0.1",port:.any)
        let listener = try NWListener(using:parameters)
        let ready = expectation(description:"listener ready"), received = expectation(description:"request received")
        let state = ShortcutTestState()
        listener.stateUpdateHandler = { if case .ready = $0 { ready.fulfill() } }
        listener.newConnectionHandler = { connection in
            let peer = ShortcutRPCPeer(connection:connection); state.server = peer
            peer.onData = { data in
                do {
                    let request = try JSONDecoder().decode(ShortcutRequest.self,from:data)
                    XCTAssertEqual(request.operation,.getStatus); received.fulfill()
                    peer.send(ShortcutReply(id:request.id,value:"native output"),closeAfterSending:true)
                } catch { XCTFail(error.localizedDescription) }
            }
            peer.start()
        }
        listener.start(queue:.main)
        defer { listener.cancel(); state.server?.close("Test beendet.") }
        await fulfillment(of:[ready],timeout:3)
        let port = try XCTUnwrap(listener.port)
        let value = try await ShortcutRPCClient().request(ShortcutRequest(.getStatus),endpoint:ShortcutEndpoint(pid:1,port:port.rawValue,token:token))
        XCTAssertEqual(value,"native output")
        await fulfillment(of:[received],timeout:3)
    }
    func testWrongSessionKeyDoesNotDeliverARequest() async throws {
        let parameters = try PairingKey.parameters(token:PairingKey.generate())
        parameters.requiredLocalEndpoint = .hostPort(host:"127.0.0.1",port:.any)
        let listener = try NWListener(using:parameters)
        let ready = expectation(description:"listener ready")
        let state = ShortcutTestState()
        listener.stateUpdateHandler = { if case .ready = $0 { ready.fulfill() } }
        listener.newConnectionHandler = { connection in
            let peer = ShortcutRPCPeer(connection:connection); state.server = peer
            peer.onData = { _ in XCTFail("Request must not pass TLS authentication") }; peer.start()
        }
        listener.start(queue:.main)
        defer { listener.cancel(); state.server?.close("Test beendet.") }
        await fulfillment(of:[ready],timeout:3)
        do {
            _ = try await ShortcutRPCClient().request(ShortcutRequest(.getStatus),endpoint:ShortcutEndpoint(pid:1,port:try XCTUnwrap(listener.port).rawValue,token:PairingKey.generate()))
            XCTFail("Wrong key must fail")
        } catch {}
    }
}
