import CoreGraphics
import CoreText
import PresentInkCore

/// Identical geometry on Mac and iPad; model coordinates always have a top-left origin.
enum InkRenderer {
    static func draw(_ stroke: InkStroke, in context: CGContext, size: CGSize) {
        guard let first = stroke.points.first, let last = stroke.points.last else { return }
        func point(_ p: InkPoint) -> CGPoint { CGPoint(x: p.x*size.width, y:p.y*size.height) }
        let a = point(first), b = point(last)
        let width = stroke.width*min(size.width,size.height)
        context.saveGState()
        if let angle = stroke.rotation {
            let center = CGPoint(x:(a.x+b.x)/2,y:(a.y+b.y)/2)
            context.translateBy(x:center.x,y:center.y); context.rotate(by:angle); context.translateBy(x:-center.x,y:-center.y)
        }
        let grouped = stroke.effectiveOpacity < 1
        if grouped {
            // Composite translucent segments once, bounded to the stroke rather than the whole screen.
            context.setAlpha(stroke.effectiveOpacity)
            let x = stroke.points.map { $0.x * size.width }, y = stroke.points.map { $0.y * size.height }
            let padding = max(20, (stroke.maximumWidth ?? stroke.width*1.5)*min(size.width,size.height)*3)
            var extent = CGRect(x: x.min() ?? a.x, y: y.min() ?? a.y,
                                width: (x.max() ?? a.x)-(x.min() ?? a.x), height: (y.max() ?? a.y)-(y.min() ?? a.y))
            if stroke.tool == .text { extent = InkTextLayout.bounds(stroke,display:DisplayInfo(width:size.width,height:size.height)) }
            context.beginTransparencyLayer(in: extent.insetBy(dx: -padding, dy: -padding), auxiliaryInfo: nil)
        }
        defer { if grouped { context.endTransparencyLayer() }; context.restoreGState() }
        context.setStrokeColor(CGColor(red: stroke.color.r, green:stroke.color.g, blue:stroke.color.b, alpha:1))
        context.setLineWidth(stroke.tool == .pen ? stroke.renderedWidth(pressure: first.pressure)*min(size.width,size.height) : width); context.setLineCap(.round); context.setLineJoin(.round)
        let rect = CGRect(x:min(a.x,b.x),y:min(a.y,b.y),width:abs(b.x-a.x),height:abs(b.y-a.y))
        switch stroke.tool {
        case .text:
            let display = DisplayInfo(width:size.width,height:size.height)
            let frame = InkTextLayout.bounds(stroke,display:display)
            let framesetter = CTFramesetterCreateWithAttributedString(InkTextLayout.attributed(stroke,display:display))
            context.textMatrix = .identity
            context.translateBy(x:frame.minX,y:frame.maxY); context.scaleBy(x:1,y:-1)
            let path = CGPath(rect:CGRect(origin:.zero,size:frame.size),transform:nil)
            CTFrameDraw(CTFramesetterCreateFrame(framesetter,CFRange(location:0,length:0),path,nil),context)

        case .rectangle: context.stroke(rect)
        case .ellipse: context.strokeEllipse(in:rect)
        case .line, .arrow:
            context.move(to:a); context.addLine(to:b)
            if stroke.tool == .arrow {
                let angle = atan2(b.y-a.y,b.x-a.x), length = max(14,width*3)
                for offset in [-CGFloat.pi/6,CGFloat.pi/6] {
                    context.move(to:b); context.addLine(to:CGPoint(x:b.x-length*cos(angle+offset),y:b.y-length*sin(angle+offset)))
                }
            }
            context.strokePath()
        default:
            if stroke.points.count == 1 { context.move(to:a); context.addLine(to:CGPoint(x:a.x+0.01,y:a.y)); context.strokePath() }
            else {
                // Pen pressure is rendered per segment; marker uses one path to avoid opacity seams.
                if stroke.tool == .pen {
                    for (p,q) in zip(stroke.points,stroke.points.dropFirst()) {
                        context.setLineWidth(stroke.renderedWidth(pressure: (p.pressure+q.pressure)/2)*min(size.width,size.height))
                        context.move(to:point(p)); context.addLine(to:point(q)); context.strokePath()
                    }
                } else { context.move(to:a); for p in stroke.points.dropFirst() { context.addLine(to:point(p)) }; context.strokePath() }
            }
        }
    }
}
