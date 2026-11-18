import XCTest
@testable import PresentInkCore

final class LocalizationTests: XCTestCase {
    func testUSEnglishAndGermanLabels() {
        XCTAssertEqual(InkLocalization.text("Rückgängig",language:"en-US"),"Undo")
        XCTAssertEqual(InkLocalization.text("Farbe",language:"en-US"),"Color")
        XCTAssertEqual(InkLocalization.text("Rückgängig",language:"de-DE"),"Rückgängig")
    }
    func testDynamicValuesArePreserved() {
        XCTAssertEqual(InkLocalization.format("Quelle: %@",arguments:["BenQ LCD"],language:"en-US"),"Source: BenQ LCD")
        XCTAssertEqual(InkLocalization.format("Einstellung ungültig. Breite muss im Werkzeugbereich %@–%@ pt liegen.",arguments:["2","12"],language:"en-US"),"Invalid setting. Width must be within the tool's range of 2–12 pt.")
    }
    func testUnknownNamesAndIDsAreNotTranslated() {
        XCTAssertEqual(InkLocalization.text("My personal profile",language:"en-US"),"My personal profile")
        XCTAssertEqual(InkLocalization.text("stroke_width",language:"en-US"),"stroke_width")
    }
    func testValueAliasesRemainLanguageIndependent() throws {
        XCTAssertEqual(try AutomationValues.tool("stift"),try AutomationValues.tool("pen"))
        XCTAssertEqual(try AutomationValues.color("rot"),try AutomationValues.color("red"))
    }
}
