import Foundation

/// Authoritative, platform-independent document. One owner holds the active stroke lease.
public struct InkDocument: Sendable {
    public private(set) var snapshot = InkSnapshot()
    public private(set) var active: InkStroke?
    public private(set) var owner: String?
    private var undoStates: [[InkStroke]] = []
    private var redoStates: [[InkStroke]] = []
    private var seen: [UUID] = []
    private var transformOriginal: InkStroke?
    public init() {}
    public mutating func reset(display: DisplayInfo) {
        guard display.valid else { return }
        self = InkDocument(); snapshot.display = display
    }
    /// Display geometry changes retain normalized strokes and their undo history.
    public mutating func updateDisplay(_ display: DisplayInfo) {
        guard display.valid, display != snapshot.display else { return }
        active = nil; owner = nil; transformOriginal = nil; snapshot.display = display
        snapshot.epoch = UUID(); snapshot.sourceEpoch = UUID(); seen.removeAll(); snapshot.revision &+= 1
    }
    /// Clear only after a presentation command was accepted. A new epoch prevents
    /// in-flight input from the old slide from resurrecting its annotations.
    @discardableResult public mutating func performSlideChange(_ navigate: () throws -> Bool) rethrows -> Bool {
        guard active == nil, try navigate() else { return false }
        if !snapshot.strokes.isEmpty { checkpoint(); snapshot.strokes = [] }
        active = nil; owner = nil; transformOriginal = nil
        snapshot.epoch = UUID(); seen.removeAll(); snapshot.revision &+= 1
        snapshot.canUndo = !undoStates.isEmpty; snapshot.canRedo = !redoStates.isEmpty
        return true
    }
    private mutating func checkpoint() {
        undoStates.append(snapshot.strokes)
        // Bound total retained geometry as well as history depth.
        while undoStates.count > 30 || (undoStates.count > 1 && undoStates.reduce(0, { $0 + $1.reduce(0, { $0 + $1.points.count }) }) > 300_000) { undoStates.removeFirst() }
        redoStates.removeAll()
    }
    public mutating func cancel(owner: String) { if self.owner == owner { active = nil; self.owner = nil; transformOriginal = nil } }
    @discardableResult public mutating func apply(_ command: InkCommand, owner incoming: String) -> Bool {
        guard command.epoch == snapshot.epoch, !seen.contains(command.id), owner == nil || owner == incoming else { return false }
        switch command.action {
        case .previewTransform(let original, let replacement):
            guard snapshot.strokes.contains(original), InkManipulation.validReplacement(replacement,for:original),
                  (active == nil || transformOriginal == original) else { return false }
            active = replacement; owner = incoming; transformOriginal = original
        case .commitTransform(let original, let replacement):
            guard let index = snapshot.strokes.firstIndex(of:original), InkManipulation.validReplacement(replacement,for:original),
                  (active == nil || transformOriginal == original) else { return false }
            if replacement != original { checkpoint(); snapshot.strokes[index] = replacement }
            active = nil; owner = nil; transformOriginal = nil
        case .editText(let original, let text):
            guard active == nil, original.tool == .text,
                  let index = snapshot.strokes.firstIndex(of: original) else { return false }
            var replacement = original; replacement.text = text
            guard replacement.valid,
                  snapshot.strokes.reduce(0, { $0 + ($1.text?.utf8.count ?? 0) }) - (original.text?.utf8.count ?? 0) + text.utf8.count <= 256_000 else { return false }
            if replacement == original { return true }
            checkpoint(); snapshot.strokes[index] = replacement
        case .preview(let stroke):
            guard transformOriginal == nil, stroke.valid, !snapshot.strokes.contains(where: { $0.id == stroke.id }), active == nil || active?.id == stroke.id else { return false }
            active = stroke; owner = incoming
        case .commit(let stroke):
            guard transformOriginal == nil, stroke.valid, active == nil || active?.id == stroke.id,
                  !snapshot.strokes.contains(where: { $0.id == stroke.id }), snapshot.strokes.count < 1_000,
                  snapshot.strokes.reduce(0, { $0 + $1.points.count }) + stroke.points.count <= 100_000,
                  snapshot.strokes.reduce(0, { $0 + ($1.text?.utf8.count ?? 0) }) + (stroke.text?.utf8.count ?? 0) <= 256_000 else { return false }
            checkpoint(); snapshot.strokes.append(stroke); active = nil; owner = nil; transformOriginal = nil
        case .cancel: active = nil; owner = nil; transformOriginal = nil
        case .erase(let point):
            guard point.valid else { return false }
            let remaining = snapshot.strokes.filter { !InkGeometry.hits($0, at: point, display: snapshot.display) }
            if remaining == snapshot.strokes { return true }
            checkpoint(); snapshot.strokes = remaining
        case .undo:
            active = nil; owner = nil; transformOriginal = nil
            if let state = undoStates.popLast() { redoStates.append(snapshot.strokes); snapshot.strokes = state }
        case .redo:
            active = nil; owner = nil; transformOriginal = nil
            if let state = redoStates.popLast() { undoStates.append(snapshot.strokes); snapshot.strokes = state }
        case .clear:
            active = nil; owner = nil; transformOriginal = nil
            if !snapshot.strokes.isEmpty { checkpoint(); snapshot.strokes = [] }
        case .visibility(let visible): snapshot.overlayVisible = visible
        }
        seen.append(command.id); if seen.count > 256 { seen.removeFirst() }
        snapshot.revision &+= 1
        snapshot.canUndo = !undoStates.isEmpty; snapshot.canRedo = !redoStates.isEmpty
        return true
    }
}
