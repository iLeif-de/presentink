import AppKit
import PresentInkCore

@objc(PresentInkScriptCommand)
final class PresentInkScriptCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let code = commandDescription.appleEventCode
        let event = String(bytes: [UInt8((code>>24)&255), UInt8((code>>16)&255), UInt8((code>>8)&255), UInt8(code&255)], encoding: .macOSRoman) ?? ""
        guard let operation = InkAutomationOperation.allCases.first(where: { $0.scriptEventCode == event }) else {
            scriptErrorNumber = -1708; scriptErrorString = inkLocalized("Unbekannter PresentInk-Befehl."); return nil
        }
        do {
            let arguments = evaluatedArguments ?? [:]
            let text = directParameter as? String
            let number = (directParameter as? NSNumber)?.doubleValue
            return try MacAutomation.onMain {
                try MacAutomation.execute(operation, text: text, number: number,
                    clearExisting: (arguments["clearingAnnotations"] as? NSNumber)?.boolValue ?? false,
                    confirmed: (arguments["confirmed"] as? NSNumber)?.boolValue ?? false,
                    positionX: (arguments["positionX"] as? NSNumber)?.doubleValue,
                    positionY: (arguments["positionY"] as? NSNumber)?.doubleValue)
            }
        } catch {
            scriptErrorNumber = (error as? AutomationFailure)?.scriptError ?? -2700
            scriptErrorString = error.localizedDescription; return nil
        }
    }
}

extension NSApplication {
    private func automationRead<T>(_ fallback: T, _ body: () throws -> T) -> T {
        do { return try MacAutomation.onMain(body) }
        catch {
            NSScriptCommand.current()?.scriptErrorNumber = (error as? AutomationFailure)?.scriptError ?? -2700
            NSScriptCommand.current()?.scriptErrorString = error.localizedDescription
            return fallback
        }
    }
    private func automationWrite(_ operation: InkAutomationOperation, text: String? = nil, number: Double? = nil) {
        _ = automationRead("") { try MacAutomation.execute(operation, text: text, number: number) }
    }
    @objc var presentInkStatus: String { automationRead("") { try MacAutomation.status() } }
    @objc var presentInkDisplays: String { automationRead("") { try MacAutomation.execute(.listDisplays) } }
    @objc var presentInkDrawing: Bool {
        get { automationRead(false) { try MacAutomation.app().drawing } }
        set { automationWrite(newValue ? .enableDrawing : .disableDrawing) }
    }
    @objc var presentInkVisible: Bool {
        get { automationRead(false) { try !MacAutomation.app().hidden } }
        set { automationWrite(newValue ? .showAnnotations : .hideAnnotations) }
    }
    @objc var presentInkDrawer: String {
        get { automationRead("hidden") {
            switch try MacAutomation.app().drawerState.presentation { case .expanded: "expanded"; case .compact: "compact"; case .hidden: "hidden"; case .invisible: "invisible" }
        } }
        set { automationWrite(.setDrawer, text: newValue) }
    }
    @objc var presentInkTool: String {
        get { automationRead("") { try MacAutomation.app().drawerState.tool.rawValue } }
        set { automationWrite(.setTool, text: newValue) }
    }
    @objc var presentInkColor: String {
        get { automationRead("") { AutomationValues.hex(try MacAutomation.app().drawerState.color) } }
        set { automationWrite(.setColor, text: newValue) }
    }
    @objc var presentInkWidth: Double {
        get { automationRead(4) { try MacAutomation.app().drawerState.width } }
        set { automationWrite(.setWidth, number: newValue) }
    }
    @objc var presentInkDisplay: Int {
        get { automationRead(0) { let app = try MacAutomation.app(); return app.screens.firstIndex(where: { app.id($0) == app.selectedDisplay }).map { $0+1 } ?? 0 } }
        set { automationWrite(.setDisplay, number: Double(newValue)) }
    }
    @objc var presentInkConnection: Bool {
        get { automationRead(false) { try !MacAutomation.app().session.token.isEmpty } }
        set { automationWrite(newValue ? .startConnection : .stopConnection) }
    }
    @objc var presentInkPreview: Bool {
        get { automationRead(false) { try MacAutomation.app().session.sharing } }
        set { automationWrite(newValue ? .startPreview : .stopPreview) }
    }
}
