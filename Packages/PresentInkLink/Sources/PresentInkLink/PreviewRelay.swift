import PresentInkCore
import Foundation

public enum PreviewStatus: Codable, Equatable {
    case paused(String), awaitingApproval, starting, live, failed(String)
    public var isStreaming: Bool { self == .live }
    public var title: String {
        switch self {
        case .paused: inkLocalized("Bildschirmvorschau pausiert")
        case .awaitingApproval: inkLocalized("Bitte am Mac freigeben")
        case .starting: inkLocalized("Bildschirmvorschau startet …")
        case .live: inkLocalized("Live-Vorschau · bis zu 6 fps")
        case .failed: inkLocalized("Bildschirmvorschau nicht verfügbar")
        }
    }
    public var detail: String {
        switch self {
        case .paused(let reason), .failed(let reason): reason
        case .awaitingApproval: inkLocalized("Im PresentInk-Fenster auf dem Mac die Bildschirmfreigabe bestätigen.")
        case .starting: inkLocalized("macOS prüft den Bildschirmaufnahmezugriff.")
        case .live: inkLocalized("Der ausgewählte Mac-Bildschirm wird übertragen.")
        }
    }
}

public struct PreviewUpdate: Codable, Equatable {
    public let revision: UInt64
    public let status: PreviewStatus
    public init(revision: UInt64, status: PreviewStatus) { self.revision = revision; self.status = status }
}

/// A late video subscriber needs the latest complete frame even if ScreenCaptureKit is now idle.
public struct PreviewRelay {
    public private(set) var status: PreviewStatus = .paused(inkLocalized("Am iPad auf ‚Mac-Bildschirm anzeigen‘ tippen."))
    public private(set) var latestFrame: VideoFrame?
    private var revision: UInt64 = 0
    public var update: PreviewUpdate { PreviewUpdate(revision: revision, status: status) }
    public init() {}
    public mutating func setStatus(_ status: PreviewStatus) {
        self.status = status; revision &+= 1
        if status != .live { latestFrame = nil }
    }
    public mutating func cache(_ frame: VideoFrame) {
        guard status == .starting || status == .live else { return }; latestFrame = frame
    }
    public var subscriberMessages: [WireMessage] {
        var messages: [WireMessage] = [.previewStatus(update)]
        if status.isStreaming, let latestFrame { messages.append(.frame(latestFrame)) }
        return messages
    }
}
