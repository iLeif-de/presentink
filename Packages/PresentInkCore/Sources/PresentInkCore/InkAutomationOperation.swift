import Foundation

public enum InkAutomationOperation: String, CaseIterable, Codable, Sendable {
    case toggleDrawing
    case enableDrawing
    case disableDrawing
    case showAnnotations
    case hideAnnotations
    case toggleAnnotations
    case expandDrawer
    case compactDrawer
    case hideDrawer
    case toggleDrawer
    case undo
    case redo
    case clear
    case startConnection
    case stopConnection
    case toggleConnection
    case startPreview
    case stopPreview
    case togglePreview
    case emergencyHide
    case showSettings
    case resetPairing
    case showApplication
    case hideApplication
    case quit
    case getStatus
    case listDisplays
    case showHelp
    case showAbout
    case openDisplaySettings
    case openCaptureSettings
    case setTool
    case setColor
    case setWidth
    case setDrawer
    case setDisplay
    case showPreferences
    case getDrawingSettings
    case setDrawingSettings
    case selectProfile
    case setOpacity
    case setPreviewPolicy
    case insertText
    public var scriptEventCode: String {
        switch self {
        case .insertText: "InTx"
        case .showPreferences: "ShPf"
        case .getDrawingSettings: "RdSt"
        case .setDrawingSettings: "ApSt"
        case .selectProfile: "SlPr"
        case .setOpacity: "StOp"
        case .setPreviewPolicy: "ShPl"

        case .toggleDrawing: "TgDr"
        case .enableDrawing: "EnDr"
        case .disableDrawing: "DsDr"
        case .showAnnotations: "ShAn"
        case .hideAnnotations: "HdAn"
        case .toggleAnnotations: "TgAn"
        case .expandDrawer: "ExDw"
        case .compactDrawer: "CpDw"
        case .hideDrawer: "HdDw"
        case .toggleDrawer: "TgDw"
        case .undo: "Undo"
        case .redo: "Redo"
        case .clear: "ClAn"
        case .startConnection: "StCn"
        case .stopConnection: "SpCn"
        case .toggleConnection: "TgCn"
        case .startPreview: "StPv"
        case .stopPreview: "SpPv"
        case .togglePreview: "TgPv"
        case .emergencyHide: "EmHd"
        case .showSettings: "ShSt"
        case .resetPairing: "RsPr"
        case .showApplication: "ShAp"
        case .hideApplication: "HdAp"
        case .quit: "Quit"
        case .getStatus: "Stat"
        case .listDisplays: "Dpls"
        case .showHelp: "ShHp"
        case .showAbout: "ShAb"
        case .openDisplaySettings: "DsSt"
        case .openCaptureSettings: "CpSt"
        case .setTool: "SlTl"
        case .setColor: "SlCl"
        case .setWidth: "StWd"
        case .setDrawer: "StDw"
        case .setDisplay: "SlDs"
        }
    }
}
