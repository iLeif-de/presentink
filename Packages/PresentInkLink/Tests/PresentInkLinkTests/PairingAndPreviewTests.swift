import XCTest
@testable import PresentInkLink

private final class MemoryPairingStorage: PairingSecretStorage {
    var values: [String: Data] = [:]
    func read(account: String) throws -> Data? { values[account] }
    func write(_ data: Data, account: String) throws { values[account] = data }
    func remove(account: String) throws { values[account] = nil }
}
final class PairingRepositoryTests: XCTestCase {
    func testHostRestartReusesKey() throws {
        let storage = MemoryPairingStorage()
        let before = try PairingRepository(storage: storage).hostKey()
        let after = try PairingRepository(storage: storage).hostKey()
        XCTAssertEqual(before, after); XCTAssertTrue(PairingKey.isValid(after))
    }
    func testRotationRevokesPreviousKey() throws {
        let repository = PairingRepository(storage: MemoryPairingStorage())
        let before = try repository.hostKey(), after = try repository.rotateHostKey()
        XCTAssertNotEqual(before, after); XCTAssertEqual(try repository.hostKey(), after)
    }
    func testTrustedMacSurvivesRepositoryRecreation() throws {
        let storage = MemoryPairingStorage(), key = PairingKey.generate()
        try PairingRepository(storage: storage).remember(id: "mac", name: "Mein Mac", key: key.uppercased())
        let saved = try XCTUnwrap(PairingRepository(storage: storage).trustedMacs().first)
        XCTAssertEqual(saved.id, "mac"); XCTAssertEqual(saved.key, key)
    }
    func testRememberUpdatesWithoutDuplicatesAndForgetOnlyRemovesOneHost() throws {
        let repository = PairingRepository(storage: MemoryPairingStorage()), key = PairingKey.generate()
        try repository.remember(id: "a", name: "Mac A", key: key)
        try repository.remember(id: "b", name: "Mac B", key: key)
        try repository.remember(id: "a", name: "Mac A neu", key: key)
        XCTAssertEqual(try repository.trustedMacs().map(\.id), ["a", "b"])
        try repository.forget(id: "a")
        XCTAssertEqual(try repository.trustedMacs().map(\.id), ["b"])
    }
    func testInvalidKeyIsNeverRemembered() throws {
        let repository = PairingRepository(storage: MemoryPairingStorage())
        XCTAssertThrowsError(try repository.remember(id: "mac", name: "Mac", key: "1234"))
        XCTAssertTrue(try repository.trustedMacs().isEmpty)
    }
}

final class PreviewRelayTests: XCTestCase {
    func testLateVideoSubscriberGetsCachedFirstFrameOnStaticScreen() {
        var relay = PreviewRelay()
        relay.setStatus(.starting)
        let frame = VideoFrame(epoch: UUID(), jpeg: Data([1,2,3]), sequence: 1)
        relay.cache(frame) // Capture can deliver before startCapture() returns.
        relay.setStatus(.live)
        XCTAssertEqual(relay.subscriberMessages.count, 2)
        guard case .frame(let delivered) = relay.subscriberMessages.last else { return XCTFail("Missing initial frame") }
        XCTAssertEqual(delivered.sequence, 1); XCTAssertEqual(delivered.jpeg, frame.jpeg)
    }
    func testPauseAndNewSourceClearCachedScreenContents() {
        var relay = PreviewRelay(); relay.setStatus(.live)
        relay.cache(VideoFrame(epoch: UUID(), jpeg: Data([1]), sequence: 1))
        relay.setStatus(.paused("Privatpause"))
        XCTAssertNil(relay.latestFrame); XCTAssertEqual(relay.subscriberMessages.count, 1)
        relay.cache(VideoFrame(epoch: UUID(), jpeg: Data([2]), sequence: 2))
        XCTAssertNil(relay.latestFrame)
        relay.setStatus(.starting); XCTAssertNil(relay.latestFrame)
    }
    func testPreviewPhasesHaveAnOrderAcrossBothChannels() {
        var relay = PreviewRelay()
        relay.setStatus(.starting); let starting = relay.update
        relay.setStatus(.live); let live = relay.update
        relay.setStatus(.paused("Privatpause")); let paused = relay.update
        XCTAssertLessThan(starting.revision, live.revision)
        XCTAssertLessThan(live.revision, paused.revision)
        guard case .previewStatus(let subscriber) = relay.subscriberMessages[0] else { return XCTFail() }
        XCTAssertEqual(subscriber, paused)
    }
    func testFailureReasonAndRequestRoundTrip() throws {
        let status = PreviewStatus.failed("Bildschirmaufnahme nicht erlaubt")
        let encoded = try JSONEncoder().encode(WireMessage.previewStatus(PreviewUpdate(revision: 7, status: status)))
        guard case .previewStatus(let decoded) = try JSONDecoder().decode(WireMessage.self, from: encoded) else { return XCTFail() }
        XCTAssertEqual(decoded.status, status); XCTAssertEqual(decoded.revision, 7); XCTAssertFalse(decoded.status.isStreaming)
        let request = try JSONEncoder().encode(WireMessage.requestPreview)
        guard case .requestPreview = try JSONDecoder().decode(WireMessage.self, from: request) else { return XCTFail() }
    }
}
