import AppKit
import PresentInkCore
import PresentInkLink

@MainActor enum ShortcutAutomation {
    static func status(_ operation: InkAutomationOperation, text: String? = nil, number: Double? = nil,
                       clearExisting: Bool = false, confirmed: Bool = false, positionX: Double? = nil, positionY: Double? = nil) async throws -> PresentInkStatusEntity {
        let json = try await run(operation,text:text,number:number,clearExisting:clearExisting,confirmed:confirmed,positionX:positionX,positionY:positionY)
        return PresentInkStatusEntity(try AutomationStatus.decode(json))
    }
    static func displays() async throws -> [PresentInkDisplayEntity] {
        let json = try await run(.listDisplays)
        return try JSONDecoder().decode([AutomationDisplay].self,from:Data(json.utf8)).map(PresentInkDisplayEntity.init)
    }
    static func settings() async throws -> PresentInkSettingsEntity {
        let json = try await run(.getDrawingSettings)
        return PresentInkSettingsEntity(try JSONDecoder().decode(DrawingLibrary.self,from:Data(json.utf8)))
    }
    static func run(_ operation: InkAutomationOperation, text: String? = nil, number: Double? = nil,
                    clearExisting: Bool = false, confirmed: Bool = false, positionX: Double? = nil, positionY: Double? = nil) async throws -> String {
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier:"de.presentink.mac").filter { !$0.isTerminated }
        let pid = try ShortcutAvailability.runningPID(apps.map(\.processIdentifier))
        guard let group = Bundle.main.object(forInfoDictionaryKey:"PresentInkShortcutsKeychainGroup") as? String,
              let endpoint = try ShortcutEndpointStore(group:group).read(), endpoint.pid == pid else {
            throw AutomationFailure.unavailable(inkLocalized("PresentInk ist noch nicht für Kurzbefehle bereit. Bitte die aktuelle App starten und erneut versuchen."))
        }
        let client = ShortcutRPCClient()
        return try await client.request(ShortcutRequest(operation,text:text,number:number,clearExisting:clearExisting,
            confirmed:confirmed,positionX:positionX,positionY:positionY),endpoint:endpoint)
    }
}
