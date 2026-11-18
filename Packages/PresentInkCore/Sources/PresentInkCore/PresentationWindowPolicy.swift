import Foundation
import CoreGraphics

/// Numeric policy kept independent of AppKit so shield-level ordering is testable.
public enum PresentationWindowPolicy {
    public struct Levels: Equatable { public let overlay: Int; public let drawer: Int }
    public static func supports(bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else { return false }
        return ["com.apple.iwork.keynote", "com.apple.keynote", "com.microsoft.powerpoint", "org.libreoffice.script"].contains(bundleIdentifier.lowercased())
    }
    public static func coversDisplay(window: CGRect, display: CGRect) -> Bool {
        guard display.width > 0, display.height > 0,
              [window.minX,window.minY,window.width,window.height,display.minX,display.minY,display.width,display.height].allSatisfy(\.isFinite) else { return false }
        let intersection = window.intersection(display)
        return !intersection.isNull && intersection.width*intersection.height >= display.width*display.height*0.95
    }
    public static func levels(presentation: Int?, normal: Int, minimumPresentation: Int, maximum: Int) -> Levels {
        // Only two slots are needed: overlay and drawer. Reserving a third slot
        // for the retired text panel pinned the overlay to the shielding level.
        let ceiling = maximum-2
        let overlay: Int
        if let presentation {
            overlay = min(ceiling,max(minimumPresentation,min(presentation,ceiling-1)+1))
        } else { overlay = normal }
        return Levels(overlay:overlay,drawer:min(maximum-1,overlay+1))
    }
}
