import XCTest
import Network
import PresentInkCore
@testable import PresentInkLink

final class FramingTests: XCTestCase {
    func testTransformAndSlideControlWireRoundTrip() throws {
        let original = InkStroke(tool:.rectangle,color:.red,width:0.004,points:[InkPoint(x:0.2,y:0.2),InkPoint(x:0.4,y:0.4)])
        var replacement = original; replacement.rotation = 0.2
        for action in [InkAction.previewTransform(original:original,replacement:replacement), .commitTransform(original:original,replacement:replacement)] {
            let command = InkCommand(epoch:UUID(),action:action)
            let decoded = try JSONDecoder().decode(WireMessage.self,from:JSONEncoder().encode(WireMessage.command(command)))
            guard case .command(let value) = decoded else { return XCTFail() }; XCTAssertEqual(value,command)
        }
        for direction in [SlideDirection.previous,.next] {
            let request = UUID()
            let decoded = try JSONDecoder().decode(WireMessage.self,from:JSONEncoder().encode(WireMessage.navigateSlide(direction,request:request)))
            guard case .navigateSlide(let value,let receivedRequest) = decoded else { return XCTFail() }; XCTAssertEqual(value,direction); XCTAssertEqual(receivedRequest,request)
        }
    }
    func testSlideNavigationResultRoundTrip() throws {
        let request = UUID(), snapshot = InkSnapshot()
        let success = try JSONDecoder().decode(WireMessage.self,from:JSONEncoder().encode(WireMessage.slideNavigationFinished(request:request,snapshot:snapshot)))
        guard case .slideNavigationFinished(let received,let state) = success else { return XCTFail() }
        XCTAssertEqual(received,request); XCTAssertEqual(state,snapshot)
        let failure = try JSONDecoder().decode(WireMessage.self,from:JSONEncoder().encode(WireMessage.slideNavigationFailed(request:request,reason:"Denied")))
        guard case .slideNavigationFailed(let failed,let reason) = failure else { return XCTFail() }
        XCTAssertEqual(failed,request); XCTAssertEqual(reason,"Denied")
    }
    func testSlideClearingKeepsCaptureIdentityButDisplayChangeInvalidatesIt() throws {
        var document = InkDocument()
        let frame = VideoFrame(epoch:document.snapshot.sourceEpoch,jpeg:Data([1,2,3]),sequence:42)
        let oldInkEpoch = document.snapshot.epoch
        XCTAssertTrue(frame.belongs(to:document.snapshot))
        XCTAssertTrue(document.performSlideChange { true })
        XCTAssertNotEqual(document.snapshot.epoch,oldInkEpoch)
        XCTAssertTrue(frame.belongs(to:document.snapshot))
        document.updateDisplay(DisplayInfo(name:"Other",width:1000,height:700))
        XCTAssertFalse(frame.belongs(to:document.snapshot))
        let decoded = try JSONDecoder().decode(InkSnapshot.self,from:JSONEncoder().encode(document.snapshot))
        XCTAssertEqual(decoded.sourceEpoch,document.snapshot.sourceEpoch)
    }
    func testInlineTextEditWireRoundTrip() throws {
        let original = try DrawingSettings().textStroke("Before",at:InkPoint(x:0.2,y:0.4),display:DisplayInfo())
        let command = InkCommand(epoch:UUID(),action:.editText(original:original,text:"After 👋"))
        let decoded = try JSONDecoder().decode(WireMessage.self,from:JSONEncoder().encode(WireMessage.command(command)))
        guard case .command(let received) = decoded else { return XCTFail("Wrong command") }
        XCTAssertEqual(received,command)
        XCTAssertEqual(WireMessage.version,9)
    }
    func testDrawingStateAndSelectionRoundTrip() throws {
        let state = DrawingSyncState(revision:42, library:DrawingLibrary())
        let decoded = try JSONDecoder().decode(WireMessage.self,from:JSONEncoder().encode(WireMessage.drawingSettings(state)))
        guard case .drawingSettings(let received) = decoded else { return XCTFail("Wrong state") }
        XCTAssertTrue(received.valid); XCTAssertEqual(received.revision,42)
        let request = DrawingSelection(tool:.marker,width:20)
        let roundtrip = try JSONDecoder().decode(WireMessage.self,from:JSONEncoder().encode(WireMessage.selectDrawing(request)))
        guard case .selectDrawing(let selection) = roundtrip else { return XCTFail("Wrong selection") }
        XCTAssertEqual(try selection.applying(to:received.settings).currentStyle.width,20)
    }
    func testDrawerVisibilityRequestAndAcknowledgementRoundTrip() throws {
        for visible in [true, false] {
            let request = try JSONDecoder().decode(WireMessage.self, from: JSONEncoder().encode(WireMessage.setMacDrawerVisible(visible)))
            guard case .setMacDrawerVisible(let requested) = request else { return XCTFail("Wrong request") }
            XCTAssertEqual(requested, visible)
            let status = try JSONDecoder().decode(WireMessage.self, from: JSONEncoder().encode(WireMessage.macDrawerVisible(visible)))
            guard case .macDrawerVisible(let acknowledged) = status else { return XCTFail("Wrong acknowledgement") }
            XCTAssertEqual(acknowledged, requested)
        }
    }

