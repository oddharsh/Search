// Written by stack.sh after its merges; empty outside a stack build, which
// keeps Settings › Flags hidden (see Flags.swift).

extension Stack {
    static let base = "248edf8"
    static let date = "24 Oct 2026"
    static let features: [StackFeature] = [
        StackFeature(number: 358, title: "The tab switcher shows every space, a row for each, and takes the pointer", status: .partlyLanded, toggle: \.switcherSpaceRows),
        StackFeature(number: 427, title: "The window moves by the top of the page, as in Arc and Dia", status: .closed, toggle: \.pageMovesWindow),
        StackFeature(number: 477, title: "Full screen keeps the window's buttons in the column's corner", status: .closed, toggle: \.fullScreenLights),
        StackFeature(number: 487, title: "A click on the tab you're on renames it; its icon opens the address", status: .closed, toggle: \.clickRenamesTab),
        StackFeature(number: 497, title: "test: isolate build tests per checkout", status: .closed),
        StackFeature(number: 697, title: "fix: keep list numbers in reading mode", status: .closed),
        StackFeature(number: 701, title: "feat: strip click trackers and send GPC", status: .open),
        StackFeature(number: 705, title: "fix: offer to save scripted sign-ins", status: .open),
        StackFeature(number: 706, title: "perf: redraw only what changed", status: .open),
    ]
}
