#!/usr/bin/env python3
"""⌘L as ⌘T, as in Arc, with the stack's switch on, in a hidden probe.

Build first (`./build.sh`), then `python3 Tests/floating_cmd_l.py`. It runs
in its own test world, with split_view.py's harness: started hidden,
everything removed afterwards.

With New tab in a floating field on and Prefs.commandLLaunches (field.cmdL,
in Settings › Flags) on, ⌘L raises the same empty field over the page that
⌘T does, and makes no tab until Return, which opens what was typed in a tab
of its own and leaves the page as it was. With field.cmdL off, ⌘L is
upstream's: the page's address, selected, to edit. Where ⌘T opens a tab rather than floating the field, as on
a blank tab, ⌘L is that too, and never makes a tab.
"""
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import split_view as sv  # noqa: E402

sv.use("floating-cmd-l")

t = sv.T()
def field(): return sv.cmd({"do": "sitesearch", "action": "state"})
def cmd_l(): sv.cmd({"do": "press", "code": 37, "chars": "l", "mods": ["cmd"]}); time.sleep(0.6)
def esc(): sv.cmd({"do": "press", "code": 53, "chars": "\x1b"}); time.sleep(0.4)
def front(): st = sv.sp("state"); return st, st["activeID"]
try:
    sv.setup(**{"newtab.floating": True, "field.cmdL": True})
    sv.launch()
    a = sv.page("a")
    sv.sp("select", id=a); time.sleep(0.3)

    before = len(sv.sp("state")["tabs"])
    cmd_l()
    st, active = front()
    up = field()
    t.ok("floating on: ⌘L raises the field over the page", up["editing"] and active == a, (up, active))
    t.ok("floating on: the field is empty, as ⌘T's is", up["typed"] == "", up["typed"])
    t.ok("floating on: no tab is made", len(st["tabs"]) == before, st["tabs"])
    esc()
    t.ok("floating on: Escape puts it away, the page as it was", not field()["editing"] and front()[1] == a)

    cmd_l()
    sv.cmd({"do": "field", "text": f"{sv.BASE}/b", "go": True})
    st, active = front()
    urls = {x["id"]: x["url"] for x in st["tabs"]}
    t.ok("floating on: Return opens a tab", len(st["tabs"]) == before + 1, st["tabs"])
    t.ok("floating on: the new tab is in front, at /b", active != a and urls[active].endswith("/b"), urls)
    t.ok("floating on: the page under the field still shows /a", urls[a].endswith("/a"), urls[a])

    # Where ⌘T opens a tab rather than floating the field, ⌘L doesn't: on a
    # blank tab it is that tab's field, and no tab is made or moved to.
    blank = next(x["id"] for x in sv.sp("state")["tabs"] if not x["url"])
    sv.sp("select", id=blank); time.sleep(0.3)
    before = len(sv.sp("state")["tabs"])
    cmd_l()
    st, active = front()
    t.ok("floating on, blank tab: ⌘L makes no tab", len(st["tabs"]) == before, st["tabs"])
    t.ok("floating on, blank tab: the blank tab stays in front", active == blank, active)
    t.ok("floating on, blank tab: ⌘L takes the field, as before", field()["editing"], field())
    esc()

    sv.quit()
    sv.setup(**{"newtab.floating": True, "field.cmdL": False})
    sv.launch()
    a = sv.page("a")
    sv.sp("select", id=a); time.sleep(0.3)

    before = len(sv.sp("state")["tabs"])
    cmd_l()
    st, active = front()
    up = field()
    t.ok("switch off: ⌘L raises the field over the page", up["editing"] and active == a, (up, active))
    t.ok("switch off: the field holds the page's address", up["typed"].endswith("/a"), up["typed"])
    t.ok("switch off: no tab is made", len(st["tabs"]) == before, st["tabs"])
    esc()
finally:
    t.done(); sv.finish()
sys.exit(1 if t.failed else 0)
