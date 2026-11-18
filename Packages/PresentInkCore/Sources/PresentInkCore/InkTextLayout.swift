import Foundation
import CoreGraphics
import CoreText

/// Shared measurement and glyph layout so hit testing and both renderers agree.
public enum InkTextLayout {
    public static func valid(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && text.count <= 2_000 &&
        text.utf8.count <= 16_384 && text.components(separatedBy: "\n").count <= 20 &&
        text.unicodeScalars.allSatisfy { !CharacterSet.controlCharacters.contains($0) || $0 == "\n" || $0 == "\t" }
    }
    public static func attributed(_ stroke: InkStroke, display: DisplayInfo) -> CFAttributedString {
        let size = max(1, stroke.width*min(display.width,display.height))
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName("Helvetica" as CFString, size, nil),
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(red:stroke.color.r,green:stroke.color.g,blue:stroke.color.b,alpha:1)
        ]
        return NSAttributedString(string:stroke.text ?? "",attributes:attributes) as CFAttributedString
    }
    public static func bounds(_ stroke: InkStroke, display: DisplayInfo) -> CGRect {
        guard let anchor = stroke.points.first, let text = stroke.text, !text.isEmpty else { return .zero }
        let font = max(1,stroke.width*min(display.width,display.height))
        // Keep at least a short first line inside the display even when tapping its far edge.
        let x = min(anchor.x*display.width,max(0,display.width-font*2))
        let y = min(anchor.y*display.height,max(0,display.height-font*1.5))
        let available = CGSize(width:max(1,display.width-x),height:max(1,display.height-y))
        let framesetter = CTFramesetterCreateWithAttributedString(attributed(stroke,display:display))
        let measured = CTFramesetterSuggestFrameSizeWithConstraints(framesetter,CFRange(location:0,length:0),nil,available,nil)
        return CGRect(x:x,y:y,width:min(available.width,max(1,ceil(measured.width)+2)),height:min(available.height,max(font*1.3,ceil(measured.height)+2)))
    }
}
