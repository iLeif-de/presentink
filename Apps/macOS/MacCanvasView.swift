import AppKit
import PresentInkCore

final class InkWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class MacCanvasView: NSView, NSTextViewDelegate {
    private var editor: InlineMacTextView?
    private var textPoint: InkPoint?
    private var originalText: InkStroke?
    private var textEpoch: UUID?
    var isEditingText: Bool { editor != nil }
    var canUndoText: Bool { editor?.undoManager?.canUndo == true }
    var canRedoText: Bool { editor?.undoManager?.canRedo == true }
    func undoText() { editor?.undoManager?.undo() }
    func redoText() { editor?.undoManager?.redo() }
    let session: MacSession
    var tool: InkTool = .pen { didSet { cancel() } }
    var ink = InkColor.red
    var width = 4.0
    private var manipulation: InkManipulation?
    private var transformed: InkStroke?
    private var dragPoint: InkPoint?
    private var draft: InkStroke?
    private var rawEnd: InkPoint?
    private var epoch: UUID?
    private var pointerTracking: NSTrackingArea?
    init(session: MacSession) { self.session = session; super.init(frame:.zero) }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { true }
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let pointerTracking { removeTrackingArea(pointerTracking) }
        let area = NSTrackingArea(rect:.zero,options:[.mouseMoved,.activeInKeyWindow,.inVisibleRect],owner:self,userInfo:nil)
        pointerTracking = area; addTrackingArea(area)
    }
    override func mouseMoved(with event: NSEvent) {
        guard !isEditingText, tool != .eraser, tool != .text,
              let edit = InkManipulation.hit(session.snapshot.strokes,at:point(event),display:session.snapshot.display) else { NSCursor.arrow.set(); return }
        switch edit.handle {
        case .move: NSCursor.openHand.set()
        case .edge(let side): (side == 0 || side == 2 ? NSCursor.resizeUpDown : NSCursor.resizeLeftRight).set()
        case .rotate: NSCursor.pointingHand.set()
        case .endpoint: NSCursor.arrow.set()
        }
    }
    override func resetCursorRects() { addCursorRect(bounds,cursor:.arrow) }
    func cancel() { dismissText(); manipulation = nil; transformed = nil; dragPoint = nil; draft = nil; rawEnd = nil; session.cancelLocal(); needsDisplay = true }
    func documentChanged() {
        if let epoch, epoch != session.snapshot.epoch { dismissText(); manipulation = nil; transformed = nil; dragPoint = nil; draft = nil; rawEnd = nil }
        if !session.snapshot.overlayVisible { dismissText() }
        epoch = session.snapshot.epoch; needsDisplay = true
    }
    private func point(_ event: NSEvent) -> InkPoint {
        let p = convert(event.locationInWindow,from:nil)
        return InkPoint(x:min(1,max(0,p.x/max(1,bounds.width))),y:min(1,max(0,p.y/max(1,bounds.height))))
    }
    override func mouseDown(with event: NSEvent) {
        guard !session.navigatingSlide, finishText(), session.active == nil else { return }
        let p = point(event)
        let existing = tool == .text ? session.snapshot.strokes.reversed().first { $0.tool == .text && InkGeometry.hits($0,at:p,display:session.snapshot.display) } : nil
        if tool == .text || existing != nil { beginText(at:existing?.points.first ?? p, original:existing); return }
        if tool == .eraser { session.command(.erase(p)); return }
        if !event.modifierFlags.contains(.option), let edit = InkManipulation.hit(session.snapshot.strokes,at:p,display:session.snapshot.display) {
            epoch = session.snapshot.epoch; manipulation = edit; transformed = edit.original; dragPoint = p
            session.command(.previewTransform(original:edit.original,replacement:edit.original)); return
        }
        epoch = session.snapshot.epoch; rawEnd = p
        draft = session.settings.stroke(at: p, display: session.snapshot.display)
        if let draft { session.command(.preview(draft)) }
    }
    private func update(_ p: InkPoint, shift: Bool) {
        guard epoch == session.snapshot.epoch else { return }
        if let manipulation {
            if manipulation.handle == .move { NSCursor.closedHand.set() }
            dragPoint = p
            let next = manipulation.updated(to:p,proportional:shift)
            transformed = next
            session.command(.previewTransform(original:manipulation.original,replacement:next)); return
        }
        guard var stroke = draft else { return }
        rawEnd = p
        if stroke.tool.isShape, let first = stroke.points.first {
            stroke.points = [first,InkGeometry.constrained(p,from:first,tool:stroke.tool,display:session.snapshot.display,shift:shift)]
        } else if stroke.points.count < 8_000 { stroke.points.append(p) }
        draft = stroke; session.command(.preview(stroke))
    }
    override func mouseDragged(with event: NSEvent) {
        if tool == .eraser { session.command(.erase(point(event))); return }
        update(point(event),shift:event.modifierFlags.contains(.shift))
    }
    override func flagsChanged(with event: NSEvent) {
        if manipulation != nil, let dragPoint { update(dragPoint,shift:event.modifierFlags.contains(.shift)); return }
        if draft?.tool.isShape == true, let rawEnd { update(rawEnd,shift:event.modifierFlags.contains(.shift)) }
    }
    override func mouseUp(with event: NSEvent) {
        update(point(event),shift:event.modifierFlags.contains(.shift))
        if let manipulation, let transformed { session.command(.commitTransform(original:manipulation.original,replacement:transformed)) }
        else if let draft { session.command(.commit(draft)) }
        manipulation = nil; transformed = nil; dragPoint = nil; draft = nil; rawEnd = nil
    }

    private func dismissText() {
        let old = editor; editor = nil; originalText = nil; textPoint = nil; textEpoch = nil
        old?.removeFromSuperview(); needsDisplay = true
    }
    @discardableResult func finishText() -> Bool {
        guard let editor else { return true }
        guard !editor.hasMarkedText() else { return false }
        let text = editor.string
        if text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty { dismissText(); return true }
        guard textEpoch == session.snapshot.epoch, let textPoint else { dismissText(); return true }
        guard InkTextLayout.valid(text) else {
            session.error = inkLocalized("Text: 1–2000 Zeichen, maximal 20 Zeilen. Position muss innerhalb des Displays liegen.")
            NSSound.beep(); return false
        }
        let previous = session.snapshot.revision
        if let originalText { session.command(.editText(original:originalText,text:text)) }
        else {
            do { try session.insertText(text,at:textPoint,expectedEpoch:textEpoch) }
            catch { session.error = error.localizedDescription; NSSound.beep(); return false }
        }
        guard session.snapshot.revision != previous || originalText?.text == text else { NSSound.beep(); return false }
        dismissText(); window?.makeFirstResponder(self); return true
    }
    func textDidChange(_ notification: Notification) { resizeText() }
    private func resizeText() {
        guard let editor, let container = editor.textContainer, let manager = editor.layoutManager else { return }
        container.containerSize = NSSize(width:editor.frame.width,height:100_000)
        manager.ensureLayout(for:container)
        let height = max((editor.font?.pointSize ?? 28)*1.5,manager.usedRect(for:container).height+4)
        editor.setFrameSize(NSSize(width:editor.frame.width,height:min(max(1,bounds.height-editor.frame.minY),height)))
    }
    private func beginText(at point: InkPoint, original: InkStroke?) {
        guard let style = original ?? (try? session.settings.textStroke("A",at:point,display:session.snapshot.display)) else { return }
        let size = max(1,style.width*min(bounds.width,bounds.height))
        let x = min(point.x*bounds.width,max(0,bounds.width-size*2)), y = min(point.y*bounds.height,max(0,bounds.height-size*1.5))
        let view = InlineMacTextView(frame:NSRect(x:x,y:y,width:max(1,bounds.width-x),height:max(1,bounds.height-y)))
        view.delegate = self
        view.allowsUndo = true
        view.isRichText = false; view.drawsBackground = false; view.textContainerInset = .zero
        view.textContainer?.lineFragmentPadding = 0
        view.font = NSFont(name:"Helvetica",size:size)
        view.textColor = NSColor(red:style.color.r,green:style.color.g,blue:style.color.b,alpha:style.opacity ?? 1)
        view.insertionPointColor = .white; view.string = original?.text ?? ""
        view.setAccessibilityLabel(inkLocalized("Beschriftung"))
        view.finish = { [weak self] in _ = self?.finishText() }
        view.cancel = { [weak self] in self?.dismissText(); self?.window?.makeFirstResponder(self) }
        textPoint = point; originalText = original; textEpoch = session.snapshot.epoch
        editor = view; addSubview(view); resizeText(); window?.makeFirstResponder(view); needsDisplay = true
    }
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.clear(dirtyRect)
        for stroke in session.snapshot.strokes where stroke.id != originalText?.id {
            InkRenderer.draw(session.active?.id == stroke.id ? session.active! : stroke,in:context,size:bounds.size)
        }
        if let active = session.active, !session.snapshot.strokes.contains(where: { $0.id == active.id }) { InkRenderer.draw(active,in:context,size:bounds.size) }
    }
}

private final class InlineMacTextView: NSTextView {
    var finish: (() -> Void)?
    var cancel: (() -> Void)?
    override func keyDown(with event: NSEvent) {
        if !hasMarkedText() {
            if event.keyCode == 53 { cancel?(); return }
            if event.keyCode == 36 && event.modifierFlags.contains(.command) { finish?(); return }
        }
        super.keyDown(with:event)
    }
}
