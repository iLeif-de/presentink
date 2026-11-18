import XCTest
@testable import PresentInkCore

final class DocumentTests: XCTestCase {
    func testDisplayResizePreservesAnnotationsAndUndoButRejectsOldCommands() {
        var doc = InkDocument(); let item = stroke()
        _ = doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.commit(item)),owner:"mac")
        let oldEpoch = doc.snapshot.epoch, oldSource = doc.snapshot.sourceEpoch
        doc.updateDisplay(DisplayInfo(name:"Projector",width:1920,height:1080))
        XCTAssertEqual(doc.snapshot.strokes,[item]); XCTAssertTrue(doc.snapshot.canUndo)
        XCTAssertNotEqual(doc.snapshot.epoch,oldEpoch)
        XCTAssertNotEqual(doc.snapshot.sourceEpoch,oldSource)
        XCTAssertFalse(doc.apply(InkCommand(epoch:oldEpoch,action:.clear),owner:"ipad"))
        _ = doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.undo),owner:"mac")
        XCTAssertTrue(doc.snapshot.strokes.isEmpty)
        _ = doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.redo),owner:"mac")
        XCTAssertEqual(doc.snapshot.strokes,[item])
    }
    func testUnchangedDisplayDoesNotChangeEpochOrRevision() {
        var doc = InkDocument(); let epoch = doc.snapshot.epoch, revision = doc.snapshot.revision
        doc.updateDisplay(doc.snapshot.display)
        XCTAssertEqual(doc.snapshot.epoch,epoch); XCTAssertEqual(doc.snapshot.revision,revision)
    }
    func testEraserMissDoesNotPublishOrCreateUndoHistory() {
        var doc = InkDocument(); let item = stroke()
        _ = doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.commit(item)),owner:"mac")
        let revision = doc.snapshot.revision
        for _ in 0..<120 {
            XCTAssertTrue(doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.erase(InkPoint(x:0.95,y:0.95))),owner:"ipad"))
        }
        XCTAssertEqual(doc.snapshot.revision,revision); XCTAssertEqual(doc.snapshot.strokes,[item])
        _ = doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.undo),owner:"mac")
        XCTAssertTrue(doc.snapshot.strokes.isEmpty)
    }
    private func stroke(_ tool: InkTool = .pen) -> InkStroke { InkStroke(tool:tool,color:.red,width:0.004,points:[InkPoint(x:0.1,y:0.1),InkPoint(x:0.3,y:0.2)]) }
    func testUndoRedoAndClearAreReversible() {
        var doc = InkDocument(); let item = stroke()
        XCTAssertTrue(doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.commit(item)),owner:"mac"))
        XCTAssertEqual(doc.snapshot.strokes,[item]); XCTAssertTrue(doc.snapshot.canUndo)
        _ = doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.clear),owner:"ipad")
        XCTAssertTrue(doc.snapshot.strokes.isEmpty)
        _ = doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.undo),owner:"ipad")
        XCTAssertEqual(doc.snapshot.strokes,[item])
        _ = doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.redo),owner:"ipad")
        XCTAssertTrue(doc.snapshot.strokes.isEmpty)
    }
    func testStrokeLeasePreventsInterleavedDevices() {
        var doc = InkDocument(); let item = stroke()
        XCTAssertTrue(doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.preview(item)),owner:"ipad"))
        XCTAssertFalse(doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.clear),owner:"mac"))
        doc.cancel(owner:"mac"); XCTAssertNotNil(doc.active)
        doc.cancel(owner:"ipad"); XCTAssertNil(doc.active)
        XCTAssertTrue(doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.clear),owner:"mac"))
    }
    func testEpochAndDuplicateCommands() {
        var doc = InkDocument(); let command = InkCommand(epoch:doc.snapshot.epoch,action:.commit(stroke()))
        XCTAssertTrue(doc.apply(command,owner:"ipad")); XCTAssertFalse(doc.apply(command,owner:"ipad"))
        doc.reset(display:DisplayInfo(name:"Beamer",width:1024,height:768))
        XCTAssertFalse(doc.apply(command,owner:"ipad")); XCTAssertTrue(doc.snapshot.strokes.isEmpty)
    }
    func testStalePreviewCannotResurrectCommittedStroke() {
        var doc = InkDocument(); let item = stroke()
        _ = doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.commit(item)),owner:"ipad")
        XCTAssertFalse(doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.preview(item)),owner:"ipad"))
        XCTAssertNil(doc.active)
    }
    func testValidationRejectsOutOfRangeSamples() {
        var doc = InkDocument(); var item = stroke(); item.points[0].x = -1
        XCTAssertFalse(doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.commit(item)),owner:"ipad"))
        item = stroke(); item.width = .infinity; XCTAssertFalse(item.valid)
        item = stroke(); item.points = Array(repeating:InkPoint(x:0.5,y:0.5),count:8_001); XCTAssertFalse(item.valid)
    }
    func testCircleConstraintUsesDisplayAspectInAllQuadrants() {
        let display = DisplayInfo(width:1920,height:1080), start = InkPoint(x:0.5,y:0.5)
        for x in [0.4,0.6] { for y in [0.4,0.6] { for tool in [InkTool.ellipse,.rectangle] {
            let end = InkGeometry.constrained(InkPoint(x:x,y:y),from:start,tool:tool,display:display,shift:true)
            XCTAssertEqual(abs(end.x-start.x)*display.width,abs(end.y-start.y)*display.height,accuracy:0.0001)
            XCTAssertEqual(end.x < start.x,x < start.x)
        } } }
        let edge = InkGeometry.constrained(InkPoint(x:1,y:0.8),from:InkPoint(x:0.9,y:0.5),tool:.ellipse,display:display,shift:true)
        XCTAssertTrue(edge.valid); XCTAssertEqual((edge.x-0.9)*1920,(edge.y-0.5)*1080,accuracy:0.0001)
    }
    func testShapeEraserHitsContourButNotEmptyInterior() {
        let display = DisplayInfo(width:1000,height:1000)
        var item = InkStroke(tool:.rectangle,color:.red,width:0.004,points:[InkPoint(x:0.1,y:0.1),InkPoint(x:0.9,y:0.9)])
        XCTAssertTrue(InkGeometry.hits(item,at:InkPoint(x:0.1,y:0.5),display:display))
        XCTAssertFalse(InkGeometry.hits(item,at:InkPoint(x:0.5,y:0.5),display:display))
        item.tool = .ellipse
        XCTAssertTrue(InkGeometry.hits(item,at:InkPoint(x:0.5,y:0.1),display:display))
        XCTAssertFalse(InkGeometry.hits(item,at:InkPoint(x:0.5,y:0.5),display:display))
    }
}
