import XCTest
@testable import PresentInkCore

final class SlideChangeTests: XCTestCase {
    func stroke() -> InkStroke { InkStroke(tool:.arrow,color:.red,width:0.004,points:[InkPoint(x:0.2,y:0.2),InkPoint(x:0.6,y:0.6)]) }
    func testSuccessfulNavigationClearsUndoablyAndRejectsOldInput() throws {
        var doc = InkDocument(); let ink = stroke()
        XCTAssertTrue(doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.commit(ink)),owner:"mac"))
        XCTAssertTrue(doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.visibility(false)),owner:"mac"))
        let before = doc.snapshot
        let stale = InkCommand(epoch:before.epoch,action:.commit(stroke()))
        var calls = 0
        XCTAssertTrue(doc.performSlideChange { calls += 1; return true })
        XCTAssertEqual(calls,1); XCTAssertTrue(doc.snapshot.strokes.isEmpty)
        XCTAssertNotEqual(doc.snapshot.epoch,before.epoch); XCTAssertTrue(doc.snapshot.canUndo)
        XCTAssertEqual(doc.snapshot.sourceEpoch,before.sourceEpoch)
        XCTAssertEqual(doc.snapshot.display,before.display)
        XCTAssertEqual(doc.snapshot.overlayVisible,before.overlayVisible)
        XCTAssertFalse(doc.apply(stale,owner:"ipad"))
        XCTAssertTrue(doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.undo),owner:"mac"))
        XCTAssertEqual(doc.snapshot.strokes,[ink])
    }
    func testFailedNavigationPreservesDocumentAndRedoHistory() throws {
        enum Failure: Error { case denied }
        var doc = InkDocument(); let first = stroke(), second = stroke()
        for ink in [first,second] { XCTAssertTrue(doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.commit(ink)),owner:"mac")) }
        XCTAssertTrue(doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.undo),owner:"mac"))
        let before = doc.snapshot
        XCTAssertThrowsError(try doc.performSlideChange { throw Failure.denied })
        XCTAssertEqual(doc.snapshot,before)
        XCTAssertTrue(doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.redo),owner:"mac"))
        XCTAssertEqual(doc.snapshot.strokes,[first,second])
    }
    func testThrottledAndBusyNavigationDoNotClearOrCallHandler() throws {
        var doc = InkDocument(); let ink = stroke()
        XCTAssertTrue(doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.commit(ink)),owner:"mac"))
        let before = doc.snapshot
        XCTAssertFalse(doc.performSlideChange { false }); XCTAssertEqual(doc.snapshot,before)
        let draft = stroke()
        XCTAssertTrue(doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:.preview(draft)),owner:"ipad"))
        var called = false
        XCTAssertFalse(doc.performSlideChange { called = true; return true })
        XCTAssertFalse(called); XCTAssertEqual(doc.active,draft); XCTAssertEqual(doc.owner,"ipad")
        XCTAssertEqual(doc.snapshot.strokes,[ink])
    }
    func testEmptySuccessfulNavigationStillInvalidatesOldCommands() {
        var doc = InkDocument(); let before = doc.snapshot
        XCTAssertTrue(doc.performSlideChange { true })
        XCTAssertNotEqual(doc.snapshot.epoch,before.epoch)
        XCTAssertFalse(doc.snapshot.canUndo)
        XCTAssertFalse(doc.apply(InkCommand(epoch:before.epoch,action:.preview(stroke())),owner:"ipad"))
    }
}
