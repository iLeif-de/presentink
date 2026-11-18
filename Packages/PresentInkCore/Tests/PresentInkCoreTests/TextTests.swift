import XCTest
@testable import PresentInkCore

final class TextTests: XCTestCase {
    func testInlineEditPreservesIdentityAndStyleAndRejectsStaleEdits() throws {
        var doc = InkDocument()
        let original = try DrawingSettings().textStroke("Alt",at:InkPoint(x:0.2,y:0.3),display:doc.snapshot.display)
        func command(_ action: InkAction) -> InkCommand { InkCommand(epoch:doc.snapshot.epoch,action:action) }
        XCTAssertTrue(doc.apply(command(.commit(original)),owner:"mac"))
        let edit = command(.editText(original:original,text:"Neu 👋\nZweite Zeile"))
        XCTAssertEqual(try JSONDecoder().decode(InkCommand.self,from:JSONEncoder().encode(edit)),edit)
        XCTAssertTrue(doc.apply(edit,owner:"ipad"))
        var expected = original; expected.text = "Neu 👋\nZweite Zeile"
        XCTAssertEqual(doc.snapshot.strokes,[expected])
        XCTAssertFalse(doc.apply(command(.editText(original:original,text:"Veraltet")),owner:"mac"))
        XCTAssertFalse(doc.apply(command(.editText(original:expected,text:String(repeating:"x",count:2001))),owner:"mac"))
        XCTAssertTrue(doc.apply(command(.undo),owner:"mac")); XCTAssertEqual(doc.snapshot.strokes,[original])
        XCTAssertTrue(doc.apply(command(.redo),owner:"mac")); XCTAssertEqual(doc.snapshot.strokes,[expected])
        let draft = DrawingSettings().stroke(at:InkPoint(x:0.1,y:0.1),display:doc.snapshot.display)
        XCTAssertTrue(doc.apply(command(.preview(draft)),owner:"mac"))
        XCTAssertFalse(doc.apply(command(.editText(original:expected,text:"Belegt")),owner:"ipad"))
        XCTAssertFalse(doc.apply(command(.editText(original:expected,text:"Belegt")),owner:"mac"))
    }
    func testTextValidationAndPayloadRoundTrip() throws {
        let settings = DrawingSettings(), display = DisplayInfo()
        let stroke = try settings.textStroke("Hallo iPad 👋\nZweite Zeile",at:InkPoint(x:0.2,y:0.3),display:display)
        XCTAssertTrue(stroke.valid); XCTAssertEqual(stroke.tool,.text)
        XCTAssertEqual(stroke.width*1080,28,accuracy:0.0001)
        XCTAssertEqual(try JSONDecoder().decode(InkStroke.self,from:JSONEncoder().encode(stroke)),stroke)
        for text in ["", "  \n", String(repeating:"x",count:2001), String(repeating:"Zeile\n",count:20), "abc\u{0}def"] {
            XCTAssertFalse(InkTextLayout.valid(text))
            XCTAssertThrowsError(try settings.textStroke(text,at:InkPoint(x:0.2,y:0.3),display:display))
        }
        var wrong = stroke; wrong.tool = .pen; XCTAssertFalse(wrong.valid)
        wrong = stroke; wrong.text = nil; XCTAssertFalse(wrong.valid)
    }
    func testTextHitTestUsesWholeLayoutAndStaysInsideDisplay() throws {
        let display = DisplayInfo(width:1000,height:700)
        let stroke = try DrawingSettings().textStroke("Lange Beschriftung\nZweite Zeile",at:InkPoint(x:0.2,y:0.3),display:display)
        let bounds = InkTextLayout.bounds(stroke,display:display)
        XCTAssertGreaterThan(bounds.width,100); XCTAssertGreaterThan(bounds.height,28)
        XCTAssertTrue(InkGeometry.hits(stroke,at:InkPoint(x:bounds.midX/1000,y:bounds.midY/700),display:display))
        XCTAssertFalse(InkGeometry.hits(stroke,at:InkPoint(x:0.9,y:0.9),display:display))
        let edge = try DrawingSettings().textStroke("Am Rand",at:InkPoint(x:1,y:1),display:display)
        let frame = InkTextLayout.bounds(edge,display:display)
        XCTAssertLessThanOrEqual(frame.maxX,1000); XCTAssertLessThanOrEqual(frame.maxY,700)
    }
    func testTextUndoRedoAndErase() throws {
        var doc = InkDocument()
        let text = try DrawingSettings().textStroke("Textobjekt",at:InkPoint(x:0.2,y:0.3),display:doc.snapshot.display)
        XCTAssertTrue(doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.commit(text)),owner:"mac"))
        XCTAssertTrue(doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.undo),owner:"mac"))
        XCTAssertTrue(doc.snapshot.strokes.isEmpty)
        XCTAssertTrue(doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.redo),owner:"mac"))
        let bounds = InkTextLayout.bounds(text,display:doc.snapshot.display)
        let target = InkPoint(x:bounds.midX/doc.snapshot.display.width,y:bounds.midY/doc.snapshot.display.height)
        XCTAssertTrue(doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.erase(target)),owner:"ipad"))
        XCTAssertTrue(doc.snapshot.strokes.isEmpty)
    }
    func testOldLibraryMigratesWithoutLosingCustomValues() throws {
        var library = DrawingLibrary(); library.current.styles[0].opacity = 0.42
        library.current.palette = [InkColor(0.1,0.2,0.3)]
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with:JSONEncoder().encode(library)) as? [String:Any])
        func old(_ original: [String:Any]) -> [String:Any] {
            var settings = original
            settings["styles"] = (settings["styles"] as! [[String:Any]]).filter { $0["tool"] as? String != "text" }
            settings["visibleTools"] = (settings["visibleTools"] as! [String]).filter { $0 != "text" }
            return settings
        }
        object["current"] = old(object["current"] as! [String:Any])
        object["profiles"] = (object["profiles"] as! [[String:Any]]).map { original in
            var profile = original; profile["settings"] = old(profile["settings"] as! [String:Any]); return profile
        }
        let migrated = try JSONDecoder().decode(DrawingLibrary.self,from:JSONSerialization.data(withJSONObject:object))
        XCTAssertTrue(migrated.valid); XCTAssertEqual(migrated.current.styles[0].opacity,0.42)
        XCTAssertEqual(migrated.current.palette,library.current.palette)
        XCTAssertTrue(migrated.current.visibleTools.contains(.text))
        XCTAssertTrue(migrated.profiles.allSatisfy { $0.settings.styles.contains { $0.tool == .text } })
    }
    func testMacKeepsTextPayloadButUsesItsOwnStyle() throws {
        var settings = DrawingSettings(); settings.tool = .text
        var incoming = try settings.textStroke("Vom iPad",at:InkPoint(x:0.2,y:0.3),display:DisplayInfo())
        incoming.color = InkColor(0,1,0); incoming.width = 0.09
        incoming.minimumWidth = nil; incoming.maximumWidth = nil
        let accepted = try XCTUnwrap(settings.authoritativeStroke(incoming,active:nil,display:DisplayInfo()))
        XCTAssertTrue(accepted.valid); XCTAssertEqual(accepted.text,"Vom iPad")
        XCTAssertEqual(accepted.color,settings.currentStyle.color)
        XCTAssertEqual(accepted.width*1080,28,accuracy:0.0001)
    }
}
