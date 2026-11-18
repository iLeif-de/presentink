import XCTest
@testable import PresentInkCore

final class DrawingSettingsTests: XCTestCase {
    func testDefaultsAndBuiltInProfilesAreValid() {
        let library = DrawingLibrary()
        XCTAssertTrue(library.valid)
        XCTAssertEqual(library.profiles.map(\.name), ["Helle Folien", "Dunkle Folien", "Whiteboard"])
        XCTAssertEqual(library.current.style(for: .marker).opacity, 0.3)
        XCTAssertEqual(library.current.style(for: .marker).width, 16)
    }
    func testMalformedConfigurationIsRejected() {
        var settings = DrawingSettings()
        settings.palette = []; XCTAssertFalse(settings.valid)
        settings = DrawingSettings(); settings.visibleTools = [.pen,.pen]; XCTAssertFalse(settings.valid)
        settings = DrawingSettings(); settings.styles.removeLast(); XCTAssertFalse(settings.valid)
        settings = DrawingSettings(); settings.styles[0].opacity = .nan; XCTAssertFalse(settings.valid)
        settings = DrawingSettings(); settings.styles[0].minimum = 13; XCTAssertFalse(settings.valid)
        settings = DrawingSettings(); settings.styles[0].quickWidths[0] = 99; XCTAssertFalse(settings.valid)
        settings = DrawingSettings(); settings.pressureSensitivity = .infinity; XCTAssertFalse(settings.valid)
    }
    func testRequestsUseTheSelectedToolsOwnLimits() throws {
        let settings = DrawingSettings()
        XCTAssertThrowsError(try DrawingSelection(width: 20).applying(to: settings))
        let marker = try DrawingSelection(tool: .marker, width: 20).applying(to: settings)
        XCTAssertEqual(marker.currentStyle.width, 20)
        XCTAssertEqual(marker.style(for: .pen).width, 4)
        XCTAssertThrowsError(try DrawingSelection(width: .nan).applying(to: marker))
    }
    func testPointWidthsMatchTheMacDisplayAndPressureIsBounded() {
        var settings = DrawingSettings()
        var style = settings.currentStyle
        style.width = 10; style.minimum = 9; style.maximum = 11; style.quickWidths = [9,10,11]
        settings.setStyle(style)
        let display = DisplayInfo(width:1920,height:1080)
        let stroke = settings.stroke(at:InkPoint(x:0.5,y:0.5),display:display)
        XCTAssertTrue(stroke.valid)
        XCTAssertEqual(stroke.width*1080,10,accuracy:0.00001)
        XCTAssertEqual(stroke.renderedWidth(pressure:0)*1080,9,accuracy:0.00001)
        XCTAssertEqual(stroke.renderedWidth(pressure:1)*1080,11,accuracy:0.00001)
        settings.pressureEnabled = false
        let constant = settings.stroke(at:InkPoint(x:0.5,y:0.5),display:display)
        XCTAssertEqual(constant.renderedWidth(pressure:0),constant.renderedWidth(pressure:1))
    }
    func testExistingStrokesKeepTheirOriginalAppearance() throws {
        var settings = DrawingSettings(); settings.tool = .marker
        let original = settings.stroke(at:InkPoint(x:0.2,y:0.3),display:DisplayInfo())
        var style = settings.currentStyle; style.opacity = 0.7; style.color = InkColor(0,1,0); style.width = 30
        settings.setStyle(style)
        let next = settings.stroke(at:InkPoint(x:0.2,y:0.3),display:DisplayInfo())
        XCTAssertEqual(original.effectiveOpacity,0.3)
        XCTAssertEqual(next.effectiveOpacity,0.7)
        XCTAssertNotEqual(original.color,next.color)
        XCTAssertNotEqual(original.width,next.width)
        XCTAssertEqual(try JSONDecoder().decode(InkStroke.self,from:JSONEncoder().encode(original)),original)
    }
    func testMacOverridesClientStyleAndFreezesItAcrossSamples() throws {
        var settings = DrawingSettings()
        let point = InkPoint(x:0.2,y:0.3)
        let forged = InkStroke(tool:.pen,color:InkColor(0,1,0),width:0.09,points:[point],opacity:0.9)
        let initial = try XCTUnwrap(settings.authoritativeStroke(forged,active:nil,display:DisplayInfo()))
        XCTAssertEqual(initial.color,settings.currentStyle.color)
        XCTAssertEqual(initial.effectiveOpacity,1)
        XCTAssertNotEqual(initial.width,forged.width)
        settings.styles[0].opacity = 0.2
        let final = try XCTUnwrap(settings.authoritativeStroke(forged,active:initial,display:DisplayInfo()))
        XCTAssertEqual(final.effectiveOpacity,1)
        var stale = forged; stale.tool = .ellipse
        XCTAssertNil(settings.authoritativeStroke(stale,active:nil,display:DisplayInfo()))
    }
    func testLegacyStrokesDecodeWithTheirOriginalDefaults() throws {
        let id = UUID()
        let json = "{\"id\":\"\(id)\",\"tool\":\"marker\",\"color\":{\"r\":1,\"g\":0,\"b\":0},\"width\":0.016,\"points\":[{\"x\":0.2,\"y\":0.3,\"pressure\":0.5}]}"
        let stroke = try JSONDecoder().decode(InkStroke.self,from:Data(json.utf8))
        XCTAssertTrue(stroke.valid); XCTAssertEqual(stroke.effectiveOpacity,0.3)
        XCTAssertEqual(stroke.width,0.016); XCTAssertNil(stroke.minimumWidth)
    }
    func testPersistenceRoundTripAndCorruptionDetection() throws {
        let suite = "PresentInkTests-\(UUID())"
        // A unique defaults domain never touches the application's real preferences.
        let isolated = UserDefaults(suiteName:suite)!
        defer { isolated.removePersistentDomain(forName:suite) }
        let repo = DrawingPreferencesRepository(defaults:isolated)
        var library = DrawingLibrary(); library.current.tool = .ellipse; library.activeProfile = nil
        try repo.save(library)
        XCTAssertEqual(try DrawingPreferencesRepository(defaults:isolated).load(),library)
        isolated.set(Data("corrupt".utf8),forKey:"drawing-library-v1")
        XCTAssertThrowsError(try repo.load())
    }
    func testSyncStateRejectsDuplicateProfiles() {
        var state = DrawingSyncState(revision:12,library:DrawingLibrary())
        XCTAssertTrue(state.valid)
        state.profiles = ["A","A"]; XCTAssertFalse(state.valid)
    }
    func testRememberedPermissionAndManualPauseAreIndependent() {
        var policy = PreviewPolicy()
        XCTAssertFalse(policy.mayStart(connected:true,requested:true,manuallyPaused:false))
        policy.trusted = true
        XCTAssertTrue(policy.mayStart(connected:true,requested:true,manuallyPaused:true))
        XCTAssertFalse(policy.mayStart(connected:true,requested:false,manuallyPaused:false))
        policy.autoStart = true
        XCTAssertTrue(policy.mayStart(connected:true,requested:false,manuallyPaused:false))
        XCTAssertFalse(policy.mayStart(connected:true,requested:false,manuallyPaused:true))
        XCTAssertFalse(policy.mayStart(connected:false,requested:true,manuallyPaused:false))
    }
}
