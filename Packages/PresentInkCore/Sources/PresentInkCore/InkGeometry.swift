import Foundation

public enum InkGeometry {
    public static func constrained(_ end: InkPoint, from start: InkPoint, tool: InkTool, display: DisplayInfo, shift: Bool) -> InkPoint {
        guard shift, tool.isShape else { return end }
        let dx = (end.x-start.x)*display.width, dy = (end.y-start.y)*display.height
        var x = dx, y = dy
        if tool == .ellipse || tool == .rectangle {
            let side = max(abs(dx),abs(dy)); x = dx < 0 ? -side : side; y = dy < 0 ? -side : side
        } else {
            let angle = (atan2(dy,dx)/(.pi/4)).rounded() * (.pi/4)
            x = hypot(dx,dy)*cos(angle); y = hypot(dx,dy)*sin(angle)
        }
        // Keep the aspect ratio/angle at edges: shrink the whole vector, never clamp axes independently.
        let nx = x/display.width, ny = y/display.height
        var scale = 1.0
        if nx > 0 { scale = min(scale, (1-start.x)/nx) }; if nx < 0 { scale = min(scale, -start.x/nx) }
        if ny > 0 { scale = min(scale, (1-start.y)/ny) }; if ny < 0 { scale = min(scale, -start.y/ny) }
        return InkPoint(x: min(1,max(0,start.x+nx*scale)), y: min(1,max(0,start.y+ny*scale)), pressure: end.pressure)
    }
    public static func hits(_ stroke: InkStroke, at point: InkPoint, display: DisplayInfo) -> Bool {
        var point = point
        if let angle = stroke.rotation, let first = stroke.points.first, let last = stroke.points.last {
            let cx = (first.x+last.x)*display.width/2, cy = (first.y+last.y)*display.height/2
            let x = point.x*display.width-cx, y = point.y*display.height-cy
            point.x = (cx+x*cos(angle)+y*sin(angle))/display.width
            point.y = (cy-x*sin(angle)+y*cos(angle))/display.height
        }
        guard let a = stroke.points.first, let b = stroke.points.last else { return false }
        if stroke.tool == .text {
            return InkTextLayout.bounds(stroke,display:display).insetBy(dx:-4,dy:-4).contains(CGPoint(x:point.x*display.width,y:point.y*display.height))
        }
        let radius = max(12, stroke.width*min(display.width,display.height)/2+8)
        var points = stroke.points
        if stroke.tool == .rectangle {
            points = [a,InkPoint(x:b.x,y:a.y),b,InkPoint(x:a.x,y:b.y),a]
        } else if stroke.tool == .ellipse {
            points = (0...256).map { i in
                let angle = Double(i)/256*2*Double.pi
                return InkPoint(x:(a.x+b.x)/2+abs(b.x-a.x)/2*cos(angle), y:(a.y+b.y)/2+abs(b.y-a.y)/2*sin(angle))
            }
        } else if stroke.tool == .line || stroke.tool == .arrow { points = [a,b] }
        if points.count == 1 { return hypot((a.x-point.x)*display.width,(a.y-point.y)*display.height) <= radius }
        var segments = Array(zip(points,points.dropFirst()))
        if stroke.tool == .arrow {
            let angle = atan2((b.y-a.y)*display.height,(b.x-a.x)*display.width)
            let size = max(14,stroke.width*min(display.width,display.height)*3)
            for offset in [-Double.pi/6,Double.pi/6] { segments.append((b,InkPoint(x:b.x-size*cos(angle+offset)/display.width,y:b.y-size*sin(angle+offset)/display.height))) }
        }
        return segments.contains { a,b in
            let dx = (b.x-a.x)*display.width, dy = (b.y-a.y)*display.height
            let px = (point.x-a.x)*display.width, py = (point.y-a.y)*display.height
            let length = dx*dx+dy*dy
            let t = length == 0 ? 0 : min(1,max(0,(px*dx+py*dy)/length))
            return hypot(px-t*dx,py-t*dy) <= radius
        }
    }
}
