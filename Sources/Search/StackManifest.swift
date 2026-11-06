// Written by stack.sh after its merges; empty outside a stack build, which
// keeps Settings › Flags hidden (see Flags.swift).

extension Stack {
    static let base = "21c557d"
    static let date = "6 Nov 2026"
    static let features: [StackFeature] = [
        StackFeature(number: -1, title: "⌘L raises ⌘T's floating field, as in Arc", status: .custom, toggle: \.commandLLaunches),
        StackFeature(number: -2, title: "The floating field leaves the page under it uncovered", status: .custom, toggle: \.unwashedField),
        StackFeature(number: 358, title: "The tab switcher shows every space, a row for each, and takes the pointer", status: .partlyLanded, toggle: \.switcherSpaceRows),
        StackFeature(number: 427, title: "The window moves by the top of the page, as in Arc and Dia", status: .closed, toggle: \.pageMovesWindow),
        StackFeature(number: 477, title: "Full screen keeps the window's buttons in the column's corner", status: .closed, toggle: \.fullScreenLights),
        StackFeature(number: 487, title: "A click on the tab you're on renames it; its icon opens the address", status: .closed, toggle: \.clickRenamesTab),
        StackFeature(number: 497, title: "test: isolate build tests per checkout", status: .closed),
        StackFeature(number: 697, title: "fix: keep list numbers in reading mode", status: .closed),
        StackFeature(number: 705, title: "fix: offer to save scripted sign-ins", status: .open),
        StackFeature(number: 706, title: "Reduce idle and per-page work", status: .open),
        StackFeature(number: 711, title: "fix: keep uBlock blocking right after launch", status: .open),
        StackFeature(number: 737, title: "fix: passkeys follow the running app's switch", status: .open),
        StackFeature(number: 738, title: "feat: add filter lists to the blocker", status: .open),
        StackFeature(number: 742, title: "Reduce tab redraws during typing and navigation", status: .open),
        StackFeature(number: 743, title: "Reduce work when switching tabs and resizing panels", status: .open),
        StackFeature(number: 744, title: "Reduce work when offering saved sign-ins", status: .open),
        StackFeature(number: 745, title: "Sleep idle tabs sooner in Low Power Mode", status: .open),
        StackFeature(number: 746, title: "feat: list open tabs in ⌘T's field", status: .open),
        StackFeature(number: 795, title: "fix: extensions hear their install and keep refused rules", status: .open),
        StackFeature(number: 917, title: "fix: draw an SVG favicon's dark look", status: .open),
        StackFeature(number: 941, title: "fix: keep tab icons on look switch", status: .open),
        StackFeature(number: 942, title: "fix: skip relook's fetch for loading tabs", status: .open),
        StackFeature(number: 945, title: "chore(build): a build off main is a yellow dev build", status: .open),
        StackFeature(number: 946, title: "feat(settings): look and layout follow a defaults write", status: .open),
    ]
}
