import CoreGraphics
import XCTest
@testable import Search

/// Where the field over a page stands once dragged (Omnibox.place): kept
/// inside the page, and pulled home near it. A probe can't drag it.
final class FieldPlaceTests: XCTestCase {
    private let room = CGSize(width: 1200, height: 800)

    private func place(_ x: CGFloat, _ y: CGFloat, in room: CGSize? = nil) -> CGSize {
        Omnibox.place(CGSize(width: x, height: y), width: 640, in: room ?? self.room)
    }

    func testNearHomeIsHome() {
        XCTAssertEqual(place(0, 0), .zero)
        XCTAssertEqual(place(12, -15), .zero, "19 points off: caught")
        XCTAssertEqual(place(0, 20), .zero, "the edge of the catch is still home")
        XCTAssertEqual(place(21, 0), CGSize(width: 21, height: 0))
        XCTAssertEqual(place(-150, 90), CGSize(width: -150, height: 90))
    }

    func testKeptInsideThePage() {
        // 1200 wide, the field 640: 280 either side, less 24 of margin. Home
        // is 160 down, so 136 up; 800 - 24 - 52 - 160 down.
        XCTAssertEqual(place(1000, -1000), CGSize(width: 256, height: -136))
        XCTAssertEqual(place(-1000, 1000), CGSize(width: -256, height: 564))
    }

    func testFollowsTheWindow() {
        // Left far right in a wide window: a narrower one keeps it at its
        // edge, and the wide one gives it back.
        XCTAssertEqual(place(300, 0, in: CGSize(width: 1600, height: 800)), CGSize(width: 300, height: 0))
        XCTAssertEqual(place(300, 0), CGSize(width: 256, height: 0))
        // Narrower than the field: no room sideways, so only up and down,
        // and a little of that is home.
        XCTAssertEqual(place(300, 10, in: CGSize(width: 600, height: 400)), .zero)
        XCTAssertEqual(place(300, 100, in: CGSize(width: 600, height: 400)), CGSize(width: 0, height: 100))
    }
}
