import Foundation

/// Internal JSON decoding only. Shortcuts exposes these values as native entity properties.
public struct AutomationStatus: Decodable, Sendable {
    public let appHidden: Bool
    public let drawingEnabled: Bool
    public let annotationsVisible: Bool
    public let drawerState: String
    public let macDrawerVisible: Bool
    public let tool: InkTool
    public let color: String
    public let strokeWidth: Double
    public let opacity: Double
    public let widthMinimum: Double
    public let widthMaximum: Double
    public let activeProfile: String?
    public let displayIndex: Int
    public let displayName: String
    public let connectionEnabled: Bool
    public let ipadConnected: Bool
    public let previewEnabled: Bool
    public let previewState: String
    public let previewDetail: String
    public let previewTrusted: Bool
    public let previewAutoStart: Bool
    public let strokeCount: Int
    public let canUndo: Bool
    public let canRedo: Bool
    public let strokeInProgress: Bool
    public let drawingSettingsSynced: Bool
    public let lastError: String?
    public static func decode(_ json: String) throws -> Self {
        let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Self.self,from:Data(json.utf8))
    }
}
public struct AutomationDisplay: Decodable, Sendable {
    public let index: Int
    public let id: UInt32
    public let name: String
    public let width: Double
    public let height: Double
    public let selected: Bool
}
public struct ShortcutRequest: Codable, Sendable {
    public var id = UUID()
    public var operation: InkAutomationOperation
    public var text: String?
    public var number: Double?
    public var clearExisting: Bool
    public var confirmed: Bool
    public var positionX: Double?
    public var positionY: Double?
    public init(_ operation: InkAutomationOperation, text: String? = nil, number: Double? = nil,
                clearExisting: Bool = false, confirmed: Bool = false, positionX: Double? = nil, positionY: Double? = nil) {
        self.operation = operation; self.text = text; self.number = number
        self.clearExisting = clearExisting; self.confirmed = confirmed; self.positionX = positionX; self.positionY = positionY
    }
}
public struct ShortcutReply: Codable, Sendable {
    public var id: UUID
    public var value: String?
    public var error: String?
    public init(id: UUID, value: String? = nil, error: String? = nil) { self.id = id; self.value = value; self.error = error }
}
public struct ShortcutEndpoint: Codable, Sendable {
    public var pid: Int32
    public var port: UInt16
    public var token: String
    public init(pid: Int32, port: UInt16, token: String) { self.pid = pid; self.port = port; self.token = token }
}

public enum ShortcutAvailability {
    public static func runningPID(_ pids: [Int32]) throws -> Int32 {
        guard !pids.isEmpty else { throw AutomationFailure.unavailable(inkLocalized("PresentInk läuft nicht. Bitte zuerst die App öffnen und den Kurzbefehl erneut ausführen.")) }
        guard pids.count == 1 else { throw AutomationFailure.unavailable(inkLocalized("Mehrere PresentInk-Kopien laufen. Bitte nur die gewünschte Version geöffnet lassen.")) }
        return pids[0]
    }
}
