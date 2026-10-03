#!/usr/bin/env python3
"""The ⌃Tab switcher and the pointer, and every space in it, in a hidden
probe (#358, by oddharsh).

Build first (`./build.sh`), then `python3 Tests/tab_switcher.py`. ⌃Tab is
pressed through the app and a click is sent through it too, so the window's
event monitor sees them as it sees a hand's; no window is made or shown.
"""
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import split_view as sv  # noqa: E402


def switcher():
    return sv.cmd({"do": "switcher"})


def ctrl_tab():
    sv.cmd({"do": "press", "code": 48, "chars": "\t", "mods": ["ctrl"]}); time.sleep(0.8)


def two_spaces():
    """A and B in the first space, C and D in another, B in front. Each
    space also has the empty tab it started with."""
    a = sv.page("a"); b = sv.page("b")
    first = sv.sp("state")["spaceID"]
    sv.sp("space", spaceAction="new", name="Two"); time.sleep(1)
    c = sv.page("c"); d = sv.page("d")
    sv.sp("space", spaceAction="go", spaceID=first); time.sleep(1)
    sv.sp("select", id=b); time.sleep(0.4)
    return a, b, c, d


def spaces(t, rows):
    """With spaces, Settings › Tabs › Every space in the tab switcher off
    (the space on screen alone, as before) or on (a row for each)."""
    sv.setup(spaces=True, **{"switcher.spaces": rows}); sv.launch()
    a, b, c, d = two_spaces()
    ctrl_tab()
    s = switcher()
    if not rows:
        t.ok("off: ⌃Tab shows the space on screen alone", s["visible"] and s["shelves"] == []
             and {a, b} <= set(s["candidates"]) and not {c, d} & set(s["candidates"]), s)
        t.ok("off: the pick is the tab last left", s["selected"] == a, s)
        sv.cmd({"do": "press", "code": 125, "chars": "\uf701", "mods": ["ctrl"]}); time.sleep(0.3)
        t.ok("off: ⌃↓ in a grid of one row stays put", switcher()["selected"] == a)
        sv.cmd({"do": "press", "code": 53, "chars": "\x1b", "mods": ["ctrl"]}); time.sleep(0.4)
        return
    names = [shelf["space"] for shelf in s["shelves"]]
    t.ok("on: a row for each space, in ⌃1–⌃9 order", s["visible"] and len(names) == 2 and names[1] == "Two", s)
    here, there = s["shelves"][0]["tabs"], s["shelves"][1]["tabs"]
    t.ok("on: the first row is this space's, the one on screen first, the pick the one left last",
         here == s["candidates"] and here[:2] == [b, a] and s["selected"] == a, s)
    t.ok("on: the other row holds that space's tabs", {c, d} <= set(there) and not {a, b} & set(there), s)
    sv.cmd({"do": "press", "code": 125, "chars": "\uf701", "mods": ["ctrl"]}); time.sleep(0.3)
    s = switcher()
    t.ok("on: ⌃↓ goes to the row below, at the same place", s["selected"] == there[1], s)
    ctrl_tab()
    s = switcher()
    t.ok("on: Tab walks the row the pick is in", s["selected"] == there[2 % len(there)], s)
    pick = s["selected"]
    x, y, w, h = s["cards"][pick]
    sv.sp("mouse", points=[[x + w / 2, y + h / 2], [x + w / 2, y + h / 2]]); time.sleep(1)
    s = switcher()
    t.ok("on: a click on another space's card goes to that space and tab",
         not s["visible"] and s["space"] == "Two" and s["active"] == pick, s)


def main():
    t = sv.T()
    try:
        spaces(t, rows=False)
        spaces(t, rows=True)
        # Every space in the switcher asked for, with spaces off: the one
        # grid, as without it.
        sv.setup(**{"switcher.spaces": True}); sv.launch()
        a = sv.page("a"); b = sv.page("b"); c = sv.page("c")
        sv.sp("select", id=c); time.sleep(0.4)
        sv.cmd({"do": "press", "code": 48, "chars": "\t", "mods": ["ctrl"]}); time.sleep(0.8)
        s = switcher()
        t.ok("⌃Tab: the switcher is up", s["visible"] and len(s["candidates"]) >= 3, s)
        t.ok("without spaces, no rows of them", s["shelves"] == [], s)
        t.ok("its cards have their places", set(s["cards"]) >= {a, b, c} and s["panel"][2] > 0, s["cards"])
        x, y, w, h = s["cards"][a]
        sv.sp("mouse", points=[[x + w / 2, y + h / 2], [x + w / 2, y + h / 2]]); time.sleep(0.6)
        s = switcher()
        t.ok("a click on a card, ⌃ held: that tab", s["active"] == a and not s["visible"], s)
        sv.cmd({"do": "press", "code": 48, "chars": "\t", "mods": ["ctrl"]}); time.sleep(0.8)
        s = switcher()
        px, py, pw, ph = s["panel"]
        sv.sp("mouse", points=[[5, 5], [5, 5]]); time.sleep(0.6)
        s = switcher()
        t.ok("a click outside the panel puts the switcher away, the tab unchanged", not s["visible"] and s["active"] == a, s)
    finally:
        t.done(); sv.finish()
    sys.exit(1 if t.failed else 0)


if __name__ == "__main__":
    main()
