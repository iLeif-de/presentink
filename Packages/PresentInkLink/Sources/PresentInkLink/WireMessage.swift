import Foundation
import PresentInkCore

public enum SlideDirection: String, Codable, Sendable { case previous, next }
public enum LinkChannel: String, Codable { case control, video }
public struct VideoFrame: Codable {
    /// Capture-source identity, independent of annotation epochs.
    public var epoch: UUID
    public var jpeg: Data
    public var sequence: UInt64
    public func belongs(to snapshot: InkSnapshot) -> Bool { epoch == snapshot.sourceEpoch }
    public init(epoch: UUID, jpeg: Data, sequence: UInt64) { self.epoch = epoch; self.jpeg = jpeg; self.sequence = sequence }
}
public enum WireMessage: Codable {
    case hello(version: Int, client: UUID, channel: LinkChannel)
    case snapshot(InkSnapshot)
    case preview(InkStroke?)
    case command(InkCommand)
    case frame(VideoFrame)
    case previewStatus(PreviewUpdate)
    case setMacDrawerVisible(Bool)
    case macDrawerVisible(Bool)
    case drawingSettings(DrawingSyncState)
    case selectDrawing(DrawingSelection)
    case settingsApplied(UInt64)
    case settingsRejected(String)
    case navigateSlide(SlideDirection, request: UUID)
    case slideNavigationFinished(request: UUID, snapshot: InkSnapshot)
    case slideNavigationFailed(request: UUID, reason: String)
    case requestPreview
    case ping(UInt64), pong(UInt64)
    case rejected(String)
    public static let version = 9
    public static let serviceType = "_presentink._tcp"
}

/// TCP is a byte stream: one receive may contain part of a message or several messages.
public struct FrameDecoder {
    public static let maximumLength = 8 * 1024 * 1024
    private var buffer = Data()
    public init() {}
    public mutating func append(_ bytes: Data) throws -> [Data] {
        buffer.append(bytes)
        var messages: [Data] = []
        while buffer.count >= 4 {
            let length = buffer.prefix(4).reduce(0) { ($0 << 8) | Int($1) }
            guard length > 0, length <= Self.maximumLength else { throw LinkError.invalidFrame }
            guard buffer.count >= 4 + length else { break }
            messages.append(Data(buffer.dropFirst(4).prefix(length)))
            buffer = Data(buffer.dropFirst(4 + length))
        }
        guard buffer.count <= Self.maximumLength + 4 else { throw LinkError.invalidFrame }
        return messages
    }
    public static func encode(_ data: Data) throws -> Data {
        guard !data.isEmpty, data.count <= maximumLength else { throw LinkError.invalidFrame }
        var length = UInt32(data.count).bigEndian
        return withUnsafeBytes(of: &length) { Data($0) } + data
    }
}
public enum LinkError: LocalizedError {
    case invalidFrame, invalidToken
    public var errorDescription: String? {
        switch self { case .invalidFrame: inkLocalized("Ungültige oder zu große Nachricht."); case .invalidToken: inkLocalized("Der Verbindungsschlüssel muss aus 32 Hex-Zeichen bestehen.") }
    }
}
