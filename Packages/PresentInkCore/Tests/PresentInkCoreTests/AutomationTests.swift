import XCTest
@testable import PresentInkCore

final class AutomationTests: XCTestCase {
    func testAliasesUseSameToolAndColorAsTheNativeUI() throws {
        XCTAssertEqual(try AutomationValues.tool(" Stift "), .pen)
        XCTAssertEqual(try AutomationValues.tool("highlighter"), .marker)
        XCTAssertEqual(try AutomationValues.tool("Rechteck"), .rectangle)
        XCTAssertEqual(try AutomationValues.color("ROT"), InkColor.palette[0])
        XCTAssertEqual(try AutomationValues.color("graphite"), InkColor.palette[5])
        XCTAssertThrowsError(try AutomationValues.tool("laser"))
    }
    func testHexColorsRoundTripAndMalformedInputIsRejected() throws {
        XCTAssertEqual(AutomationValues.hex(try AutomationValues.color("#18a2FF")), "#18A2FF")
        for invalid in ["18A2FF", "#123", "#12345678", "#GG1122", "transparent", ""] {
            XCTAssertThrowsError(try AutomationValues.color(invalid))
        }
    }
    func testPresetColorReadWriteRoundTripKeepsNativeSelection() throws {
        for color in InkColor.palette { XCTAssertEqual(try AutomationValues.color(AutomationValues.hex(color)), color) }
    }
    func testWidthsRejectRatherThanSilentlyClamp() throws {
        XCTAssertEqual(try AutomationValues.width(2), 2)
        XCTAssertEqual(try AutomationValues.width(12), 12)
        XCTAssertEqual(try AutomationValues.width(4.5), 4.5)
        for invalid in [-1.0, 1.99, 12.01, .infinity, .nan] { XCTAssertThrowsError(try AutomationValues.width(invalid)) }
    }
    func testDrawerStatesAreExplicitAndIdempotent() throws {
        XCTAssertEqual(try AutomationValues.drawer("ausgezogen"), "expanded")
        XCTAssertEqual(try AutomationValues.drawer("compact"), "compact")
        XCTAssertEqual(try AutomationValues.drawer("versteckt"), "hidden")
        XCTAssertEqual(try AutomationValues.drawer("invisible"), "invisible")
        XCTAssertEqual(try AutomationValues.drawer("unsichtbar"), "invisible")
        XCTAssertThrowsError(try AutomationValues.drawer("sometimes"))
    }
    func testAppleEventCodesAreUniqueFourCharacterCodes() {
        let codes = InkAutomationOperation.allCases.map(\.scriptEventCode)
        XCTAssertEqual(Set(codes).count, codes.count)
        XCTAssertTrue(codes.allSatisfy { $0.utf8.count == 4 })
    }
}
