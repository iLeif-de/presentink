import XCTest
@testable import PresentInkCore

final class ManipulationTests: XCTestCase {
    let display = DisplayInfo(width:1000,height:500)
    func shape(_ tool: InkTool = .rectangle) -> InkStroke {
        InkStroke(tool:tool,color:.red,width:0.004,points:[InkPoint(x:0.3,y:0.3),InkPoint(x:0.7,y:0.7)])
    }
    func point(_ x: Double, _ y: Double) -> InkPoint { InkPoint(x:x,y:y) }
    func testHitRegionsAndTopmostObjectPriority() {
        let rect = shape(), ellipse = shape(.ellipse), line = shape(.arrow)
        XCTAssertEqual(InkManipulation.hit([rect],at:point(0.5,0.5),display:display)?.handle,.move)
        XCTAssertEqual(InkManipulation.hit([rect],at:point(0.3,0.3),display:display)?.handle,.rotate)
        XCTAssertEqual(InkManipulation.hit([rect],at:point(0.7,0.5),display:display)?.handle,.edge(1))
        XCTAssertEqual(InkManipulation.hit([ellipse],at:point(0.5,0.3),display:display)?.handle,.edge(0))
        XCTAssertEqual(InkManipulation.hit([line],at:point(0.7,0.7),display:display)?.handle,.endpoint(1))
        XCTAssertEqual(InkManipulation.hit([rect,line],at:point(0.5,0.5),display:display)?.original.id,line.id)
        XCTAssertNil(InkManipulation.hit([rect],at:point(0.9,0.9),display:display))
    }
    func testMoveClampsWholeObjectWithoutDistortingGeometry() {
        let original = shape()
        let click = InkManipulation(original:original,handle:.edge(1),start:point(0.7,0.5),display:display)
        XCTAssertEqual(click.updated(to:point(0.7,0.5),proportional:true),original)
        let drag = InkManipulation(original:original,handle:.move,start:point(0.5,0.5),display:display)
        let moved = drag.updated(to:point(1,1),proportional:false)
        XCTAssertEqual(moved.points[1].x,1,accuracy:0.000001)
        XCTAssertEqual(moved.points[1].y,1,accuracy:0.000001)
        XCTAssertEqual(moved.points[1].x-moved.points[0].x,0.4,accuracy:0.000001)
        XCTAssertEqual(moved.id,original.id); XCTAssertEqual(moved.color,original.color)
        XCTAssertTrue(InkManipulation.validReplacement(moved,for:original))
    }
    func testEndpointAnchorsOtherEndAndSnapsInDisplayCoordinates() {
        let original = shape(.arrow)
        let drag = InkManipulation(original:original,handle:.endpoint(1),start:point(0.7,0.7),display:display)
        let moved = drag.updated(to:point(0.6,0.8),proportional:true)
        XCTAssertEqual(moved.points[0].x,original.points[0].x,accuracy:0.000001)
        XCTAssertEqual(moved.points[0].y,original.points[0].y,accuracy:0.000001)
        let dx = (moved.points[1].x-moved.points[0].x)*display.width
        let dy = (moved.points[1].y-moved.points[0].y)*display.height
        XCTAssertEqual(abs(dx),abs(dy),accuracy:0.000001)
    }
    func testSideResizeAndProportionalResizeKeepOppositeSide() {
        let original = shape()
        let drag = InkManipulation(original:original,handle:.edge(1),start:point(0.7,0.5),display:display)
        let wide = drag.updated(to:point(0.8,0.5),proportional:false)
        XCTAssertEqual(wide.points[0].x,0.3,accuracy:0.000001)
        XCTAssertEqual(wide.points[1].x,0.8,accuracy:0.000001)
        XCTAssertEqual(wide.points[0].y,0.3,accuracy:0.000001)
        let proportional = drag.updated(to:point(0.8,0.5),proportional:true)
        let width = (proportional.points[1].x-proportional.points[0].x)*display.width
        let height = (proportional.points[1].y-proportional.points[0].y)*display.height
        XCTAssertEqual(width/height,2,accuracy:0.000001)
        XCTAssertEqual((proportional.points[0].y+proportional.points[1].y)/2,0.5,accuracy:0.000001)
    }
    func testRotationHitTestingAndResizingRotatedEdge() {
        var original = shape(); original.rotation = .pi/2
        let corners = InkManipulation.corners(original,display:display)
        XCTAssertEqual(corners[0].x,600,accuracy:0.000001)
        XCTAssertEqual(corners[0].y,50,accuracy:0.000001)
        XCTAssertTrue(InkGeometry.hits(original,at:point(0.6,0.5),display:display))
        XCTAssertFalse(InkGeometry.hits(original,at:point(0.8,0.5),display:display))
        let drag = InkManipulation(original:original,handle:.edge(1),start:point(0.5,0.9),display:display)
        let resized = drag.updated(to:point(0.5,0.95),proportional:false)
        let c = InkManipulation.corners(resized,display:display)
        XCTAssertEqual(c[0].y,50,accuracy:0.000001)
        XCTAssertEqual(c[1].y,475,accuracy:0.000001)
        let rotate = InkManipulation(original:shape(),handle:.rotate,start:point(0.7,0.7),display:display)
        XCTAssertEqual(rotate.updated(to:point(0.4,0.9),proportional:true).rotation ?? 0,.pi/2,accuracy:0.000001)
    }
    func testResizeStopsAtBoundaryAndPreservesRatio() {
        let original = shape()
        let drag = InkManipulation(original:original,handle:.edge(1),start:point(0.7,0.5),display:display)
        let result = drag.updated(to:point(1,0.5),proportional:true)
        XCTAssertTrue(result.valid)
        let width = (result.points[1].x-result.points[0].x)*display.width
        let height = (result.points[1].y-result.points[0].y)*display.height
        XCTAssertEqual(width/height,2,accuracy:0.000001)
        XCTAssertLessThanOrEqual(result.points[1].x,1)
        XCTAssertGreaterThan(result.points[1].x,0.99)
    }
    func testTransformLeaseStaleProtectionStyleValidationAndSingleUndo() throws {
        var doc = InkDocument(); let original = shape()
        func command(_ action: InkAction) -> InkCommand { InkCommand(epoch:doc.snapshot.epoch,action:action) }
        XCTAssertTrue(doc.apply(command(.commit(original)),owner:"mac"))
        var changed = original; changed.points = [point(0.4,0.3),point(0.8,0.7)]
        XCTAssertTrue(doc.apply(command(.previewTransform(original:original,replacement:changed)),owner:"ipad"))
        XCTAssertEqual(doc.snapshot.strokes,[original]); XCTAssertEqual(doc.active,changed)
        XCTAssertFalse(doc.apply(command(.commitTransform(original:original,replacement:changed)),owner:"mac"))
        XCTAssertFalse(doc.apply(command(.commit(changed)),owner:"ipad"))
        var tampered = changed; tampered.color = InkColor(0,0,0)
        XCTAssertFalse(doc.apply(command(.commitTransform(original:original,replacement:tampered)),owner:"ipad"))
        XCTAssertTrue(doc.apply(command(.commitTransform(original:original,replacement:changed)),owner:"ipad"))
        XCTAssertFalse(doc.apply(command(.commitTransform(original:original,replacement:changed)),owner:"mac"))
        XCTAssertTrue(doc.apply(command(.undo),owner:"mac")); XCTAssertEqual(doc.snapshot.strokes,[original])
        XCTAssertTrue(doc.apply(command(.redo),owner:"mac")); XCTAssertEqual(doc.snapshot.strokes,[changed])
        let preview = command(.previewTransform(original:changed,replacement:changed))
        XCTAssertEqual(try JSONDecoder().decode(InkCommand.self,from:JSONEncoder().encode(preview)),preview)
        XCTAssertTrue(doc.apply(preview,owner:"mac")); doc.cancel(owner:"mac"); XCTAssertNil(doc.active)
        XCTAssertTrue(doc.apply(command(.undo),owner:"ipad")); XCTAssertEqual(doc.snapshot.strokes,[original])
    }
    func testCancellationNoOpAndRotationValidation() throws {
        var doc = InkDocument(); let original = shape()
        func apply(_ action: InkAction) -> Bool { doc.apply(InkCommand(epoch:doc.snapshot.epoch,action:action),owner:"mac") }
        XCTAssertTrue(apply(.commit(original)))
        XCTAssertTrue(apply(.previewTransform(original:original,replacement:original)))
        XCTAssertTrue(apply(.commitTransform(original:original,replacement:original)))
        XCTAssertTrue(apply(.undo)); XCTAssertTrue(doc.snapshot.strokes.isEmpty)
        var invalid = shape(.line); invalid.rotation = 0.2; XCTAssertFalse(invalid.valid)
        invalid = original; invalid.rotation = .infinity; XCTAssertFalse(invalid.valid)
        let decoded = try JSONDecoder().decode(InkStroke.self,from:JSONEncoder().encode(original))
        XCTAssertNil(decoded.rotation)
    }
}
