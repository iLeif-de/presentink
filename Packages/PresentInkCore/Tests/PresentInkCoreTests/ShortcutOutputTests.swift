import XCTest
@testable import PresentInkCore

final class ShortcutOutputTests: XCTestCase {
    func testStatusDecodesNativeFieldTypesAndNulls() throws {
        let json = ##"{"app_hidden":true,"drawing_enabled":false,"annotations_visible":true,"drawer_state":"invisible","mac_drawer_visible":false,"tool":"text","color":"#123456","stroke_width":28,"opacity":0.4,"width_minimum":8,"width_maximum":96,"active_profile":null,"display_index":1,"display_name":"Display","connection_enabled":true,"ipad_connected":true,"preview_enabled":false,"preview_state":"paused","preview_detail":"Pause","preview_trusted":true,"preview_auto_start":false,"stroke_count":3,"can_undo":true,"can_redo":false,"stroke_in_progress":false,"drawing_settings_synced":true,"last_error":null}"##
        let result = try AutomationStatus.decode(json)
        XCTAssertEqual(result.tool,.text); XCTAssertEqual(result.strokeWidth,28)
        XCTAssertTrue(result.annotationsVisible); XCTAssertFalse(result.drawingEnabled)
        XCTAssertEqual(result.opacity,0.4); XCTAssertNil(result.activeProfile); XCTAssertNil(result.lastError)
        XCTAssertEqual(result.strokeCount,3); XCTAssertTrue(result.drawingSettingsSynced)
    }
    func testStoppedAppAndAmbiguousCopiesAreErrors() throws {
        XCTAssertThrowsError(try ShortcutAvailability.runningPID([]))
        XCTAssertThrowsError(try ShortcutAvailability.runningPID([12,13]))
        XCTAssertEqual(try ShortcutAvailability.runningPID([12]),12)
    }
    func testRequestRoundTripPreservesExplicitArguments() throws {
        let request = ShortcutRequest(.setDisplay,number:2,clearExisting:true)
        let restored = try JSONDecoder().decode(ShortcutRequest.self,from:JSONEncoder().encode(request))
        XCTAssertEqual(restored.id,request.id); XCTAssertEqual(restored.operation,.setDisplay)
        XCTAssertEqual(restored.number,2); XCTAssertTrue(restored.clearExisting); XCTAssertFalse(restored.confirmed)
    }
}
