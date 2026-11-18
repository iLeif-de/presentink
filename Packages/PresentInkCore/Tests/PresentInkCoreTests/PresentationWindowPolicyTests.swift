import XCTest
@testable import PresentInkCore

final class PresentationWindowPolicyTests: XCTestCase {
    func testShieldLevelHasRoomForOverlayAndDrawer() {
        let shield = 2_147_483_628, maximum = 2_147_483_631
        let result = PresentationWindowPolicy.levels(presentation:shield,normal:24,minimumPresentation:1001,maximum:maximum)
        XCTAssertEqual(result.overlay,shield+1)
        XCTAssertEqual(result.drawer,shield+2)
        XCTAssertLessThan(result.drawer,maximum)
    }
    func testNormalAndLowerPresentationLevels() {
        XCTAssertEqual(PresentationWindowPolicy.levels(presentation:nil,normal:24,minimumPresentation:1001,maximum:2_147_483_631).overlay,24)
        let result = PresentationWindowPolicy.levels(presentation:1000,normal:24,minimumPresentation:1001,maximum:2_147_483_631)
        XCTAssertEqual(result.overlay,1001); XCTAssertEqual(result.drawer,1002)
    }
    func testUnknownVeryHighLevelsAreCappedWithoutOverflow() {
        let result = PresentationWindowPolicy.levels(presentation:Int.max,normal:24,minimumPresentation:1001,maximum:2_147_483_631)
        XCTAssertEqual(result.overlay,2_147_483_629); XCTAssertEqual(result.drawer,2_147_483_630)
    }
    func testFullscreenCoverageOnOffsetDisplay() {
        let display = CGRect(x:0,y:-900,width:1440,height:900)
        XCTAssertTrue(PresentationWindowPolicy.coversDisplay(window:display,display:display))
        XCTAssertTrue(PresentationWindowPolicy.coversDisplay(window:CGRect(x:0,y:-880,width:1440,height:880),display:display))
        XCTAssertFalse(PresentationWindowPolicy.coversDisplay(window:CGRect(x:0,y:-900,width:720,height:900),display:display))
        XCTAssertFalse(PresentationWindowPolicy.coversDisplay(window:CGRect(x:0,y:0,width:1440,height:900),display:display))
    }
    func testInvalidDisplayGeometryDoesNotTriggerFullscreen() {
        XCTAssertFalse(PresentationWindowPolicy.coversDisplay(window:.zero,display:.zero))
        XCTAssertFalse(PresentationWindowPolicy.coversDisplay(window:CGRect(x:0,y:0,width:100,height:100),display:CGRect(x:0,y:0,width:0,height:100)))
    }
    func testKnownPresentationApplicationsOnly() {
        for id in ["com.apple.iWork.Keynote","com.apple.Keynote","com.microsoft.Powerpoint","org.libreoffice.script"] {
            XCTAssertTrue(PresentationWindowPolicy.supports(bundleIdentifier:id))
        }
        XCTAssertFalse(PresentationWindowPolicy.supports(bundleIdentifier:"com.apple.loginwindow"))
        XCTAssertFalse(PresentationWindowPolicy.supports(bundleIdentifier:nil))
    }
}
