import XCTest
@testable import Search

/// Each row of the field's list reads name over address (Omnibox.Row.lines),
/// whichever of key and title the kind keeps its name in.
@MainActor
final class OmniboxRowTests: XCTestCase {
    private let url = URL(string: "http://localhost:56908/parser")!

    private func lines(_ key: String, _ title: String, _ kind: Suggestion.Kind) -> [String] {
        let lines = Omnibox.Row.lines(Suggestion(key: key, title: title, url: url, kind: kind))
        return [lines.top, lines.under]
    }

    func testTheNameGoesOnTop() {
        // Built as openPages and the search row build them: the name, or
        // the words, in the key.
        XCTAssertEqual(lines("How to write a parser", "localhost:56908/parser", .open),
                       ["How to write a parser", "localhost:56908/parser"])
        XCTAssertEqual(lines("kett", "Google", .search), ["kett", "Google"])
        // A place's name is its title.
        XCTAssertEqual(lines("www.example.com/a", "Example", .visited), ["Example", "example.com/a"])
        XCTAssertEqual(lines("example.com/a", "Example", .bookmark), ["Example", "example.com/a"])
        XCTAssertEqual(lines("github.com", "GitHub", .known), ["GitHub", "github.com"])
    }

    func testNoTitleIsOneLine() {
        XCTAssertEqual(lines("www.example.com", "", .visited), ["example.com", ""])
        XCTAssertEqual(lines("kettle", "", .suggested), ["kettle", ""])
        let command = Omnibox.Row.lines(.command(.history))
        XCTAssertEqual([command.top, command.under], [AddressCommand.history.title, ""])
    }
}
