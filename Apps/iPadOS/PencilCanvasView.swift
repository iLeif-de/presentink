import SwiftUI
import UIKit
import PresentInkCore

struct PencilCanvasView: UIViewRepresentable {
    @ObservedObject var model: CompanionModel
    func makeUIView(context: Context) -> PencilSurface { PencilSurface(model:model) }
    func updateUIView(_ view: PencilSurface, context: Context) { view.syncText(); view.setNeedsDisplay() }
}
final class PencilSurface: UIView, UIPencilInteractionDelegate, UITextViewDelegate {
    private var editor: InlinePadTextView?
    private var placementID: UUID?
    @discardableResult private func finishText() -> Bool {
        guard let editor, let placement = model.textPlacement else { return true }
        // Done explicitly accepts any pending Scribble/IME composition before validation.
        editor.unmarkText()
        if editor.text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty { model.textPlacement = nil; syncText(); return true }
        do { try model.insertText(editor.text,placement:placement); syncText(); return true }
        catch { model.error = error.localizedDescription; return false }
    }
    @objc private func doneText() { _ = finishText() }
    @objc private func cancelText() { model.textPlacement = nil; syncText() }
    func syncText() {
        guard let placement = model.textPlacement else {
            let old = editor; editor = nil; placementID = nil; old?.resignFirstResponder(); old?.removeFromSuperview(); setNeedsDisplay(); return
        }
        if placementID != placement.id {
            editor?.removeFromSuperview()
            let view = InlinePadTextView()
            view.backgroundColor = .clear; view.textContainerInset = .zero; view.textContainer.lineFragmentPadding = 0
            view.delegate = self
            view.isScrollEnabled = false
            view.text = placement.original?.text ?? ""
            view.accessibilityLabel = inkLocalized("Beschriftung")
            view.finish = { [weak self] in _ = self?.finishText() }
            view.cancel = { [weak self] in self?.cancelText() }
            let bar = UIToolbar(); bar.sizeToFit()
            bar.items = [UIBarButtonItem(title:inkLocalized("Abbrechen"),style:.plain,target:self,action:#selector(cancelText)), UIBarButtonItem(systemItem:.flexibleSpace), UIBarButtonItem(title:inkLocalized("Fertig"),style:.prominent,target:self,action:#selector(doneText))]
            view.inputAccessoryView = bar
            editor = view; placementID = placement.id; addSubview(view)
            positionText(); view.becomeFirstResponder()
        } else { positionText() }
    }
    func textViewDidChange(_ textView: UITextView) { positionText() }
    private func positionText() {
        guard let editor, let placement = model.textPlacement,
              let style = placement.original ?? (try? model.settings.textStroke("A",at:placement.point,display:model.snapshot.display)) else { return }
        let rect = contentRect, size = max(1,style.width*min(rect.width,rect.height))
        let x = min(placement.point.x*rect.width,max(0,rect.width-size*2)), y = min(placement.point.y*rect.height,max(0,rect.height-size*1.5))
        editor.font = UIFont(name:"Helvetica",size:size)
        editor.textColor = UIColor(red:style.color.r,green:style.color.g,blue:style.color.b,alpha:style.opacity ?? 1)
        editor.frame = CGRect(x:rect.minX+x,y:rect.minY+y,width:max(1,rect.width-x),height:min(max(size*1.5,editor.sizeThatFits(CGSize(width:max(1,rect.width-x),height:100_000)).height),max(1,rect.height-y)))
    }
    let model: CompanionModel
    private var tracking: UITouch?
    private var lastPencilActivity = -Double.infinity
    private var drawingSize = CGSize.zero
    init(model: CompanionModel) {
        self.model = model; super.init(frame:.zero)
        backgroundColor = UIColor(red:0.04,green:0.055,blue:0.09,alpha:1)
        isMultipleTouchEnabled = true
        addInteraction(UIPencilInteraction(delegate:self))
        let hover = UIHoverGestureRecognizer(target:self,action:#selector(pencilHover(_:)))
        hover.cancelsTouchesInView = false
        hover.allowedTouchTypes = [NSNumber(value:UITouch.TouchType.pencil.rawValue)]
        addGestureRecognizer(hover)
        model.finishText = { [weak self] in self?.finishText() ?? true }
        model.cancelText = { [weak self] in self?.cancelText() }
        accessibilityLabel = inkLocalized("Pencil-Zeichenfläche für das ausgewählte Mac-Display")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
    private var contentRect: CGRect {
        let aspect = model.snapshot.display.width/model.snapshot.display.height
        let width = min(bounds.width,bounds.height*aspect), height = min(bounds.height,bounds.width/aspect)
        return CGRect(x:(bounds.width-width)/2,y:(bounds.height-height)/2,width:width,height:height)
    }
    private func sample(_ touch: UITouch) -> InkPoint? {
        let location = touch.location(in:self), rect = contentRect
        guard rect.width > 0, rect.height > 0, rect.contains(location) else { return nil }
        let pressure = touch.type == .pencil && touch.maximumPossibleForce > 0 ? min(1,max(0,Double(touch.force/touch.maximumPossibleForce))) : 0.5
        return InkPoint(x:Double((location.x-rect.minX)/rect.width),y:Double((location.y-rect.minY)/rect.height),pressure:pressure)
    }
    @objc private func pencilHover(_ recognizer: UIHoverGestureRecognizer) {
        lastPencilActivity = ProcessInfo.processInfo.systemUptime
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let pencil = touches.first { $0.type == .pencil }
        if pencil != nil {
            lastPencilActivity = ProcessInfo.processInfo.systemUptime
            if tracking?.type == .direct { model.cancel(); tracking = nil }
        }
        guard tracking == nil else { return }
        let finger = touches.first { $0.type == .direct && $0.majorRadius <= 35 }
        guard let touch = pencil ?? (ProcessInfo.processInfo.systemUptime-lastPencilActivity > 0.35 ? finger : nil), let point = sample(touch) else { return }
        // A tap outside the editor finishes this label, rather than immediately
        // opening another editor and summoning the keyboard again.
        if model.textPlacement != nil { _ = finishText(); return }
        if model.tool == .text, model.editText(at:point) { syncText(); return }
        if model.tool == .text { model.begin(point); syncText(); setNeedsDisplay(); return }
        tracking = touch; model.begin(point); setNeedsDisplay()
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let tracking, touches.contains(tracking) else { return }
        // Coalesced Pencil samples retain fidelity without sending a message for every sensor sample.
        let samples = (event?.coalescedTouches(for:tracking) ?? [tracking]).compactMap(sample)
        model.append(samples,shift:event?.modifierFlags.contains(.shift) == true); setNeedsDisplay()
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let tracking, touches.contains(tracking) else { return }
        if let point = sample(tracking) { model.append([point],shift:event?.modifierFlags.contains(.shift) == true) }
        if tracking.type == .pencil { lastPencilActivity = ProcessInfo.processInfo.systemUptime }
        model.end(); self.tracking = nil; setNeedsDisplay()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let tracking, touches.contains(tracking) else { return }; model.cancel(); self.tracking = nil; setNeedsDisplay()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        // Overlay visibility/layout passes must not interrupt a Pencil stroke.
        if drawingSize != bounds.size {
            if tracking != nil { model.cancel(); tracking = nil }
            drawingSize = bounds.size
        }
        positionText(); setNeedsDisplay()
    }
    func pencilInteraction(_ interaction: UIPencilInteraction, didReceiveTap tap: UIPencilInteraction.Tap) { model.pencilAction(UIPencilInteraction.preferredTapAction) }
    func pencilInteraction(_ interaction: UIPencilInteraction, didReceiveSqueeze squeeze: UIPencilInteraction.Squeeze) {
        if squeeze.phase == .ended { model.pencilAction(UIPencilInteraction.preferredSqueezeAction) }
    }
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let content = contentRect
        context.saveGState(); context.clip(to:content)
        UIColor(red:0.09,green:0.11,blue:0.16,alpha:1).setFill(); context.fill(content)
        if let image = model.image { image.draw(in:content) }
        else {
            context.setStrokeColor(UIColor.white.withAlphaComponent(0.045).cgColor); context.setLineWidth(1)
            stride(from:content.minX,to:content.maxX,by:32).forEach { x in context.move(to:CGPoint(x:x,y:content.minY)); context.addLine(to:CGPoint(x:x,y:content.maxY)) }
            stride(from:content.minY,to:content.maxY,by:32).forEach { y in context.move(to:CGPoint(x:content.minX,y:y)); context.addLine(to:CGPoint(x:content.maxX,y:y)) }
            context.strokePath()
        }
        context.translateBy(x:content.minX,y:content.minY)
        for stroke in model.strokesToDraw where stroke.id != model.textPlacement?.original?.id { InkRenderer.draw(stroke,in:context,size:content.size) }
        context.restoreGState()
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.15).cgColor); context.setLineWidth(1); context.stroke(content.insetBy(dx:0.5,dy:0.5))
    }
}

private final class InlinePadTextView: UITextView {
    var finish: (() -> Void)?
    var cancel: (() -> Void)?
    override var keyCommands: [UIKeyCommand]? {
        (super.keyCommands ?? []) + [UIKeyCommand(input:"\r",modifierFlags:.command,action:#selector(commitText)), UIKeyCommand(input:UIKeyCommand.inputEscape,modifierFlags:[],action:#selector(escapeText))]
    }
    @objc private func commitText() { finish?() }
    @objc private func escapeText() { if markedTextRange == nil { cancel?() } }
}