    func testFragmentedAndCoalescedTCPFrames() throws {
        let first = Data("hello".utf8), second = Data("world".utf8)
        let bytes = try FrameDecoder.encode(first)+FrameDecoder.encode(second)
        var decoder = FrameDecoder()
        XCTAssertTrue(try decoder.append(bytes.prefix(2)).isEmpty)
        XCTAssertTrue(try decoder.append(bytes.dropFirst(2).prefix(3)).isEmpty)
        XCTAssertEqual(try decoder.append(bytes.dropFirst(5)),[first,second])
    }
    func testOversizedAndZeroLengthAreRejected() {
        var decoder = FrameDecoder()
        XCTAssertThrowsError(try decoder.append(Data([255,255,255,255])))
        decoder = FrameDecoder(); XCTAssertThrowsError(try decoder.append(Data([0,0,0,0])))
    }
    func testSessionTokenValidation() {
        XCTAssertThrowsError(try PairingKey.parameters(token:"123456"))
        XCTAssertNoThrow(try PairingKey.parameters(token:PairingKey.generate()))
    }
}

private final class LoopbackState: @unchecked Sendable {
    // Network callbacks and this test access these fields only on the main queue.
    var server: SecurePeer?
    var failure: String?
}
@MainActor final class SecureLoopbackTests: XCTestCase {
    func testAuthenticatedTLSMessageRoundtrip() async throws {
        let token = PairingKey.generate()
        let listener = try NWListener(using:PairingKey.parameters(token:token),on:.any)
        let listening = expectation(description:"listener ready")
        let received = expectation(description:"encrypted roundtrip")
        let state = LoopbackState()
        listener.stateUpdateHandler = { state in if case .ready = state { listening.fulfill() } }
        listener.newConnectionHandler = { connection in
            let peer = SecurePeer(connection:connection); state.server = peer
            peer.onMessage = { message in if case .ping(let value) = message { peer.send(.pong(value)) } }
            peer.onClose = { state.failure = $0 }; peer.start()
        }
        listener.start(queue:.main)
        await fulfillment(of:[listening],timeout:5)
        let port = try XCTUnwrap(listener.port)
        let client = SecurePeer(connection:NWConnection(host:"127.0.0.1",port:port,using:try PairingKey.parameters(token:token)))
        client.onReady = { client.send(.ping(42)) }
        client.onMessage = { message in if case .pong(42) = message { received.fulfill() } }
        client.onClose = { state.failure = $0 }
        client.start()
        await fulfillment(of:[received],timeout:8)
        XCTAssertNil(state.failure)
        client.onClose = nil; state.server?.onClose = nil; client.close(); state.server?.close(); listener.cancel()
    }
}

@MainActor final class AuthenticationFailureTests: XCTestCase {
    func testWrongSessionKeyCannotAuthenticate() async throws {
        let listener = try NWListener(using:PairingKey.parameters(token:PairingKey.generate()),on:.any)
        let listening = expectation(description:"listener ready")
        let refused = expectation(description:"wrong key refused")
        let state = LoopbackState()
        listener.stateUpdateHandler = { value in if case .ready = value { listening.fulfill() } }
        listener.newConnectionHandler = { connection in
            let peer = SecurePeer(connection:connection); state.server = peer; peer.start()
        }
        listener.start(queue:.main)
        await fulfillment(of:[listening],timeout:5)
        let client = SecurePeer(connection:NWConnection(host:"127.0.0.1",port:try XCTUnwrap(listener.port),using:try PairingKey.parameters(token:PairingKey.generate())))
        client.onReady = { XCTFail("A different key must never authenticate") }
        client.onClose = { _ in refused.fulfill() }
        client.start(); await fulfillment(of:[refused],timeout:8)
        client.onClose = nil; client.close(); state.server?.close(); listener.cancel()
    }
}

@MainActor final class SnapshotBackpressureTests: XCTestCase {
    func testBurstKeepsFinalSnapshotWithoutUnboundedQueue() async throws {
        let listener = try NWListener(using:PairingKey.parameters(token:Self.key),on:.any)
        let ready = expectation(description:"listener ready")
        let final = expectation(description:"latest snapshot arrives")
        var server: SecurePeer?
        var revisions: [UInt64] = []
        listener.stateUpdateHandler = { if case .ready = $0 { ready.fulfill() } }
        listener.newConnectionHandler = { connection in
            let peer = SecurePeer(connection:connection); server = peer
            peer.onMessage = { message in
                if case .snapshot(let snapshot) = message {
                    revisions.append(snapshot.revision)
                    if snapshot.revision == 120 { final.fulfill() }
                }
            }
            peer.start()
        }
        listener.start(queue:.main)
        await fulfillment(of:[ready],timeout:3)
        let client = SecurePeer(connection:NWConnection(host:"127.0.0.1",port:try XCTUnwrap(listener.port),using:try PairingKey.parameters(token:Self.key)))
        client.onReady = {
            for revision in 0...120 {
                var snapshot = InkSnapshot(); snapshot.revision = UInt64(revision)
                client.send(.snapshot(snapshot))
            }
        }
        client.start()
        await fulfillment(of:[final],timeout:5)
        XCTAssertEqual(revisions.first,0); XCTAssertEqual(revisions.last,120)
        XCTAssertEqual(revisions.count,2,"Only the first and newest snapshot should be encoded and sent")
        client.close(); server?.close(); listener.cancel()
    }
    private static let key = PairingKey.generate()
}
