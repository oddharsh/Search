// Written by stack.sh after its merges; empty outside a stack build, which
// keeps Settings › Flags hidden (see Flags.swift).

extension Stack {
    static let base = "fcad70a"
    static let date = "14 Nov 2026"
    static let features: [StackFeature] = [
        StackFeature(number: -1, title: "⌘L raises ⌘T's floating field, as in Arc", status: .custom, toggle: \.commandLLaunches),
        StackFeature(number: -2, title: "The floating field leaves the page under it uncovered", status: .custom, toggle: \.unwashedField),
        StackFeature(number: 358, title: "The tab switcher shows every space, a row for each, and takes the pointer", status: .partlyLanded, toggle: \.switcherSpaceRows),
        StackFeature(number: 427, title: "The window moves by the top of the page, as in Arc and Dia", status: .closed, toggle: \.pageMovesWindow),
        StackFeature(number: 477, title: "Full screen keeps the window's buttons in the column's corner", status: .closed, toggle: \.fullScreenLights),
        StackFeature(number: 487, title: "A click on the tab you're on renames it; its icon opens the address", status: .closed, toggle: \.clickRenamesTab),
        StackFeature(number: 497, title: "test: isolate build tests per checkout", status: .closed),
        StackFeature(number: 697, title: "fix: keep list numbers in reading mode", status: .closed),
        StackFeature(number: 711, title: "fix: keep uBlock blocking right after launch", status: .closed),
        StackFeature(number: 738, title: "feat: add filter lists to the blocker", status: .closed),
        StackFeature(number: 744, title: "Reduce work when offering saved sign-ins", status: .closed),
        StackFeature(number: 746, title: "feat: list open tabs in ⌘T's field", status: .closed),
        StackFeature(number: 795, title: "fix: extensions hear their install and keep refused rules", status: .closed),
        StackFeature(number: 941, title: "fix: keep tab icons on look switch", status: .closed),
        StackFeature(number: 945, title: "chore(build): a build off main is a yellow dev build", status: .closed),
        StackFeature(number: 960, title: "fix(overlay): one overlay holds the keyboard", status: .closed),
        StackFeature(number: 977, title: "feat(field): set the page back as Peek does", status: .closed),
        StackFeature(number: 978, title: "feat(curtain): hide elements with a compiled rule list", status: .closed),
        StackFeature(number: 1095, title: "fix(dusk): keep a sticky header dark on scroll", status: .open),
        StackFeature(number: 1097, title: "test(settings): FollowFileTests names foldsToIcons and instantMotion", status: .open),
    ]
}
