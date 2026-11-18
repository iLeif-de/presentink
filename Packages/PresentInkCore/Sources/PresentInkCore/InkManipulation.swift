import Foundation
import CoreGraphics

/// Invisible hit regions shared by both clients. All calculations use physical
/// display proportions, not a square normalized coordinate system.
public struct InkManipulation: Sendable {
    public enum Handle: Equatable, Sendable { case move, endpoint(Int), rotate, edge(Int) }
    public let original: InkStroke
    public let handle: Handle
    public let start: InkPoint
    public let display: DisplayInfo
    public init(original: InkStroke, handle: Handle, start: InkPoint, display: DisplayInfo) {
        self.original = original; self.handle = handle; self.start = start; self.display = display
    }
    private func pixel(_ p: InkPoint) -> CGPoint { CGPoint(x:p.x*display.width,y:p.y*display.height) }
    private func normalized(_ p: CGPoint, pressure: Double = 0.5) -> InkPoint {
        func stable(_ value: Double) -> Double { (-0.000000001...1.000000001).contains(value) ? min(1,max(0,value)) : value }
        return InkPoint(x:stable(p.x/display.width),y:stable(p.y/display.height),pressure:pressure)
    }
    private static func rotate(_ p: CGPoint, around center: CGPoint, angle: Double) -> CGPoint {
        let x = p.x-center.x, y = p.y-center.y
        return CGPoint(x:center.x+x*cos(angle)-y*sin(angle),y:center.y+x*sin(angle)+y*cos(angle))
    }
    public static func corners(_ stroke: InkStroke, display: DisplayInfo) -> [CGPoint] {
        guard let a = stroke.points.first, let b = stroke.points.last else { return [] }
        let x0 = min(a.x,b.x)*display.width, x1 = max(a.x,b.x)*display.width
        let y0 = min(a.y,b.y)*display.height, y1 = max(a.y,b.y)*display.height
        let center = CGPoint(x:(x0+x1)/2,y:(y0+y1)/2)
        return [CGPoint(x:x0,y:y0),CGPoint(x:x1,y:y0),CGPoint(x:x1,y:y1),CGPoint(x:x0,y:y1)]
            .map { rotate($0,around:center,angle:stroke.rotation ?? 0) }
    }
    public static func hit(_ strokes: [InkStroke], at point: InkPoint, display: DisplayInfo, tolerance: Double = 12) -> InkManipulation? {
        let p = CGPoint(x:point.x*display.width,y:point.y*display.height)
        func distance(_ a: CGPoint, _ b: CGPoint) -> Double { hypot(a.x-b.x,a.y-b.y) }
        for stroke in strokes.reversed() {
            guard let first = stroke.points.first, let last = stroke.points.last else { continue }
            var handle: Handle?
            if stroke.tool == .rectangle || stroke.tool == .ellipse {
                let c = corners(stroke,display:display)
                let center = CGPoint(x:(first.x+last.x)*display.width/2,y:(first.y+last.y)*display.height/2)
                let width = abs(last.x-first.x)*display.width, height = abs(last.y-first.y)*display.height
                let local = rotate(p,around:center,angle:-(stroke.rotation ?? 0))
                // Tiny shapes retain a usable center; handles never consume the whole interior.
                let radius = min(tolerance,max(3,min(width,height)/4))
                if c.contains(where: { distance(p,$0) <= radius }) { handle = .rotate }
                else if let edge = (0..<4).first(where: { i in
                    distance(p,CGPoint(x:(c[i].x+c[(i+1)%4].x)/2,y:(c[i].y+c[(i+1)%4].y)/2)) <= radius
                }) { handle = .edge(edge) }
                else if stroke.tool == .rectangle {
                    if abs(local.x-center.x) <= width/2 && abs(local.y-center.y) <= height/2 { handle = .move }
                } else if width > 0, height > 0 {
                    let x = (local.x-center.x)/(width/2), y = (local.y-center.y)/(height/2)
                    if x*x+y*y <= 1 { handle = .move }
                }
                if handle == nil, InkGeometry.hits(stroke,at:point,display:display) { handle = .move }
            } else {
                if stroke.tool != .text, stroke.points.count > 1 {
                    let a = CGPoint(x:first.x*display.width,y:first.y*display.height)
                    let b = CGPoint(x:last.x*display.width,y:last.y*display.height)
                    let radius = min(tolerance,distance(a,b)/4)
                    if distance(p,a) <= radius { handle = .endpoint(0) }
                    else if distance(p,b) <= radius { handle = .endpoint(stroke.points.count-1) }
                }
                if handle == nil, InkGeometry.hits(stroke,at:point,display:display) { handle = .move }
            }
            if let handle { return InkManipulation(original:stroke,handle:handle,start:point,display:display) }
        }
        return nil
    }
    public func updated(to point: InkPoint, proportional: Bool) -> InkStroke {
        guard original.valid, point.valid, start.valid, display.valid else { return original }
        if let result = candidate(to:point,proportional:proportional) { return result }
        // Stop at the canvas boundary instead of snapping back to the original.
        var low = 0.0, high = 1.0, best = original
        for _ in 0..<12 {
            let fraction = (low+high)/2
            let intermediate = InkPoint(x:start.x+(point.x-start.x)*fraction,y:start.y+(point.y-start.y)*fraction)
            if let result = candidate(to:intermediate,proportional:proportional) { low = fraction; best = result }
            else { high = fraction }
        }
        return best
    }
    private func candidate(to point: InkPoint, proportional: Bool) -> InkStroke? {
        var result = original
        let p = pixel(point), down = pixel(start)
        guard hypot(p.x-down.x,p.y-down.y) >= 2 else { return original }
        let a = pixel(original.points[0]), b = pixel(original.points[original.points.count-1])
        let center = CGPoint(x:(a.x+b.x)/2,y:(a.y+b.y)/2)
        let angle = original.rotation ?? 0
        switch handle {
        case .move:
            let extent: [CGPoint]
            if original.tool == .rectangle || original.tool == .ellipse { extent = Self.corners(original,display:display) }
            else if original.tool == .text {
                let r = InkTextLayout.bounds(original,display:display)
                extent = [r.origin,CGPoint(x:r.maxX,y:r.maxY)]
            } else { extent = original.points.map(pixel) }
            let dx = min(display.width-(extent.map(\.x).max() ?? 0),max(-(extent.map(\.x).min() ?? 0),p.x-down.x))
            let dy = min(display.height-(extent.map(\.y).max() ?? 0),max(-(extent.map(\.y).min() ?? 0),p.y-down.y))
            result.points = original.points.map { normalized(CGPoint(x:pixel($0).x+dx,y:pixel($0).y+dy),pressure:$0.pressure) }
        case .endpoint(let index):
            let fixed = index == 0 ? b : a, moving = index == 0 ? a : b
            var target = CGPoint(x:moving.x+p.x-down.x,y:moving.y+p.y-down.y)
            if proportional {
                let snapped = InkGeometry.constrained(normalized(target),from:normalized(fixed),tool:.line,display:display,shift:true)
                target = pixel(snapped)
            }
            let oldLength = hypot(moving.x-fixed.x,moving.y-fixed.y)
            guard oldLength > 0.01 else { return original }
            let scale = hypot(target.x-fixed.x,target.y-fixed.y)/oldLength
            let rotation = atan2(target.y-fixed.y,target.x-fixed.x)-atan2(moving.y-fixed.y,moving.x-fixed.x)
            result.points = original.points.map {
                let q = pixel($0), turned = Self.rotate(q,around:fixed,angle:rotation)
                return normalized(CGPoint(x:fixed.x+(turned.x-fixed.x)*scale,y:fixed.y+(turned.y-fixed.y)*scale),pressure:$0.pressure)
            }
        case .rotate:
            let delta = atan2(p.y-center.y,p.x-center.x)-atan2(down.y-center.y,down.x-center.x)
            var next = angle+delta
            if proportional { next = (next/(.pi/4)).rounded() * (.pi/4) }
            let normalized = atan2(sin(next),cos(next))
            result.rotation = abs(atan2(sin(normalized-angle),cos(normalized-angle))) < 0.000000001 ? original.rotation : normalized
        case .edge(let index):
            let local = Self.rotate(p,around:center,angle:-angle)
            let initial = Self.rotate(down,around:center,angle:-angle)
            var left = min(a.x,b.x), right = max(a.x,b.x), top = min(a.y,b.y), bottom = max(a.y,b.y)
            let oldWidth = right-left, oldHeight = bottom-top
            guard oldWidth > 0.01, oldHeight > 0.01 else { return original }
            let minimum = 4.0
            switch index {
            case 0: top = min(bottom-minimum,top+local.y-initial.y)
            case 1: right = max(left+minimum,right+local.x-initial.x)
            case 2: bottom = max(top+minimum,bottom+local.y-initial.y)
            default: left = min(right-minimum,left+local.x-initial.x)
            }
            if proportional {
                if index == 0 || index == 2 {
                    let width = (bottom-top)*oldWidth/oldHeight
                    left = center.x-width/2; right = center.x+width/2
                } else {
                    let height = (right-left)*oldHeight/oldWidth
                    top = center.y-height/2; bottom = center.y+height/2
                }
            }
            // Moving a rotated side also moves the center in the rotated axes.
            let nextCenter = Self.rotate(CGPoint(x:(left+right)/2,y:(top+bottom)/2),around:center,angle:angle)
            let w = right-left, h = bottom-top
            result.points = [normalized(CGPoint(x:nextCenter.x-w/2,y:nextCenter.y-h/2),pressure:original.points[0].pressure),normalized(CGPoint(x:nextCenter.x+w/2,y:nextCenter.y+h/2),pressure:original.points.last!.pressure)]
        }
        if result.tool == .rectangle || result.tool == .ellipse {
            guard Self.corners(result,display:display).allSatisfy({ $0.x >= -0.001 && $0.y >= -0.001 && $0.x <= display.width+0.001 && $0.y <= display.height+0.001 }) else { return nil }
        }
        return result.valid ? result : nil
    }
    /// Only geometry may change; clients cannot alter style, identity, payload size or text.
    public static func validReplacement(_ replacement: InkStroke, for original: InkStroke) -> Bool {
        var expected = original; expected.points = replacement.points; expected.rotation = replacement.rotation
        return replacement.valid && replacement.points.count == original.points.count && replacement == expected
    }
}
