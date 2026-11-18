import Foundation

public enum InkTool: String, Codable, CaseIterable, Sendable, Identifiable {
    case pen, marker, line, arrow, rectangle, ellipse, eraser, text
    public var id: Self { self }
    public var title: String {
        switch self { case .pen: inkLocalized("Stift"); case .marker: inkLocalized("Marker"); case .line: inkLocalized("Linie"); case .arrow: inkLocalized("Pfeil"); case .rectangle: inkLocalized("Rechteck"); case .ellipse: "Ellipse"; case .eraser: inkLocalized("Radierer"); case .text: "Text" }
    }
    public var symbol: String {
        switch self { case .pen: "pencil.tip"; case .marker: "highlighter"; case .line: "line.diagonal"; case .arrow: "arrow.up.right"; case .rectangle: "rectangle"; case .ellipse: "oval"; case .eraser: "eraser"; case .text: "textformat" }
    }
    public var isShape: Bool { [.line, .arrow, .rectangle, .ellipse].contains(self) }
}
public struct InkColor: Codable, Equatable, Sendable, Identifiable {
    public var r: Double; public var g: Double; public var b: Double
    public var id: String { "\(r)-\(g)-\(b)" }
    public init(_ r: Double, _ g: Double, _ b: Double) { self.r = r; self.g = g; self.b = b }
    public static let red = InkColor(1, 0.22, 0.28)
    public static let palette = [red, InkColor(1,0.8,0.12), InkColor(0.22,0.55,1), InkColor(0.15,0.85,0.55), InkColor(1,1,1), InkColor(0.08,0.09,0.13)]
    public var valid: Bool { [r,g,b].allSatisfy { $0.isFinite && (0...1).contains($0) } }
}
public struct InkPoint: Codable, Equatable, Sendable {
    /// Normalized, top-left origin; pressure is optional hardware input, not required for geometry.
    public var x: Double; public var y: Double; public var pressure: Double
    public init(x: Double, y: Double, pressure: Double = 0.5) { self.x = x; self.y = y; self.pressure = pressure }
    public var valid: Bool { [x,y,pressure].allSatisfy { $0.isFinite && (0...1).contains($0) } }
}
public struct InkStroke: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var tool: InkTool
    public var color: InkColor
    /// Width as a fraction of the shorter display edge. Default: four points on a 1000-point edge.
    public var width: Double
    public var points: [InkPoint]
    // Optional for backwards-compatible decoding of earlier strokes.
    public var rotation: Double?
    public var text: String?
    public var opacity: Double?
    public var pressureSensitivity: Double?
    public var minimumWidth: Double?
    public var maximumWidth: Double?
    public var effectiveOpacity: Double { opacity ?? (tool == .marker ? 0.3 : 1) }
    public func renderedWidth(pressure: Double) -> Double {
        let sensitivity = pressureSensitivity ?? 1
        let value = width * (1 + (pressure - 0.5) * sensitivity)
        return min(maximumWidth ?? .greatestFiniteMagnitude, max(minimumWidth ?? 0, value))
    }
    public init(id: UUID = UUID(), tool: InkTool, color: InkColor, width: Double, points: [InkPoint], opacity: Double? = nil, pressureSensitivity: Double? = nil, minimumWidth: Double? = nil, maximumWidth: Double? = nil, text: String? = nil) {
        self.id = id; self.tool = tool; self.color = color; self.width = width; self.points = points
        self.text = text
        self.opacity = opacity; self.pressureSensitivity = pressureSensitivity; self.minimumWidth = minimumWidth; self.maximumWidth = maximumWidth
    }
    public var valid: Bool {
        (rotation == nil || ([InkTool.rectangle, .ellipse].contains(tool) && rotation!.isFinite && abs(rotation!) <= .pi+0.000001)) &&
        (tool == .text ? (text.map(InkTextLayout.valid) == true && points.count == 1) : text == nil) &&
        tool != .eraser && color.valid && width.isFinite && (0.000001...100).contains(width) &&
        (opacity == nil || (opacity!.isFinite && (0.05...1).contains(opacity!))) &&
        (pressureSensitivity == nil || (pressureSensitivity!.isFinite && (0...1).contains(pressureSensitivity!))) &&
        (minimumWidth == nil || (minimumWidth!.isFinite && minimumWidth! > 0 && minimumWidth! <= width)) &&
        (maximumWidth == nil || (maximumWidth!.isFinite && maximumWidth! >= width && maximumWidth! <= 100)) &&
        !points.isEmpty && points.count <= 8_000 && points.allSatisfy(\.valid)
    }
}
public struct DisplayInfo: Codable, Equatable, Sendable {
    public var name: String; public var width: Double; public var height: Double
    public init(name: String = inkLocalized("Zeichenfläche"), width: Double = 1920, height: Double = 1080) { self.name = name; self.width = width; self.height = height }
    public var valid: Bool { width.isFinite && height.isFinite && (1...32_768).contains(width) && (1...32_768).contains(height) && name.count <= 256 }
}
public struct InkSnapshot: Codable, Equatable, Sendable {
    public var epoch = UUID()
    /// Independent capture-source identity; slide edits do not invalidate video.
    public var sourceEpoch = UUID()
    public var revision: UInt64 = 0
    public var display = DisplayInfo()
    public var strokes: [InkStroke] = []
    public var overlayVisible = true
    public var canUndo = false
    public var canRedo = false
    public init() {}
    public var valid: Bool { display.valid && strokes.reduce(0, { $0 + ($1.text?.utf8.count ?? 0) }) <= 256_000 && strokes.count <= 1_000 && strokes.reduce(0, { $0 + $1.points.count }) <= 100_000 && strokes.allSatisfy(\.valid) && Set(strokes.map(\.id)).count == strokes.count }
}
public enum InkAction: Codable, Equatable, Sendable {
    case previewTransform(original: InkStroke, replacement: InkStroke)
    case commitTransform(original: InkStroke, replacement: InkStroke)
    case editText(original: InkStroke, text: String)
    case preview(InkStroke), commit(InkStroke), cancel, erase(InkPoint), undo, redo, clear, visibility(Bool)
}
public struct InkCommand: Codable, Equatable, Sendable {
    public var id: UUID
    public var epoch: UUID
    public var action: InkAction
    public init(epoch: UUID, action: InkAction, id: UUID = UUID()) { self.id = id; self.epoch = epoch; self.action = action }
}
