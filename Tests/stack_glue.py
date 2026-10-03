#!/usr/bin/env python3
"""Where two of the stack's pull requests meet, in a hidden probe: the keys
in the ⌃Tab switcher (#495) on another space's card (#358's rows).

Build first (`./build.sh`), then `python3 Tests/stack_glue.py`.
"""
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import split_view as sv  # noqa: E402
from tab_switcher import ctrl_tab, switcher, two_spaces  # noqa: E402


def press(code, ch):
    sv.cmd({"do": "press", "code": code, "chars": ch, "mods": ["ctrl"]}); time.sleep(0.6)


def main():
    t = sv.T()
    try:
        sv.setup(spaces=True, **{"switcher.spaces": True, "switcher.keys": True}); sv.launch()
        a, b, c, d = two_spaces()
        ctrl_tab()
        press(125, "")  # ⌃↓, to the other space's row
        s = switcher()
        there = s["shelves"][1]["tabs"]
        pick = s["selected"]
        t.ok("the pick is on another space's card", pick in there and pick in (c, d), s)
        press(46, "m")
        s = switcher()
        t.ok("⌃M mutes another space's tab, the switcher still up", pick in s["muted"] and s["visible"], s)
        press(46, "m")
        t.ok("⌃M again unmutes it", pick not in switcher()["muted"])
        press(13, "w")
        s = switcher()
        left = s["shelves"][1]["tabs"] if len(s["shelves"]) > 1 else []
        t.ok("⌃W closes it: out of its row, the switcher still up", s["visible"] and pick not in left, s)
        t.ok("and the space on screen is untouched", s["space"] != "Two" and {a, b} <= set(s["candidates"]), s)
        sv.cmd({"do": "press", "code": 53, "chars": "\x1b", "mods": ["ctrl"]}); time.sleep(0.4)
        # The rows are made afresh from each space's parked tabs: gone there,
        # gone from the space.
        ctrl_tab()
        s = switcher()
        t.ok("⌃Tab again: still gone from that space's row", len(s["shelves"]) == 2
             and pick not in s["shelves"][1]["tabs"] and ({c, d} - {pick}) <= set(s["shelves"][1]["tabs"]), s)
        sv.cmd({"do": "press", "code": 53, "chars": "\x1b", "mods": ["ctrl"]}); time.sleep(0.4)
    finally:
        t.done(); sv.finish()
    sys.exit(1 if t.failed else 0)


if __name__ == "__main__":
    main()
