// Written by stack.sh after its merges; empty outside a stack build, which
// keeps Settings › Flags hidden (see Flags.swift).

extension Stack {
    static let base = "35aa051"
    static let date = "9 Oct 2026"
    static let features: [StackFeature] = [
        StackFeature(number: 358, title: "The tab switcher shows every space, a row for each, and takes the pointer", status: .partlyLanded, toggle: \.switcherSpaceRows),
        StackFeature(number: 427, title: "The window moves by the top of the page, as in Arc and Dia", status: .closed, toggle: \.pageMovesWindow),
        StackFeature(number: 429, title: "Tabs that close themselves, as in Arc: kept by a pin, a name or a group", status: .open, page: .tabs),
        StackFeature(number: 431, title: "A link's small window comes alone, and its keys act on its page", status: .open),
        StackFeature(number: 450, title: "Light pages darkened while Search is dark, in their own colours", status: .open, toggle: \.darkensPages),
        StackFeature(number: 472, title: "Settings › General › Home page, while an extension offers a page", status: .open),
        StackFeature(number: 474, title: "A swipe back from a small window's first page closes it", status: .open),
        StackFeature(number: 475, title: "A dev build is named for its branch, on a yellow icon", status: .open),
        StackFeature(number: 477, title: "Full screen keeps the window's buttons in the column's corner", status: .closed, toggle: \.fullScreenLights),
        StackFeature(number: 480, title: "Small windows in the ⌃Tab switcher", status: .open),
        StackFeature(number: 487, title: "A click on the tab you're on renames it; its icon opens the address", status: .closed, toggle: \.clickRenamesTab),
        StackFeature(number: 489, title: "build.sh records the SDK the app was built with", status: .open),
        StackFeature(number: 493, title: "New small windows cascade instead of stacking exactly", status: .open),
        StackFeature(number: 495, title: "Keys in the ⌃Tab switcher, off unless turned on", status: .open, toggle: \.switcherKeys),
        StackFeature(number: 497, title: "Each checkout's build tests in a world of its own", status: .open),
        StackFeature(number: 519, title: "A link from another app opens in the small window alone, with no window open", status: .closed),
        StackFeature(number: 562, title: "The floating video goes out and comes back in one step", status: .open),
        StackFeature(number: 567, title: "Hold or right-click Back and Forward for every page that way", status: .open),
    ]
}
